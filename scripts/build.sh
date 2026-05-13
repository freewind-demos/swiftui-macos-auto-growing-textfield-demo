#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/System/Volumes/Data/Applications/Xcode.app/Contents/Developer}"

cd "$ROOT"

PROJ_NAME="$(rtk yq -r '.name' project.yml)"
if [[ -z "${PROJ_NAME}" ]]; then
  echo "error: could not read name from project.yml" >&2
  exit 1
fi

rtk xcodegen generate
DERIVED="${ROOT}/build/DerivedData"
rtk rm -rf "$DERIVED"

rtk xcodebuild -project "${PROJ_NAME}.xcodeproj" \
  -scheme "${PROJ_NAME}" \
  -configuration Debug \
  -derivedDataPath "${DERIVED}" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  build

echo "Debug app: ${DERIVED}/Build/Products/Debug/${PROJ_NAME}.app"

