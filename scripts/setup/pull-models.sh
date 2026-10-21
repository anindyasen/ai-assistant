#!/usr/bin/env bash
# Pull all models used by this project.
set -euo pipefail

MODELS=(
  "qwen3:8b"           # main reasoning / tool calling
  "qwen3:4b"           # fast classification / bulk ops
  "moondream"          # vision (photo organization)
  "nomic-embed-text"   # embeddings for semantic search
)

echo "==> Checking Ollama..."
if ! curl -sf http://localhost:11434/api/version >/dev/null; then
  echo "Ollama is not running. Start it with: sudo systemctl enable --now ollama" >&2
  exit 1
fi

for m in "${MODELS[@]}"; do
  if ollama list | awk '{print $1}' | grep -qx "$m"; then
    echo "    [skip] $m (already present)"
  else
    echo "==> Pulling $m..."
    ollama pull "$m"
  fi
done

echo "==> Done. Current models:"
ollama list
