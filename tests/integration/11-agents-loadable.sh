#!/usr/bin/env bash
# 11-agents-loadable: agent definitions exist, are valid, and route to the right models.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

REPO_DIR="$(cd "$TESTS_DIR/.." && pwd)"
AGENTS_DIR="$REPO_DIR/config/agents"

assert_dir "$AGENTS_DIR"

# Expected agents and their required model class
declare -A EXPECT_MODEL=(
  [assistant]="ollama/qwen3:8b"
  [researcher]="ollama/qwen3:8b"
  [analyst]="ollama/qwen3:8b"
  [file-organizer]="ollama/qwen3:4b"
)

for name in "${!EXPECT_MODEL[@]}"; do
  f="$AGENTS_DIR/$name.md"
  assert_file "$f"

  # Frontmatter must be delimited and contain mode + model
  head -1 "$f" | grep -qx -- "---" || fail "$name.md: missing frontmatter"
  grep -q "^mode:" "$f"     || fail "$name.md: missing mode"
  grep -q "^model:" "$f"    || fail "$name.md: missing model"

  want="${EXPECT_MODEL[$name]}"
  grep -qx "model: $want" "$f" \
    || fail "$name.md: expected 'model: $want' (hybrid routing)"
done

# assistant must be a primary (orchestrator) agent
grep -qx "mode: primary" "$AGENTS_DIR/assistant.md" \
  || fail "assistant.md must be mode: primary"

# file-organizer must be usable both as a script entry point and a subagent
grep -qx "mode: all" "$AGENTS_DIR/file-organizer.md" \
  || fail "file-organizer.md must be mode: all"

pass "agents present with correct mode + hybrid model routing"
