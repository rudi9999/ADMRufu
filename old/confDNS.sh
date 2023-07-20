#!/bin/bash

source ../module

newDNS(){
	del 3
	back
	in_opcion -nazu 'INGRESA TU HOST/IP DNS'
	if [[ $opcion = '0' ]] || [[ $opcion = "" ]]; then
		return
	fi
	opcion=$(echo "$opcion" | tr -d '[[:space:]]')
	echo "nameserver $opcion" >> /etc/resolvconf/resolv.conf.d/head
	resolvconf -u
	del 4
	print_center -verd 'Nuevo host/ip dns agregado!'
	enter
}

delDNS(){
	title 'REMOVER UN HOST/IP DNS'
	i=0
	for d in ${dns[@]}; do
		let i++
		[[ -z $d ]] && continue
		echo " $(msg -verd "[$i]") $(msg -verm2 '>') $(msg -azu "$d")"	
	done
	back
	opcion=$(selection_fun $i)
	[[ $opcion = 0 ]] && return
	linea=$(grep -n -E "${dns[$opcion]}" /etc/resolvconf/resolv.conf.d/head|awk '{print $1}'|cut -d ':' -f1)
	sed -i "${linea}d" /etc/resolvconf/resolv.conf.d/head
	#sed -i "/nameserver ${dns[$opcion]}/d" /etc/resolvconf/resolv.conf.d/head
	resolvconf -u
	print_center -ama 'Host/Ip dns removido!'
	enter
}

menuDNS(){
	unset dns
	resolv=$(cat /etc/resolvconf/resolv.conf.d/head|grep -v '#'|grep nameserver|cut -d ' ' -f2)
	title 'CONFIGURACION DE IP DNS'
	print_center -verm2 'funcion beta, por fallos reportar a @Rufu99'
	msg -bar3
	print_center -ama '	lista de ip dns activas'
	msg -bar3
	i=1
	while read line; do
		#echo " $(msg -verd "[$i]") $(msg -verm2 ">") $(msg -azu "$line")"
		echo "     $(msg -verd "NameServer") $(msg -verm2 ">") $(msg -azu "$line")"
		dns[$i]="$line"
		let i++
	done <<< $(echo "$resolv")
	msg -bar
	echo -ne " $(msg -verd "[0]") $(msg -verm2 ">")"
	echo " $(msg -bra "\033[1;41mVOLVER")   $(msg -verd "[1]") $(msg -verm2 ">") $(msg -verd "AGREGAR DNS")   $(msg -verd "[2]") $(msg -verm2 ">") $(msg -verm2 "QUITAR DNS")"
	msg -bar
	opcion=$(selection_fun 2)
	case $opcion in
		1)newDNS;;
		2)delDNS;;
		0) return 1;;
	esac
}

install_resolv(){
	if [[ $(which resolvconf) = "" ]]; then
		title -ama 'AVISO!!!!'
		print_center -ama 'Esta funcion requiere del paquete resolvconf'
		msg -bar
		in_opcion 'Quieres instalar resolvconf [s/n]'
		case $opcion in
			s|S)apt install resolvconf -y;;
			n|N)return 1;;
			  *)return 1;;
		esac
	fi
}

while [[ $? -eq 0 ]]; do
	install_resolv
	[[ $? -eq 0 ]] && menuDNS
done