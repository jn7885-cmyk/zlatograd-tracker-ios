#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "=== Zlatograd Tracker v2.5.1 - iOS setup ==="

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: Flutter is not in PATH."
  exit 1
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "ERROR: Xcode is not installed or command line tools are not selected."
  exit 1
fi

echo "[1/7] Restoring Zlatograd failover2 tracker source..."
python3 - <<'PY'
import base64
import gzip
from pathlib import Path

parts = sorted(Path("source_parts").glob("main.failover2.b64.[0-9][0-9]"))
if not parts:
    raise SystemExit("ERROR: failover2 tracker source archive is missing")
encoded = "".join(p.read_text(encoding="utf-8").strip() for p in parts)
raw = gzip.decompress(base64.b64decode(encoded))
Path("/tmp/zlatograd_main.dart").write_bytes(raw)
print(f"Restored failover2 tracker main.dart from {len(parts)} parts: {len(raw)} bytes")
PY

echo "[2/7] Creating iOS shell with installed Flutter..."
flutter create --platforms=ios --org bg.zlatograd --project-name zlatograd_tracker .
cp /tmp/zlatograd_main.dart lib/main.dart
python3 - <<'PY'
from pathlib import Path

p = Path("lib/main.dart")
lines = p.read_text(encoding="utf-8").splitlines()
out = []
for line in lines:
    indent = line[:len(line) - len(line.lstrip())]
    body = line[len(indent):]
    if body.startswith("if ("):
        depth = 0
        close = -1
        for idx, ch in enumerate(body[3:], start=3):
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    close = idx
                    break
        if close >= 0:
            tail = body[close + 1:].strip()
            if tail and not tail.startswith("{") and tail.endswith(";"):
                out.append(indent + body[:close + 1] + " {")
                out.append(indent + "  " + tail)
                out.append(indent + "}")
                continue
    out.append(line)
p.write_text("\n".join(out) + "\n", encoding="utf-8")
PY
rm -f test/widget_test.dart

echo "[3/7] Resolving Flutter packages..."
flutter pub get

echo "[4/7] Applying iOS permissions, background GPS, local network and zlatograd:// deep link..."
python3 - <<'PY'
from pathlib import Path
import plistlib

path = Path("ios/Runner/Info.plist")
with path.open("rb") as f:
    plist = plistlib.load(f)

plist["NSCameraUsageDescription"] = "Камерата се използва само за сканиране на QR кода на състезателя."
plist["NSLocationWhenInUseUsageDescription"] = "Местоположението се използва за GPS проследяване на участника по време на състезанието."
plist["NSLocationAlwaysAndWhenInUseUsageDescription"] = "GPS проследяването трябва да продължи и когато екранът е заключен или приложението е на заден план по време на активно състезание."
plist["NSLocalNetworkUsageDescription"] = "Приложението се свързва с локалния състезателен сървър на Zlatograd Bike n Run."
plist["UIBackgroundModes"] = ["location"]
plist["NSLocationTemporaryUsageDescriptionDictionary"] = {
    "RaceTracking": "За точно време и позиция по трасето е необходима прецизна GPS локация."
}
plist["CFBundleURLTypes"] = [{
    "CFBundleURLName": "bg.zlatograd.zlatograd_tracker",
    "CFBundleTypeRole": "Editor",
    "CFBundleURLSchemes": ["zlatograd"],
}]
plist["NSAppTransportSecurity"] = {
    "NSAllowsLocalNetworking": True,
    "NSAllowsArbitraryLoads": True,
}
plist["FlutterDeepLinkingEnabled"] = False

with path.open("wb") as f:
    plistlib.dump(plist, f, fmt=plistlib.FMT_XML, sort_keys=False)

print("Info.plist updated successfully")
PY

echo "[5/7] Applying Dart fixes and formatting..."
dart fix --apply
dart format lib

echo "[6/7] Flutter analyze..."
flutter analyze

echo "[7/7] No-sign iOS compile check..."
flutter build ios --debug --no-codesign

echo
echo "SUCCESS: iOS failover source and debug no-sign build are ready."
