#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Expo iOS development build requires macOS with Xcode installed." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${APP_DIR}/.." && pwd)"
MODULE_FRAMEWORKS_DIR="${APP_DIR}/modules/vk-turn-core/ios/Frameworks"
SOURCE_FRAMEWORK="${ROOT_DIR}/ios/Frameworks/VkTurnCore.xcframework"

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to prepare the Expo development build." >&2
  exit 1
fi

echo "Building VkTurnCore.xcframework..."
"${ROOT_DIR}/bridge/scripts/build-ios-framework.sh"

if [[ ! -d "${SOURCE_FRAMEWORK}" ]]; then
  echo "Expected framework was not produced at ${SOURCE_FRAMEWORK}" >&2
  exit 1
fi

echo "Syncing framework into local Expo module..."
mkdir -p "${MODULE_FRAMEWORKS_DIR}"
rm -rf "${MODULE_FRAMEWORKS_DIR}/VkTurnCore.xcframework"
cp -R "${SOURCE_FRAMEWORK}" "${MODULE_FRAMEWORKS_DIR}/"

cd "${APP_DIR}"

if [[ ! -d "${APP_DIR}/node_modules" ]]; then
  echo "Installing JavaScript dependencies..."
  npm install
fi

echo "Generating native iOS project..."
npx expo prebuild --platform ios

echo "Installing CocoaPods..."
npx pod-install

echo "Ready: run 'npx expo run:ios --device' from ${APP_DIR}"
