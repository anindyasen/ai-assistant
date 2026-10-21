#!/usr/bin/env bash
# Symlink this repo's OpenCode config into OpenCode's config path,
# so edits here are version-controlled and take effect immediately.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$REPO_DIR/config/opencode.json"
DEST_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
DEST="$DEST_DIR/opencode.json"

mkdir -p "$DEST_DIR"

if [ -L "$DEST" ]; then
  echo "[skip] $DEST is already a symlink -> $(readlink "$DEST")"
elif [ -e "$DEST" ]; then
  BACKUP="$DEST.bak.$(date +%s)"
  echo "[warn] $DEST exists and is not a symlink. Backing up to $BACKUP"
  mv "$DEST" "$BACKUP"
  ln -s "$SRC" "$DEST"
else
  ln -s "$SRC" "$DEST"
  echo "[ok] Linked $DEST -> $SRC"
fi

# Create dirs for MCP env files (contents are gitignored)
mkdir -p "$HOME/.config/local-ai/gmail"

echo "==> Config linked. Run 'opencode' and type /models to verify."
