# تهيئة ضيف ويندوز: Git وFlutter وأدوات بناء Visual Studio.
#
# النسخة تأتي وسيطًا من Vagrantfile وهي نفس نسخة منصّة التكامل.
#
# أدوات Visual Studio هي الجزء الثقيل (نحو 10GB) وهي شرط لبناء ويندوز:
# Flutter يترجم الغلاف الأصلي بـMSVC.

param([Parameter(Mandatory = $true)][string]$Version)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
  Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = 3072
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
    'https://community.chocolatey.org/install.ps1'))
  $env:PATH = "$env:PATH;C:\ProgramData\chocolatey\bin"
}

# Git يجلب bash، وبه يعمل tools/checks.sh نفسه بلا قائمة فحوص ثانية.
choco install -y --no-progress git

choco install -y --no-progress visualstudio2022buildtools
choco install -y --no-progress visualstudio2022-workload-vctools

$flutter = "C:\flutter"
if (-not (Test-Path "$flutter\bin\flutter.bat")) {
  $archive = "flutter_windows_$Version-stable.zip"
  $url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/$archive"
  Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\$archive"
  Expand-Archive -Path "$env:TEMP\$archive" -DestinationPath "C:\" -Force
  Remove-Item "$env:TEMP\$archive"
}

[Environment]::SetEnvironmentVariable(
  "PATH", "$flutter\bin;" + [Environment]::GetEnvironmentVariable("PATH", "Machine"), "Machine")
$env:PATH = "$flutter\bin;$env:PATH"

& "$flutter\bin\flutter.bat" --version
& "$flutter\bin\flutter.bat" config --enable-windows-desktop --no-analytics
