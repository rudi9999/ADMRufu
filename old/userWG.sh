#!/bin/bash

cl_data(){
	peer=$(wg)
	data=$(cat /etc/wireguard/wg0.conf)
	user=$(echo "$data"|grep '^# BEGIN_PEER'|cut -d ' ' -f3)
	[[ -z $user ]] && print_center -ama "no hay clientes wireguard!" && return
	all_line="$(msg -azu "N°")-$(msg -azu "USUARIO")-$(msg -verd "DOWNLOAD")-$(msg -verm2 "UPLOAD")-$(msg -ama "LAST")-$(msg -azu "DAIS")\n"
	n='0'
	for i in `echo "${user}"`; do
		let n++
		dias=$(echo "$data"|grep -w "$i"|cut -d ' ' -f4)
		EXPTIME="$(($(($(date '+%s' -d "${dias}") - $(date +%s))) / 86400))"
		if [[ $EXPTIME -lt 0 ]]; then
			ext=$(msg -verm2 "[EXP]")
		else
			ext=$(msg -verd "[$EXPTIME]")
		fi
		PublicKey=$(echo "$data"|sed -n "/^# BEGIN_PEER $i/,/^# END_PEER $i/p"|grep 'PublicKey'|cut -d ' ' -f3)
		time=$(echo "$peer"|grep "$PublicKey" -A 5|grep -w 'latest handshake')
		if [[ ! -z $time ]]; then
			hora=$(echo $time|cut -d ' ' -f3,5,7|sed 's/ /:/g')
		else
			hora='00:00:00'
		fi
		consumo=$(echo "$peer"|grep "$PublicKey" -A 5|grep -w 'transfer')
		if [[ ! -z $consumo ]]; then
			up=$(echo $consumo|cut -d ' ' -f2,3|sed 's/ //g')
			dow=$(echo $consumo|cut -d ' ' -f5,6|sed 's/ //g')
		else
			dow='00.00KiB'
			up='00.00KiB'
		fi
		all_line+="$(msg -verd "$n)")-$(msg -azu "$i")-$(msg -blu "$dow")-$(msg -blu "$up")-$(msg -ama "$hora")-$ext\n"
	done
	echo -e "$all_line"|column -t -s '-'
}

new_wg(){
	octet=2
	while grep AllowedIPs /etc/wireguard/wg0.conf | cut -d "." -f 4 | cut -d "/" -f 1 | grep -q "$octet"; do
		(( octet++ ))
	done

	if [[ "$octet" -eq 256 ]]; then
		title -ama "255 clientes configurados"
		print_center -verm2 "No se pueden configurar mas"
		enter
		return 0
	fi

	title -ama "NUEVO CLIENTE WIREGUARD"
	cl_data
	back
	while [[ -z "$client" ]]; do
		in_opcion -nazu "NOMBRE DE CLIENTE"
		unsanitized_client="${opcion}"
		client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
		if [[ ! $(grep "^# BEGIN_PEER $client$" /etc/wireguard/wg0.conf) = "" ]]; then
			tput cuu1 && tput dl1
			print_center -verm2 "El cliete ya existe!"
			sleep 2
			tput cuu1 && tput dl1
			unset client
			continue
		elif [[ ${#client} -gt 12 ]]; then
			tput cuu1 && tput dl1
			print_center -verm2 "Nombre con mas de 12 caracteres!"
			sleep 2
			tput cuu1 && tput dl1
			unset client
		fi
	done
	[[ $client = 0 ]] && return 0

	while [[ -z "$dias_wg" ]]; do
		in_opcion -nazu "Tiempo en dias"
		dias_wg=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]//g' <<< "$opcion")
		if [[ $dias_wg = 0 ]]; then
			tput cuu1 && tput dl1 && tput cuu1 && tput dl1
			print_center -ama "operacion canselada!"
			enter
			return 0
		elif [[ ! $dias_wg =~ $numero ]]; then
			tput cuu1 && tput dl1
			print_center -verm2 "ingresa solo numeros!"
			sleep 2
			tput cuu1 && tput dl1
			unset dias_wg
			continue
		elif [[ $dias_wg -gt 365 ]]; then
			tput cuu1 && tput dl1
			print_center -verm2 "no puedes exeder los 365 dias!"
			sleep 2
			tput cuu1 && tput dl1
			unset dias_wg
			continue
		fi
	done

	valid=$(date '+%C%y-%m-%d' -d " +$dias_wg days")

	dns=$(cat ${ADM_tmp}/wg_dns)
	key=$(wg genkey)
	psk=$(wg genpsk)

	cat << EOF >> /etc/wireguard/wg0.conf
# BEGIN_PEER $client $valid
[Peer]
PublicKey = $(wg pubkey <<< $key)
PresharedKey = $psk
AllowedIPs = 10.7.0.$octet/32$(grep -q 'fddd:2c4:2c4:2c4::1' /etc/wireguard/wg0.conf && echo ", fddd:2c4:2c4:2c4::$octet/128")
# END_PEER $client
EOF

	cat << EOF > ~/"$client".conf
[Interface]
Address = 10.7.0.$octet/24$(grep -q 'fddd:2c4:2c4:2c4::1' /etc/wireguard/wg0.conf && echo ", fddd:2c4:2c4:2c4::$octet/64")
DNS = $dns
PrivateKey = $key

[Peer]
PublicKey = $(grep PrivateKey /etc/wireguard/wg0.conf | cut -d " " -f 3 | wg pubkey)
PresharedKey = $psk
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $(grep '^# ENDPOINT' /etc/wireguard/wg0.conf | cut -d " " -f 3):$(grep ListenPort /etc/wireguard/wg0.conf | cut -d " " -f 3)
PersistentKeepalive = 25
EOF

[[ ! -d ${ADM_tmp}/client_wg ]] && mkdir ${ADM_tmp}/client_wg && chmod -R +x ${ADM_tmp}/client_wg
cp -f ~/"$client".conf ${ADM_tmp}/client_wg/
	wg addconf wg0 <(sed -n "/^# BEGIN_PEER $client/,/^# END_PEER $client/p" /etc/wireguard/wg0.conf)
	title -ama "CLIENTE WIREGUARD CREADO CON EXITO!"
	print_center -verd "Su archivo de configuracion se encuentra en"
	dircfg=~/"$client.conf"
	print_center -verd "$dircfg"
	msg -bar
	print_center -ama "Quires ver el QR digita [QR]"
	in_opcion_down "Enter para salir"
	if [[ $opcion = @(QR|qr) ]]; then
		title -ama "CLIENTE QR WIREGUARD"
		qrencode -t ansiutf8 < ~/"$client.conf"
		msg -bar
		print_center -ama "CLIENTE QR WIREGUARD"
		enter
	fi
	return 0
}

del_wg(){
	number_of_clients=$(grep -c '^# BEGIN_PEER' /etc/wireguard/wg0.conf)
	if [[ "$number_of_clients" = 0 ]]; then
		title -verm2 "No hay clientes para eliminar"
		sleep 2
		return 0
	fi
	title "ELIMINAR CLIENTES WIREGUARD"
	cl_data
	back
	opcion=$(selection_fun $n)
	[[ $opcion = 0 ]] && return 0
	client=$(grep '^# BEGIN_PEER' /etc/wireguard/wg0.conf | cut -d ' ' -f 3 | sed -n "$opcion"p)
	wg set wg0 peer "$(sed "/^# BEGIN_PEER $client$/,\$p" /etc/wireguard/wg0.conf | grep -m 1 PublicKey | cut -d " " -f 3)" remove
	sed -i "/^# BEGIN_PEER $client/,/^# END_PEER $client/d" /etc/wireguard/wg0.conf
	rm -rf ~/"$client".conf
	rm -rf ${ADM_tmp}/client_wg/"$client".conf
	print_center -ama "Cliente $client eliminado!"
	enter
	return 0
}

view_wg(){
	number_of_clients=$(grep -c '^# BEGIN_PEER' /etc/wireguard/wg0.conf)
	if [[ "$number_of_clients" = 0 ]]; then
		title -ama "No hay clientes configurados"
		sleep 2
		return 0
	fi
	title "DATOS CLIENTES WIREGUARD"
	cl_data
	back
	opcion=$(selection_fun $n)
	[[ $opcion = 0 ]] && return 0
	client=$(grep '^# BEGIN_PEER' /etc/wireguard/wg0.conf | cut -d ' ' -f 3 | sed -n "$opcion"p)
	[[ ! -e ~/"$client.conf" ]] && cp -f ${ADM_tmp}/client_wg/"$client".conf ~/"$client".conf
	title -ama "CLIENTE QR WIREGUARD"
	print_center -verd "Su archivo de configuracion se encuentra en"
	dircfg=~/"$client.conf"
	print_center -verd "$dircfg"
	msg -bar
	print_center -ama "Quires ver el QR digita [QR]"
	in_opcion_down "Enter para salir"
	if [[ $opcion = @(QR|qr) ]]; then
		title -ama "CLIENTE QR WIREGUARD"
		qrencode -t ansiutf8 < ~/"$client.conf"
		msg -bar
		print_center -ama "CLIENTE QR WIREGUARD"
		enter
	fi
	return 0
}

menuWG(){
	unset client
	unset dias_wg
	if [[ ! $(dpkg --get-selections|grep -w 'wireguard'|head -1) ]]; then
		title -verm2 "WIREGUARD no esta instalado!"
		print_center -ama "Para administrar clientes\nprimero deve instalar wireguard"
		enter
		return 0
	elif [[ $(systemctl status wg-quick@wg0.service|grep -w 'Active'|awk -F ' ' '{print $2}') = "inactive" ]]; then
		title -verm2 "WIREGUARD no esta activo!"
		print_center -ama "Para administrar clientes\nprimero deve activar wireguard"
		enter
		return 0
	fi
	title "ADMINISTACION DE CUENTAS WIREGUARD"
	menu_func "NUEVO CLIENTE WG" \
	"ELIMINAR CLIENTE WG" \
	"VER DATOS DE CLIENTES"
	back
	opcion=$(selection_fun 3)
	case $opcion in
		1)new_wg;;
		2)del_wg;;
		3)view_wg;;
		0)return 1;;
	esac
}

while [[  $? -eq 0 ]]; do
	menuWG
done
