#!/usr/bin/env bash
# Simple tests for linux_cli.sh
set -u -o pipefail

SCRIPT="./linux_cli.sh"

fail_count=0
ok_count=0

run_test() {
  local name="$1"
  shift
  echo "Running test: $name"
  if "$@"; then
    echo "  OK"
    ok_count=$((ok_count+1))
  else
    echo "  FAILED"
    fail_count=$((fail_count+1))
  fi
}

# Test 1: help should exit with 0
run_test "help_exit_zero" bash -c "$SCRIPT -h >/dev/null 2>&1"

# Test 2: no arguments should show help and exit 0
run_test "no_args_exit_zero" bash -c "$SCRIPT >/dev/null 2>&1"

# Test 3: unknown switch should fail (non-zero)
run_test "unknown_switch_nonzero" bash -c "! $SCRIPT -Z >/dev/null 2>&1"

echo
echo "Tests passed: $ok_count"
echo "Tests failed: $fail_count"

# Non-zero exit if something failed
if [ "$fail_count" -ne 0 ]; then
  exit 1
fi
