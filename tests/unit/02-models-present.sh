#!/usr/bin/env bash
# 02-models-present: the project's Ollama models are pulled.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

assert_cmd ollama

if ! curl -sf http://localhost:11434/api/version >/dev/null; then
  skip "Ollama is not running"
fi

LIST="$(ollama list | awk 'NR>1{print $1}')"
missing=()
for m in qwen3:8b qwen3:4b moondream nomic-embed-text:latest; do
  if echo "$LIST" | grep -qx "$m"; then
    continue
  fi
  # accept :latest variants
  base="$(echo "$m" | cut -d: -f1)"
  if echo "$LIST" | grep -qE "^${base}(:latest)?$"; then
    continue
  fi
  missing+=("$m")
done

[ "${#missing[@]}" -eq 0 ] || fail "missing models: ${missing[*]}"

pass "all project models present"
