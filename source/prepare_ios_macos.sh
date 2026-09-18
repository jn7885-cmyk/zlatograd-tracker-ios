#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "=== Zlatograd Tracker v2.5.0 - iOS setup ==="

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: Flutter is not in PATH."
  exit 1
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "ERROR: Xcode is not installed or command line tools are not selected."
  exit 1
fi

echo "[1/6] Creating iOS shell with installed Flutter..."
flutter create --platforms=ios --org bg.zlatograd --project-name zlatograd_tracker .

echo "[2/6] Resolving Flutter packages..."
flutter pub get

echo "[3/6] Applying iOS permissions, background GPS, local network and zlatograd:// deep link..."
PLIST="ios/Runner/Info.plist"
PB="/usr/libexec/PlistBuddy"

set_plist_string() {
  local key="$1"
  local value="$2"
  "$PB" -c "Delete :$key" "$PLIST" >/dev/null 2>&1 || true
  "$PB" -c "Add :$key string $value" "$PLIST"
}

set_plist_bool() {
  local key="$1"
  local value="$2"
  "$PB" -c "Delete :$key" "$PLIST" >/dev/null 2>&1 || true
  "$PB" -c "Add :$key bool $value" "$PLIST"
}

set_plist_string NSCameraUsageDescription "Камерата се използва само за сканиране на QR кода на състезателя."
set_plist_string NSLocationWhenInUseUsageDescription "Местоположението се използва за GPS проследяване на участника по време на състезанието."
set_plist_string NSLocationAlwaysAndWhenInUseUsageDescription "GPS проследяването трябва да продължи и когато екранът е заключен или приложението е на заден план по време на активно състезание."
set_plist_string NSLocalNetworkUsageDescription "Приложението се свързва с локалния състезателен сървър на Zlatograd Bike n'Run."

"$PB" -c "Delete :UIBackgroundModes" "$PLIST" >/dev/null 2>&1 || true
"$PB" -c "Add :UIBackgroundModes array" "$PLIST"
"$PB" -c "Add :UIBackgroundModes:0 string location" "$PLIST"

"$PB" -c "Delete :NSLocationTemporaryUsageDescriptionDictionary" "$PLIST" >/dev/null 2>&1 || true
"$PB" -c "Add :NSLocationTemporaryUsageDescriptionDictionary dict" "$PLIST"
"$PB" -c "Add :NSLocationTemporaryUsageDescriptionDictionary:RaceTracking string За точно време и позиция по трасето е необходима прецизна GPS локация." "$PLIST"

"$PB" -c "Delete :CFBundleURLTypes" "$PLIST" >/dev/null 2>&1 || true
"$PB" -c "Add :CFBundleURLTypes array" "$PLIST"
"$PB" -c "Add :CFBundleURLTypes:0 dict" "$PLIST"
"$PB" -c "Add :CFBundleURLTypes:0:CFBundleURLName string bg.zlatograd.zlatograd_tracker" "$PLIST"
"$PB" -c "Add :CFBundleURLTypes:0:CFBundleTypeRole string Editor" "$PLIST"
"$PB" -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$PLIST"
"$PB" -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string zlatograd" "$PLIST"

# Test/LAN mode: Race Control currently may use plain HTTP on a local network.
# Before App Store release, move the server to HTTPS and tighten/remove this exception.
"$PB" -c "Delete :NSAppTransportSecurity" "$PLIST" >/dev/null 2>&1 || true
"$PB" -c "Add :NSAppTransportSecurity dict" "$PLIST"
"$PB" -c "Add :NSAppTransportSecurity:NSAllowsLocalNetworking bool true" "$PLIST"
"$PB" -c "Add :NSAppTransportSecurity:NSAllowsArbitraryLoads bool true" "$PLIST"

# app_links owns deep-link delivery. Disable Flutter's built-in deep-link handler to avoid duplicate handling.
set_plist_bool FlutterDeepLinkingEnabled false

echo "[4/6] Formatting Dart..."
dart format lib

echo "[5/6] Flutter analyze..."
flutter analyze

echo "[6/6] No-sign iOS compile check..."
flutter build ios --debug --no-codesign

echo
echo "SUCCESS: iOS source and debug no-sign build are ready."
echo "Next: open ios/Runner.xcworkspace (or Runner.xcodeproj), select your Apple Team and physical iPhone, then Run."
