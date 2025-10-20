#!/bin/bash
# linux_cli.sh
# Domaci ukol z lekce 5

########################################
# 0) help funkce (nahore, at ji muzu zavolat hned)
show_help() {
  echo "=== Pomoc / napoveda ==="
  echo "Pouziti: $0 [volby]"
  echo
  echo "Volby (snazil jsem se je udelat jednoduse):"
  echo " -h                ukaze tuto napovedu"
  echo " -o SOUBOR         presmeruje vystup (log) do souboru uz od startu"
  echo " -s                vypise balicky, ktere maji update (apt)"
  echo " -u                udela update a upgrade balicku (apt)"
  echo " --link            vytvori odkaz (pouziju i dalsi prepinace nize)"
  echo "    --type TYP     typ odkazu: soft nebo hard"
  echo "    --from SRC     odkud odkaz vede"
  echo "    --to   DST     kam odkaz vede"
  echo " --install-binlink udela symlink /bin/linux_cli -> tenhle skript (potrebuje sudo)"
  echo " --search-beae [DIR] najde soubory, ktere uvnitr obsahuji b...e...a...e"
  echo " --info            vypise uvodni informace (shell, uzivatel, system, env)"
  echo
  echo "Priklady:"
  echo " $0 -s"
  echo " $0 -o mujlog.txt -u"
  echo " $0 --link --type soft --from /etc/hosts --to /tmp/hosts_link"
  echo " $0 --install-binlink"
  echo " $0 --search-beae /var/log"
  echo " $0 --info"
  echo "========================"
}

# 0.1) kdyz chci jen napovedu, rovnou ji ukazu a skoncim (at se netiskne nic jineho)
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  show_help
  exit 0
fi

# 0.2) najdu -o SOUBOR, abych logoval uz od zacatku (udelam to naivne)
LOGFILE=""
NEXT_IS_FILE="no"
for arg in "$@"; do
  if [ "$NEXT_IS_FILE" = "yes" ]; then
    LOGFILE="$arg"
    break
  fi
  if [ "$arg" = "-o" ]; then
    NEXT_IS_FILE="yes"
  fi
done

if [ -n "$LOGFILE" ]; then
  touch "$LOGFILE" 2>/dev/null
  if [ $? -eq 0 ]; then
    exec >"$LOGFILE" 2>&1
    echo "[INFO] Logovani do souboru je zapnute."
  else
    echo "[ERROR] Nemuzu psat do souboru: $LOGFILE (log zustane na obrazovce)" 1>&2
  fi
fi

########################################
# 1) jednoduche log funkce
log() { echo "[INFO] $*"; }
logError() { echo "[ERROR] $*" 1>&2; }

# 2) pomocne
have_apt() { command -v apt >/dev/null 2>&1; }
is_macos() { [ "$(uname -s)" = "Darwin" ]; }

# 3) funkce na vypsani uvodnich informaci (jen kdyz si o ne reknu)
print_intro() {
  # 1) jaky pouzivame shell
  echo "My shell is:"
  echo $SHELL

  # 2) aktualni uzivatel
  echo "My current user is:"
  whoami

  # 3) verze linuxu
  echo "My linux distribution is:"
  if [ -f /etc/os-release ]; then
    cat /etc/os-release
  else
    echo "/etc/os-release not found (this is probably macOS, not Linux)"
  fi

  # 4) environment variables
  echo "My environment variables are:"
  printenv
}

########################################
# 4) zkusim nacist funkce ze soft_hard_links.sh (z predminule hodiny)
if [ -f "./soft_hard_links.sh" ]; then
  . ./soft_hard_links.sh
fi
########################################
# 5) jednotlive akce

list_updates() {
  echo "# 3) seznam updatovatelných balicku"
  if have_apt; then
    echo "Davam: sudo apt update"
    sudo apt update
    echo "A ted balicky co jdou povysit:"
    apt list --upgradable 2>/dev/null
  else
    if is_macos; then
      log "[macOS] Tuhle cast umim jen s apt (Debian/Ubuntu)."
    else
      logError "Zatim umim jen apt (Debian/Ubuntu)."
    fi
  fi
}

upgrade_packages() {
  echo "# 4) update a upgrade balicku"
  if have_apt; then
    echo "Davam: sudo apt update"
    sudo apt update
    echo "Davam: sudo apt upgrade -y"
    sudo apt upgrade -y
    echo "Hotovo (doufam)."
  else
    if is_macos; then
      log "[macOS] Update/upgrade podporuju jen pres apt (Debian/Ubuntu)."
    else
      logError "Neumim jiny package manager, promin."
    fi
  fi
}

create_link() {
  echo "# 5) vytvarim odkaz"
  typ="$1"
  src="$2"
  dst="$3"

  if [ -z "$typ" ] || [ -z "$src" ] || [ -z "$dst" ]; then
    logError "Musim dostat --type, --from a --to"
    return 1
  fi
  if [ ! -e "$src" ]; then
    logError "Zdroj neexistuje: $src"
    return 1
  fi

  # kdyz mam funkce z soft_hard_links.sh, zkusim je
  if [ "$typ" = "soft" ] && [ "$(type -t create_soft_link 2>/dev/null)" = "function" ]; then
    create_soft_link "$src" "$dst"
    return $?
  fi
  if [ "$typ" = "hard" ] && [ "$(type -t create_hard_link 2>/dev/null)" = "function" ]; then
    create_hard_link "$src" "$dst"
    return $?
  fi

  # fallback: moje jednoducha verze
  if [ "$typ" = "hard" ] && [ -d "$src" ]; then
    logError "Hard link na adresar neumim (a ani to nejde)."
    return 1
  fi
  if [ "$typ" = "soft" ]; then
    echo "ln -s \"$src\" \"$dst\""
    ln -s "$src" "$dst"
  elif [ "$typ" = "hard" ]; then
    echo "ln \"$src\" \"$dst\""
    ln "$src" "$dst"
  else
    logError "Neznamy typ linku: $typ (dej soft nebo hard)"
    return 1
  fi

  if [ $? -eq 0 ]; then
    log "Odkaz vytvoren: $dst -> $src (typ $typ)"
  else
    logError "Nepodarilo se to."
  fi
}

install_binlink() {
  echo "# 6) symlink do /bin"
  self="$0"
  if [ ! -f "$self" ] && command -v realpath >/dev/null 2>&1; then
    self="$(realpath "$0" 2>/dev/null)"
  fi
  if [ -z "$self" ]; then
    logError "Neumim zjistit cestu k tomuhle skriptu."
    return 1
  fi
  echo "sudo ln -sf \"$self\" /bin/linux_cli"
  sudo ln -sf "$self" /bin/linux_cli
  if [ $? -eq 0 ]; then
    echo "Hotovo, zkus: linux_cli -h"
  else
    logError "Nepodarilo se udelat symlink (na macOS muze blokovat SIP)."
  fi
}

search_beae() {
  echo "# 7) hledam beae v souborech (obsah)"
  dir="${1:-.}"
  echo "Adresar: $dir"
  # -I preskoci binarky, -l vypise jen jmeno souboru
  find "$dir" -type f -exec grep -I -l -E 'b.*e.*a.*e' {} + 2>/dev/null
}

########################################
# 6) zpracovani argumentu

if [ $# -eq 0 ]; then
  # kdyz nic nezadas, ukazu intro + help
  print_intro
  show_help
  exit 0
fi

DO_LIST="no"
DO_UPGRADE="no"
DO_LINK="no"
LINK_TYPE=""
LINK_FROM=""
LINK_TO=""
DO_INSTALL="no"
DO_SEARCH="no"
SEARCH_DIR="."
SHOW_INTRO="no"

while [ $# -gt 0 ]; do
  case "$1" in
    -o)
      shift # preskocim jmeno souboru, log jsem uz nastavil nahore
      ;;
    -s)
      DO_LIST="yes"
      ;;
    -u)
      DO_UPGRADE="yes"
      ;;
    --link)
      DO_LINK="yes"
      ;;
    --type)
      shift
      LINK_TYPE="$1"
      ;;
    --from)
      shift
      LINK_FROM="$1"
      ;;
    --to)
      shift
      LINK_TO="$1"
      ;;
    --install-binlink)
      DO_INSTALL="yes"
      ;;
    --search-beae)
      DO_SEARCH="yes"
      if [ -n "$2" ] && [ "${2#-}" = "$2" ]; then
        shift
        SEARCH_DIR="$1"
      fi
      ;;
    --info)
      SHOW_INTRO="yes"
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      logError "Neznama volba: $1 (zkus -h)"
      ;;
  esac
  shift
done

########################################
# 7) spusteni podle voleb

if [ "$SHOW_INTRO" = "yes" ]; then
  print_intro
fi

if [ "$DO_LIST" = "yes" ]; then
  list_updates
fi

if [ "$DO_UPGRADE" = "yes" ]; then
  upgrade_packages
fi

if [ "$DO_LINK" = "yes" ]; then
  create_link "$LINK_TYPE" "$LINK_FROM" "$LINK_TO"
fi

if [ "$DO_INSTALL" = "yes" ]; then
  install_binlink
fi

if [ "$DO_SEARCH" = "yes" ]; then
  search_beae "$SEARCH_DIR"
fi

# kdyz nezadal nic pouzitelneho (krome -o), aspon help
if [ "$SHOW_INTRO" = "no" ] && [ "$DO_LIST" = "no" ] && [ "$DO_UPGRADE" = "no" ] && \
   [ "$DO_LINK" = "no" ] && [ "$DO_INSTALL" = "no" ] && [ "$DO_SEARCH" = "no" ]; then
  show_help
fi