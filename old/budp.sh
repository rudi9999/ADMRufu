#!/bin/bash

service_badvpn(){

	echo -e "[Unit]
Description=BadVPN UDPGW Service
After=network.target\n
[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:$1 --max-clients 1000 --max-connections-for-client 10
Restart=always
RestartSec=3s\n
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/badvpn.$1.service

	systemctl enable badvpn.$1 &>/dev/null
    systemctl start badvpn.$1 &>/dev/null

    if [[ $(systemctl is-active badvpn.$1) = 'active' ]]; then
    	echo 'active'
    else
    	echo 'inactive'
    fi
}

IN_PORT(){
	while [[ -z $_PORT ]]; do
		read -rp " $(msg -ama "INGRESE UN PUERTO [DEFAULT 7300]:") " -e -i  7300 _PORT
		del 1
		if [[ -z $_PORT ]]; then
			_PORT='7300'
		elif [[ ! $_PORT =~ $numero ]]; then
			print_center -verm2 'ingresa solo numeros'
			sleep 2
			unset _PORT
			del 1
			continue
		fi

		TTOTAL=($_PORT)
  		for((i=0; i<${#TTOTAL[@]}; i++)); do
  			[[ $(mportas|grep "${TTOTAL[$i]}") = "" ]] && {
  				echo " $(msg -azu 'Puerto Elegido:') $(msg -verd "${TTOTAL[$i]} OK")"
  				PORT="$PORT ${TTOTAL[$i]}"
  			} || {
  				echo " $(msg -azu 'Puerto Elegido:') $(msg -verm2 "${TTOTAL[$i]} FAIL")"
  			}
  		done

  		[[ -z $PORT ]] && {
  			msg -bar
  			print_center -verm2 'Ningun Puerto Valida Fue Elegido'
  			sleep 2
  			del $((${#TTOTAL[@]} + 2))
  			unset _PORT
  			unset PORT
  			continue
  		}
	done
	unset _PORT
}

install(){
	clr(){
		cd $HOME
        rm -rf ${ADM_src}/badvpn-master*
	}
	if [[ $(type -p badvpn-udpgw) ]]; then
		_services=$(systemctl list-unit-files|grep badvpn|awk '{print $1}')

		print_center -ama 'REMOVIENDO BADVPN'
		while [[ ! -z $_services ]] && read line; do
			systemctl stop $line &>/dev/null
			systemctl disable $line &>/dev/null
		done <<< $(echo "$_services")
		rm -rf /etc/systemd/system/badvpn*
		rm -rf $(type -p badvpn-udpgw)
		del 1
		print_center -verd 'BADVPN REMOVIDO!!!'
		enter
	else
		title 'instalador badvpn-udpgw by @Rufu99'
		IN_PORT
		msg -bar
		print_center -ama "INSTALADO BADVPN"
		msg -bar
		rm -rf ${ADM_src}/badvpn-master*
		msg -nazu " INSTALADO DEPENDECIAS... "
		if apt install cmake -y &>/dev/null; then
			msg -verd "[OK]"
		else
			del 1
            print_center -verm2 'FALLA AL INSTALAR DEPENDENCIAS "cmake"\nINTENTE INSTALAR DE FORMA MANUAL\n\napt install cmake\n\nE INTENTE NUEVAMENTE'
            enter
            return
        fi

        cd ${ADM_src}
        msg -nazu " DESCARGANDO BADVPN...... "
        if wget https://github.com/rudi9999/ADMRufu/raw/main/Utils/badvpn/badvpn-master.zip &>/dev/null; then
            msg -verd "[OK]"
        else
        	clr
        	del 1
        	print_center -verm2 'FALLA AL DESCARGAR BADVPN'
            enter
            return
        fi

        msg -nazu " DESCOMPRIMIENDO......... "
        if unzip badvpn-master.zip &>/dev/null; then
            msg -verd "[OK]"
        else
        	clr
        	del 1
            print_center -verm2 'FALLA AL DESCOMPRIMIR PAQUETE ZIP'
            enter
            return
        fi

        msg -nazu " COMPILANDO BADVPN....... "

        cd badvpn-master
        mkdir build
        cd build

        if cmake .. -DCMAKE_INSTALL_PREFIX="/" -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 &>/dev/null ; then
            msg -verd "[OK]"
        else
        	clr
        	del 1
            print_center -verm2 'FALLA DE COMPILACION'
            enter
            return 1
        fi

        msg -nazu ' INSTALANDO.............. '
        if make install &>/dev/null; then
        	msg -verd "[OK]"
        else
        	clr
        	del 1
        	print_center -verm2 'FALLA DE INSTALACION'
        	enter
        	return
        fi
        clr

        msg -nazu ' INICIANDO............... '
        if [[ $(service_badvpn $PORT) = 'active' ]]; then
        	msg -verd "[OK]"
        else
        	del 1
        	print_center -verm2 'FALLA AL INICIAR SERVICIO BADVPN'
        fi
        enter
	fi
}

all_service(){
	n=1
	while read line; do
		serv_por[$n]=$line
		viw_port=$(echo "$line"|awk -F '.' '{print $2}')
		if [[ $(systemctl is-active $line) = 'active' ]]; then
			sta="\e[1m\e[32mON"
		else
			sta="\e[1m\e[31mOFF"
		fi
		echo -e " $(msg -verd "[$n]") $(msg -verm2 '>') $(msg -azu "$viw_port") $sta"
		let n++
	done <<< $(echo "$_services")

}

restart(){
	print_center -ama 'BUSCANDO SERVICIOS...'
	_services=$(systemctl list-unit-files|grep badvpn|awk '{print $1}')
	#_services=$(systemctl --all|grep badvpn|awk '{print $1}')
	if [[ $(echo "$_services"|wc -l) = 1 ]]; then
		if [[ $(systemctl is-enabled $_services) = 'disabled' ]]; then
			systemctl enable $_services &>/dev/null
		fi
		systemctl restart $_services &>/dev/null
		del 1
		print_center -verd 'BADVPN REINICIADO!!!'
		enter
		return
	fi
	title 'REINICIO DE SERVICIOS'
	all_service
	echo " $(msg -verd "[$n]") $(msg -verm2 '>') $(msg -azu 'REINICIAR TODOS')"
	back
	_opcion=$(selection_fun $n)
	[[ $_opcion = 0 ]] && return
	print_center -ama 'REINICIANDO BADVPN'
	while [[ $_opcion = $n ]] && read line; do
		if [[ $(systemctl is-enabled $line) = 'enabled' ]]; then
			systemctl enable $line &>/dev/null
		fi
		systemctl restart $line &>/dev/null
	done <<< $(echo "${serv_por[@]}")
	if [[ ! $_opcion = $n ]]; then
		if [[ $(systemctl is-enabled ${serv_por[$_opcion]}) = 'disabled' ]]; then
			systemctl enable ${serv_por[$_opcion]} &>/dev/null
		fi
		systemctl restart ${serv_por[$_opcion]} &>/dev/null
	fi
	del 1
	print_center -verd 'BADVPN REINICIADO'
	enter
}

stop(){
	#_services=$(systemctl list-unit-files|grep badvpn|awk '{print $1}')
	#_services=$(systemctl list-units --type=service|grep badvpn|awk '{print $1}')
	_services=$(systemctl list-units --all --state=active|grep badvpn|awk '{print $1}')
	if [[ $(echo "$_services"|wc -l) = 1 ]]; then
		print_center -ama 'PARANDO BADVPN'
		if [[ $(systemctl is-enabled $_services) = 'enabled' ]]; then
			systemctl disable $_services &>/dev/null
		fi
		systemctl stop $_services &>/dev/null
		del 1
		print_center -verd 'BADVPN PARANDO!!!'
		enter
		return
	fi

	title 'DETENER SERVICIOS BADVPN'
	all_service
	echo " $(msg -verd "[$n]") $(msg -verm2 '>') $(msg -azu 'PARAR TODOS')"
	back
	_opcion=$(selection_fun $n)
	[[ $_opcion = 0 ]] && return

	print_center -ama 'PARANDO SERVICIO BADVPN'

	while [[ $_opcion = $n ]] && read line; do
		if [[ $(systemctl is-enabled $line) = 'enabled' ]]; then
			systemctl disable $line &>/dev/null
		fi
		systemctl stop $line &>/dev/null
	done <<< $(echo "${serv_por[@]}")

	if [[ ! $_opcion = $n ]]; then
		if [[ $(systemctl is-enabled ${serv_por[$_opcion]}) = 'enabled' ]]; then
			systemctl disable ${serv_por[$_opcion]} &>/dev/null
		fi
		systemctl stop ${serv_por[$_opcion]} &>/dev/null
	fi

	del 1
	print_center -verd 'SERVICIO BADVPN PARADO'
	enter
}

del_port(){
	#_services=$(systemctl list-unit-files|grep badvpn|awk '{print $1}')
	_services=$(ls /etc/systemd/system |grep 'badvpn.')
	while [[ $(echo "$_services"|wc -l) -gt 1 ]]; do
		title -ama 'QUITAR PUERTOS BADVPN'
		all_service
		back
		_opcion=$(selection_fun $n)
		[[ $_opcion = 0 ]] && break
		viw_port=$(echo "${serv_por[$_opcion]}"|awk -F '.' '{print $2}')
		print_center -ama "REMOVIENDO BADVPN $viw_port"
		if [[ $(systemctl is-enabled ${serv_por[$_opcion]}) = 'enabled' ]]; then
			systemctl disable ${serv_por[$_opcion]} &>/dev/null
		fi
		systemctl stop ${serv_por[$_opcion]} &>/dev/null
		rm -rf /etc/systemd/system/${serv_por[$_opcion]}
		_services=$(ls /etc/systemd/system |grep 'badvpn.')
		del 1
		print_center -verd "BADVPN $viw_port REMOVIENDO"
		enter
	done
}

add_port(){
	title 'AGREGAR NUEVOS PUERTOS'
	IN_PORT
	msg -bar
	if [[ $(service_badvpn $PORT) = 'active' ]]; then
        print_center -verd 'PUERTO BADVPN AGREGADO'
    else
        print_center -verm2 'FALLA AL AGREGAR PUERTO BADVPN'
    fi
    unset PORT
    enter
}

menu_badvpn(){
	title -ama 'BADVPN-UDPGW BY @Rufu99'
	#_services=$(systemctl --all|grep badvpn|awk '{print $1}'|wc -l)
	_services=$(ls /etc/systemd/system |grep 'badvpn.'|wc -l)

	if [[ $(type -p badvpn-udpgw) ]]; then
		unset op1 op2 op3
		echo " $(msg -verd '[1]') $(msg -verm2 '>') $(msg -verm2 'DESINSTALAR BADVPN-UDPGW')"
		msg -bar
		print_center -ama 'OPCIONES DE INICIO'
		msg -bar3
		echo " $(msg -verd '[2]') $(msg -verm2 '>') $(msg -verd 'INICIAR/REINICIAR BADVPN-UDPGW')"
		_num=3
		if [[ $(systemctl list-units --all --state=active|grep badvpn|awk '{print $1}'|wc -l) -gt 0 ]]; then
			echo " $(msg -verd "[$_num]") $(msg -verm2 '>') $(msg -ama 'PARAR PUERTOS BADVPN-UDPGW')"
			op1=$_num; let _num++
		fi
		msg -bar
		print_center -ama 'OPCIONES DE PUERTOS'
		msg -bar3
		echo " $(msg -verd "[$_num]") $(msg -verm2 '>') $(msg -azu 'AGREGAR PUERTO BADVPN-UDPGW')"
		op2=$_num
		if [[ $_services -gt 1 ]]; then
			let _num++
			echo " $(msg -verd "[$_num]") $(msg -verm2 '>') $(msg -azu 'QUITAR UN PUERTO BADVPN-UDPGW')"
			op3=$_num
		fi
	else
		echo " $(msg -verd '[1]') $(msg -verm2 '>') $(msg -verd 'INSTALAR BADVPN-UDPGW')"
		_num=1
	fi
	back
	opcion=$(selection_fun $_num)
	case $opcion in
		1)install;;
		2)restart;;
		"$op1")stop;;
		"$op2")add_port;;
		"$op3")del_port;;
		0)return 1;;
	esac
}

while [[  $? -eq 0 ]]; do
  menu_badvpn
done

