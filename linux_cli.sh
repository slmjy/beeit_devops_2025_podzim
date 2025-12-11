#! /bin/bash

printUser() {
	echo "User is: "
	whoami
}

printOsVersion() {
	echo "OS Version: "
	cat /etc/os-release
}

printShellUsed() {
	echo "Shell used: $SHELL"
}

logError() {
	echo "Error: $1" >&2
}

printEnvs() {
	echo "All environment variables: "
	env
}

log() {
	echo "======= $1 ======="
}


logError() {
	echo "$1" >&2
}

listUpgradablePackages() {
	apt list --upgradable
}

upgradePackages() {
	apt-get update && apt-get upgrade
}

addLink() {
	ln -s $(dirname "$0")/$(basename "$0") /bin/linux_cli/$(basename "$0")
}
log("Welcome to Task 4\n")

printShellUsed
printUser
printOsVersion
printEnvs

logError "O oh!"

export MY_ENV_VAR=1
OS_VERSION=($cat /etc/os-release
