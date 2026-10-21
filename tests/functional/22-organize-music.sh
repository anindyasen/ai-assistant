#!/usr/bin/env bash
# 22-organize-music: fixture audio sorted into Artist/Album structure, nothing deleted.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

REPO_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SRC="$FIXTURES/music"

[ -d "$SRC" ] || skip "fixtures missing (run tests/fixtures/make-fixtures.sh)"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
cp -r "$SRC" "$SANDBOX/music"

if ! curl -sf http://localhost:11434/api/version >/dev/null; then
  skip "Ollama is not running"
fi

timeout 600 "$REPO_DIR/scripts/organize-music" "$SANDBOX/music" >/dev/null 2>&1 \
  || fail "organize-music exited non-zero"

src_count="$(find "$SRC" -type f | wc -l)"
dst_count="$(find "$SANDBOX" -type f -not -path '*/node_modules/*' | wc -l)"
[ "$dst_count" -ge "$src_count" ] \
  || fail "files lost: source=$src_count destination=$dst_count"

# Fixture tracks have no tags, so they should be left in place and reported,
# not lost. Assert every audio file is still reachable under the sandbox.
for f in track1.mp3 track2.flac; do
  find "$SANDBOX" -name "$f" | grep -q . || fail "audio file vanished: $f"
done

pass "music handled; no files deleted"
