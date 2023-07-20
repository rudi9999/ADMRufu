#!/bin/bash

if [[ ! -e /root/module ]]; then
	wget -O /root/module 'https://raw.githubusercontent.com/rudi9999/Herramientas/main/module/module' &>/dev/null
	chmod +x /root/module
fi
source /root/module

download_udpServer(){
	msg -nama '        Descargando binario UDPserver .....'
	if wget -O /usr/bin/udpServer 'https://bitbucket.org/iopmx/udprequestserver/downloads/udpServer' &>/dev/null ; then
		chmod +x /usr/bin/udpServer
		msg -verd 'OK'
	else
		msg -verm2 'fail'
		rm -rf /usr/bin/udpServer*
	fi
}

make_service(){
	ip_nat=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | sed -n 1p)
	interfas=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}'|grep "$ip_nat"|awk {'print $NF'})
	ip_publica=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$(wget -T 10 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/" || curl -m 10 -4Ls "http://ip1.dynupdate.no-ip.com/")")

	#ip_nat=$(fun_ip nat)
	#interfas=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}'|grep "$ip_nat"|awk {'print $NF'})
	#ip_publica=$(fun_ip)

cat <<EOF > /etc/systemd/system/UDPserver.service
[Unit]
Description=UDPserver Service by @Rufu99
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/bin/udpServer -ip=$ip_publica -net=$interfas$Port -mode=system
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target6
EOF

	msg -nama '        Ejecutando servicio UDPserver .....'
	systemctl start UDPserver &>/dev/null
	if [[ $(systemctl is-active UDPserver) = 'active' ]]; then
		msg -verd 'OK'
		systemctl enable UDPserver &>/dev/null
	else
		msg -verm2 'fail'
	fi
}

install_UDP(){
	title 'INSTALACION UDPserver'
	exclude
	download_udpServer
	if [[ $(type -p udpServer) ]]; then
		make_service
		msg -bar3
		if [[ $(systemctl is-active UDPserver) = 'active' ]]; then
			print_center -verd 'instalacion completa'
		else
			print_center -verm2 'falla al ejecutar el servicio'
		fi
	else
		echo
		print_center -ama 'Falla al descargar el binario udpServer'
	fi
	enter	
}

uninstall_UDP(){
	title 'DESINTALADOR UDPserver'
	read -rp " $(msg -ama "QUIERE DISINSTALAR UDPserver? [S/N]:") " -e -i S UNINS
	[[ $UNINS != @(S|s) ]] && return
	systemctl stop UDPserver &>/dev/null
	systemctl disable UDPserver &>/dev/null
	rm -rf /etc/systemd/system/UDPserver.service
	rm -rf /usr/bin/udpServer
	del 1
	print_center -ama "desinstalacion completa!"
	enter
}

reset(){
	if [[ $(systemctl is-active UDPserver) = 'active' ]]; then
		systemctl stop UDPserver &>/dev/null
		systemctl disable UDPserver &>/dev/null
		print_center -ama 'UDPserver detenido!'
	else
		systemctl start UDPserver &>/dev/null
		if [[ $(systemctl is-active UDPserver) = 'active' ]]; then
			systemctl enable UDPserver &>/dev/null
			print_center -verd 'UDPserver iniciado!'
		else
			print_center -verm2 'falla al inciar UDPserver!'
		fi	
	fi
	enter
}

exclude(){
	title 'Excluir puertos UDP'
	print_center -ama 'UDPserver cubre el rango total de puertos.'
	print_center -ama 'puedes excluir puertos UDP'
	msg -bar3
	print_center -ama 'Ejemplos de puertos a excluir:'
	print_center -ama 'dnstt (slowdns) udp 53 5300'
	print_center -ama 'wireguard udp 51820'
	print_center -ama 'openvpn udp 1194'
	msg -bar
	print_center -verd 'ingresa los puertos separados por espacios'
	print_center -verd 'Ejemplo: 53 5300 51820 1194'
	msg -bar3
	in_opcion_down 'digita puertos o enter saltar'
	del 2
	tmport=($opcion)
	for (( i = 0; i < ${#tmport[@]}; i++ )); do
		num=$((${tmport[$i]}))
		if [[ $num -gt 0 ]]; then
			echo "$(msg -ama " Puerto a excluir >") $(msg -azu "$num") $(msg -verd "OK")"
			Port+=" $num"
		else
			msg -verm2 " No es un puerto > ${tmport[$i]}?"
			continue
		fi
	done

	if [[ -z $Port ]]; then
		unset Port
		print_center -ama 'no se excluyeron puertos'
	else
		Port=" -exclude=$(echo "$Port"|sed "s/ /,/g"|sed 's/,//')"
	fi
	msg -bar3
}

add_exclude(){
	title 'Excluir puertos UDP'
	print_center -ama 'UDPserver cubre el rango total de puertos.'
	print_center -ama 'puedes excluir puertos UDP'
	msg -bar3
	print_center -ama 'Ejemplos de puertos a excluir:'
	print_center -ama 'dnstt (slowdns) udp 53 5300'
	print_center -ama 'wireguard udp 51820'
	print_center -ama 'openvpn udp 1194'
	msg -bar
	print_center -verd 'ingresa los puertos separados por espacios'
	print_center -verd 'Ejemplo: 53 5300 51820 1194'
	in_opcion_down 'Ingresa puertos o enter para canselar'
	del 4
	tmport=($opcion)
	unset Port
	for (( i = 0; i < ${#tmport[@]}; i++ )); do
		num=$((${tmport[$i]}))
		if [[ $num -gt 0 ]]; then
			echo "$(msg -ama " Puerto a excluir >") $(msg -azu "$num") $(msg -verd "OK")"
			Port+=" $num"
		else
			msg -verm2 " No es un puerto > ${tmport[$i]}?"
			continue
		fi
	done
	if [[ $Port = "" ]]; then
		unset Port
		print_center -ama 'no se excluyeron puertos'
	else
		exclude=$(cat /etc/systemd/system/UDPserver.service|grep 'exclude')
		if systemctl is-active UDPserver &>/dev/null; then
			systemctl stop UDPserver &>/dev/null
			systemctl disable UDPserver &>/dev/null
			iniciar=1
		fi
		if [[ -z $exclude ]]; then
			Port=" -exclude=$(echo "$Port"|sed "s/ /,/g"|sed 's/,//')"
			sed -i "s/ -mode/$Port -mode/" /etc/systemd/system/UDPserver.service
		else
			exclude_port=$(echo $exclude|awk '{print $4}'|cut -d '=' -f2)
			Port="-exclude=$exclude_port$(echo "$Port"|sed "s/ /,/g")"
			sed -i "s/-exclude=$exclude_port/$Port/" /etc/systemd/system/UDPserver.service
		fi
		if [[ $iniciar = 1 ]]; then
			systemctl start UDPserver &>/dev/null
			systemctl enable UDPserver &>/dev/null
		fi
	fi
	enter
}

quit_exclude(){
	title 'QUITAR PUERTO DE EXCLUCION'
	exclude=$(cat /etc/systemd/system/UDPserver.service|grep 'exclude'|awk '{print $4}')
	ports=($port)
	for (( i = 0; i < ${#ports[@]}; i++ )); do
		a=$(($i+1))
		echo "             $(msg -verd "[$a]") $(msg -verm2 '>') $(msg -azu "${ports[$i]}")"
	done
	if [[ ! ${#ports[@]} = 1 ]]; then
		let a++
		msg -bar
		echo "             $(msg -verd "[0]") $(msg -verm2 ">") $(msg -bra "\033[1;41mVOLVER")  $(msg -verd "[$a]") $(msg -verm2 '> QUITAR TODOS')"
		msg -bar
	else
		msg -bar
		echo "             $(msg -verd "[0]") $(msg -verm2 ">") $(msg -bra "\033[1;41mVOLVER")"
		msg -bar
	fi
	opcion=$(selection_fun $a)
	[[ $opcion = 0 ]] && return
	if systemctl is-active UDPserver &>/dev/null; then
		systemctl stop UDPserver &>/dev/null
		systemctl disable UDPserver &>/dev/null
		iniciar=1
	fi
	if [[ $opcion = $a ]]; then
		sed -i "s/$exclude //" /etc/systemd/system/UDPserver.service
		print_center -ama 'Se quito todos los puertos excluidos'
	else
		let opcion--
		unset Port
		for (( i = 0; i < ${#ports[@]}; i++ )); do
			[[ $i = $opcion ]] && continue
			echo "$(msg -ama " Puerto a excluir >") $(msg -azu "${ports[$i]}") $(msg -verd "OK")"
			Port+=" ${ports[$i]}"
		done
		Port=$(echo $Port|sed 's/ /,/g')
		sed -i "s/$exclude/-exclude=$Port/" /etc/systemd/system/UDPserver.service
	fi
	if [[ $iniciar = 1 ]]; then
		systemctl start UDPserver &>/dev/null
		systemctl enable UDPserver &>/dev/null
	fi
	enter
}

menu_udp(){
	title 'SCRIPT DE CONFIGRACION UDPserver BY @Rufu99'
	print_center -ama 'UDPserver Binary by team newtoolsworks'
	print_center -ama 'UDPclient Android SocksIP'
	msg -bar
	if [[ $(type -p udpServer) ]]; then
		if [[ $(systemctl is-active UDPserver) = 'active' ]]; then
			estado="\e[1m\e[32m[ON]"
		else
			estado="\e[1m\e[31m[OFF]"
		fi

		port=$(cat /etc/systemd/system/UDPserver.service|grep 'exclude')

		if [[ ! $port = "" ]]; then
			port=$(echo $port|awk '{print $4}'|cut -d '=' -f2|sed 's/,/ /g')
			print_center -ama "PUERTOS EXCLUIDOS $port"
			msg -bar
		fi
		echo " $(msg -verd "[1]") $(msg -verm2 '>') $(msg -verm2 'DESINSTALAR UDPserver')"
		echo -e " $(msg -verd "[2]") $(msg -verm2 '>') $(msg -azu 'INICIAR/DETENER UDPserver') $estado"
		msg -bar3
		print_center -ama 'EXCLUCION DE PUERTO'
		msg -bar3
		echo " $(msg -verd "[3]") $(msg -verm2 '>') $(msg -verd 'AGREGAR PUERTO A LISTA DE EXCLUSION')"
		num=3
		if [[ ! $port = "" ]]; then
			echo " $(msg -verd "[4]") $(msg -verm2 '>') $(msg -verm2 'QUITAR PUERTO A LISTA DE EXCLUSION')"
			num=4
		fi
		a=x; b=1
	else
		echo " $(msg -verd "[1]") $(msg -verm2 '>') $(msg -verd 'INSTALAR UDPserver')"
		num=1; a=1; b=x
	fi
	back
	opcion=$(selection_fun $num)

	case $opcion in
		$a)install_UDP;;
		$b)uninstall_UDP;;
		2)reset;;
		3)add_exclude;;
		4)quit_exclude;;
		0)return 1;;
	esac
}

while [[  $? -eq 0 ]]; do
  menu_udp
done