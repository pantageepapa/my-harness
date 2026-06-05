#!/usr/bin/env bash
# Download a pinned jira-cli binary into ./bin/, no brew or system install
# required. Re-runnable: skips work if the right version is already there.
#
# Run from anywhere: `bash scripts/install-jira-cli.sh`.

set -euo pipefail

JIRA_CLI_VERSION="1.7.0"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$REPO_ROOT/bin"
BIN_PATH="$BIN_DIR/jira"

err() { printf >&2 'error: %s\n' "$*"; }
note() { printf '%s\n' "$*"; }

uname_s="$(uname -s)"
uname_m="$(uname -m)"

case "$uname_s" in
  Darwin) os="macOS" ;;
  Linux)  os="linux" ;;
  *) err "unsupported OS: $uname_s"; exit 1 ;;
esac

case "$uname_m" in
  arm64|aarch64) arch="arm64" ;;
  x86_64|amd64)  arch="x86_64" ;;
  *) err "unsupported arch: $uname_m"; exit 1 ;;
esac

asset="jira_${JIRA_CLI_VERSION}_${os}_${arch}.tar.gz"
url="https://github.com/ankitpokhrel/jira-cli/releases/download/v${JIRA_CLI_VERSION}/${asset}"
checksums_url="https://github.com/ankitpokhrel/jira-cli/releases/download/v${JIRA_CLI_VERSION}/checksums.txt"

if [[ -x "$BIN_PATH" ]]; then
  current="$("$BIN_PATH" version 2>/dev/null | grep -oE 'Version="[^"]+"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
  if [[ "$current" == "$JIRA_CLI_VERSION" ]]; then
    note "jira-cli v$JIRA_CLI_VERSION already present at $BIN_PATH"
    exit 0
  fi
  note "found jira-cli v$current at $BIN_PATH; replacing with v$JIRA_CLI_VERSION"
fi

mkdir -p "$BIN_DIR"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

note "downloading $asset..."
curl -fsSL "$url" -o "$tmp/$asset"
curl -fsSL "$checksums_url" -o "$tmp/checksums.txt"

note "verifying checksum..."
expected="$(grep " $asset\$" "$tmp/checksums.txt" | awk '{print $1}')"
if [[ -z "$expected" ]]; then
  err "no checksum entry for $asset in checksums.txt"
  exit 1
fi
if command -v shasum >/dev/null 2>&1; then
  actual="$(shasum -a 256 "$tmp/$asset" | awk '{print $1}')"
elif command -v sha256sum >/dev/null 2>&1; then
  actual="$(sha256sum "$tmp/$asset" | awk '{print $1}')"
else
  err "neither shasum nor sha256sum available; cannot verify download"
  exit 1
fi
if [[ "$actual" != "$expected" ]]; then
  err "checksum mismatch: expected $expected, got $actual"
  exit 1
fi

note "extracting..."
tar -xzf "$tmp/$asset" -C "$tmp"

# Tarball layout: jira_<version>_<os>_<arch>/bin/jira
extracted_bin="$(find "$tmp" -type f -name jira -path '*/bin/jira' | head -1)"
if [[ -z "$extracted_bin" ]]; then
  err "could not locate jira binary in extracted archive"
  exit 1
fi

mv "$extracted_bin" "$BIN_PATH"
chmod +x "$BIN_PATH"

note "installed jira-cli v$JIRA_CLI_VERSION → $BIN_PATH"
note ""
note "Verify: $BIN_PATH version"
