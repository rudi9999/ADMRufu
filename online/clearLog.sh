#!/bin/bash

#source /etc/ADMRufu/module

opc=$1

clearlog(){
	filesBack=$(ls -lh /var/log/|awk '{print $9}')
	for backs in $filesBack; do
		rm -rf /var/log/$backs.*
	done
	files=$(ls -lh /var/log/|grep adm|grep "M\|G"|awk '{print $9}')
	for i in $files; do
		> /var/log/$i
	done

	echo "$(printf '%(%H:%M:%S)T')" > /root/clearlog.txt
}

autoClearLog(){
	title 'PROGRAMADOR DE TAREA CLEAR LOGS'
	if [[ ! -z $(crontab -l|grep 'clearLog.sh') ]]; then
	    msg -azu " Tarea programada cada $(msg -verd "[ $(crontab -l|grep 'clearLog.sh'|awk '{print $2}'|sed $'s/[^[:alnum:]\t]//g')HS ]")"
	    msg -bar
	    while :
	    do
		    in_opcion -nama 'Quitar tarea programada [S/N]'
		    del 2
		    case $opcion in
		      s|S)  crontab -l > /root/cron && sed -i '/clearLog.sh/ d' /root/cron && crontab /root/cron && rm /root/cron
					print_center -verd 'Tarea automatica removida!'
					enter
					return;;
		      n|N)  return;;
		      	*)  print_center -ama 'Selecciona S para si, N para no'
					sleep 2
					del 1
		    esac
	    done
	fi 

    in_opcion -nama 'PERIODO DE EJECUCION DE LA TAREA [1-12HS]'
    del 2
    if [[ $opcion =~ $numero ]]; then
		crontab -l > /root/cron
		echo "0 */$opcion * * * sudo /etc/ADMRufu/source/tool/clearLog.sh --clearlog" >> /root/cron
		crontab /root/cron
		rm /root/cron
		msg -azu " Tarea automatica programada cada: $(msg -verd "${opcion}HS")" && msg -bar && sleep 2
    else
		print_center -verm2 'ingresar solo numeros entre 1 y 12'
		sleep 2
		msg -bar
    fi
}

menuClearLog(){
	title 'HERRAMIENTA CLEAR LOGS'
	menu_func 'LIMPIAR LOGS' 'PROGRAMAR TAREA AUTOMATICA'
	back
	opcion=$(selection_fun 2)
	case $opcion in
		1)  print_center -ama 'limpiando logs'
			clearlog
			sleep 2
			del 1
			print_center -verd 'limpiesa de logs completa'
			enter;;
		2)autoClearLog;;
		0)return 1;;
	esac
}

if [[ $opc = '--clearlog' ]]; then
	clearlog
	exit
fi
while [[ $? -eq 0 ]]; do
	menuClearLog
done
