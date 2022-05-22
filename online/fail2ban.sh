#!/bin/bash

install_fail2(){
	title "INSTALADOR FAIL2BAN BY @Rufu99"
	echo -ne "        $(msg -azu "Instalando fail2ban")$(msg -ama "............")"
	if apt install fail2ban -y &>/dev/null ; then
		msg -verd "INSTALL"
		echo '[sshd]
enabled = true

# NOTA: no edite  o quete las lineas comentadas!

# "bantime" es el tiempo de baneo.
#[s = segundos, m = minutos, h = horas].
bantime = 5m

# "findtime" tiempo en el que se aplica el numero de intentos de coneccion.
# [s = segundos, m = minutos, h = horas]
findtime = 1m

# "maxretry" numero de intentos de coneccion.
maxretry = 3' > /etc/fail2ban/jail.d/defaults-debian.conf
		service fail2ban restart &>/dev/null
	else
		msg -verm2 "FAIL"
	fi
	enter
}

uninstall_fail2(){
	title "DESINSTALADOR FAIL2BAN"
	echo -ne "        $(msg -azu "Desinstalando fail2ban")$(msg -ama "............")"
	if apt remove fail2ban -y &>/dev/null ; then
		apt purge fail2ban -y &>/dev/null
		msg -verd "[OK]"
	else
		msg -verm2 "[FAIL]"
	fi
	enter
}

bantime_f(){
	in_opcion -nama "Ingresa el timepo en (1h, 1m, 1s)"
	tput cuu1 && tput dl1
	if [[ $opcion = @(0|"") ]]; then
		return
	elif [[ ${#opcion} -gt 3 ]]; then
		print_center -verm2 "solo ingresa max 3 caracteres!"
		sleep 2
		return
	elif [[ ${#opcion} -eq 1 ]]; then
		print_center -verm2 "ingresa al menos 2 caracteres!"
		sleep 2
		return
	fi
	c=${#opcion}
	if [[ $c -eq 2 ]]; then
		if [[ ${opcion:1} != @(h|m|s) ]]; then
			print_center -verm2 "formato incorrecto!"
			sleep 2
			return
		fi
		if [[ ! ${opcion:0:1} =~ $numero ]]; then
			print_center -verm2 "formato incorrecto!"
			sleep 2
			return
		fi
	elif [[ $c -eq 3 ]]; then
		if [[ ${opcion:2} != @(h|m|s) ]]; then
			print_center -verm2 "formato incorrecto!"
			sleep 2
			return
		fi
		if [[ ! ${opcion:0:2} =~ $numero ]]; then
			print_center -verm2 "formato incorrecto!"
			sleep 2
			return
		fi
		if [[ ${opcion:0:1} -eq 0 ]]; then
			print_center -verm2 "formato incorrecto!"
			sleep 2
			return
		fi
		if [[ ${opcion:0:2} -gt 23 ]]; then
			if [[ ${opcion:2} = 'h' ]]; then
				print_center -verm2 "formato incorrecto!"
				sleep 2
				return
			fi	
		fi
	fi
	bantime=$(grep 'bantime =' /etc/fail2ban/jail.d/defaults-debian.conf|cut -d ' ' -f3)
	sed -i "8 s/$bantime/$opcion/" /etc/fail2ban/jail.d/defaults-debian.conf
	service fail2ban restart &>/dev/null
	print_center -verd "timepo de banneo modificado"
	enter
}

findtime_f(){
	in_opcion -nama "Ingresa el periodo en (1h, 1m, 1s)"
	tput cuu1 && tput dl1
	if [[ $opcion = @(0|"") ]]; then
		return
	elif [[ ${#opcion} -gt 3 ]]; then
		print_center -verm2 "solo ingresa max 3 caracteres!"
		sleep 2
		return
	elif [[ ${#opcion} -eq 1 ]]; then
		print_center -verm2 "ingresa al menos 2 caracteres!"
		sleep 2
		return
	fi
	c=${#opcion}
	if [[ $c -eq 2 ]]; then
		if [[ ${opcion:1} != @(h|m|s) ]]; then
			print_center -verm2 "formato incorrecto!"
			sleep 2
			return
		fi
		if [[ ! ${opcion:0:1} =~ $numero ]]; then
			print_center -verm2 "formato incorrecto!"
			sleep 2
			return
		fi
	elif [[ $c -eq 3 ]]; then
		if [[ ${opcion:2} != @(h|m|s) ]]; then
			print_center -verm2 "formato incorrecto!"
			sleep 2
			return
		fi
		if [[ ! ${opcion:0:2} =~ $numero ]]; then
			print_center -verm2 "formato incorrecto!"
			sleep 2
			return
		fi
		if [[ ${opcion:0:1} -eq 0 ]]; then
			print_center -verm2 "formato incorrecto!"
			sleep 2
			return
		fi
		if [[ ${opcion:0:2} -gt 23 ]]; then
			if [[ ${opcion:2} = 'h' ]]; then
				print_center -verm2 "formato incorrecto!"
				sleep 2
				return
			fi	
		fi
	fi
	findtime=$(grep 'findtime =' /etc/fail2ban/jail.d/defaults-debian.conf|cut -d ' ' -f3)
	sed -i "12 s/$findtime/$opcion/" /etc/fail2ban/jail.d/defaults-debian.conf
	service fail2ban restart &>/dev/null
	print_center -verd "periodo de banneo modificado"
	enter
}

maxretry_f(){
	in_opcion -nama "Ingresa el num de intentos [min-2/max-999]"
	tput cuu1 && tput dl1
	if [[ $opcion = @(0|"") ]]; then
		return
	elif [[ ${#opcion} -gt 3 ]]; then
		print_center -verm2 "solo ingresa max 3 caracteres!"
		sleep 2
		return
	elif [[ ! $opcion =~ $numero ]]; then
		print_center -verm2 "ingresa solo nuemros!"
		sleep 2
		return
	elif [[ $opcion -lt 2 ]]; then
		print_center -verm2 "ingresa un numero mayor a 1!"
		sleep 2
		return
	fi
	maxretry=$(grep 'maxretry =' /etc/fail2ban/jail.d/defaults-debian.conf|cut -d ' ' -f3)
	sed -i "15 s/$maxretry/$opcion/" /etc/fail2ban/jail.d/defaults-debian.conf
	service fail2ban restart &>/dev/null
	print_center -verd "intentos de coneccion modificado"
	enter
}

nano_f(){
	nano /etc/fail2ban/jail.d/defaults-debian.conf
	service fail2ban restart &>/dev/null
	print_center -verd "conf fail2ban modificado!!!"
	enter
}

log_f(){
	stoplog(){
		print_center -ama "saliendo del Log fail2ban!!!"
		enter
	}
	trap "stoplog" INT TERM
	clear
	tail -n 200 -f /var/log/fail2ban.log | grep "NOTICE"
}

clearlog_f(){
	echo '' > /var/log/fail2ban.log &>/dev/null
	print_center -verd "Log fail2ban limpiado!!!"
	enter
}

fail2_menu(){
	title "MENU INTALACION Y CONFIGURACION FAIL2BAN"
	if [[ $(dpkg --get-selections|grep -w 'fail2ban'|head -1) ]]; then
		bantime=$(grep 'bantime =' /etc/fail2ban/jail.d/defaults-debian.conf|cut -d ' ' -f3)
		time=$(msg -azu "tiemp ban: \e[32m$bantime")
		findtime=$(grep 'findtime =' /etc/fail2ban/jail.d/defaults-debian.conf|cut -d ' ' -f3)
		per=$(msg -azu "periodo:   \e[32m$findtime")
		maxretry=$(grep 'maxretry =' /etc/fail2ban/jail.d/defaults-debian.conf|cut -d ' ' -f3)
		int=$(msg -azu "intentos:  \e[32m$maxretry")
		echo " $(msg -verd "[1]") $(msg -verm2 ">") $(msg -verm2 "DESINSTALAR") $(msg -azu "FAIL2BAN")         $(msg -verm2 '|')  $(msg -ama "Conf actual")"
		msg -bar3
		echo " $(msg -verd "[2]") $(msg -verm2 ">") $(msg -azu "MODIFICAR TIMEPO DE BAN")      $(msg -verm2 '|') $time"
		echo " $(msg -verd "[3]") $(msg -verm2 ">") $(msg -azu "MODIFICAR PERIODO DE BAN")     $(msg -verm2 '|') $per"
		echo " $(msg -verd "[4]") $(msg -verm2 ">") $(msg -azu "MODIFICAR NUMERO DE INTENTOS") $(msg -verm2 '|') $int"
		echo " $(msg -verd "[5]") $(msg -verm2 ">") $(msg -azu "MODIFICAR MANUAL (CON NANO)")  $(msg -verm2 '|')"
		msg -bar3
		echo " $(msg -verd "[6]") $(msg -verm2 ">") $(msg -ama "VER LOG FAIL2BAN")"
		echo " $(msg -verd "[7]") $(msg -verm2 ">") $(msg -ama "LIMPIAR LOG FAIL2BAN")"
		nu=7; in=a; un=1
	else
		echo " $(msg -verd "[1]") $(msg -verm2 ">") $(msg -verd "INSTALAR") $(msg -azu "FAIL2BAN")"
		nu=1; in=1; un=a
	fi
	back
	opcion=$(selection_fun $nu)
	case $opcion in
		"$in")install_fail2;;
		"$un")uninstall_fail2;;
		2)bantime_f;;
		3)findtime_f;;
		4)maxretry_f;;
		5)nano_f;;
		6)log_f;;
		7)clearlog_f;;
		0)return 1;;
	esac
}

while [[  $? -eq 0 ]]; do
	fail2_menu
done