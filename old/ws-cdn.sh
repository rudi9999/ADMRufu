#!/bin/bash
clear
drop_port(){
    local portasVAR=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN")
    local NOREPEAT
    local reQ
    local Port

    while read port; do
        reQ=$(echo ${port}|awk '{print $1}')
        Port=$(echo {$port} | awk '{print $9}' | awk -F ":" '{print $2}')
        [[ $(echo -e $NOREPEAT|grep -w "$Port") ]] && continue
        NOREPEAT+="$Port\n"

        case ${reQ} in
            cupsd|systemd-r|exim4)continue;;
            *)DPB+=" $reQ:$Port";;
        esac
    done <<< "${portasVAR}"
 }

conf(){
	[[ $opcion = @(n|N) ]] && return 1
	drop_port
	encab
	print_center -azu "Selecciones puerto de redireccion de trafico"
	msg -bar

	n=1
	for i in $DPB; do
        proto=$(echo $i|awk -F ":" '{print $1}')
        proto2=$(printf '%-12s' "$proto")
        port=$(echo $i|awk -F ":" '{print $2}')
        echo -e " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -ama "$proto2")$(msg -azu "$port")"
        drop[$n]=$port
        num_opc="$n"
        let n++ 
    done
	back
	opc=$(selection_fun $num_opc)
	[[ $opc = 0 ]] && return 1
	encab
	echo -e "\033[1;33m Puerto de redireccion de trafico: \033[1;32m${drop[$opc]}"
	msg -bar
 while [[ -z $opc2 ]]; do
	echo -ne "\033[1;37m Ingrese un puerto para WEBSOCKET: " && read opc2
	tput cuu1 && tput dl1

        [[ $(mportas|grep -w "${opc2}") = "" ]] && {
        	echo -e "\033[1;33m $(fun_trans  "Puerto de websocket:")\033[1;32m ${opc2} OK"
        	msg -bar
        } || {
        	echo -e "\033[1;33m $(fun_trans  "Puerto de websocket:")\033[1;31m ${opc2} FAIL" && sleep 2
        	tput cuu1 && tput dl1
        	unset opc2
        }
 done

 	while :
 	do
	echo -ne "\033[1;37m Desea continuar [s/n]: " && read start
	tput cuu1 && tput dl1
	if [[ -z $start ]]; then
		echo -e "\033[1;37m deves ingresar una opcion \033[1;32m[S] \033[1;37mpara Si \033[1;31m[n] \033[1;37mpara No." && sleep 2
		tput cuu1 && tput dl1
	else
		[[ $start = @(n|N) ]] && break
		if [[ $start = @(s|S) ]]; then
			node_v="$(which nodejs)" && [[ $(ls -l ${node_v}|grep -w 'node') ]] && node_v="$(which node)"
echo -e "[Unit]
Description=P7COM-nodews1
Documentation=https://p7com.net/
After=network.target nss-lookup.target\n
[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=${node_v} /etc/ADMRufu/install/WS-Proxy.js -dhost 127.0.0.1 -dport ${drop[$opc]} -mport $opc2
Restart=on-failure
RestartSec=3s\n
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/nodews.$opc2.service

			systemctl enable nodews.$opc2 &>/dev/null
			systemctl start nodews.$opc2 &>/dev/null
			for ufww in `echo $opc2`; do
				ufw allow $ufww/tcp > /dev/null 2>&1
			done
			print_center -verd "Ejecucion con exito"
			enter
			break
		fi
	fi
	done
	return 1
 }

stop_ws () {
	ck_ws=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND"|grep "node")
	if [[ -z $(echo "$ck_ws" | awk '{print $1}' | head -n 1) ]]; then
		print_center -verm2 "WEBSOCKET no encontrado"
	else
		ck_port=$(echo "$ck_ws" | awk '{print $9}' | awk -F ":" '{print $2}')
		for i in $ck_port; do
			systemctl stop nodews.${i} &>/dev/null
			systemctl disable nodews.${1} &>/dev/null
			rm /etc/systemd/system/nodews.${i}.service &>/dev/null
		done
		print_center -verm2 "WEBSOCKET detenido"	
	fi
	enter
	return 1
 }

 stop_port () {
 	clear
	STWS=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND"|grep "node" | awk '{print $9}' | awk -F ":" '{print $2}')
	title "DETENER UN PUERTO"
 	n=1
	for i in $STWS; do
		echo -e " \033[1;32m[$n] \033[1;31m> \033[1;37m$i\033[0m"
		wspr[$n]=$i
		let n++	
	done
 	back
 	echo -ne "\033[1;37m opcion: " && read prws
 	tput cuu1 && tput dl1
 	[[ $prws = "0" ]] && return
 	systemctl stop nodews.${wspr[$prws]} &>/dev/null
	systemctl disable nodews.${wspr[$prws]} &>/dev/null
	rm /etc/systemd/system/nodews.${wspr[$prws]}.service &>/dev/null
	print_center -verm2 "PUERTO WEBSOCKET ${wspr[$prws]} detenido"
 	enter
	return 1
 }

encab(){
	title "SSH OVER WEBSOCKET CDN CLOUDFLARE"
 }

encab
menu_func "INICIAR/AGREGAR PROXY WS CDN" "DETENER PROXY WS CDN"

sf=2
[[ $(lsof -V -i tcp -P -n|grep -v "ESTABLISHED"|grep -v "COMMAND"|grep "node"|wc -l) -ge "2" ]] && echo -e "$(msg -verd " [3]") $(msg -verm2 ">") $(msg -azu "DETENER UN PUERTO")" && sf=3
back
selection=$(selection_fun ${sf})
case ${selection} in
	1) conf;;
	2) stop_ws && read foo;;
	3) stop_port;;
	0)return 1;;
esac