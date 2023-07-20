#!/bin/bash

ip=$(fun_ip nat)
ip_vps=$(fun_ip)

phpdir="$ADM_src/checkUserOnline"
checkUserdir="$phpdir/checkUser"
phpfile="$phpdir/index.php"

dependencias(){
	soft="php"
	#soft="nginx php8.1 php8.1-fpm"
	for install in $soft; do
		leng="${#install}"
		puntos=$(( 21 - $leng))
		pts="."
		for (( a = 0; a < $puntos; a++ )); do
			pts+="."
		done
		msg -nazu "      instalando $install $(msg -ama "$pts")"
		if apt install $install -y &>/dev/null ; then
			msg -verd "INSTALL"
		else
			msg -verm2 "FAIL"
			sleep 2
			del 1
			print_center -ama "aplicando fix a $install"
			dpkg --configure -a &>/dev/null
			sleep 2
			del 1
			msg -nazu "      instalando $install $(msg -ama "$pts")"
			if apt install $install -y &>/dev/null ; then
				msg -verd "INSTALL"
			else
				msg -verm2 "FAIL"
				install_chk=$install
				break
			fi
		fi
	done
}

start(){
	if [[ -d $phpdir ]]; then
		systemctl stop checkuser &>/dev/null
		systemctl disable checkuser &>/dev/null
		rm -rf /etc/systemd/system/checkuser.service
		rm -rf $phpdir
		print_center -verd 'DESINSTALACION COMPLETA'
		enter
		return
	fi
	title 'SELECCIONA UN PERTO'
	unset chekuser
	unset opcion
	while [[ -z "${chekuser}" ]]; do
		dport=$(shuf -i 0-65535 -n 1)
		in_opcion -nama "Ingresa un puerto [def = $dport]"
		chekuser=$opcion
		[[ -z $chekuser ]] && chekuser=$dport
		del 1
		if [[ ! $chekuser =~ $numero ]]; then
			print_center -verm2 'ingresa solo numeros!'
			sleep 2
			del 1
			unset chekuser
		elif [[ $chekuser -lt 10 ]]; then
			print_center -verm2 'ingresa un numero mayor a 10'
			sleep 2
			del 1
			unset chekuser
		elif [[ $chekuser -gt 65535 ]]; then
			print_center -verm2 'ingresa un numero menor a 65535'
			sleep 2
			del 1
			unset chekuser
		elif [[ -z $(mportas|grep "$PORT") ]]; then
			print_center -verm2 "Puerto en uso!"
			sleep 2
			del 1
			unset chekuser
		fi
	done
	echo " $(msg -ama "PUERTO") $(msg -verd "$chekuser")"
	msg -bar
	print_center 'SELECCIONA UN FORMATO DE FECHA'
	msg -bar
	menu_func 'DD/MM/YYYY (DIAS/MES/AÑO)' 'YYYY/MM/DD (AÑO/MES/DIAS)'
	msg -bar
	date=$(selection_fun 2)
	case $date in
		1)fecha[0]="dmY"; fecha[1]="DD/MM/YYYY";;
		2)fecha[0]="Ymd"; fecha[1]="YYYY/MM/DD";;
		0)return;;
	esac
	del 6
	echo " $(msg -ama "FORMATO CHEKUSER") $(msg -verd "${fecha[1]}")"
	msg -bar
	print_center 'SELECCIONA UN FORMATO DE USUARIOS ONLINE'
	msg -bar
	menu_func 'DIRECTO (mas usado)' 'JSON'
	msg -bar
	date=$(selection_fun 2)
	case $date in
		1)ONLINE="DIRECTO";;
		2)ONLINE="JSON";;
		0)return;;
	esac
	del 6
	echo " $(msg -ama "FORMATO USER ONLINES") $(msg -verd "$ONLINE")"
	enter
	del 2
	print_center -ama 'Instalando paquetes necesarios'
	echo
	dependencias
	if [[ ! $install_chk = "" ]]; then
		msg -bar
		print_center -verm2 "falla al instalar $install_chk\nno se puede continual con la instalacion"
		enter
		return
	fi
	echo
	print_center -ama 'Removiendo paquetes no necesarios'
	apt remove apache2 -y &>/dev/null
	apt purge apache2 -y &>/dev/null
	apt autoremove -y &>/dev/null
	rm -rf $phpdir
	mkdir -p $checkUserdir
	echo "<?php
	/*ini_set('display_errors', '1');
	ini_set('display_startup_errors', 1);
	error_reporting(E_ALL);*/

	\$datos = file_get_contents(\"php://input\");
	\$update = json_decode(\$datos,true);
	\$FORMATO = \"${fecha[0]}\";
	\$ONLINE = \"$ONLINE\";
	if (isset(\$update)) {	
		\$usuario = \$update['user'];
		\$cmd = \"sudo chage -l \".\$usuario.\"|grep 'Account expires'\";
		\$datos = shell_exec(\$cmd);
		if (isset(\$datos)) {
			\$fecha = explode(': ',\$datos);
			\$date=date_create(\$fecha[1]);
			echo date_format(\$date,\$FORMATO = \"dmY\");
		}
	} else {
		\$ssh = shell_exec('ps -x | grep sshd | grep -v root | grep priv | wc -l');
		if (file_exists('/etc/openvpn/openvpn-status.log')) {
			\$openvpn = shell_exec('grep -c \"10.8.0\" /etc/openvpn/openvpn-status.log');
		} else {
			\$openvpn = \"0\";
		}
		if (file_exists('/etc/default/dropbear')) {
			\$drp = shell_exec('ps aux | grep dropbear | grep -v grep | wc -l');
			\$dropbear=\$drp - 1;
		} else {
			\$dropbear = \"0\";
		}

		\$total = \$ssh + \$openvpn + \$dropbear;

		switch (\$ONLINE) {
			case 'DIRECTO':
				echo \$total;
				break;
			case 'JSON':
				\$datos = array(\"onlines\"=>\$total,\"limite\"=>\"2500\");
				\$json = json_encode(\$datos,true);
				echo \$json;
				break;
			default:
				echo \$total;
				break;
		}
	}	
	exit();
?>" > $phpfile
	ln -s $phpfile $checkUserdir
	chmod -R 775 $phpdir
	echo -e "[Unit]
Description=chekUser y UserOnline Service by @Rufu99
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=$(type -p php) -S $ip:$chekuser -t $phpdir/
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/checkuser.service
	systemctl start checkuser &>/dev/null
	msg -bar
	if [[ $(systemctl is-active checkuser) ]]; then
		systemctl enable checkuser &>/dev/null
		print_center -verd 'Instalacion completa'
	else
		systemctl stop checkuser &>/dev/null
		rm -rf $phpdir
		print_center -verm2 'Falla de instalacion'
	fi	
    enter
}

mod_port(){
	title 'SELECCIONA UN PERTO'
	unset chekuser
	unset opcion
    while [[ -z "$chekuser" ]]; do
    	dport=$(shuf -i 0-65535 -n 1)
    	in_opcion -nama "Ingresa un puerto [def = $dport]"
    	chekuser=$opcion
    	[[ -z "$chekuser" ]] && chekuser=$dport
    	del 2
    	if [[ ! $chekuser =~ $numero ]]; then
    		print_center -verm2 'ingresa solo numeros!'
    		sleep 2
    		del 1
    		unset chekuser
    	elif [[ $chekuser -lt 10 ]]; then
    		print_center -verm2 'ingresa un numero mayor a 10'
    		sleep 2
    		del 1
    		unset chekuser
    	elif [[ $chekuser -gt 65535 ]]; then
    		print_center -verm2 'ingresa un numero menor a 65535'
    		sleep 2
    		del 1
    		unset chekuser
    	elif [[ ! $(mportas|grep -w "$PORT") = "" ]]; then
			print_center -verm2 "Puerto en uso!"
			sleep 2
			del 1
    		unset chekuser
    	fi
    done
    echo " $(msg -ama "PUERTO") $(msg -verd "$chekuser")"
    msg -bar

    #stdctl=$(systemctl is-active checkuser)

    systemctl stop checkuser &>/dev/null
    if [[ $? = 0 ]]; then
    	systemctl disable checkuser &>/dev/null
    	tmp=$(cat $stl)
    	sed -i "s/$port_stl/$chekuser/g" $stl
    	systemctl start checkuser &>/dev/null
    	if [[ $? = 0 ]]; then
    		systemctl enable checkuser &>/dev/null
    		print_center -verd 'PUERTO MODIFICADO CON EXITO'
    	else
    		echo "$tmp" > $stl
    		print_center -verm2 'falla al reiniciar el servicio\nNo se modifico el puerto!'
    	fi
    else
    	print_center -ama 'falla al detener el servicio\nNo se modifico el puerto!'
    fi
    enter
    return
}

mod_fdate(){
	title 'SELECCIONA UN FORMATO DE FECHA'
	menu_func 'DD/MM/YYYY' 'YYYY/MM/DD'
    msg -bar
    date=$(selection_fun 2)
    case $date in
    	1)fecha[0]="dmY"; fecha[1]="DD/MM/YYYY";;
    	2)fecha[0]="Ymd"; fecha[1]="YYYY/MM/DD";;
    	0)return;;
    esac
    del 3
    echo " $(msg -ama "FORMATO DE FECHA") $(msg -verd "${fecha[1]}")"
    msg -bar
    _oldf=$(grep -E 'FORMATO' $phpfile|head -1|cut -d '"' -f2)
    sed -i "8 s/$_oldf/${fecha[0]}/g" $phpfile &>/dev/null
    print_center -verd 'FORMATO DE FECHA MODIFICADO'
    enter
    return
}

mod_udate(){
	title 'SELECCIONA UN FORMATO DE USERONLINE'
	menu_func 'DIRECTO' 'JSON'
	msg -bar
	date=$(selection_fun 2)
	case $date in
		1)TIPO="DIRECTO";;
		2)TIPO="JSON";;
		0)return;;
	esac
	del 3
	echo " $(msg -ama "FORMATO USERONLINE") $(msg -verd "$TIPO")"
	msg -bar
	_oldt=$(grep -E 'ONLINE' $phpfile|head -1|cut -d '"' -f2)
	sed -i "9 s/$_oldt/$TIPO/g" $phpfile &>/dev/null
	print_center -verd 'FORMATO DE USERONLINE MODIFICADO'
	enter
	return
}

STOP(){
	estado=$(systemctl is-active checkuser)
	case $estado in
		active)	systemctl stop checkuser &>/dev/null
			systemctl disable checkuser &>/dev/null
			if [[ $? = 0 ]]; then
				print_center -ama 'Sevicio checkuser detenido'
			else
				print_center -verm2 'Falla al detener servicio'
			fi;;
	      inactive)	systemctl start checkuser &>/dev/null
			systemctl enable checkuser &>/dev/nu
			if [[ $? = 0 ]]; then
				print_center -ama 'Servicio checkuser iniciado'
			else
				print_center -verm2 'falla al iniciar servicio'
			fi;;
	esac
	enter
	return
}

menu_chekuser(){
	stl='/etc/systemd/system/checkuser.service'
	port_ck=$(ps x|grep -v 'grep'|grep 'php -S'|awk -F ' ' '{print $7}'|cut -d ':' -f2)
	title 'VERIFICACION DE USUARIOS ONLINE'
	num=1
	if [[ -e $stl ]]; then
		port_stl=$(cat $stl|grep php|awk -F ' ' '{print $3}'|cut -d ':' -f2)
		formato_CK=$(cat "$phpfile"|grep 'FORMATO'|head -1|cut -d '"' -f2)
		case $formato_CK in
	    		'Ymd')fecha_data="YYYY/MM/DD";;
	    		'dmY')fecha_data="DD/MM/YYYY";;
	    	esac
		formato_US=$(cat "$phpfile"|grep 'ONLINE'|head -1|cut -d '"' -f2)
		if [[ ! -z $port_ck ]]; then
			url="$ip_vps:$port_ck"
			print_center -ama 'Podes usar estos formatos para\nChekUser y UserOnline'
			echo
			print_center -ama "URL: http://$url"
			print_center -ama "URL: http://$url/checkUser"
			echo
			msg -bar
		fi
		echo " $(msg -verd '[1]') $(msg -verm2 '>') $(msg -verm2 'DESINSTALAR') $(msg -azu 'CHEKUSER Y USERONLINE')"
		echo " $(msg -verd '[2]') $(msg -verm2 '>') $(msg -ama 'INICIAR/DETENER') $(msg -azu 'CHEKUSER Y USERONLINE')"
		msg -bar3
		echo " $(msg -verd '[3]') $(msg -verm2 '>') $(msg -azu 'MODIFICAR PUERTO')               $(msg -verd "$port_stl")"
		echo " $(msg -verd '[4]') $(msg -verm2 '>') $(msg -azu 'MODIFICAR FORMATO CHEKUSER')     $(msg -verd "$fecha_data")"
		echo " $(msg -verd '[5]') $(msg -verm2 '>') $(msg -azu 'MODIFICAR FORMATO USERONLINE')   $(msg -verd "$formato_US")"
		num=5
	else
	        print_center -verm2 'ADVERTENCIA!!!\nesto puede generar consumo de ram/cpu\nen metodos de coneccion inestables\nse recomienda no usar chekuser en esos casos'
	        msg -bar
		echo " $(msg -verd '[1]') $(msg -verm2 '>') $(msg -verd 'ACTIVAR') $(msg -azu 'CHEKUSER Y USER ONLINE')"
	fi
	back
	opcion=$(selection_fun $num)
	case $opcion in
		1)start;;
		2)STOP;;
		3)mod_port;;
		4)mod_fdate;;
		5)mod_udate;;
		0)return 1;;
	esac
}

while [[  $? -eq 0 ]]; do
  menu_chekuser
done