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
PRODUCT_BUNDLE_IDENTIFIER="${PRODUCT_BUNDLE_IDENTIFIER:-com.cheburnet.vkturnproxyios}"
ARCHIVE_PATH="${ARCHIVE_PATH:-${IOS_DIR}/build/VkTurnProxyIOS.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-${IOS_DIR}/build/export}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-}"

if [[ -z "${DEVELOPMENT_TEAM:-}" ]]; then
  echo "Set DEVELOPMENT_TEAM before running this script." >&2
  echo "Example: DEVELOPMENT_TEAM=ABCDE12345 ${BASH_SOURCE[0]}" >&2
  exit 1
fi

if [[ ! -d "${PROJECT_PATH}" ]]; then
  echo "Xcode project not found. Preparing macOS build artifacts first..."
  "${SCRIPT_DIR}/prepare-macos-build.sh"
fi

mkdir -p "$(dirname "${ARCHIVE_PATH}")"

echo "Archiving app..."
xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination "generic/platform=iOS" \
  -archivePath "${ARCHIVE_PATH}" \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
  PRODUCT_BUNDLE_IDENTIFIER="${PRODUCT_BUNDLE_IDENTIFIER}" \
  -allowProvisioningUpdates \
  clean archive

if [[ -n "${EXPORT_OPTIONS_PLIST}" ]]; then
  echo "Exporting IPA..."
  mkdir -p "${EXPORT_PATH}"
  xcodebuild \
    -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist "${EXPORT_OPTIONS_PLIST}" \
    -allowProvisioningUpdates
  echo "IPA exported to ${EXPORT_PATH}"
else
  echo "Archive created at ${ARCHIVE_PATH}"
  echo "To export an IPA, set EXPORT_OPTIONS_PLIST=/path/to/ExportOptions.plist and rerun."
fi
