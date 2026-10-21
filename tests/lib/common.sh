#!/usr/bin/env bash
# Shared test helpers. Source this from test scripts.
# Exit codes: 0=pass, 1=fail, 77=skip

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES="$TESTS_DIR/fixtures"

pass()  { echo "ok: $*"; exit 0; }
fail()  { echo "FAIL: $*" >&2; exit 1; }
skip()  { echo "skip: $*"; exit 77; }

assert_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "command not found: $1"
}

assert_file() { [ -e "$1" ] || fail "missing file: $1"; }
assert_dir()  { [ -d "$1" ] || fail "missing dir: $1"; }

assert_eq() {
  [ "$1" = "$2" ] || fail "expected '$2', got '$1'"
}

# True if an env file with a non-placeholder value exists
has_secret() {
  local f="$1" key="$2"
  [ -f "$f" ] || return 1
  grep -q "^${key}=secret_" "$f" 2>/dev/null
}
