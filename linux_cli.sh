#!/bin/bash

# --------------- PROMĚNNÉ ----------------
LOGOVAT_DO_SOUBORU=false
SOUBOR_LOGU="./linux_cli.log"

# ---------------- FLAGY ------------------
FLAG_VYPSAT_UPDATE=false
FLAG_VYTVORIT_LINK=false
FLAG_UPGRADE=false
CILOVY_SOUBOR_LOGU=""
LINK_ZDROJ=""
LINK_CIL=""


# --------------- 1. MANUÁL ---------------

function zobrazitManual() {
    echo -e "
=======================================================
----------------MANUÁL (linux_cli.sh)-----------------
=======================================================
-----------Script pro správu systému a souborů---------

-----------------------POUŽITÍ-------------------------

 Pro spuštění napiš ./linux_cli.sh <FLAGY> [POZIČNÍ ARGUMENTY]

=======================================================

-----------------------FLAGY---------------------------

  -h            Zobrazit manuál
  -i            Vypíše info o uživateli, shellu a OS
  -a            Vypíše balíčky, který čekaj na aktualizaci
  -u            Provede 'apt update' a 'apt upgrade'
  -s            Vytvoří SOFT LINK - musí se zadat v tomhle pořadí: <zdroj> <cíl>
  -f <soubor>   Přepne výpis logů někam
  -x            Samoinstalace skriptu do /bin/linux_cli (samoinstalace)

-------------------------------------------------------
"
}


# =======================================================
# --------------- FUNKCE pro Docker (-p) ----------------
# =======================================================

function informaceOProcesech() {
    zaloguj "Získávám informace o procesech."
    local pid_aktualni=$$
    local pid_rodic=$PPID
    local priorita=$(ps -o ni= -p $$ | tr -d ' ')
    local pocet_procesu=$(ps aux --no-headers | wc -l)

    echo "--- Informace o aktuálním procesu ---"
    echo "PID aktuálního skriptu: $pid_aktualni"
    echo "PID rodičovského procesu: $pid_rodic"
    echo "Priorita (Nice Value): $priorita"
    echo "Celkový počet procesů v OS: $pocet_procesu"

    return 0
}

# --------------- 2. LOGOVÁNÍ ---------------

function zaloguj() {
    local zprava="[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    if [ "$LOGOVAT_DO_SOUBORU" = true ]; then
        echo "$zprava" >> "$SOUBOR_LOGU"
    else
        echo -e "\033[32m$zprava\033[0m"
    fi
}

function zalogujChybu() {
    local zprava="[CHYBA] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    local kod_ukonceni=$2

    if [ "$LOGOVAT_DO_SOUBORU" = true ]; then
        echo "$zprava" >> "$SOUBOR_LOGU"
    else
        echo -e "\033[31m$zprava\033[0m" >&2
    fi

    if [ ! -z "$kod_ukonceni" ]; then
       exit "${kod_ukonceni:-1}"
    fi
}

# --------------- 3. SYSTÉMOVÉ FUNKCE ---------------

function zakladniInfo() {
    zaloguj "Vypsání informací o systému:"
    echo "Shell: $SHELL"
    echo "Uživatel: $(whoami)"
    echo "Verze OS:"
    cat /etc/os-release
    printenv | head -n 5
    return 0
}

function vypsatAktualizace() {
    zaloguj "Vyhledávání balíčků"
    if ! sudo apt update 2>/dev/null; then
        zalogujChybu "Chyba při spuštění 'apt update'." 1
        return 1
    fi
    local seznam_balicku=$(apt list --upgradable 2>/dev/null | grep -v 'Listing...')

    if [ -z "$seznam_balicku" ]; then
        zaloguj "Žádný aktualizace k dispozici"
    else
        zaloguj "Dostupné aktualizace:"
        echo "$seznam_balicku"
    fi
    return 0
}

function provestUpgrade() {
    zaloguj "Probíhá aktualizace"
    if sudo apt update && sudo apt upgrade -y; then
        zaloguj "Update a Upgrade hotovo."
        return 0
    else
        zalogujChybu "Chyba při aktualizaci." 1
        return 1
    fi
}

# --------------- 4. SOUBORY A LINKY ---------------

function vytvoritLink() {
    local typ_linku="$1"
    local zdroj="$2"
    local cil="$3"
    local prikaz="ln"

    if [ "$typ_linku" == "soft" ]; then
        prikaz="ln -s"
        zaloguj "Vytváří se SOFT link"
    elif [ "$typ_linku" == "hard" ]; then
        prikaz="ln"
        zaloguj "Vytváří se HARD link"
    fi

    if $prikaz "$zdroj" "$cil"; then
        zaloguj "Link byl vytvořen"
        return 0
    else
        zalogujChybu "Vytváření linku selhalo" 1
        return 1
    fi
}

function samoinstalace() {
    zaloguj "Instaluju tvuj link do /bin/linux_cli"
    local cesta_skriptu=$(realpath "$0")

    if sudo ln -sf "$cesta_skriptu" "/bin/linux_cli"; then
        zaloguj "Hotovo"
        return 0
    else
        zalogujChybu "Nepodařilo se vytvořit link" 1
        return 1
    fi
}

function najitRegex() {
    local adresar="${1:-.}"
    zaloguj "Hledám soubory v: $adresar"
    find "$adresar" -regextype posix-extended -regex '.*b.*e.*a.*e.*'
    if [ $? -eq 0 ]; then
        zaloguj "Hledání hotovooo."
        return 0
    else
        zalogujChybu "Příkaz find skončil chybou." 1
        return 1
    fi
}

# =======================================================
# ---------- 5. MAIN kód - POUŽITÍ FLAGŮ getopts --------
# =======================================================

# Cyklus pro zpracování flagů
while getopts ":hpiausxf:" volba; do
    case "${volba}" in
        h)
            zobrazitManual
            exit 0
            ;;
        i)
            zakladniInfo
            ;;
        p) # <--- NOVÝ FLAG PRO PROCESY
            informaceOProcesech
            ;;
        a)
            FLAG_VYPSAT_UPDATE=true
            ;;
        u)
            FLAG_UPGRADE=true
            ;;
        s)
            FLAG_VYTVORIT_LINK=true
            ;;
        x)
            samoinstalace
            ;;
        f)
            CILOVY_SOUBOR_LOGU="${OPTARG}"
            ;;
        \?)
            zalogujChybu "Neplatný flag: -${OPTARG}. Použijte -h." 1
            ;;
        :)
            zalogujChybu "Flag -${OPTARG} vyžaduje hodnotu." 1
            ;;
    esac
done

shift "$((OPTIND-1))"

# --------- OŠETŘENÍ A NASTAVENÍ GLOBÁLNÍCH STAVŮ ---------

# 1. flag -f (soubor logu)
if [ ! -z "$CILOVY_SOUBOR_LOGU" ]; then
    if [ -f "$CILOVY_SOUBOR_LOGU" ]; then
        zaloguj "Upozornění: Soubor logu '$CILOVY_SOUBOR_LOGU' již existuje. Bude připojen."
    fi
    SOUBOR_LOGU="$CILOVY_SOUBOR_LOGU"
    LOGOVAT_DO_SOUBORU=true
fi


# 2. Zpracování zadani pro tvorbu linku s flagem -s)
if [ "$FLAG_VYTVORIT_LINK" = true ]; then
    if [ "$#" -lt 2 ]; then
        zalogujChybu "Chyba: Flag -s vyžaduje dva poziční argumenty: <zdroj> <cíl_linku>." 1
    fi
    LINK_ZDROJ="$1"
    LINK_CIL="$2"
    
    if [ -e "$LINK_CIL" ]; then
        zalogujChybu "Link '$LINK_CIL' již existuje. Akce zrušena." 1
    fi
    
    shift 2
fi


# 3. Update, Link, Upgrade

if [ "$FLAG_VYPSAT_UPDATE" = true ]; then
    vypsatAktualizace
fi

if [ "$FLAG_VYTVORIT_LINK" = true ]; then
    vytvoritLink "soft" "$LINK_ZDROJ" "$LINK_CIL"
fi

if [ "$FLAG_UPGRADE" = true ]; then
    provestUpgrade
fi

if [ "$#" -gt 0 ]; then
    najitRegex "$1"
fi


# konec
exit 0
