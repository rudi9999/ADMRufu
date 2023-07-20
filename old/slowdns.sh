#!/bin/bash

info(){
	nodata(){
		msg -bar
		print_center -ama "SIN INFORMACION SLOWDNS!!!"
		enter
	}

	if [[ -e  ${ADM_slow}/domain_ns ]]; then
		ns=$(cat ${ADM_slow}/domain_ns)
		if [[ -z "$ns" ]]; then
			nodata
			return
		fi
	else
		nodata
		return
	fi

	if [[ -e ${ADM_slow}/server.pub ]]; then
		key=$(cat ${ADM_slow}/server.pub)
		if [[ -z "$key" ]]; then
			nodata
			return
		fi
	else
		nodata
		return
	fi

    title -ama "DATOS DE SU CONECCION SLOWDNS"
	msg -ama "TU NS (Nameserver): $(cat ${ADM_slow}/domain_ns)"
	msg -bar3
	msg -ama "TU LLAVE: $(cat ${ADM_slow}/server.pub)"
	enter
}

drop_port(){
    local portasVAR=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN")
    local NOREPEAT
    local reQ
    local Port
    unset DPB
    while read port; do
        reQ=$(echo ${port}|awk '{print $1}')
        Port=$(echo {$port} | awk '{print $9}' | awk -F ":" '{print $2}')
        [[ $(echo -e $NOREPEAT|grep -w "$Port") ]] && continue
        NOREPEAT+="$Port\n"

        case ${reQ} in
        	sshd|dropbear|stunnel4|stunnel|python|python3|v2ray)DPB+=" $reQ:$Port";;
            *)continue;;
        esac
    done <<< "${portasVAR}"
 }

ini_slow(){
	title "INSTALADOR SLOWDNS By @Rufu99"
	drop_port
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
    msg -bar
    opc=$(selection_fun $num_opc)
    echo "${drop[$opc]}" > ${ADM_slow}/puerto
    PORT=$(cat ${ADM_slow}/puerto)
    title "INSTALADOR SLOWDNS By @Rufu99"
    echo -e " $(msg -ama "Puerto de coneccion atraves de SlowDNS:") $(msg -verd "$PORT")"
    msg -bar3

    unset NS
    while [[ -z $NS ]]; do
    	msg -nama " Tu dominio NS: "
    	read NS
    	del 1
    done

    if [[ ! -e ${ADM_inst}/dns-server ]]; then
    	msg -nama " Descargando binario...."
    	if wget -O ${ADM_inst}/dns-server https://github.com/rudi9999/ADMRufu/raw/main/Utils/SlowDNS/dns-server &>/dev/null ; then
    		chmod +x ${ADM_inst}/dns-server
    		msg -verd "[OK]"
            sleep 2
    	else
    		msg -verm2 "[fail]"
    		msg -bar
    		print_center -ama "No se pudo descargar el binario"
    		print_center -verm2 "Instalacion canselada"
    		enter
    		return
    	fi
    	msg -bar3
    fi

    echo "$NS" > ${ADM_slow}/domain_ns
    echo -e " $(msg -ama "TU DOMINIO NS:") $(msg -verd "$NS")"
    msg -bar3

    if [[ -e "${ADM_slow}/server.pub" ]]; then
        pub=$(cat ${ADM_slow}/server.pub)
    else
        ex_key='n'
    fi

    while [[ ! -z $pub ]] && [[ -z $ex_key ]]; do
        read -rp " $(msg -ama "USAR CLAVE EXISTENTE? [S/N]:") " -e -i S ex_key
        del 1
        if [[ -z $ex_key ]]; then
            print_center -verm2 'INGRESA UN VALO [S] O [N]'
            sleep 2
            del 1
            unset ex_key
        elif [[ $ex_key != @(s|S|n|N) ]]; then
            print_center -verm2 'INGRESA UN VALO [S] O [N]'
            sleep 2
            del 1
            unset ex_key
        fi
    done


    case $ex_key in
        s|S|y|Y) echo -e " $(msg -ama "TU CLAVE:") $(msg -verd "$(cat ${ADM_slow}/server.pub)")";;
            n|N) rm -rf ${ADM_slow}/server.key; rm -rf ${ADM_slow}/server.pub
                 ${ADM_inst}/dns-server -gen-key -privkey-file ${ADM_slow}/server.key -pubkey-file ${ADM_slow}/server.pub &>/dev/null
                 echo -e " $(msg -ama "TU CLAVE:") $(msg -verd "$(cat ${ADM_slow}/server.pub)")";;
    esac

    msg -bar
    print_center -ama 'INICIANDO SERVICIO SLOWDNS'

        systemctl stop slowdns &>/dev/null
        systemctl disable slowdns &>/dev/null
        rm -rf /etc/systemd/system/slowdns.service

        systemctl stop slowdns-iptables &>/dev/null
        systemctl disable slowdns-iptables &>/dev/null
        rm -rf /etc/systemd/system/slowdns-iptables.service

    iptables_path=$(command -v iptables)

    echo "[Unit]
Before=network.target

[Service]
Type=oneshot

ExecStart=$iptables_path -I INPUT -p udp --dport 5300 -j ACCEPT
ExecStart=$iptables_path -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
ExecStop=$iptables_path -D INPUT -p udp --dport 5300 -j ACCEPT
ExecStop=$iptables_path -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/slowdns-iptables.service

    echo "[Unit]
Description=DNSTT Service by @Rufu99
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=${ADM_inst}/dns-server -udp :5300 -privkey-file ${ADM_slow}/server.key $NS 127.0.0.1:$PORT
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/slowdns.service

    systemctl enable slowdns-iptables &>/dev/null
    systemctl start slowdns-iptables &>/dev/null

    systemctl enable slowdns &>/dev/null
    systemctl start slowdns &>/dev/null
    
    del 1
    if [[ $(systemctl is-active slowdns) = 'active' ]]; then
        print_center -verd 'SLOWDNS INICIADO'
    else
        print_center -verm2 'FALLA AL INICIAR SLOWDNS'
    fi
    enter
}

reset_slow(){
    print_center -ama 'REINICIANDO SLOWDNS'

    if [[ $(systemctl is-enabled slowdns) = 'disabled' ]]; then
        systemctl enable slowdns &>/dev/null
    fi

    if [[ $(systemctl is-enabled slowdns-iptables) = 'disabled' ]]; then
        systemctl enable slowdns-iptables &>/dev/null
    fi

    systemctl restart slowdns &>/dev/null
    systemctl restart slowdns-iptables &>/dev/null

    if [[ $(systemctl is-active slowdns) = 'active' ]]; then
        del 1
        print_center -verd 'SLOWDNS REINICIANDO'
    else
        del 1
        print_center -verm2 'FALLA AL INICIAR SLOWDNS'
    fi
    enter
}

stop_slow(){
    print_center -ama 'DETENIENDO SERVICIO SLOWDNS'

    systemctl stop slowdns &>/dev/null
    systemctl disable slowdns &>/dev/null
    systemctl stop slowdns-iptables &>/dev/null
    systemctl disable slowdns-iptables &>/dev/null

    if [[ $(systemctl is-active slowdns) = 'inactive' ]]; then
        del 1
        print_center -verd 'SLOWDNS DETENIDO!!!'
    else
        del 1
        print_center -verm2 'FALLA AL DETENER SERVICIO SLOWDNS'    
    fi
    enter
}

menu_slow(){
    title 'INSTALADOR SLOWDNS By @Rufu99'
    menu_func "Ver Informacion\n$(msg -bar3)" "$(msg -verd "INSTALAR E INICIAR SLOWDNS")" "$(msg -ama "INICIAR/REINICIAR SLOWDNS")" "$(msg -verm2 "PARAR SLOWDNS")" 
    back
    opcion=$(selection_fun 5)

    case $opcion in
        1)info;;
        2)ini_slow;;
        3)reset_slow;;
        4)stop_slow;;
        0)return 1;;
    esac
}

while [[  $? -eq 0 ]]; do
  menu_slow
done
