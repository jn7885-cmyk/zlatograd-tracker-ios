#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
flutter clean
flutter pub get
flutter build ios --debug --no-codesign
