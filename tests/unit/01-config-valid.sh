#!/usr/bin/env bash
# 01-config-valid: opencode.json is valid JSON, has required keys, no bad schema.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

REPO_DIR="$(cd "$TESTS_DIR/.." && pwd)"
CONFIG="$REPO_DIR/config/opencode.json"

assert_file "$CONFIG"
assert_cmd jq

jq . "$CONFIG" >/dev/null || fail "config/opencode.json is not valid JSON"

# Required top-level keys
for key in model small_model provider permission; do
  jq -e "has(\"$key\")" "$CONFIG" >/dev/null || fail "missing top-level key: $key"
done

# Provider must use the OpenAI-compatible SDK and the /v1 endpoint
jq -e '.provider.ollama.npm == "@ai-sdk/openai-compatible"' "$CONFIG" >/dev/null \
  || fail "provider.ollama.npm must be @ai-sdk/openai-compatible"
jq -e '.provider.ollama.options.baseURL | endswith("/v1")' "$CONFIG" >/dev/null \
  || fail "provider baseURL must end with /v1"

# MCP entries must use an object environment (not an array or environmentPaths)
if jq -e '.mcp' "$CONFIG" >/dev/null 2>&1; then
  jq -e '.mcp | to_entries[] | .value.environment | type == "object"' "$CONFIG" >/dev/null \
    || fail "every mcp.*.environment must be a JSON object"
  ! jq -e '.mcp | .. | objects | has("environmentPaths")' "$CONFIG" >/dev/null 2>&1 \
    || fail "environmentPaths is not a valid OpenCode field"
fi

pass "config valid, required keys present, provider/mcp schema correct"
