#!/usr/bin/env bash
# تهيئة ضيف لينكس: أدوات بناء Flutter لسطح المكتب.
#
# النسخة تأتي وسيطًا من `Vagrantfile` وهي **نفس نسخة منصّة التكامل**، فما
# يمرّ هنا يمرّ هناك. حزمة مختلفة تعني بيئة مختلفة، والفحص يفقد معناه.

set -euo pipefail

version="${1:?نسخة Flutter مطلوبة}"
root=/opt/flutter

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
  git curl unzip xz-utils zip rsync \
  clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev

if [ ! -x "$root/bin/flutter" ]; then
  archive="flutter_linux_${version}-stable.tar.xz"
  url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/$archive"
  curl -fsSL "$url" -o "/tmp/$archive"
  rm -rf "$root"
  tar -xf "/tmp/$archive" -C /opt
  rm -f "/tmp/$archive"
fi

# المستودع مملوك للمضيف من منظور git داخل الضيف.
git config --system --add safe.directory "$root"
chown -R vagrant:vagrant "$root"

printf 'export PATH="%s/bin:$PATH"\n' "$root" > /etc/profile.d/flutter.sh
chmod +x /etc/profile.d/flutter.sh

sudo -u vagrant env PATH="$root/bin:$PATH" flutter --version
sudo -u vagrant env PATH="$root/bin:$PATH" flutter config --enable-linux-desktop --no-analytics
