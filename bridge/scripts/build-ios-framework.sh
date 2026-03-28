#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${ROOT_DIR}/../ios/Frameworks"
OUTPUT_FILE="${OUTPUT_DIR}/VkTurnCore.xcframework"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "iOS framework build requires macOS with Xcode installed." >&2
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

if ! command -v go >/dev/null 2>&1; then
  echo "Go is not installed. Install Go first: https://go.dev/dl/" >&2
  exit 1
fi

if ! command -v gomobile >/dev/null 2>&1; then
  echo "gomobile not found. Installing it with go install..." >&2
  go install golang.org/x/mobile/cmd/gomobile@latest
  export PATH="$(go env GOPATH)/bin:${PATH}"
fi

gomobile init

cd "${ROOT_DIR}"
gomobile bind -target=ios -o "${OUTPUT_FILE}" ./proxycore

echo "Built ${OUTPUT_FILE}"
