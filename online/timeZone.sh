#!/bin/bash
#source ../../module
title 'CONFIGURACION DE ZONA HORARIA'
timezones=$(timedatectl list-timezones|grep America)
i=0
while read line; do
	if [[ $(echo $line|awk -F '/' '{print $2}') = "$no_rep" ]]; then
		continue
	fi
	let i++
	zone[$i]=$line
	echo " $(msg -verd "[$i]") $(msg -verm2 '>') $(msg -ama "$line")"
	no_rep=$(echo $line|awk -F '/' '{print $2}')
done <<< "$timezones"
back
zones=$(selection_fun $i)
if [[ $zones -gt 0 ]]; then
	timedatectl set-timezone ${zone["$zones"]}
	title -verd 'ZONA HORARIA MODIFICADA'
	newzone=$(timedatectl|grep 'Time zone')
	print_center -ama "$(timedatectl|grep 'Time zone')"
else
	title -verm2 'ZONA HORARIA NO MODIFICADA'
	print_center 'Se mantiene la conf del sistema'
	msg -bar
	newzone=$(timedatectl|grep 'Time zone')
	print_center -ama "$(timedatectl|grep 'Time zone')"
fi
enter
