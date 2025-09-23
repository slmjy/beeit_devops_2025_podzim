#!/bin/bash

s_u="$SHELL"
c_u="${SUDO_USER:-$(whoami)}"
l_v="$(lsb_release -a | grep "Description" | cut -d: -f2 | xargs)"
e_v="$(env | grep -v "LS_COLORS=" | grep -v "SHELL=" | head -n 10)"

wall "Shell used: $s_u
Current user: $c_u
Linux version: $l_v
Environment vars: 
$e_v"

	


