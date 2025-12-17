#!/usr/bin/env bash


TESTS_FAILED=0

run_test() {
    local name="$1"
    shift
    echo "=== TEST: $name ==="
    if "$@"; then
        echo "OK"
    else
        echo "FAIL"
        TESTS_FAILED=1
    fi
    echo
}

CLI="/app/linux_cli.sh"

# Test 1: help běží a skončí s kódem 0
run_test "help"           "$CLI" -h

# Test 2: seznam balíčků s updatem (-a)
run_test "list-upgrades"  "$CLI" -a

# Test 3: info o procesech (-p)
run_test "process-info"   "$CLI" -p



if [ "$TESTS_FAILED" -eq 0 ]; then
    echo "Všechny testy prošly."
else
    echo "Některé testy selhaly."
fi

exit "$TESTS_FAILED"
