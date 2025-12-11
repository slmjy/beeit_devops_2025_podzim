#!/bin/bash

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
	if [ "$(id -u)" -eq 0 ]; then
		apt list --upgradable
	else 
		echo "Only root authorized for updates."
	fi
}
update_upgrade()
{
	if [ "$(id -u)" -eq 0 ]; then
		apt update
		apt upgrade -y
		echo "Upgrade finished."
	else
		echo "Only root authorized for upgrades."
	fi
}
DO_NOT_UNCOMMENT

find_be_e_files()
{
	echo "Files with b and e letters:"
	find / -type f -name '.*b.*e.*e.*' 2>/dev/null
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
    echo "Script runs all functions automatically."
    echo "Functions:"
    echo "  log               - Writes message to the log"
    echo "  create_link       - Creates a soft or hard link"
    echo "  install_self_link - Creates a ling to the scipt in /bin"
    echo "  list_updates      - Lists packages available for update"
    echo "  update_upgrade    - Performs system update and upgrade"
    echo "  find_be_e_files   - Finds files containing the letters be, e "	

}
if [[ "$1" == "-h" ]]; then
	help
	exit 0
fi

log "Script started"
create_link "file.txt" "soft_link.txt" "soft"
install_self_link
# list_updates
# update_upgrade
# find_be_e_files
monitor_system




	


