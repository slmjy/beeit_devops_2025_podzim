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


# ukol 5
#logovaci funkce
log() { echo "[INFO] $1"; }
logError() { echo "[ERROR] $1" >&2; }

#vytvareni linku
create_link() { [[ $3 == "soft" ]] && ln -s "$1" "$2" || ln "$1" "$2"; }

#vypis aktualizaci
list_updates() { git update-git-for-windows; echo $?; }

#provedeni aktualizaci
update_packages() { git update-git-for-windows}

# === Hledání souborů s 'b','e','a','e' v pořadí ===
najdi_pismena() { find "${1:-.}" -type f -name "*b*e*e*" 2>/dev/null; }
