#!/bin/bash

if [[ $(dpkg --get-selections|grep -w 'htop'|head -1) = "" ]]; then
	title "INSTALADO HTOP..."
	if apt install htop -y &>/dev/null ; then
		print_center -verd "Htop instalado"
		sleep 2
	else
		print_center -verm2 "Htop NO instalado"
		sleep 2
		return 1
	fi
fi
htop
