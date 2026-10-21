#!/usr/bin/env bash
# 04-scripts-executable: all entry-point scripts exist and are executable.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

REPO_DIR="$(cd "$TESTS_DIR/.." && pwd)"

scripts=(
  scripts/organize-photos
  scripts/organize-downloads
  scripts/organize-music
  scripts/portfolio-report
  scripts/morning-brief
  scripts/setup/install-deps.sh
  scripts/setup/pull-models.sh
  scripts/setup/link-config.sh
)

for s in "${scripts[@]}"; do
  f="$REPO_DIR/$s"
  assert_file "$f"
  [ -x "$f" ] || fail "not executable: $s"
done

# All must pass a bash syntax check
for s in "${scripts[@]}"; do
  bash -n "$REPO_DIR/$s" || fail "syntax error: $s"
done

pass "all scripts present, executable, syntax-clean"
