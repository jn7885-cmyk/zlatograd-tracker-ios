#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [ -d ios/Runner.xcworkspace ]; then
  open ios/Runner.xcworkspace
else
  open ios/Runner.xcodeproj
fi
