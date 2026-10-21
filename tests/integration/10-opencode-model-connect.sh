#!/usr/bin/env bash
# 10-opencode-model-connect: OpenCode can reach the Ollama model end-to-end.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

assert_cmd opencode

if ! curl -sf http://localhost:11434/api/version >/dev/null; then
  skip "Ollama is not running"
fi

# Ask the fast model for a trivial deterministic answer. Keep it small so CPU is fast.
out="$(cd /tmp && env -u OPENCODE_CONFIG_CONTENT timeout 300 \
  opencode run --agent file-organizer --auto \
  "Reply with exactly the word: CONNECTED" 2>&1)" || fail "opencode run failed"

echo "$out" | grep -q "CONNECTED" \
  || fail "model did not return expected token; output: $out"

pass "OpenCode reached the model and got a response"
