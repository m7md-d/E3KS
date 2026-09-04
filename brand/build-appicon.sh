#!/bin/bash
# يبني مجموعة أيقونة macOS من `e3ks-icon.svg` — المصدر الواحد للرمز (`07`).
#
# بلا أي تنصيب: يرسم Chrome الموجود على الجهاز، ويقيس `sips` من نظام macOS.
# لا يُعاد رسم شيء بيدنا، فأي تعديل على الـSVG يسري على الأيقونة بأمر واحد.
#
#   ./brand/build-appicon.sh
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
out="$here/../apps/e3ks_desktop/macos/Runner/Assets.xcassets/AppIcon.appiconset"
chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

[ -x "$chrome" ] || { echo "لم أجد Chrome — وهو الراسم الوحيد المتاح بلا تنصيب."; exit 1; }

# شبكة أيقونات macOS: جسم الرمز ‎824‎ داخل لوحة ‎1024‎ شفّافة، فيبقى الهامش
# الذي يتوقّعه Dock وLaunchpad. نصف قطر الـSVG ‎(114/512)‎ يطابق ‎(185/824)‎.
wrap() {  # ملف SVG ← صفحة بمقاس أيقونة
python3 - "$1" "$2" <<'PY'
import sys
source, target = sys.argv[1], sys.argv[2]
svg = open(source, encoding='utf-8').read()
inner = svg[svg.index('>', svg.index('<svg')) + 1 : svg.rindex('</svg>')]
open(target, 'w', encoding='utf-8').write(
    '<!doctype html><meta charset="utf-8">'
    '<style>html,body{margin:0;padding:0;background:transparent}</style>'
    '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" '
    'viewBox="0 0 1024 1024">'
    '<g transform="translate(100,100) scale(1.609375)">' + inner + '</g></svg>'
)
PY
}

shoot() {  # صفحة ← PNG بمقاس 1024
  "$chrome" --headless --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=1 --default-background-color=00000000 \
    --window-size=1024,1024 --screenshot="$2" "file://$1" >/dev/null 2>&1
}

wrap "$here/e3ks-icon.svg"       "$work/full.html"
wrap "$here/e3ks-icon-small.svg" "$work/small.html"
shoot "$work/full.html"  "$work/app_icon_1024.png"
shoot "$work/small.html" "$work/small.png"

# النسخة الكاملة من ‎128‎ فما فوق، ونسخة الأحجام الصغيرة لما دونها: عند ‎16px‎
# يذوب الشريط الرفيع والزاوية المدوَّرة فيصير الرمز لطخة.
for size in 512 256 128; do
  sips -Z "$size" "$work/app_icon_1024.png" --out "$work/app_icon_$size.png" >/dev/null
done
for size in 64 32 16; do
  sips -Z "$size" "$work/small.png" --out "$work/app_icon_$size.png" >/dev/null
done

cp "$work"/app_icon_*.png "$out/"
echo "تمّت الأيقونة في $out"
