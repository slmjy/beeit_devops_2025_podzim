#!/usr/bin/env bash

# Domaci ukol September 23/2025

echo "=== Info o systému ==="

# 1) Jaký shell používám
echo "Shell: $SHELL"

# 2) Jaký je aktuální uživatel
echo "Uživatel: $(whoami)"

# 3) Jakou verzi Linuxu používám (/etc/os-release)
echo "Verze Linuxu:"
grep "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | tr -d '"'

# 4) Jaké environment variables jsou na úrovni OS
echo
echo "Environment variables:"
printenv


# Domaci ukol October 6/2025

# Pevne daný log súbor v tvojom projekte
LOG_MODE="stdout"
LOG_FILE="/home/silvia_keshi/beeit_devops_2025_podzim/linux_cli.log"

# Pevné cesty pre linky v projekte
SRC_FILE="/home/silvia_keshi/beeit_devops_2025_podzim/test.txt"
SOFT_LINK="/home/silvia_keshi/beeit_devops_2025_podzim/test_soft_link.txt"
HARD_LINK="/home/silvia_keshi/beeit_devops_2025_podzim/test_hard_link.txt"

# Pevný adresár pre find
SEARCH_DIR="/home/silvia_keshi/beeit_devops_2025_podzim"

log() {
    if [ "$LOG_MODE" = "file" ]; then
        echo "[INFO] $*" >> "$LOG_FILE"
    else
        echo "[INFO] $*"
    fi
}

logError() {
    echo "[ERROR] $*" >&2
}

set_log_file() {
    LOG_MODE="file"
    log "Logování nastaveno do souboru: $LOG_FILE"
}

set_log_stdout() {
    LOG_MODE="stdout"
    log "Logování nastaveno na STDOUT."
}

create_soft_link() {

    if [ ! -e "$SRC_FILE" ]; then
        log "Zdrojový soubor neexistuje, vytvářím: $SRC_FILE"
        echo "test file" > "$SRC_FILE"
    fi
    ln -sfn "$SRC_FILE" "$SOFT_LINK"
    log "Soft link: $SOFT_LINK → $SRC_FILE"
}

create_hard_link() {
    if [ ! -e "$SRC_FILE" ]; then
        logError "Zdrojový soubor neexistuje: $SRC_FILE"
        return 1
    fi
    ln -f "$SRC_FILE" "$HARD_LINK"
    log "Hard link: $HARD_LINK → $SRC_FILE"
}

list_upgradable() {
    log "Hledám balíčky s dostupným updatem…"
    apt list --upgradable 2>/dev/null
}

upgrade_packages() {
    log "Provádím apt update && apt upgrade -y…"
    sudo apt update && sudo apt upgrade -y
}

find_beae_files() {
    log "Hledám soubory v $SEARCH_DIR s písmeny b e a e v tomto pořadí…"
    find "$SEARCH_DIR" -regextype posix-extended -regex '.*b.*e.*a.*e.*' 2>/dev/null
}

show_help() {
    cat <<EOF
Použití: $0 PŘÍKAZ

  -h, help
      Zobrazí tuto nápovědu.

  log-file
      Logování do souboru:
        $LOG_FILE

  log-stdout
      Logování na obrazovku .

  link-soft
      Vytvoří soft link:
        zdroj: $SRC_FILE
        link:  $SOFT_LINK

  link-hard
      Vytvoří hard link:
        zdroj: $SRC_FILE
        link:  $HARD_LINK

  list-upgrades
      Vypíše balíčky, které mají dostupný update.

  upgrade
      Provede apt update && apt upgrade -y.

  find-beae
      Najde soubory v:
        $SEARCH_DIR
      které mají v názvu písmena b e a e v tomto pořadí.
EOF
}

main() {
    case "$1" in
        -h|help|"")
            show_help
            ;;
        log-file)
            set_log_file
            ;;
        log-stdout)
            set_log_stdout
            ;;
        link-soft)
            create_soft_link
            ;;
        link-hard)
            create_hard_link
            ;;
        list-upgrades)
            list_upgradable
            ;;
        upgrade)
            upgrade_packages
            ;;
        find-beae)
            find_beae_files
            ;;
        *)
            logError "Neznámý příkaz: $1"
            show_help
            exit 1
            ;;
    esac
}

	main "$@"

#Domaci ukol October 6/2025

process_info() {
    log "Info o procesech:"

    # PID aktuálního procesu
    echo "PID aktuálního procesu: $$"

    # PID rodiče
    echo "PID rodičovského procesu: $PPID"

    # Priorita procesu (PRI)
    echo -n "Priorita procesu: "
    ps -p $$ -o pri= 2>/dev/null || echo "nelze zjistit"

    # Celkový počet procesů v OS
    echo -n "Celkový počet procesů v systému: "
    ps -e --no-headers 2>/dev/null | wc -l
}





