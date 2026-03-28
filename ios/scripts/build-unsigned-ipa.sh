#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script must be run on macOS." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_PATH="${IOS_DIR}/VkTurnProxyIOS.xcodeproj"
SCHEME="${SCHEME:-VkTurnProxyIOS}"
CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_ROOT="${BUILD_ROOT:-${IOS_DIR}/build/unsigned}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${BUILD_ROOT}/DerivedData}"
APP_NAME="${APP_NAME:-VkTurnProxyIOS}"
OUTPUT_IPA_PATH="${OUTPUT_IPA_PATH:-${BUILD_ROOT}/${APP_NAME}-unsigned.ipa}"

if [[ ! -d "${PROJECT_PATH}" ]]; then
  echo "Xcode project not found. Preparing build artifacts first..."
  "${SCRIPT_DIR}/prepare-macos-build.sh"
fi

rm -rf "${BUILD_ROOT}"
mkdir -p "${BUILD_ROOT}/Payload"

echo "Building unsigned iPhoneOS app..."
xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  clean build

APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}-iphoneos/${APP_NAME}.app"

if [[ ! -d "${APP_PATH}" ]]; then
  echo "Built app not found at ${APP_PATH}" >&2
  exit 1
fi

cp -R "${APP_PATH}" "${BUILD_ROOT}/Payload/"

cd "${BUILD_ROOT}"
/usr/bin/zip -qry "${OUTPUT_IPA_PATH}" Payload

echo "Unsigned IPA created at ${OUTPUT_IPA_PATH}"
echo "Use AltStore/AltServer to sign and install this IPA with your Apple ID."
