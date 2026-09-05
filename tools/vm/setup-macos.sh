#!/usr/bin/env bash
set -e

FLUTTER_VERSION="${1:-3.47.2}"
# رابط نسخة الماك لمعالجات Intel (لأن QEMU/KVM على معالجك AMD يحاكي Intel x64)
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_${FLUTTER_VERSION}-stable.zip"

echo "====> إعداد نظام macOS وتثبيت Flutter $FLUTTER_VERSION <===="

# 1. التأكد من تحديث Homebrew (إذا كان موجوداً في الصندوق)
if command -v brew >/dev/null 2>&1; then
  echo "--> جاري تحديث Homebrew..."
  brew update >/dev/null 2>&1
fi

# 2. تحميل وتثبيت Flutter في مجلد المستخدم
if [ ! -d "$HOME/flutter" ]; then
  echo "--> جاري تحميل Flutter نسخة الماك..."
  curl -sL "$FLUTTER_URL" -o /tmp/flutter.zip
  
  echo "--> جاري فك الضغط..."
  unzip -q /tmp/flutter.zip -d "$HOME"
  rm /tmp/flutter.zip
else
  echo "--> Flutter متوفر مسبقاً."
fi

# 3. إضافة Flutter إلى متغيرات البيئة (PATH)
if ! grep -q "flutter/bin" "$HOME/.zprofile" 2>/dev/null; then
  echo 'export PATH="$HOME/flutter/bin:$PATH"' >> "$HOME/.zprofile"
  echo 'export PATH="$HOME/flutter/bin:$PATH"' >> "$HOME/.bash_profile" 2>/dev/null || true
fi

export PATH="$HOME/flutter/bin:$PATH"

# 4. الإعداد الأولي وإلغاء التتبع
echo "--> تجهيز بيئة Flutter..."
flutter config --no-analytics >/dev/null
flutter precache >/dev/null

echo "====> اكتمل الإعداد بنجاح! <===="
