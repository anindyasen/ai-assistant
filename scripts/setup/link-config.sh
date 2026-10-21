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

# Link agent definitions (hybrid model routing lives here)
AGENTS_SRC="$REPO_DIR/config/agents"
AGENTS_DEST="$DEST_DIR/agents"
if [ -d "$AGENTS_SRC" ]; then
  if [ -L "$AGENTS_DEST" ]; then
    echo "[skip] $AGENTS_DEST is already a symlink -> $(readlink "$AGENTS_DEST")"
  elif [ -e "$AGENTS_DEST" ]; then
    echo "[warn] $AGENTS_DEST exists and is not a symlink. Leaving it untouched."
    echo "       Merge manually from $AGENTS_SRC if needed."
  else
    ln -s "$AGENTS_SRC" "$AGENTS_DEST"
    echo "[ok] Linked $AGENTS_DEST -> $AGENTS_SRC"
  fi
fi

# Warn if a stray opencode.jsonc exists (OpenCode merges both; ours may be shadowed).
# Stash it inside the repo's ignored .local/ dir instead of leaving local state outside.
if [ -e "$DEST_DIR/opencode.jsonc" ]; then
  STASH="$REPO_DIR/.local/stashed/opencode.jsonc"
  mkdir -p "$(dirname "$STASH")"
  mv "$DEST_DIR/opencode.jsonc" "$STASH"
  echo "[ok] Moved stray $DEST_DIR/opencode.jsonc -> $STASH (ignored, kept in project)"
fi

# Create dirs for MCP env files (contents are gitignored)
mkdir -p "$HOME/.config/local-ai/gmail"

echo "==> Config linked. Run 'opencode' and type /models to verify."
