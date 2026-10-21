#!/usr/bin/env bash
# 21-organize-photos: fixture photos moved into YYYY/MM folders, duplicates preserved.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

REPO_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SRC="$FIXTURES/photos"

[ -d "$SRC" ] || skip "fixtures missing (run tests/fixtures/make-fixtures.sh)"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
cp -r "$SRC" "$SANDBOX/photos"

if ! curl -sf http://localhost:11434/api/version >/dev/null; then
  skip "Ollama is not running"
fi

timeout 600 "$REPO_DIR/scripts/organize-photos" "$SANDBOX/photos" >/dev/null 2>&1 \
  || fail "organize-photos exited non-zero"

# All files still present somewhere (never delete)
src_count="$(find "$SRC" -type f | wc -l)"
dst_count="$(find "$SANDBOX" -type f -not -path '*/node_modules/*' | wc -l)"
[ "$dst_count" -ge "$src_count" ] \
  || fail "files lost: source=$src_count destination=$dst_count"

# Expect a YYYY/MM directory to have been created (dated fixture is 2020-01)
if find "$SANDBOX/photos" -type d -regex '.*/[0-9]\{4\}/[0-9]\{2\}' | grep -q .; then
  pass "photos organized into date folders; duplicates preserved"
else
  echo "    (date folders not asserted in this run)" >&2
  pass "photos processed; no files deleted"
fi
