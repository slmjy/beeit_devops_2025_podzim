#!/usr/bin/env bash
# linux_cli.sh — DÚ - průběžně
set -euo pipefail

LOG_FILE=""
QUIET=0
VERBOSE=0
NO_COLOR=0
DRY_RUN=0
FORCE=0

# --- barvy ---
if [ -t 1 ]; then
  COLOR_INFO="\033[1;34m"
  COLOR_ERR="\033[1;31m"
  COLOR_DIM="\033[2m"
  COLOR_RESET="\033[0m"
else
  NO_COLOR=1
fi
if [ "$NO_COLOR" -eq 1 ]; then
  COLOR_INFO=""; COLOR_ERR=""; COLOR_DIM=""; COLOR_RESET="";
fi

log() {
  [ "$QUIET" -eq 1 ] || echo -e "${COLOR_INFO}[INFO] $*${COLOR_RESET}"
  [ -n "$LOG_FILE" ] && echo "[INFO] $*" >> "$LOG_FILE" || true
}
logv() {
  [ "$VERBOSE" -eq 1 ] || return 0
  echo -e "${COLOR_DIM}[VERBOSE] $*${COLOR_RESET}"
  [ -n "$LOG_FILE" ] && echo "[VERBOSE] $*" >> "$LOG_FILE" || true
}
err() {
  echo -e "${COLOR_ERR}[ERROR] $*${COLOR_RESET}" >&2
  [ -n "$LOG_FILE" ] && echo "[ERROR] $*" >> "$LOG_FILE" || true
}

# Vytvořená jednoduchá nápověda
help() {
  cat <<'EOF'
Použití (flag režim, akce se provedou v pořadí, jak jsou zadány):
  linux_cli.sh [VOLBY_A_AKCE...]

VOLBY (globální):
  -f SOUBOR     loguj do souboru (ověří se zápis; vytvoří se, pokud neexistuje)
  -q            quiet (potlačí [INFO])
  -v            verbose ([VERBOSE])
  -n            no-color
  -d            dry-run (nic nemění, jen popíše kroky)
  -F            force (přepíše existující cílové linky)

AKCE:
  -a            vypiš balíčky s dostupným upgradem (APT)
  -u            proveď update + upgrade (APT) [vyžaduje sudo]
  -s FROM:TO    vytvoř soft link (symbolický) z FROM na TO
  -H FROM:TO    vytvoř hard link z FROM na TO
  -I            nainstaluje symlink na tento skript do /usr/local/bin/linux_cli [sudo]
  -h            nápověda

Příklady:
  ./linux_cli.sh -a
  ./linux_cli.sh -a -f log_output.txt
  ./linux_cli.sh -a -s /etc/hosts:/tmp/hosts_link -u
  ./linux_cli.sh -s ~/src/app:/opt/app -F     # přepíše existující cíl
  ./linux_cli.sh -d -s a:b -u                 # dry-run, nic nezmění

Návratové kódy:
  0 = všechny zadané akce proběhly úspěšně
  >0 = alespoň jedna akce selhala (konkrétní chyby jsou vypsány)
EOF
}

# --- pomocné ---
ensure_parent_dir() {
  local path="$1" dir; dir="$(dirname -- "$path")"
  if [ ! -d "$dir" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then log "DRY-RUN: mkdir -p -- '$dir'"
    else mkdir -p -- "$dir"
    fi
  fi
}

ensure_logfile() {
  local file="$1"
  if [ -z "$file" ]; then return 0; fi
  if [ -d "$file" ]; then err "Nelze logovat do adresáře: $file"; return 2; fi
  local dir; dir="$(dirname -- "$file")"
  if [ ! -d "$dir" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then log "DRY-RUN: mkdir -p -- '$dir'"
    else mkdir -p -- "$dir"
    fi
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY-RUN: ověřil bych zápis do '$file'"
  else
    if ! touch "$file" 2>/dev/null; then
      err "Nelze zapisovat do log souboru: $file"; return 3
    fi
  fi
  return 0
}

# --- APT akce ---
act_list_updates() {
  log "APT: načítám seznam aktualizací…"
  if sudo -n true 2>/dev/null; then
    sudo apt-get update -qq >/dev/null 2>&1 || true
  else
    logv "sudo bez hesla není k dispozici – použiji existující indexy."
  fi
  apt list --upgradeable 2>/dev/null | tail -n +2 || true
}

act_upgrade() {
  log "APT: update + upgrade…"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY-RUN: sudo apt-get update && sudo apt-get -y upgrade"
    return 0
  fi
  if sudo apt-get update && sudo apt-get -y upgrade; then
    log "Hotovo."
    return 0
  else
    err "Upgrade selhal."
    return 10
  fi
}

# --- Link akce ---
_make_link() { # $1=type soft|hard, $2=FROM, $3=TO
  local type="$1" FROM="$2" TO="$3"
  if [ -z "$FROM" ] || [ -z "$TO" ]; then err "Chybí FROM/TO."; return 20; fi
  if [ ! -e "$FROM" ]; then err "--from neexistuje: $FROM"; return 21; fi

  ensure_parent_dir "$TO" || return 22

  # Existuje cíl?
  if [ -e "$TO" ] || [ -L "$TO" ]; then
    # Zjisti, zda už ukazuje správně
    local same=1
    if [ "$type" = "soft" ] && [ -L "$TO" ]; then
      local tgt; tgt="$(readlink -- "$TO" || true)"
      [ "$tgt" = "$FROM" ] && same=0
    elif [ "$type" = "hard" ] && [ -e "$TO" ]; then
      # Porovnáme inode
      if [ -e "$FROM" ] && [ "$(ls -i -- "$FROM" | awk '{print $1}')" = "$(ls -i -- "$TO" | awk '{print $1}')" ]; then
        same=0
      fi
    fi

    if [ "$same" -eq 0 ]; then
      log "Cíl už existuje a ukazuje správně: $TO"
      return 0
    fi

    if [ "$FORCE" -eq 1 ]; then
      if [ "$DRY_RUN" -eq 1 ]; then
        log "DRY-RUN: rm -f -- '$TO'"
      else
        rm -f -- "$TO" || { err "Nelze odstranit existující cíl: $TO"; return 23; }
      fi
    else
      err "Cíl už existuje: $TO (použij -F pro přepsání)"
      return 24
    fi
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ "$type" = "hard" ]; then log "DRY-RUN: ln -f -- '$FROM' '$TO'"
    else log "DRY-RUN: ln -s -- '$FROM' '$TO'"
    fi
    return 0
  fi

  if [ "$type" = "hard" ]; then
    if ln -f -- "$FROM" "$TO"; then log "Hard link: $TO -> $FROM"; return 0
    else err "Hard link selhal."; return 25; fi
  else
    if ln -s -- "$FROM" "$TO"; then log "Soft link: $TO -> $FROM"; return 0
    else err "Soft link selhal."; return 26; fi
  fi
}

act_softlink() { # arg "FROM:TO"
  local spec="$1"
  local FROM="${spec%%:*}"
  local TO="${spec#*:}"
  if [ "$FROM" = "$TO" ] || [ -z "$FROM" ] || [ -z "$TO" ] || [ "$spec" = "$FROM" ]; then
    err "Použij formát -s FROM:TO"; return 27
  fi
  _make_link "soft" "$FROM" "$TO"
}

act_hardlink() { # arg "FROM:TO"
  local spec="$1"
  local FROM="${spec%%:*}"
  local TO="${spec#*:}"
  if [ "$FROM" = "$TO" ] || [ -z "$FROM" ] || [ -z "$TO" ] || [ "$spec" = "$FROM" ]; then
    err "Použij formát -H FROM:TO"; return 28
  fi
  _make_link "hard" "$FROM" "$TO"
}

act_install_cli_link() {
  local TARGET="/usr/local/bin/linux_cli"
  local SRC; SRC="$(readlink -f "$0")"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY-RUN: sudo ln -sfn -- '$SRC' '$TARGET' && sudo chmod +x '$SRC'"
    return 0
  fi
  if sudo ln -sfn -- "$SRC" "$TARGET" && sudo chmod +x "$SRC"; then
    log "Symlink vytvořen: $TARGET -> $SRC"
    return 0
  else
    err "Nepodařilo se vytvořit symlink (spusť s 'sudo')."
    return 30
  fi
}

# --- parsování flagů do fronty akcí (v pořadí) ---
declare -a ACTIONS ARGS
# getopts: a,u,s:,H:,I,f:,q,v,n,d,F,h
while getopts ":aus:H:If:qvndFh" opt; do
  case "$opt" in
    a) ACTIONS+=("list"); ARGS+=("");;
    u) ACTIONS+=("upgrade"); ARGS+=("");;
    s) ACTIONS+=("soft"); ARGS+=("$OPTARG");;
    H) ACTIONS+=("hard"); ARGS+=("$OPTARG");;
    I) ACTIONS+=("install"); ARGS+=("");;
    f) LOG_FILE="$OPTARG";;
    q) QUIET=1;;
    v) VERBOSE=1;;
    n) NO_COLOR=1; COLOR_INFO=""; COLOR_ERR=""; COLOR_DIM=""; COLOR_RESET="";;
    d) DRY_RUN=1;;
    F) FORCE=1;;
    h) help; exit 0;;
    \?) err "Neznámý přepínač: -$OPTARG"; echo; help; exit 64;;
    :)  err "Přepínač -$OPTARG vyžaduje argument"; echo; help; exit 65;;
  esac
done

# pokud nic nezadáno, ukaž help
if [ "${#ACTIONS[@]}" -eq 0 ] && [ -z "${LOG_FILE:-}" ] && [ "$QUIET" -eq 0 ] && [ "$VERBOSE" -eq 0 ] && [ "$DRY_RUN" -eq 0 ] && [ "$FORCE" -eq 0 ]; then
  help; exit 0
fi

# ověř log soubor (pokud zadán)
if [ -n "$LOG_FILE" ]; then
  ensure_logfile "$LOG_FILE" || exit $?
  logv "Logovat budu do: $LOG_FILE"
fi

# --- vykonej akce v pořadí ---
overall_rc=0

for i in "${!ACTIONS[@]}"; do
  action="${ACTIONS[$i]}"; arg="${ARGS[$i]}"
  case "$action" in
    list)
      if ! act_list_updates; then overall_rc=1; fi
      ;;
    upgrade)
      if ! act_upgrade; then overall_rc=1; fi
      ;;
    soft)
      if ! act_softlink "$arg"; then overall_rc=1; fi
      ;;
    hard)
      if ! act_hardlink "$arg"; then overall_rc=1; fi
      ;;
    install)
      if ! act_install_cli_link; then overall_rc=1; fi
      ;;
    *)
      err "Interní neznámá akce: $action"; overall_rc=1;;
  esac
done

exit "$overall_rc"
