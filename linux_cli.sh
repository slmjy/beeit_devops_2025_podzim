#!/usr/bin/env bash

# DÚ z 2025-10-06
LOG_FILE=""

# Pokud není specifikován LOG_FILE, tak vypisuje na STDOUT nebo ERROR OUT
log() {
  if [ -n "$LOG_FILE" ]; then echo "[INFO] $*" >> "$LOG_FILE"; else echo "[INFO] $*"; fi
}

logError() {
  if [ -n "$LOG_FILE" ]; then echo "[ERROR] $*" >> "$LOG_FILE"; fi
  echo "[ERROR] $*" >&2
}

# Vytvořená jednoduchá nápověda
help() {
  cat <<EOF
Použití: $0 [--log-file SOUBOR] PŘÍKAZ

PŘÍKAZY:
  -h, --help            nápověda
  link --from A --to B [--type soft|hard]
                        vytvoří link (výchozí soft)
  list-updates          vypíše balíčky s dostupnou aktualizací (APT)
  upgrade               provede update + upgrade (APT) [vyžaduje sudo]
  install-cli-link      vytvoří symlink na tento skript do /bin/linux_cli [sudo]

  find-beae             najde soubory obsahující v názvu písmena b, e, a, e (v tomto pořadí)

PŘÍKLADY:
  $0 link --from /etc/hosts --to /tmp/hosts_link --type soft
  $0 --log-file /tmp/cli.log list-updates
  sudo $0 upgrade
  sudo $0 install-cli-link
EOF
}

# Funkce pro vytvoření linku
cmd_link() {
  FROM=""; TO=""; TYPE="soft"
  while [ $# -gt 0 ]; do
    case "$1" in
      --from) FROM="$2"; shift 2;;
      --to)   TO="$2";   shift 2;;
      --type) TYPE="$2"; shift 2;;
      *) logError "Neznámý argument: $1"; return 1;;
    esac
  done
  if [ -z "$FROM" ] || [ -z "$TO" ]; then logError "Musíš zadat --from a --to."; return 1; fi

  if [ "$TYPE" = "hard" ]; then
    ln -f "$FROM" "$TO" && log "Hard link: $TO -> $FROM" || logError "Hard link selhal."
  else
    ln -sfn "$FROM" "$TO" && log "Soft link: $TO -> $FROM" || logError "Soft link selhal."
  fi
}

# funkce pro výpis seznamu aktualizací
cmd_list_updates() {
  log "APT: načítám seznam aktualizací…"
  sudo apt-get update -qq >/dev/null 2>&1
  apt list --upgradeable 2>/dev/null | tail -n +2
}

cmd_upgrade() {
  log "APT: update + upgrade…"
  sudo apt-get update && sudo apt-get -y upgrade && log "Hotovo." || logError "Upgrade selhal."
}

# instalace do /bin/linux_cli
cmd_install_cli_link() {
  TARGET="/bin/linux_cli"
  SRC="$(readlink -f "$0")"
  sudo ln -sfn "$SRC" "$TARGET" && sudo chmod +x "$SRC" \
    && log "Symlink vytvořen: $TARGET -> $SRC" \
    || logError "Nepodařilo se vytvořit symlink. Spusť s 'sudo'."
}

cmd_find_beae() {
  log "Hledám soubory, které mají v názvu písmena b, e, a, e v tomto pořadí..."
  find / -type f -regex '.*b.*e.*a.*e.*' 2>/dev/null
  log "Hledání dokončeno."
}


# Zjištění parametrů
if [ "$#" -eq 0 ]; then help; exit 0; fi
if [ "$1" = "--log-file" ]; then LOG_FILE="$2"; shift 2; fi
CMD="${1:-}"; shift || true

case "$CMD" in
  -h|--help) help ;;
  link) cmd_link "$@" ;;
  list-updates) cmd_list_updates ;;
  upgrade) cmd_upgrade ;;
  install-cli-link) cmd_install_cli_link ;;
  find-beae) cmd_find_beae ;; 
  *) logError "Neznámý příkaz: $CMD"; help; exit 1 ;;
esac

