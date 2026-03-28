#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script must be run on macOS." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${IOS_DIR}/.." && pwd)"
BRIDGE_DIR="${ROOT_DIR}/bridge"
TOOLS_DIR="${ROOT_DIR}/.tools"
XCODEGEN_DIR="${TOOLS_DIR}/xcodegen"
XCODEGEN_VERSION="${XCODEGEN_VERSION:-2.45.3}"
XCODEGEN_BIN="${XCODEGEN_DIR}/xcodegen/bin/xcodegen"

mkdir -p "${TOOLS_DIR}"

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools are missing. Install Xcode first and run xcode-select." >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required." >&2
  exit 1
fi

if [[ ! -x "${XCODEGEN_BIN}" ]]; then
  ARCHIVE="${TOOLS_DIR}/xcodegen-${XCODEGEN_VERSION}.zip"
  URL="https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip"
  echo "Downloading XcodeGen ${XCODEGEN_VERSION}..."
  curl -L "${URL}" -o "${ARCHIVE}"
  rm -rf "${XCODEGEN_DIR}"
  mkdir -p "${XCODEGEN_DIR}"
  ditto -x -k "${ARCHIVE}" "${XCODEGEN_DIR}"
  chmod +x "${XCODEGEN_BIN}"
fi

echo "Building Go mobile framework..."
"${BRIDGE_DIR}/scripts/build-ios-framework.sh"

echo "Generating Xcode project..."
cd "${IOS_DIR}"
"${XCODEGEN_BIN}" generate --spec "${IOS_DIR}/project.yml"

echo "Ready: ${IOS_DIR}/VkTurnProxyIOS.xcodeproj"
