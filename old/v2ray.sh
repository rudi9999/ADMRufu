#!/bin/bash

restart(){
	title "REINICIANDO V2RAY"
	if [[ "$(v2ray restart|awk '{printf $3}')" = "success" ]]; then
		print_center -verd "v2ray restart success !"
	else
		print_center -verm2 "v2ray restart fail !"
	fi
	msg -bar
	sleep 3
}

ins_v2r(){
	if [[ $(type -p v2ray|grep v2ray) ]]; then
		uninstall
		title -ama 'Reinstalandon v2ray...!!!'
		sleep 3
	else
		title "ESTA POR INSTALAR V2RAY!"
		print_center -ama "La instalacion puede tener alguna fallas!\npor favor observe atentamente el log de intalacion.\npodria contener informacion sobre algunos errores!\ny deveran corregirse de forma manual antes de\ncontinuar usando el script."
		enter
	fi
	source <(curl -sSL https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Utils/v2ray/v2ray.sh)
	#source <(curl -sL https://multi.netlify.app/v2ray.sh)
}

v2ray_tls(){
	db="$(ls ${ADM_crt})"
    if [[ ! "$(echo "$db"|grep '.crt')" = "" ]]; then
        cert=$(echo "$db"|grep '.crt')
        key=$(echo "$db"|grep '.key')
        DOMI=$(cat "${ADM_src}/dominio.txt")
        title "CERTIFICADO SSL ENCONTRADO"
        echo -e "$(msg -azu "DOMI:") $(msg -ama "$DOMI")"
        echo -e "$(msg -azu "CERT:") $(msg -ama "$cert")"
        echo -e "$(msg -azu "KEY:")  $(msg -ama "$key")"
        msg -bar
        msg -ne " Continuar, usando este certificado [S/N]: " && read opcion_tls

        if [[ $opcion_tls = @(S|s) ]]; then
            cert=$(jq --arg a "${ADM_crt}/$cert" --arg b "${ADM_crt}/$key" '.inbounds[].streamSettings.tlsSettings += {"certificates":[{"certificateFile":$a,"keyFile":$b}]}' < $config)
            domi=$(echo "$cert"|jq --arg a "$DOMI" '.inbounds[] += {"domain":$a}')
            echo "$domi"|jq --arg a 'tls' '.inbounds[].streamSettings += {"security":$a}' > $temp
            chmod 777 $temp
            mv -f $temp $config
            reiniciar
            return
        fi
    fi

	title "CERTIFICADO TLS V2RAY"
	echo -e "\033[1;37m"
	v2ray tls
	enter
 }

uninstall(){
	#V2ray
    #bash <(curl -L -s https://multi.netlify.app/go.sh) --remove >/dev/null 2>&1
    bash <(curl -L -s https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Utils/v2ray/go.sh) --remove >/dev/null 2>&1
    rm -rf /etc/v2ray >/dev/null 2>&1
    rm -rf /var/log/v2ray >/dev/null 2>&1

    #Xray
    #bash <(curl -L -s https://multi.netlify.app/go.sh) --remove -x >/dev/null 2>&1
    bash <(curl -L -s https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Utils/v2ray/go.sh) --remove -x >/dev/null 2>&1
    rm -rf /etc/xray >/dev/null 2>&1
    rm -rf /var/log/xray >/dev/null 2>&1

    #v2ray iptable
    bash <(curl -L -s https://multi.netlify.app/v2ray_util/global_setting/clean_iptables.sh)

    #multi-v2ray
    pip uninstall v2ray_util -y
    rm -rf /usr/share/bash-completion/completions/v2ray.bash >/dev/null 2>&1
    rm -rf /usr/share/bash-completion/completions/v2ray >/dev/null 2>&1
    rm -rf /usr/share/bash-completion/completions/xray >/dev/null 2>&1
    rm -rf /etc/bash_completion.d/v2ray.bash >/dev/null 2>&1
    rm -rf /usr/local/bin/v2ray >/dev/null 2>&1
    rm -rf /etc/v2ray_util >/dev/null 2>&1

    #v2ray
    crontab -l|sed '/SHELL=/d;/v2ray/d'|sed '/SHELL=/d;/xray/d' > crontab.txt
    crontab crontab.txt >/dev/null 2>&1
    rm -f crontab.txt >/dev/null 2>&1

    systemctl restart cron >/dev/null 2>&1

    #multi-v2ray
    sed -i '/v2ray/d' ~/.bashrc
    sed -i '/xray/d' ~/.bashrc
    source ~/.bashrc
 }

removeV2Ray(){
	print_center -ama 'REMOVIENDO V2RAY ...'
    uninstall &>/dev/null
    del 1
    print_center -ama "V2RAY REMOVIDO!"
    enter
}

 v2ray_stream(){
 	title "PROTOCOLOS V2RAY"
 	echo -e "\033[1;37m"
	v2ray stream
	enter
 }

 port(){
 	port=$(jq -r '.inbounds[].port' $config)
 	title "CONFING PERTO V2RAY"
	print_center -azu "Puerto actual: $(msg -ama "$port")"
	back

	while [[ -z $_port ]]; do
		in_opcion "Nuevo puerto"
		_port=$(echo "$opcion" | tr -d '[[:space:]]')
		del 2
		if [[ -z "$_port" ]]; then
			print_center -verm2 'deves ingresar una opcion'
			sleep 2
			del 1
		elif [[ ! $_port =~ $numero ]]; then
			print_center -verm2 " solo deves ingresar numeros"
			sleep 2
			del 1
			unset _port
		elif [[ "$_port" = "0" ]]; then
			break
		fi
	done

	[[ $_port = 0 ]] && unset _port && return
	mv $config $temp
	jq --argjson a "$_port" '.inbounds[] += {"port":$a}' < $temp >> $config
	chmod 777 $config
	rm $temp
	unset _port
	reiniciar
 }

 alterid(){
 	aid=$(jq -r '.inbounds[].settings.clients[0].alterId' $config)
 	title "CONFING alterId V2RAY"
	print_center -azu "alterid actual: $(msg -ama "$aid")"
	back
	while [[ -z $_aid ]]; do
		in_opcion "Nuevo alterid"
		_aid=$(echo "$opcion" | tr -d '[[:space:]]')
		del 2
		if [[ -z "$_aid" ]]; then
			print_center -verm2 "deves ingresar una opcion"
			sleep 2
			del 1
		elif [[ ! $_aid =~ $numero ]]; then
			print_center -verm2 "solo deves ingresar numeros"
			sleep 2
			del 1
			unset _aid
		elif [[ "$_aid" = "0" ]]; then
			break
		fi
	done
	[[ $_aid = 0 ]] && unset _aid && return	
	mv $config $temp
	jq --argjson a "$_aid" '.inbounds[].settings.clients[] += {"alterId":$a}' < $temp >> $config
	chmod 777 $config
	rm $temp
	unset _aid
	reiniciar
 }

 n_v2ray(){
 	title "CONFIGRACION NATIVA V2RAY"
 	echo -ne "\033[1;37m"
	v2ray
 }

 address(){
 	add=$(jq -r '.inbounds[].domain' $config) && [[ $add = null ]] && _add=$(wget -qO- ipv4.icanhazip.com)
 	title "CONFING address V2RAY"
	print_center -azu "actual: $(msg -ama "$add")"
	back

	while [[ -z $_add ]]; do
		in_opcion "Nuevo address"
		_add=$(echo "$opcion" | tr -d '[[:space:]]')
		del 2
		if [[ -z "$_add" ]]; then
			print_center -verm2 "deves ingresar una opcion"
			sleep 2
			del 1
		elif [[ "$_add" = "0" ]]; then
			break
		elif [[ $(echo "$_add"|grep "\.") = "" ]]; then
			print_center -verm2 'formato no valido'
			sleep 2
			del 1
			unset _add
		fi
	done
	[[ $_add = 0 ]] && unset _add && return
	mv $config $temp
	jq --arg a "$_add" '.inbounds[] += {"domain":$a}' < $temp >> $config
	chmod 777 $config
	rm $temp
	unset _add
	reiniciar
 }

 host(){
 	host=$(jq -r '.inbounds[].streamSettings.wsSettings.headers.Host' $config) && [[ $host = null ]] && host='sin host'
 	title "CONFING host V2RAY"
	print_center -azu "Actual: $(msg -ama "$host")"
	back

	while [[ -z $_host ]]; do
		in_opcion "Nuevo host"
		_host=$(echo "$opcion" | tr -d '[[:space:]]')
		del 2
		if [[ -z "$_host" ]]; then
			print_center -verm2 "deves ingresar una opcion"
			sleep 2
			_host=0
		elif [[ "$_host" = "0" ]]; then
			break
		elif [[ $(echo "$_host"|grep "\.") = "" ]]; then
			print_center -verm2 'formato no valido'
			sleep 2
			del 1
			unset _host
		fi
	done
	[[ $_host = 0 ]] && unset _host && return
	mv $config $temp
	jq --arg a "$_host" '.inbounds[].streamSettings.wsSettings.headers += {"Host":$a}' < $temp >> $config
	chmod 777 $config
	rm $temp
	unset _host
	reiniciar
 }

 path(){
 	path=$(jq -r '.inbounds[].streamSettings.wsSettings.path' $config) && [[ $path = null ]] && _path='/ADMRufu'
 	title "CONFING path V2RAY"
	print_center -azu "Actual: $(msg -ama "$path")"
	back

	while [[ -z $_path ]]; do
		in_opcion "Nuevo path"
		_path=$(echo "$opcion" | tr -d '[[:space:]]')
		del 2
		if [[ -z "$_path" ]]; then
			print_center -verm2 "deves ingresar una opcion"
			sleep 2
			del 1
		elif [[ "$_path" = "0" ]]; then
			break
		fi
	done
	[[ $_path = 0 ]] && unset _path && return
	mv $config $temp
	jq --arg a "$_path" '.inbounds[].streamSettings.wsSettings += {"path":$a}' < $temp >> $config
	chmod 777 $config
	rm $temp
	unset _path
	reiniciar
 }

 reset(){
 	title "RESTAURANDO AJUSTES V2RAY"
 	print_center -ama 'De ser posible, desea salvar y restaurar\nlos usuarios, de forma automatica'
 	msg -bar
 	read -rp " $(msg -azu "salvar usuarios [S/N]:") " -e -i S _user_save
 	del 1
 	if [[ $_user_save = @(s|S) ]]; then
 		user=$(jq -c '.inbounds[].settings.clients' < $config)
 		back_dir="/root/back_user_v2r_$(printf '%(%d-%m-%H:%M:%S)T').json"
 		jq '.' <<< $(echo "$user") > $back_dir
 		print_center -verd "copia: $back_dir"
 		msg -bar
 	fi
 	v2ray new &>/dev/null

 	jq 'del(.inbounds[].streamSettings.kcpSettings[])' < $config > $temp
 	rm $config
    jq '.inbounds[].streamSettings += {"network":"ws","wsSettings":{"path": "/ADMRufu/","headers": {"Host": "ejemplo.com"}}}' < $temp > $config
    chmod 777 $config
    rm $temp
    if [[ ! -z "$user" ]]; then
    	mv $config $temp
    	jq --argjson a "$user" '.inbounds[].settings += {"clients":$a}' < $temp > $config
    	chmod 777 $config
    fi
    reiniciar
 }

reiniciar(){
	print_center -ama 'Reiniciando v2ray!!!'
	if [[ $(v2ray restart|grep success) ]]; then
		del 1
		print_center -verd 'Reinicio de v2ray exitoso!!!'
	else
		del 1
		print_center -verm2 'Reinicio de v2ray fallido!!!'
	fi
	enter
	clear
}

detener(){
	print_center -ama 'Deteniedo v2ray!!!'
	if [[ $(v2ray stop|grep success) ]]; then
		del 1
		print_center -verd 'Se detuvo v2ray con exitoso!!!'
	else
		del 1
		print_center -verm2 'Falla al detener v2ray!!!'
	fi
	enter
	clear
}

menu_v2ray(){
	title 'v2ray manager by @Rufu99'
	print_center -ama "INSTALACION"
	msg -bar3

	if [[ $(type -p v2ray|grep v2ray) ]]; then
		echo " $(msg -verd '[1]') $(msg -verm2 '>') $(msg -verd 'REINSTALAR V2RAY')"
		echo " $(msg -verd '[2]') $(msg -verm2 '>') $(msg -verm2 'DESINSTALAR V2RAY')"

		echo " $(msg -verd '[3]') $(msg -verm2 '>') $(msg -ama 'REINICIAR')"
		echo " $(msg -verd '[4]') $(msg -verm2 '>') $(msg -azu 'DETENER')"
		msg -bar
		print_center -ama 'CONFIGRACION'
		msg -bar3
		echo "         $(msg -ama 'SERVIDOR')          $(msg -verm2 '│')          $(msg -ama 'CLIENTES')"
		msg -bar3
		echo -ne " $(msg -verd '[5]') $(msg -verm2 '>') $(msg -azu 'CERTIFICADO SSL/TLS') $(msg -verm2 '│')" && echo "   $(msg -verd '[10]') $(msg -verm2 '>') $(msg -azu 'ADDRESS')"
		echo -ne " $(msg -verd '[6]') $(msg -verm2 '>') $(msg -azu 'PROTOCOLOS')          $(msg -verm2 '│')" && echo "   $(msg -verd '[11]') $(msg -verm2 '>') $(msg -azu 'HOST/IP')"
		echo -ne " $(msg -verd '[7]') $(msg -verm2 '>') $(msg -azu 'PUERTO')              $(msg -verm2 '│')" && echo "   $(msg -verd '[12]') $(msg -verm2 '>') $(msg -azu 'PATH')"
		echo " $(msg -verd '[8]') $(msg -verm2 '>') $(msg -azu 'ALTERID')             $(msg -verm2 '│')"
		echo " $(msg -verd '[9]') $(msg -verm2 '>') $(msg -azu 'CONF V2RAY')          $(msg -verm2 '│')"
		msg -bar
		print_center -ama 'EXTRAS'
		msg -bar3
		echo " $(msg -verd '[13]') $(msg -verm2 '>') $(msg -azu 'RESTABLECER AJUSTES')"
		num=13
	else
		echo " $(msg -verd '[1]') $(msg -verm2 '>') $(msg -verd 'INSTALAR V2RAY')"
		num=1
	fi
	back
	m_opcion=$(selection_fun $num)
	case $m_opcion in
		1)ins_v2r;;
		2)removeV2Ray;;
		3)reiniciar;;
		4)detener;;
		5)v2ray_tls;;
		6)v2ray_stream;;
		7)port;;
		8)alterid;;
		9)n_v2ray;;
		10)address;;
		11)host;;
		12)path;;
		13)reset;;
		0)return 1;;
	esac
}

while [[  $? -eq 0 ]]; do
  menu_v2ray
done








