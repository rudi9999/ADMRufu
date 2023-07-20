#!/bin/bash

funcion_crear(){
	if [[ -e "/swapfile" ]]; then
		title "DETENIENDO MEMORIA SWAP"
		fun_bar 'swapoff -a' 'STOP SWAPFILE  '
		fun_bar 'sed -i '/swap/d' /etc/fstab' 'REMOV AUTO-RUN '
		fun_bar 'sed -i '/vm.swappiness/d' /etc/sysctl.conf' 'REMOV PRORITY  '
		fun_bar 'sysctl -p' 'RELOAD CONFG   '
		fun_bar 'rm -rf /swapfile' 'REMOV SWAPFILE '
		msg -bar
		print_center -verd "SWAPFILE DETENIDO"
		msg -bar
		read foo
		return
	fi

	memoria=$(dmidecode --type memory | grep ' MB'|awk '{print $2}')
	if [[ "$memoria" -gt "2048" ]]; then
		msg -azu " Su sistema cuenta con mas de 2GB de ram\n No es necesario la creacion de memoria swap" 
		msg -bar
		read foo
		return 1
	fi
	title "INSTALADO MEMORIA SWAP"
	fun_bar 'fallocate -l 2G /swapfile' 'MAKE SWAPFILE    '
	#fun_bar "dd if=/dev/zero of=$swap bs=1MB count=2048" 'MAKE SWAPFILE    '
	fun_bar 'ls -lh /swapfile' 'VERIFIC SWAPFILE '
	fun_bar 'chmod 600 /swapfile' 'ASSIGN PERMISOS  '
	fun_bar 'mkswap /swapfile' 'ASSIGN FORMATO   '
	msg -bar
	print_center -verd "SWAPFILE CREADO CON EXITO"
	msg -bar
	read foo	
}

funcion_activar(){
	title "ACTIVAR SWAPFILE"
	menu_func "PREMANENTE" "HASTA EL PROXIMO REINICO"
	back
	opcion=$(selection_fun 2)
	case $opcion in
		  1)sed -i '/swap/d' $fstab
			echo "$swap none swap sw 0 0" >> $fstab
			swapon $swap
			print_center -verd "SWAPFILE ACTIVO"
			msg -bar
			sleep 2;;
		  2)swapon $swap
			print_center -verd "SWAPFILE ACTIVO"
			msg -bar
			sleep 2;;
    	  0)return;;
	esac
}


funcion_prio(){
	title "PRIORIDAD SWAP"
	menu_func "10" "20 (recomendado)" "30" "40" "50" "60" "70" "80" "90" "100"
	back
	opcion=$(selection_fun 10)
	case $opcion in
		0)return;;
		*)
if [[ $(cat "$sysctl"|grep "vm.swappiness") = "" ]]; then
	echo "vm.swappiness=${opcion}0" >> $sysctl
	sysctl -p &>/dev/null
else
	sed -i '/vm.swappiness=/d' $sysctl
	echo "vm.swappiness=${opcion}0" >> $sysctl
	sysctl -p &>/dev/null
fi
print_center -verd "PRIORIDAD SWAP EN ${opcion}0"
msg -bar
sleep 2;;
	esac
}

while :
do
	title 'SWAP MANAGER By @Rufu99'
	menu_func "CREAR/DESACTIVAR /SWAPFILE" \
	"ACTIVAR SWAP" \
	"PRIORIDAD SWAP"
	back
	opcion="$(selection_fun 3)"

	case $opcion in
		1)funcion_crear;;
		2)funcion_activar;;
		3)funcion_prio;;
		0)break;;
	esac
	[[ "$?" = "1" ]] && break
done
return 1
