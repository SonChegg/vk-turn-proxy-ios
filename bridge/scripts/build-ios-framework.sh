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

export GO111MODULE="${GO111MODULE:-on}"
export PATH="$(go env GOPATH)/bin:${PATH}"

if ! command -v gomobile >/dev/null 2>&1 || ! command -v gobind >/dev/null 2>&1; then
  echo "gomobile toolchain not found. Installing it with go install..." >&2
  go install golang.org/x/mobile/cmd/gomobile@latest
  go install golang.org/x/mobile/cmd/gobind@latest
fi

MOBILE_SRC="$(go env GOPATH)/src/golang.org/x/mobile"
if [[ ! -d "${MOBILE_SRC}/bind" ]]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "git is required to fetch golang/mobile fallback sources into GOPATH." >&2
    exit 1
  fi

  mkdir -p "$(dirname "${MOBILE_SRC}")"
  if [[ -d "${MOBILE_SRC}" ]]; then
    echo "golang/mobile exists at ${MOBILE_SRC}, but the bind sources are incomplete." >&2
    echo "Delete that directory or repair it, then rerun the build." >&2
    exit 1
  fi

  echo "golang/mobile sources are missing in GOPATH. Cloning fallback copy..." >&2
  git clone --depth 1 https://github.com/golang/mobile "${MOBILE_SRC}"
fi

gomobile init

cd "${ROOT_DIR}"
gomobile bind -target=ios -o "${OUTPUT_FILE}" ./proxycore

echo "Built ${OUTPUT_FILE}"
