#!/usr/bin/env bash
# common helpers for scripts in this repo
set -euo pipefail

warn() { printf '⚠️  %s\n' "$*" >&2; }
info() { printf '➜ %s\n' "$*"; }
die()  { printf '✖ %s\n' "$*" >&2; exit 1; }

require_cmd() { command -v "$1" >/dev/null || die "Missing required command: $1"; }

# detect OS (simple)
OS="$(uname -s)"
case "$OS" in
  Darwin) OS="macOS" ;;
  Linux)  OS="linux" ;;
  *)      OS="unknown" ;;
esac
export OS
