#!/bin/sh

echo "=== Akutální shell ==="
echo "$SHELL"

echo ""
echo "=== Uživatel ==="
whoami

echo ""
echo "=== Verze linuxu ==="
if [ -f /etc/os-release ]; then
    cat /etc/os-release
else
    echo "/etc/os-release not found."
fi

echo ""
echo "=== Environmentální proměnné ==="
printenv
