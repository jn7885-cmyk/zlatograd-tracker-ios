#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo "This requires a valid Apple Developer signing setup in Xcode."
flutter clean
flutter pub get
flutter build ipa --release
