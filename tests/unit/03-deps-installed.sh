#!/usr/bin/env bash
# 03-deps-installed: required system tools and the project venv exist.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

REPO_DIR="$(cd "$TESTS_DIR/.." && pwd)"

missing=()
for c in exiftool fdupes ffprobe jq curl; do
  command -v "$c" >/dev/null 2>&1 || missing+=("$c")
done
[ "${#missing[@]}" -eq 0 ] || fail "missing tools: ${missing[*]}"

# yfinance in the project-local venv
VENV_PY="$REPO_DIR/.venv/bin/python"
if [ ! -x "$VENV_PY" ]; then
  skip "project .venv not created yet (run scripts/setup/install-deps.sh)"
fi
"$VENV_PY" -c "import yfinance" 2>/dev/null \
  || fail "yfinance not importable from .venv"

pass "system tools present; yfinance importable from .venv"
