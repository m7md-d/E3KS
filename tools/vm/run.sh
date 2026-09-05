#!/usr/bin/env bash
#
# الواجهة الموحّدة: يشغّل `tools/checks.sh` داخل كل آلة في المصفوفة.
#
#   ./tools/vm/run.sh                 كل ما يتوفّر مزوّده على هذا المضيف
#   ./tools/vm/run.sh linux windows   آلات بعينها
#   ./tools/vm/run.sh --halt          يوقفها بعد الفراغ
#   ./tools/vm/run.sh --destroy       يحذفها ويستردّ المساحة
#   ./tools/vm/run.sh --recreate      يهدم وينشئ من جديد قبل الفحص
#
# **الآلات تُعرَّف في `machines.conf` وحده**، ومنه يقرأ هذا السكربت ويقرأ
# `Vagrantfile`. المزوّد عمود في ذلك الملف: Vagrant لما يدعمه، وTart لضيف
# macOS. تبديل مزوّد آلة تغييرُ كلمة، لا تعديلُ سكربت.
#
# ولا يُنصَّب شيء من هنا: ينقص المزوّد فتُتخطّى آلته ويُطبع أمر تنصيبه (`06` §1).
#
# القرص: نحو 10GB لضيف لينكس، و60GB لويندوز بأدوات Visual Studio، و80GB
# لصورة macOS المحمَّلة بـXcode. و`--destroy` يستردّها.

set -uo pipefail

self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
here="$(dirname "$self")"
root="$(cd "$here/../.." && pwd)"
conf="$here/machines.conf"
cd "$here" || exit 1

# ما لا يُنسَخ إلى الضيف: يُبنى هناك من جديد.
EXCLUDES="--exclude=.git/ --exclude=.dart_tool/ --exclude=build/ --exclude=docs/screenshots/"

# بيانات الدخول إلى ضيف macOS: خارج ملف التعريف لأنها بيئة لا بنية.
macos_user="${E3KS_MACOS_USER:-admin}"
macos_password="${E3KS_MACOS_PASSWORD:-admin}"
ssh_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

after=""
recreate=0
machines=""

for arg in "$@"; do
  case "$arg" in
    --halt) after=halt ;;
    --destroy) after=destroy ;;
    --recreate) recreate=1 ;;
    -h | --help)
      sed -n '3,20p' "$self" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*)
      printf 'وسيط غير معروف: %s\n' "$arg" >&2
      exit 2
      ;;
    *) machines="$machines $arg" ;;
  esac
done

have() { command -v "$1" >/dev/null 2>&1; }

# قراءة ملف التعريف: العمود الأول اسم، ثم مزوّد ونظام وصورة ونواة وذاكرة.
names() { awk '$1 ~ /^#/ {next} NF >= 6 {print $1}' "$conf"; }
field() { awk -v n="$1" -v c="$2" '$1 ~ /^#/ {next} NF >= 6 && $1 == n {print $c; exit}' "$conf"; }

[ -r "$conf" ] || {
  printf 'ملف التعريف مفقود: %s\n' "$conf" >&2
  exit 2
}

if [ -z "$machines" ]; then
  for name in $(names); do
    have "$(field "$name" 2)" && machines="$machines $name"
  done
  if [ -z "$machines" ]; then
    printf 'لا مزوّد على هذا المضيف.\n' >&2
    printf '  Vagrant: sudo apt-get install -y vagrant virtualbox\n' >&2
    printf '  Tart:    brew install cirruslabs/cli/tart sshpass\n' >&2
    exit 2
  fi
fi

# ---------------------------------------------------------------- Vagrant

run_vagrant() {
  machine="$1"
  [ "$recreate" -eq 1 ] && vagrant destroy -f "$machine" >/dev/null 2>&1
  vagrant up "$machine" --provision-with setup || return 1
  vagrant provision "$machine" --provision-with checks || return 2
}

finish_vagrant() {
  case "$after" in
    halt) vagrant halt "$1" >/dev/null 2>&1 ;;
    destroy) vagrant destroy -f "$1" >/dev/null 2>&1 ;;
  esac
}

# ------------------------------------------------------------------- Tart

run_tart() {
  machine="$1"
  vm="e3ks-$machine"
  image="$(field "$machine" 4)"
  cpus="$(field "$machine" 5)"
  memory="$(field "$machine" 6)"

  have sshpass || {
    printf 'sshpass غير موجود: brew install sshpass\n' >&2
    return 1
  }

  [ "$recreate" -eq 1 ] && tart delete "$vm" >/dev/null 2>&1

  if ! tart list --format json 2>/dev/null | grep -q "\"$vm\""; then
    printf 'استنساخ %s — يطول أول مرّة.\n' "$image"
    tart clone "$image" "$vm" || return 1
    tart set "$vm" --cpu "$cpus" --memory "$memory" >/dev/null 2>&1
  fi

  tart run --no-graphics "$vm" >/dev/null 2>&1 &
  tart_pid=$!

  ip=""
  attempt=0
  while [ "$attempt" -lt 60 ]; do
    ip="$(tart ip "$vm" 2>/dev/null)"
    [ -n "$ip" ] && break
    attempt=$((attempt + 1))
    sleep 2
  done

  if [ -z "$ip" ]; then
    printf 'تعذّر الحصول على عنوان الضيف.\n' >&2
    kill "$tart_pid" >/dev/null 2>&1
    return 1
  fi

  # الشجرة الحالية تُنسَخ كما هي، بلا التزام ولا دفع.
  if ! rsync -az --delete $EXCLUDES \
    -e "sshpass -p $macos_password ssh $ssh_opts" \
    "$root/" "$macos_user@$ip:e3ks/"; then
    kill "$tart_pid" >/dev/null 2>&1
    return 1
  fi

  sshpass -p "$macos_password" ssh $ssh_opts "$macos_user@$ip" \
    'cd ~/e3ks && ./tools/checks.sh'
  status=$?

  case "$after" in
    halt | destroy) tart stop "$vm" >/dev/null 2>&1 ;;
  esac
  kill "$tart_pid" >/dev/null 2>&1
  [ "$after" = destroy ] && tart delete "$vm" >/dev/null 2>&1

  [ "$status" -eq 0 ] || return 2
  return 0
}

# ------------------------------------------------------------------ تشغيل

failures=0
report=""

for machine in $machines; do
  backend="$(field "$machine" 2)"
  if [ -z "$backend" ]; then
    printf 'آلة غير معرَّفة في %s: %s\n' "$conf" "$machine" >&2
    exit 2
  fi
  if ! have "$backend"; then
    printf '[متخطّى] %s: %s غير منصَّب على هذا المضيف\n' "$machine" "$backend"
    continue
  fi

  printf '\n======== %s (%s) ========\n' "$machine" "$backend"

  case "$backend" in
    vagrant) run_vagrant "$machine" ;;
    tart) run_tart "$machine" ;;
    *)
      printf 'مزوّد غير معروف: %s\n' "$backend" >&2
      exit 2
      ;;
  esac
  status=$?

  case "$status" in
    0) printf '[سليم]  %s\n' "$machine" ;;
    1)
      printf '[فشل]   %s: تعذّرت التهيئة\n' "$machine"
      report="$report\n  $machine: تهيئة"
      failures=$((failures + 1))
      ;;
    *)
      printf '[فشل]   %s: سقطت الفحوص\n' "$machine"
      report="$report\n  $machine: فحوص"
      failures=$((failures + 1))
      ;;
  esac

  [ "$backend" = vagrant ] && finish_vagrant "$machine"
done

printf '\n----------------------------------------\n'
printf 'الآلات:%s\n' "$machines"

if [ "$failures" -gt 0 ]; then
  printf 'سقط:%b\n' "$report"
  exit 1
fi

printf 'النتيجة: كل الآلات سليمة.\n'
