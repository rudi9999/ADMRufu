#!/bin/bash
_squid=$(apt-cache search squid|grep -v "squid*\-"|grep -v "\-squid*"|grep -w "squid* "|awk '{print $1}')

lista(){
	n=0
    while read line; do
    	[[ $line = '' ]] && continue
    	let n++
    	echo -e " $(msg -verd "$n)") $(msg -verm2 ">") $(msg -teal "$line")"
    	pay[$n]=$line
    done <<< $(cat $1)

    [[ $n = 0 ]] && print_center -ama 'NO SE ENCONTRARON ELEMENTOS EN LA LISTA'
}

lsexpre(){
    n=0
    while read line; do
    	let n++
    	echo -e " $(msg -verd "$n)") $(msg -verm2 ">") $(msg -teal "$line")"
    	pay[$n]=$line
    done <<< $(cat $payload2)
}

install(){

	if [[ $(type -p squid) ]]; then
		title 'DESINSTALAR SQUID'
		read -rp " $(msg -ama "ESTA SEGURO? [S/N]:") " -e -i N UNINSTALL
		[[ $UNINSTALL != @(S|s) ]] && return
		del 1
		print_center -ama 'Desintalando Squid...\naguarde un momento, puede llevar algo de tiempo!!!'
		service squid stop > /dev/null 2>&1
		apt-get remove $_squid -y >/dev/null 2>&1
		apt-get purge $_squid -y >/dev/null 2>&1
		apt-get autoremove -y >/dev/null 2>&1
		apt-get autoclean -y >/dev/null 2>&1
		rm -rf /etc/squid
		rm -rf /etc/dominio-denie
		rm -rf /etc/exprecion-denie
		del 2
		print_center -ama 'Squid, desinstalado con exito!!!'
		enter
		return
	fi

  title 'INSTALADOR SQUID ADMRufu'

  while [[ -z $PORT ]]; do
  	print_center -ama 'Podes ingresar mas de un puerto a la vez!!'
  	print_center -ama 'Solo [enter] para canselar!!!'
  	in_opcion_down 'Seleccione su puerto'
  	[[ $opcion = '' ]] && return
  	del 4

  	TTOTAL=($opcion)
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
  		unset PORT
  		continue
  	}
  done
  msg -bar
  read -rp " $(msg -ama " TODO LISTO, CONTINUAR CON LA INSTALACION? [S/N]:") " -e -i S CONTINUAR
  [[ $CONTINUAR != @(S|s) ]] && unset PORT && return
  del 1
  apt-get install $_squid -y
  msg -bar
  print_center -ama 'instalacion de paquetes squid completa!!!\nverifique el log en busca de posibles fallos!!!'
  msg -bar
  read -rp " $(msg -ama " CONTINUAR CON LA CONFIGURACION? [S/N]:") " -e -i S _CONTINUAR
  [[ $_CONTINUAR != @(S|s) ]] && unset PORT && return
  title 'CONFIGURANDO SQUID'
  print_center -ama 'Aguarde un momento...'

  cat <<-EOF > /etc/dominio-denie
.ejemplo.com/  
EOF

  cat <<-EOF > /etc/exprecion-denie
torrent  
EOF

  if [[ -d /etc/squid ]]; then
    var_squid="/etc/squid/squid.conf"
    mipatch="/etc/squid"
  elif [[ -d /etc/squid3 ]]; then
    var_squid="/etc/squid3/squid.conf"
    mipatch="/etc/squid3"
  fi

  ip=$(fun_ip)

  cat <<-EOF > $var_squid
#Configuracion SquiD
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
acl SSH dst $ip-$ip/255.255.255.255
acl exprecion-denie url_regex '/etc/exprecion-denie'
acl dominio-denie dstdomain '/etc/dominio-denie'
http_access deny exprecion-denie
http_access deny dominio-denie
http_access allow SSH
http_access allow manager localhost
http_access deny manager
http_access allow localhost

#puertos
EOF

	for pts in $(echo -e $PORT); do
		echo -e "http_port $pts" >> $var_squid
		[[ $(type -p ufw) ]] && ufw allow $pts/tcp &>/dev/null 2>&1
	done

	cat <<-EOF >> $var_squid
http_access allow all
coredump_dir /var/spool/squid
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320

#Nombre Squid
visible_hostname ADMRufu
EOF

	service ssh restart > /dev/null 2>&1
	/etc/init.d/squid start > /dev/null 2>&1
	service squid restart > /dev/null 2>&1

	del 1
	print_center -verd "INSTALACION Y CONFIGURACION SQUID FINALIZADA!!!"
	enter
}

del_host(){
	while :
	do
		title 'LISTA DE HOST BLOQUEADOS EN EL SQUID'
		lista $payload
		back
		d_host=$(selection_fun $n)
		if [[ $d_host = 0 ]]; then
			if [[ $ext = 1 ]]; then
				print_center -ama 'REINICIANDO SQUID'
				service ssh restart &>/dev/null
				/etc/init.d/squid reload &>/dev/null
				service squid restart &>/dev/null
				del 1
				unset ext
				print_center -ama "HOST REMOVIDO DE LA LISTA!!!"
				enter
			fi
			break
		fi
		host="${pay[$d_host]}"
		sed -i "$d_host d" $payload
		#sed -i "/$host/d" $payload
		ext=1
	done
}

add_host(){
	while :
	do
		title 'LISTA DE HOST BLOQUEADOS EN EL SQUID'
		lista $payload
		back

		while [[ $_HOST != \.* ]]; do
			read -rp " $(msg -ama " DIGITA UN NUEVO HOST:") " -e -i . _HOST
			if [[ $_HOST = 0 ]]; then
				if [[ $ext = 1 ]]; then
					del 1
					print_center -ama 'REINICIANDO SQUID'
					service ssh restart &>/dev/null
					/etc/init.d/squid reload &>/dev/null
					service squid restart &>/dev/null
					del 1
					unset _HOST
					unset ext
					print_center -ama "HOST AGREGADO A LA LISTA!!!"
					enter
				fi
				return
			elif [[ ! $(cat "$payload"|grep -w "$_HOST/") = "" ]]; then
				del 1
				print_center -verm2 "EL NOMBRE DE HOST YA EXISTE!!!"
				sleep 2
				del 1
				unset _HOST
			elif [[ $_HOST = \.* ]]; then
				break
			else
				del 1
				print_center -verm2 "EL NOMBRE DE HOST DEVE INICIAR CON .punto.com"
				sleep 2
				del 1
				unset _HOST
			fi
		done
		_HOST="$_HOST/"
		echo "$_HOST" >> $payload && sed -i '/^$/d' $payload
		unset _HOST
		ext=1
	done
}

add_expre(){
	while :
	do
		title 'LISTA DE EXPRECIONES BLOQUEADAS EN EL SQUID'
		lista $payload2
		back

		while [[ -z $_HOST ]]; do
			read -rp " $(msg -ama " DIGITA UNA PALABRE:") " -e -i torrent _HOST
			if [[ $_HOST = 0 ]]; then
				if [[ $ext = 1 ]]; then
					del 1
					print_center -ama 'REINICIANDO SQUID'
					service ssh restart &>/dev/null
					/etc/init.d/squid reload &>/dev/null
					service squid restart &>/dev/null
					del 1
					unset _HOST
					unset ext
					print_center -ama "EXPRECION AGREGADA A LA LISTA!!!"
					enter
				fi
				return
			elif [[ -z $_HOST ]]; then
				del 1
				print_center -ama 'INGRESA UNA PALABRA!!!'
				sleep 2
				del 1
			elif [[ ! $(cat "$payload2"|grep -w "$_HOST") = "" ]]; then
				del 1
				print_center -verm2 "LA EXPRECION YA EXISTE!!!"
				sleep 2
				del 1
				unset _HOST
			fi
		done

		echo "$_HOST" >> $payload2 && sed -i '/^$/d' $payload2
		unset _HOST
		ext=1
	done
}

del_expre(){
	while :
	do
		title 'LISTA DE EXPRECIONES BLOQUEADAS EN SQUID'
		lista $payload2
		back
		d_host=$(selection_fun $n)
		if [[ $d_host = 0 ]]; then
			if [[ $ext = 1 ]]; then
				print_center -ama 'REINICIANDO SQUID'
				service ssh restart &>/dev/null
				/etc/init.d/squid reload &>/dev/null
				service squid restart &>/dev/null
				del 1
				unset ext
				print_center -ama "EXPRECION REMOVIDO DE LA LISTA!!!"
				enter
			fi
			break
		fi
		host="${pay[$d_host]}"
		sed -i "$d_host d" $payload2
		#sed -i "/$host/d" $payload
		ext=1
	done
}

del_expre2(){
  unset opcion
  clear
  msg -bar
  print_center -ama "$(fun_trans "Exprecion regular Dentro del Squid")"
  msg -bar
  lsexpre
  back
  while [[ -z $opcion ]]; do
      msg -ne " Eliminar la palabra numero: " && read opcion
      if [[ ! $opcion =~ $numero ]]; then
        tput cuu1 && tput dl1
        print_center -verm2 "ingresa solo numeros"
        sleep 2s
        tput cuu1 && tput dl1
        unset opcion
      elif [[ $opcion -gt ${#pay[@]} ]]; then
        tput cuu1 && tput dl1
        print_center -ama "solo numeros entre 0 y ${#pay[@]}"
        sleep 2s
        tput cuu1 && tput dl1
        unset opcion
      fi
  done
  [[ $opcion = 0 ]] && return 1
  host="${pay[$opcion]}"
  [[ -z $host ]] && return 1
  [[ `grep -c "^$host" $payload2` -ne 1 ]] && print_center -ama "$(fun_trans  "Palabra No Encontrado")" && return 1
  grep -v "^$host" $payload2 > /tmp/a && mv -f /tmp/a $payload2
  clear
  msg -bar
  print_center -ama "$(fun_trans "Palabra Removida Con Exito")"
  msg -bar
  lsexpre
  msg -bar
  print_center -ama "Reiniciando servicios"
  if [[ ! -f "/etc/init.d/squid" ]]; then
      service squid3 reload &>/dev/null
      service squid3 restart &>/dev/null
  else
      /etc/init.d/squid reload &>/dev/null
      service squid restart &>/dev/null
  fi
  tput cuu1 && tput dl1
  tput cuu1 && tput dl1
  enter
  return 1
}

add_port(){
	if [[ -e /etc/squid/squid.conf ]]; then
    	local CONF="/etc/squid/squid.conf"
  	elif [[ -e /etc/squid3/squid.conf ]]; then
    	local CONF="/etc/squid3/squid.conf"
  	fi
  	local miport=$(cat ${CONF}|grep -w 'http_port'|awk -F ' ' '{print $2}'|tr '\n' ' ')
  	local line="$(cat ${CONF}|sed -n '/http_port/='|head -1)"
  	local NEWCONF="$(cat ${CONF}|sed "$line c ADMR_port"|sed '/http_port/d')"
  	title -ama "AGREGAR UN PUERTOS SQUID"
  	while [[ -z $PORT ]]; do
  	print_center -ama 'Podes ingresar mas de un puerto a la vez!!'
  	print_center -ama 'Solo [enter] para canselar!!!'
  	in_opcion_down 'Seleccione su puerto'
  	[[ $opcion = '' ]] && return
  	del 4
  	TTOTAL=($opcion)
  	for((i=0; i<${#TTOTAL[@]}; i++)); do
  		[[ $(mportas|grep -v squid|grep -v '>'|grep "${TTOTAL[$i]}") = "" ]] && {
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
  		unset PORT
  		continue
  	}
	done
  	PORT="$miport $PORT"
  	rm ${CONF}
  	while read varline; do
  		if [[ ! -z "$(echo "$varline"|grep 'ADMR_port')" ]]; then
      		for i in `echo $PORT`; do
        	echo -e "http_port ${i}" >> ${CONF}
        	ufw allow $i/tcp &>/dev/null 2>&1
      		done
      		continue
    	fi
    	echo -e "${varline}" >> ${CONF}
  	done <<< "${NEWCONF}"
  	msg -bar
  	print_center -ama "AGUARDE, REINICIANDO SQUID"

  	service ssh restart > /dev/null 2>&1
    /etc/init.d/squid start > /dev/null 2>&1
    service squid restart > /dev/null 2>&1
    del 1
  	print_center -verd "PUERTOS AGREGADOS"
  	enter
}

del_port(){
	squidport=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN"|grep -E 'squid|squid3')
	if [[ $(echo "$squidport"|wc -l) -lt '2' ]];then
		title -ama 'SOLO HAY UN PUERTO!!!'
		read -rp " $(msg -ama "DESEA DETENER SQUID? [S/N]:") " -e -i N STOP
		if [[ $STOP = @(S|s) ]]; then
			del 1
			print_center -ama "AGUARDE, DETENIEDO SQUID!!!"
			service ssh restart > /dev/null 2>&1
			/etc/init.d/squid stop > /dev/null 2>&1
			service squid stop > /dev/null 2>&1
			del 1
			print_center -verd 'SQUID DETENIDO!!!'
			enter
		fi
		return
	fi
	if [[ -e /etc/squid/squid.conf ]]; then
    	local CONF="/etc/squid/squid.conf"
  	elif [[ -e /etc/squid3/squid.conf ]]; then
    	local CONF="/etc/squid3/squid.conf"
  	fi
	title -ama "QUITAR UN PUERTO SQUID"
    n=0
    while read i; do
    	let n++
        port=$(echo $i|awk -F ' ' '{print $9}'|cut -d ':' -f2)
        echo -e " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -azu "$port")"
        drop[$n]=$port 
    done <<< $(echo "$squidport")
    back
    opc=$(selection_fun $n)
    [[ $opc = 0 ]] && return
    sed -i "/http_port ${drop[$opc]}/d" $CONF
  	print_center -azu "AGUARDE REINICIANDO SQUID"
  	service ssh restart > /dev/null 2>&1
    /etc/init.d/squid start > /dev/null 2>&1
    service squid restart > /dev/null 2>&1
    del 1
    print_center -verd "SQUID REINICIANDO!!!"
    print_center -ama "PUERTO ${drop[$opc]} REMOVIDO"
  	enter	
}

restart(){
	print_center -ama "REINICIANDO SQUID..."
	service ssh restart > /dev/null 2>&1
    /etc/init.d/squid restart > /dev/null 2>&1
    service squid restart > /dev/null 2>&1
    del 1
    print_center -verd 'SQUID REINICIADO!!!'
    enter
}

stop_squid(){
	print_center -ama "DETENIEDO SQUID..."
	service ssh restart > /dev/null 2>&1
    /etc/init.d/squid stop > /dev/null 2>&1
    service squid stop > /dev/null 2>&1
    del 1
    print_center -verd 'SQUID DETENIDO!!!'
    enter
}

menu_squid(){
  payload="/etc/dominio-denie"
  payload2="/etc/exprecion-denie"
  title -ama 'CONFIGURACION DE SQUID'
  if [[ $(type -p squid) ]]; then
  	pid=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN" | grep -E 'squid'|wc -l)
  	[[ $pid = 0 ]] && pid='\e[1m\e[31m[OFF]' || pid='\e[1m\e[32m[ON]'
  	echo " $(msg -verd '[1]') $(msg -verm2 '>') $(msg -verm2 'DESINSTALAR SQUID')"
  	echo -e " $(msg -verd '[2]') $(msg -verm2 '>') $(msg -ama 'INICIAR/REINICIAR SQUID') $pid"
  	echo " $(msg -verd '[3]') $(msg -verm2 '>') $(msg -azu 'DETENER SQUID')"
  	msg -bar3
  	echo " $(msg -verd '[4]') $(msg -verm2 '>') $(msg -azu 'AGREGAR PUERTO')"
  	echo " $(msg -verd '[5]') $(msg -verm2 '>') $(msg -azu 'QUITAR PUERTO')"
  	msg -bar
  	print_center -ama 'FIREWALL SQUID'
  	msg -bar3
  	echo " $(msg -verd '[6]') $(msg -verm2 '>') $(msg -azu 'BLOQUEAR HOST')"
  	echo " $(msg -verd '[7]') $(msg -verm2 '>') $(msg -azu 'DESBLOQUEAR HOST')"
  	msg -bar3
  	echo " $(msg -verd '[8]') $(msg -verm2 '>') $(msg -azu 'BLOQUEAR EXPRECIONES REGULARES')"
  	echo " $(msg -verd '[9]') $(msg -verm2 '>') $(msg -azu 'DESBLOQUEAR EXPRECIONES REGULARES')"
  	num=9
  else
  	print_center -ama 'por razones propias del funcionamiento de squid\ncada reinicio del servicio puede presentar demoras.'
  	msg -bar
  	echo " $(msg -verd '[1]') $(msg -verm2 '>') $(msg -verd 'INSTALAR SQUID')"
  	num=1
  fi
  back
  opcion=$(selection_fun $num)

  case $opcion in
  	1)install;;
  	2)restart;;
  	3)stop_squid;;
  	4)add_port;;
  	5)del_port;;
  	6)add_host;;
    7)del_host;;
    8)add_expre;;
    9)del_expre;;
    0)return 1;;
  esac
}

while [[  $? -eq 0 ]]; do
  menu_squid
done