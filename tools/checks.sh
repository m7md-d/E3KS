#!/usr/bin/env bash
#
# فحوص المشروع كلها بأمر واحد، على أي نظام.
#
#   ./tools/checks.sh              كل الفحوص، ثم بناء نظام الجهاز
#   ./tools/checks.sh --no-build   الفحوص وحدها (أسرع في حلقة العمل)
#
# **هذا الملف هو ما تشغّله منصّة التكامل أيضًا** (`checks.yml`)، فما يمرّ
# عندك يمرّ عندها. الفرق الوحيد بينهما بيئة العامل، لا قائمة الفحوص.
#
# ولا يبني إلا نظام الجهاز الذي يشغّله: بناء كل منصّة يحتاج أدواتها. ويندوز
# يحتاج ويندوز، وmacOS يحتاج جهاز Apple. البقيّة على `build.yml`.

set -uo pipefail

self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
root="$(cd "$(dirname "$self")/.." && pwd)"
cd "$root" || exit 1

build=1
for arg in "$@"; do
  case "$arg" in
    --no-build) build=0 ;;
    -h|--help)
      sed -n '3,13p' "$self" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      printf 'وسيط غير معروف: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

command -v flutter >/dev/null 2>&1 || {
  printf 'flutter غير موجود في PATH.\n' >&2
  exit 2
}

case "$(uname -s)" in
  Darwin) host=macos ;;
  Linux) host=linux ;;
  MINGW* | MSYS* | CYGWIN*) host=windows ;;
  *) host="" ;;
esac

failures=0
skipped=""

# لقطة لملفات الترجمة المولَّدة **قبل** حلّ الحزم: `pub get` يعيد توليدها من
# ملفات ARB، فمقارنتها بعده تكشف أن الملتزَم قديم. حدث هذا فعلًا: صياغة
# عُدّلت في ARB بلا إعادة توليد، فمرّ محليًّا وسقط على العامل.
l10n_snapshot="$(mktemp -d)"
trap 'rm -rf "$l10n_snapshot"' EXIT
cp apps/e3ks_desktop/lib/l10n/app_localizations*.dart "$l10n_snapshot/" 2>/dev/null

step() {
  name="$1"
  shift
  printf '\n=== %s\n' "$name"
  if "$@"; then
    printf '[سليم]  %s\n' "$name"
  else
    printf '[فشل]   %s\n' "$name"
    failures=$((failures + 1))
  fi
}

# `--enforce-lockfile`: نفس نسخ الحزم الملتزَمة بالضبط، فلا يختلف المبنيّ
# عمّا اختُبر. وحلّ الحزم يسبق التنسيق لأن `dart format` يقرأ إصدار اللغة
# من `package_config.json`؛ بلا ذلك يختلف ناتجه.
resolve() {
  (cd packages/e3ks_engine && dart pub get --enforce-lockfile) &&
    (cd tools/e3ks_cli && dart pub get --enforce-lockfile) &&
    (cd apps/e3ks_desktop && flutter pub get --enforce-lockfile)
}

check_l10n() {
  for file in apps/e3ks_desktop/lib/l10n/app_localizations*.dart; do
    if ! diff -q "$l10n_snapshot/$(basename "$file")" "$file" >/dev/null 2>&1; then
      printf 'ملفات الترجمة المولَّدة قديمة. أعيد توليدها الآن — التزمها.\n'
      return 1
    fi
  done
  return 0
}

check_format() {
  dart format --output=none --set-exit-if-changed \
    packages/e3ks_engine/lib packages/e3ks_engine/test \
    apps/e3ks_desktop/lib apps/e3ks_desktop/test apps/e3ks_desktop/tool \
    tools/e3ks_cli/bin tools/e3ks_cli/lib tools/release
}

check_version() {
  dart tools/release/bump_version.dart --check
}

check_engine() {
  (cd packages/e3ks_engine && dart analyze --fatal-infos && dart test)
}

check_cli() {
  (cd tools/e3ks_cli && dart analyze --fatal-infos)
}

check_app() {
  (cd apps/e3ks_desktop && flutter analyze --fatal-infos && flutter test)
}

build_host() {
  (cd apps/e3ks_desktop && flutter build "$host" --release)
}

step "حلّ الحزم" resolve
step "الترجمة المولَّدة" check_l10n
step "التنسيق" check_format
step "رقم الإصدار" check_version
step "المحرّك: تحليل واختبار" check_engine
step "سطر الأوامر: تحليل" check_cli
step "التطبيق: تحليل واختبار" check_app

if [ "$build" -eq 1 ]; then
  if [ -z "$host" ]; then
    skipped="نظام غير معروف"
  elif [ "$host" = linux ] && ! pkg-config --exists gtk+-3.0 2>/dev/null; then
    skipped="بناء لينكس: تنقص حزم GTK"
    printf '\nلبناء لينكس:\n  sudo apt-get install -y ninja-build libgtk-3-dev clang cmake pkg-config\n'
  else
    step "بناء $host" build_host
  fi
fi

printf '\n----------------------------------------\n'
case "$host" in
  macos) printf 'لم يُبنَ هنا: windows و linux — كلٌّ يحتاج نظامه.\n' ;;
  linux) printf 'لم يُبنَ هنا: windows و macos — كلٌّ يحتاج نظامه.\n' ;;
  windows) printf 'لم يُبنَ هنا: macos و linux — كلٌّ يحتاج نظامه.\n' ;;
esac
printf 'ما لا يُبنى هنا يبنيه build.yml على منصّة التكامل.\n'

[ -n "$skipped" ] && printf 'متخطّى: %s\n' "$skipped"

if [ "$failures" -gt 0 ]; then
  printf 'النتيجة: %d فحصًا فشل.\n' "$failures"
  exit 1
fi

printf 'النتيجة: كل الفحوص سليمة.\n'
