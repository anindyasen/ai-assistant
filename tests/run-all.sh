#!/usr/bin/env bash
# Run the test suite.
# Usage:
#   run-all.sh                # all layers
#   run-all.sh --fast         # unit only
#   run-all.sh <layer>        # e.g. unit | integration | functional
#   run-all.sh <file-path>    # single test
set -u

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0; FAIL=0; SKIP=0; FAILED_TESTS=()

run_one() {
  local t="$1" name rel
  rel="${t#"$TESTS_DIR"/}"
  printf '%-55s ' "$rel"
  bash "$t" >/tmp/opencode-test-out.$$ 2>&1
  local rc=$?
  case $rc in
    0)  echo "PASS"; PASS=$((PASS+1)) ;;
    77) echo "SKIP"; SKIP=$((SKIP+1)); sed 's/^/    /' /tmp/opencode-test-out.$$ ;;
    *)  echo "FAIL"; FAIL=$((FAIL+1)); FAILED_TESTS+=("$rel")
        sed 's/^/    /' /tmp/opencode-test-out.$$ ;;
  esac
  rm -f /tmp/opencode-test-out.$$
}

collect() { find "$TESTS_DIR/$1" -name '[0-9]*.sh' -type f 2>/dev/null | sort; }

ARG="${1:-}"

if [ -n "$ARG" ] && [ -f "$ARG" ]; then
  run_one "$(realpath "$ARG")"
elif [ "$ARG" = "--fast" ] || [ "$ARG" = "unit" ]; then
  for t in $(collect unit); do run_one "$t"; done
elif [ -n "$ARG" ]; then
  for t in $(collect "$ARG"); do run_one "$t"; done
else
  for layer in unit integration functional; do
    for t in $(collect "$layer"); do run_one "$t"; done
  done
fi

echo
echo "PASS=$PASS  FAIL=$FAIL  SKIP=$SKIP"
if [ "$FAIL" -gt 0 ]; then
  echo "Failed:"
  printf '  - %s\n' "${FAILED_TESTS[@]}"
  exit 1
fi
