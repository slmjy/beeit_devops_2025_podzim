#!/bin/bash
#du
echo "Current shell: $SHELL"

echo "Current user: $USER"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Linux version: $PRETTY_NAME"
fi

echo "Environment variables:"
printenv
