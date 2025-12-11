#! /bin/bash


#echo "Pouzivam SHELL:"
#echo $SHELL

#echo "Aktualni uzivatel je:"
#whoami

#echo "Distribuce linuxu:"
#cat /etc/os-release

#echo "Evnironment variables v OS jsou:"
#printenv


LOG_MODE="stdout"
LOG_FILE="linux_cli.log"
EXIT_CODE=0 



log() {
	if [ "$LOG_MODE" = "file" ]; then
		echo "$1 $2" >> "$LOG_FILE"
	else
		echo "=== $1 $2 ==="
	fi
 } 

log_error() {
	if [ "$LOG_MODE" = "file" ]; then
		echo "$1" >> "$LOG_FILE"
	else
		echo "Error: $1" >&2
	fi       	
}

list_update() {
	log "$1" ""
	apt list --upgradable 2>/dev/null | grep -v "Listing..." | while read -r line; do
		log "$line" ""
	done
}

upgrade_package() {
	log "Upgrade started" ""
	sudo apt upgrade -y >> "$LOG_FILE"
      	if [ $? -ne 0 ]; then
		log_error "Upgrade failed"
		EXIT_CODE=1
	else
		log "Upgrade complete" ""
	fi	
}

show_help() {
	echo "You can use: ./linux_cli.sh [option]"
	echo ""
	echo "This help contains these options:"
	echo "-h, --help		Shows this help"
	echo "--create-link		Soft link creation"
	echo "-a			Availabe for upgrade"
	echo "-u			Upgrade file"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
fi

create_soft_link() {
	target_path="$(realpath "$0")"
	link_path="/bin/linux_cli"
	
	if [ -L "$link_path" ]; then
		log "Soft link already exists:" "$link_path"
	else
		sudo ln -s "$target_path" "$link_path"
		if [ $? -ne 0 ]; then
			log_error "Failed to create soft link"
			EXIT_CODE=2
		else
			log "Soft link created:" "$link_path -> $target_path"
		fi
	fi
}

if [ "$1" = "--create-link" ]; then
	create_soft_link
	exit 0
fi


#log "System" "OK" 
#log_error "Need restart"
#list_update "Packages for upgrade:"
#upgrade_package "Ugrade package"

#find_bee_files() {
#	find / -type f -regextype posix-extended -regex ".*/.*b.*e.*e.*"
#}

#if [ "$1" = "--find-bee" ]; then
#	find_bee_files
#	exit 0
#fi

while [[ $# -gt 0 ]]; do
	case "$1" in
		-a)
			DO_LIST=true
			;;
		-u)
			DO_UPGRADE=true
			;;
		--create-link)
			DO_LINK=true
			;;
		-f)
			shift
			LOG_FILE="$1"
			LOG_MODE="file"
			if [ -e "$LOG_FILE" ]; then
				echo "Log file "$LOG_FILE" already exists."
			fi
			;;
		-h|--help)
			show_help
			exit 0
			;;
		*)
			log_error "Unknow parameter. $1"
			exit 99
			;;
	esac
	shift
done


[ "$DO_LIST" = true ] && list_update
[ "$DO_UPGRADE" = true ] && upgrade_package
[ "$DO_LINK" = true ] && create_soft_link

exit $EXIT_CODE
