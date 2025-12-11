#!/bin/bash

EXIT_CODE=0
LOG_FILE="logfile.log"
ERROR_LOG="error.log"

log()
{
	echo "$1" >> "$LOG_FILE"
	echo "$1" >&2
}

logError()
{
	echo "$1" >> "$LOG_FILE"
	echo "$1" >> "$ERROR_LOG"
	echo "$1" >&2
	EXIT_CODE=1
}

create_link()
{
	local main="$1"
	local link="$2"
	local type="$3"

	if [ ! -e "$main" ]; then
		logError "File '$main' does not exits. Link is not created"
		return
	fi

	if [ "$type" = "soft" ]; then
		if ln -s "$main" "$link" 2>/dev/null; then
			log "Soft link OK: $link -> $main"
		else
			logError "Soft link error $link -> $main"
		fi
	elif [ "$type" = "hard" ]; then
		if ln "$main" "$link" 2>/dev/null; then
			log "Hard link OK: $link -> $main"
		else
			logError "Hard link error: $link -> $main"
		fi
	else
		logError "Link type error"
	fi	
}

install_self_link()
{
	if ln -sf "$(realpath "$0")" /bin/linux_cli.sh 2>/dev/null; then
		log "Script softlink created at /bin/linux_cli.sh"
	else 
		logError "Script softlink not created. Permission denied"
	fi
}

: << 'DO_NOT_UNCOMMENT'
list_updates()
{
    local output="$1"

    if [ "$(id -u)" -ne 0 ]; then
        echo "Only root authorized for updates." >&2
        EXIT_CODE=1
        return
    fi

    if [[ -n "$output" ]]; then
        apt list --upgradable > "$output" 2>/dev/null
    else
        apt list --upgradable
    fi

    EXIT_CODE=$?
}

update_upgrade()
{
	if [ "$(id -u)" -eq 0 ]; then
		apt update
		apt upgrade -y
		echo "Upgrade finished."
	else
		echo "Only root authorized for upgrades."
		EXIT_CODE=1
	fi
}
DO_NOT_UNCOMMENT

find_be_e_files()
{
	echo "First 5 files containing 'be' or 'e':"
    if ! find ~/ -type f \( -name '*be*' -o -name '*e*' \) 2>/dev/null | head -n 1 | grep -q .; then
        echo "No files found."
    else
        find ~/ -type f \( -name '*be*' -o -name '*e*' \) 2>/dev/null | head -n 5
    fi
}

monitor_system()
{
	s_u="$SHELL"
	c_u="${SUDO_USER:-$(whoami)}"
	l_v="$(lsb_release -a | grep "Description" | cut -d: -f2 | xargs)"
	e_v="$(env | grep -v "LS_COLORS=" | grep -v "SHELL=" | head -n 10)"

	wall "Shell used: $s_u
Current user: $c_u
Linux version: $l_v
Environment vars: 
$e_v"

	log "OS info sent via wall"
}

help()
{
	echo "Script usage:"
    echo "Use flags for running ft: create_link, list_updates, update_upgrade."
    echo "Functions:"
    echo "  create_link (flag -s)				- Creates a soft or hard link
			- Correct input <file.txt> <soft/hardlink.txt> <soft/hard>"
    echo "  list_updates (flag -a)				- Lists packages available for update"
	echo "  list updates (flag -f <file.txt>)  	- Save lsit of packages to file"
	echo "  update_upgrade (flag -u)			- Performs system update and upgrade"
    echo "  find_be_e_files						- Finds files containing the letters be, e"
	echo "  log									- Writes message to the log"
	echo "  install_self_link					- Creates a ling to the scipt in /bin"
}

while (( $# > 0 )); do
	case "$1" in
		-h)
			help
			shift
			;;
        # -a)
		# 	if [[ "$2" == "-f" ]]; then
		# 		list_updates "$3"
		# 		shift 3
		# 	else
		# 		list_updates
		# 		shift
		# 	fi
		# 	;;
		# -u)
		# 	update_upgrade
		# 	shift
		# 	;;
		-s)
			if (( $# < 4 )); then
				echo "Input ./linux_cli.sh <file.txt> <soft/hardlink.txt> <soft/hard>"
				exit 1
			fi
			create_link "$2" "$3" "$4"
			shift 4
			;;
		*)
			echo "Input correct flag"
			help
			exit_CODE=1
			exit $EXIT_CODE
	esac
done

log "Script started"
install_self_link
find_be_e_files
monitor_system
exit $EXIT_CODE
