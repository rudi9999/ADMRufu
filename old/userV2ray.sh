#!/bin/bash

restart(){
	title "REINICIANDO V2RAY"
	if [[ "$(v2ray restart|awk '{printf $3}')" = "success" ]]; then
		print_center -verd "v2ray restart success !"
		msg -bar
		sleep 3
	else
		print_center -verm2 "v2ray restart fail !"
		msg -bar
		sleep 3
		return
	fi
}

list(){
	name=$(printf '%-25s' "$2")
	fecha=$(printf '%-10s' "$3")
	if [[ "$4" = "EXP" ]]; then
		dias=$(msg -verm2 "[$4]")
	else
		dias=$(msg -verd "[$4]")
	fi
	echo -e "$(msg -verd " [$1]") $(msg -verm2 ">") $(msg -azu "$name") $(msg -verm2 "$fecha") $dias"
 }

userDat(){
	n=$(printf '%-5s' 'N°')
	u=$(printf '%-25s' 'Usuarios')
	f=$(printf '%-10s' 'fech exp')
	msg -azu "  $n $u $f dias"
	msg -bar
 }

 list_user(){
 	unset seg
	seg=$(date +%s)
 	userDat
 	users=$(jq '.inbounds[].settings.clients | length' $config)
	for (( i = 0; i < $users; i++ )); do
		user=$(jq -r --argjson a "$i" '.inbounds[].settings.clients[$a].email' < $config)
		fecha=$(jq -r --argjson a "$i" '.inbounds[].settings.clients[$a].date' < $config)
		[[ "$user" = "null" ]] && continue

		seg_exp=$(date +%s --date="$fecha")
		exp="$(($(($seg_exp - $seg)) / 86400))"

		[[ "$exp" -lt "0" ]] && exp="EXP"

		list "$i" "$user" "$fecha" "$exp"
		l=$i
	done
 }

 col2(){
 	msg -ne "$1" && msg -ama " $2"
 }

 vmess(){
 	ps=$(jq -r .inbounds[].settings.clients[$1].email $config) && [[ $ps = null ]] && ps="default"
	id=$(jq -r .inbounds[].settings.clients[$1].id $config)
	aid=$(jq .inbounds[].settings.clients[$1].alterId $config)
	add=$(jq -r .inbounds[].domain $config) && [[ $add = null ]] && add=$(wget -qO- ipv4.icanhazip.com)
	host=$(jq -r .inbounds[].streamSettings.wsSettings.headers.Host $config) && [[ $host = null ]] && host=''
	net=$(jq -r .inbounds[].streamSettings.network $config)
	path=$(jq -r .inbounds[].streamSettings.wsSettings.path $config) && [[ $path = null ]] && path=''
	port=$(jq .inbounds[].port $config)
	tls=$(jq -r .inbounds[].streamSettings.security $config)

	title "DATOS DE USUARIO: $ps"
	col2 "Remarks:" "$ps"
	col2 "Address:" "$add"
	col2 "Port:" "$port"
	col2 "id:" "$id"
	col2 "alterId:" "$aid"
	col2 "security:" "none"
	col2 "network:" "$net"
	col2 "Head Type:" "none"
	[[ ! $host = '' ]] && col2 "Host/SNI:" "$host"
	[[ ! $path = '' ]] && col2 "Path:" "$path"
	col2 "TLS:" "$tls"
	msg -bar
 	var="{\"v\":\"2\",\"ps\":\"$ps\",\"add\":\"$add\",\"port\":$port,\"aid\":$aid,\"type\":\"none\",\"net\":\"$net\",\"path\":\"$path\",\"host\":\"$host\",\"id\":\"$id\",\"tls\":\"$tls\"}"
	msg -ama "vmess://$(echo "$var"|jq -r '.|@base64')"
	msg -bar
	read foo
 }

newuser(){
	title "CREAR NUEVO USUARIO V2RAY"
	list_user
	back
	in_opcion "Nuevo Usuario"
	opcion=$(echo "$opcion" | tr -d '[[:space:]]')
	if [[ "$opcion" = "0" ]]; then
		return
	elif [[ -z "$opcion" ]]; then
		tput cuu1 && tput dl1
		msg -verm2 " no se puede ingresar campos vacios..."
		sleep 2
		return
	elif [[ ! "$opcion" =~ $tx_num ]]; then
		tput cuu1 && tput dl1
		msg -verm2 " ingrese solo letras y numeros..."
		sleep 2
		return
	elif [[ "${#opcion}" -lt "4" ]]; then
		tput cuu1 && tput dl1
		msg -verm2 " nombre demaciado corto!"
		sleep 2
		return
	elif [[ "$(jq -r '.inbounds[].settings.clients[].email' < $config|grep "$opcion")" ]]; then
		tput cuu1 && tput dl1
		msg -verm2 " este nombe de ususario ya existe..."
		sleep 2
		return
	fi
	email="$opcion"
	in_opcion "Dias de duracion"
	opcion=$(echo "$opcion" | tr -d '[[:space:]]')
	if [[ "$opcion" = "0" ]]; then
		return
	elif [[ ! "$opcion" =~ $numero ]]; then
		tput cuu1 && tput dl1
		msg -verm2 " ingresa solo numeros"
		sleep 2
		return
	fi

	dias=$(date '+%y-%m-%d' -d " +$opcion days")
	alterid=$(jq -r '.inbounds[].settings.clients[0].alterId' < $config)
	uuid=$(uuidgen)
	var="{\"alterId\":"$alterid",\"id\":\"$uuid\",\"email\":\"$email\",\"date\":\"$dias\"}"

	
	mv $config $temp
	jq --argjson a "$users" --argjson b "$var" '.inbounds[].settings.clients[$a] += $b' < $temp > $config
	chmod 777 $config
	rm -rf $temp
	restart
	vmess "$users"
}

deluser(){
	title "ELIMINAR USUARIOS"
	list_user
	back
	in_opcion "Opcion"
	opcion=$(echo "$opcion" | tr -d '[[:space:]]')
	if [[ "$opcion" = "0" ]]; then
		return
	elif [[ ! "$opcion" =~ $numero ]]; then
		tput cuu1 && tput dl1
		msg -verm2 " ingresa solo numeros"
		sleep 2
		return
	fi
	mv $config $temp
	jq --argjson a "$opcion" 'del(.inbounds[].settings.clients[$a])' < $temp > $config
	chmod 777 $config
	rm -rf $temp
	restart
}

datos(){
	title "DATOS DE USUARIOS"
	list_user
	back
	in_opcion "Opcion"
	vmess "$opcion"
}

respaldo(){
	title "COPIAS DE SEGURIDAD DE USUARIOS"
	menu_func "CREAR COPIA DE USUARIOS" "RESTAURAR COPIA DE USUARIO"
	back
	opcion=$(selection_fun 2)

	case $opcion in
		1)rm -rf /root/User-V2ray.txt
		jq '.inbounds[].settings.clients' < $config > /root/User-V2ray.txt
		title "COPIA REALIZADO CON EXITO"
		msg -ne " Copia: " && msg -ama "/root/User-V2ray.txt"
		msg -bar
		read foo;;
		2)[[ ! -e "/root/User-V2ray.txt" ]] && msg -verm2 " no hay copia de ususarios!" && sleep 3 && return
		var=$(cat /root/User-V2ray.txt)
		[[  -z "$var" ]] && msg -verm2 " copia de ususarios vacio!" && sleep 3 && return
		mv $config $temp
		jq --argjson a "$var" '.inbounds[].settings += {clients:$a}' < $temp > $config
		chmod 777 $config
		rm -rf $temp
		title "COPIA RESTAURADA CON EXITO"
		sleep 2
		restart;;
		0)return;;
	esac
}

renewuser(){
	title "RENOVAR USUARIO V2RAY"
	list_user
	back
	in_opcion "Opcion"
	del 2
	opcion=$(echo "$opcion" | tr -d '[[:space:]]')
	if [[ "$opcion" = "0" ]]; then
		return
	elif [[ ! "$opcion" =~ $numero ]]; then
		del 2
		print_center -verm2 "ingresa solo numeros"
		sleep 2
		return
	elif [[ "$opcion" -gt "$l" ]]; then
		del 2
		print_center -verm2 "ingresa solo numeros entre 0 y $l"
		sleep 2
		return
	fi
	user=$opcion && unset opcion
	nombre=$(jq -r --argjson a "$user" '.inbounds[].settings.clients[$a].email' $config)
	in_opcion "Dias de expiracion para $nombre"
	opcion=$(echo "$opcion" | tr -d '[[:space:]]')
	if [[ "$opcion" = "0" ]]; then
		return
	elif [[ ! "$opcion" =~ $numero ]]; then
		del 1
		print_center -verm2 "ingresa solo numeros"
		sleep 2
		return
	fi
	dias=$(date '+%y-%m-%d' -d " +$opcion days") && unset opcion
	mv $config $temp
	jq --argjson a "$user" --arg b "$dias" '.inbounds[].settings.clients[$a] += {"date":$b}' < $temp > $config
	chmod 777 $config
	rm -rf $temp
	restart
}

while :
do
	title "GESTION DE USUARIOS V2RAY"
	print_center -ama "De momento este menu solo esta\noptimizado para usuarios VMESS"
	msg -bar
	menu_func "$(msg -verd "CREAR USUARIOS")" \
	"$(msg -verm2 "ELIMINAR USUARIOS")" \
	"-bar3 RENOVAR USUARIO" \
	"$(msg -ama "VMESS DE USUARIOS")" \
	"RESPALDO DE SEGURIDAD"
	back
	opcion=$(selection_fun 5)
	case $opcion in
		1)newuser;;
		2)deluser;;
		3)renewuser;;
		4)datos;;
		5)respaldo;;
		0)break;;
	esac
done