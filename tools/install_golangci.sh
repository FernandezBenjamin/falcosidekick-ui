#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Download and install golangci-lint prebuilt binary into TOOLS_BIN_DIR
set -euo pipefail

VER="${1:-}"
DEST_DIR="${2:-}"
if [[ -z "${VER}" || -z "${DEST_DIR}" ]]; then
  echo "usage: $0 <version> <dest_dir>" >&2
  exit 1
fi

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) echo "Unsupported arch: $ARCH" >&2; exit 1 ;;
 esac

# Strip 'v' prefix from version for the filename
VER_NO_V="${VER#v}"
TARBALL="golangci-lint-${VER_NO_V}-${OS}-${ARCH}.tar.gz"
URL="https://github.com/golangci/golangci-lint/releases/download/${VER}/${TARBALL}"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL -o "$TMP_DIR/$TARBALL" "$URL"
mkdir -p "$TMP_DIR/extract"
tar -xzf "$TMP_DIR/$TARBALL" -C "$TMP_DIR/extract"

BIN_SRC=$(find "$TMP_DIR/extract" -type f -name golangci-lint -perm -111 | head -n1)
if [[ -z "$BIN_SRC" ]]; then
  echo "Failed to locate golangci-lint in archive" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
cp "$BIN_SRC" "$DEST_DIR/golangci-lint-${VER}"
ln -sf "golangci-lint-${VER}" "$DEST_DIR/golangci-lint"

echo "Installed golangci-lint ${VER} to ${DEST_DIR}"
