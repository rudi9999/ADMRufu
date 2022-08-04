#!/bin/bash
clear
#source /etc/ADMRufu/module

smtp_port="25,26,465,587"
pop3_port="109,110,995"
imap_port="143,218,220,993"
other_port="24,50,57,105,106,158,209,1109,24554,60177,60179"

firewall_port="$(pwd)/firewall_port" && [[ ! -e ${firewall_port} ]] && echo -e "$smtp_port\n$pop3_port\n$imap_port\n$other_port" > ${firewall_port}

bt_key_word="torrent
.torrent
peer_id=
announce
info_hash
get_peers
find_node
BitTorrent
announce_peer
BitTorrent protocol
announce.php?passkey=
magnet:
xunlei
sandai
Thunder
XLLiveUD"

firewall_txt="$(pwd)/firewall_txt" && [[ ! -e ${firewall_txt} ]] && echo -e "${bt_key_word}" > ${firewall_txt}

check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_BT(){
	Cat_KEY_WORDS
	BT_KEY_WORDS=$(echo -e "$Ban_KEY_WORDS_list"|grep "torrent")
}
check_SPAM(){
	Cat_PORT
	SPAM_PORT=$(echo -e "$Ban_PORT_list"|grep "${smtp_port}")
}
Cat_PORT(){
	Ban_PORT_list=$(iptables -t filter -L OUTPUT -nvx --line-numbers|grep "REJECT"|awk '{print $13}')
}
Cat_KEY_WORDS(){
	Ban_KEY_WORDS_list=""
	Ban_KEY_WORDS_v6_list=""
	if [[ ! -z ${v6iptables} ]]; then
		Ban_KEY_WORDS_v6_text=$(${v6iptables} -t mangle -L OUTPUT -nvx --line-numbers|grep "DROP")
		Ban_KEY_WORDS_v6_list=$(echo -e "${Ban_KEY_WORDS_v6_text}"|sed -r 's/.*\"(.+)\".*/\1/')
	fi
	Ban_KEY_WORDS_text=$(${v4iptables} -t mangle -L OUTPUT -nvx --line-numbers|grep "DROP")
	Ban_KEY_WORDS_list=$(echo -e "${Ban_KEY_WORDS_text}"|sed -r 's/.*\"(.+)\".*/\1/')
}
View_PORT(){
	Cat_PORT
	if [[ ! -z ${Ban_PORT_list} ]]; then
		port_list=${Ban_PORT_list}
		print_center -azu "LISTA DE PUERTO BLOQUEADOS \e[32m[ON]"
		msg -bar
		echo -e "\033[1;97m${port_list}"
	else
		port_list=$(cat $firewall_port)
		print_center -azu "LISTA DE PUERTO BLOQUEADOS \e[31m[OFF]"
		msg -bar
		echo -e "\033[1;97m${port_list}"
	fi
}
View_KEY_WORDS(){
	Cat_KEY_WORDS
	if [[ ! "${op_1[1]}" = '1' ]]; then
		txt_list=${Ban_KEY_WORDS_list}
		print_center -azu "lista de palabras claves \e[32m[ON]"
		msg -bar
		msg -azu "${txt_list}"
	else
		txt_list=$(cat ${firewall_txt})
		print_center -azu "lista de palabras claves \e[31m[OFF]"
		msg -bar
		msg -azu "${txt_list}"
	fi
}
View_KEY_WORDS_2(){
	Cat_KEY_WORDS
	if [[ "${op_1[1]}" = '1' ]]; then
		txt_list=${Ban_KEY_WORDS_list}
		print_center -azu "lista de palabras claves \e[32m[ON]"
		msg -bar
		msg -azu "${txt_list}"
	else
		txt_list=$(cat ${firewall_txt})
		print_center -azu "lista de palabras claves \e[31m[OFF]"
		msg -bar
		msg -azu "${txt_list}"
	fi
}
View_ALL(){
	clear
	msg -bar
	View_PORT
	msg -bar
	View_KEY_WORDS_2
}
Save_iptables_v4_v6(){
	if [[ ${release} == "centos" ]]; then
		if [[ ! -z "$v6iptables" ]]; then
			service ip6tables save
			chkconfig --level 2345 ip6tables on
		fi
		service iptables save
		chkconfig --level 2345 iptables on
	else
		if [[ ! -z "$v6iptables" ]]; then
			ip6tables-save > /etc/ip6tables.up.rules
			echo -e "#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules\n/sbin/ip6tables-restore < /etc/ip6tables.up.rules" > /etc/network/if-pre-up.d/iptables
		else
			echo -e "#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules" > /etc/network/if-pre-up.d/iptables
		fi
		iptables-save > /etc/iptables.up.rules
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
Set_key_word() { $1 -t mangle -$3 OUTPUT -m string --string "$2" --algo bm --to 65535 -j DROP; }
Set_tcp_port() {
	[[ "$1" = "$v4iptables" ]] && $1 -t filter -$3 OUTPUT -p tcp -m multiport --dports "$2" -m state --state NEW,ESTABLISHED -j REJECT --reject-with icmp-port-unreachable
	[[ "$1" = "$v6iptables" ]] && $1 -t filter -$3 OUTPUT -p tcp -m multiport --dports "$2" -m state --state NEW,ESTABLISHED -j REJECT --reject-with tcp-reset
}
Set_udp_port() { $1 -t filter -$3 OUTPUT -p udp -m multiport --dports "$2" -j DROP; }


Set_SPAM_Code_v4(){
	while read line; do
		Set_tcp_port $v4iptables "$line" $s
		Set_udp_port $v4iptables "$line" $s
	done <<< $(cat "$firewall_port")
}

Set_SPAM_Code_v4_back(){
	for i in ${smtp_port} ${pop3_port} ${imap_port} ${other_port}
		do
		Set_tcp_port $v4iptables "$i" $s
		Set_udp_port $v4iptables "$i" $s
	done
}

Set_SPAM_Code_v4_v6(){
	while read line; do
		for j in $v4iptables $v6iptables
		do
			Set_tcp_port $j "$line" $s
			Set_udp_port $j "$line" $s
		done
	done <<< $(cat "$firewall_port")
}

Set_SPAM_Code_v4_v6_back(){
	for i in ${smtp_port} ${pop3_port} ${imap_port} ${other_port}
	do
		for j in $v4iptables $v6iptables
		do
			Set_tcp_port $j "$i" $s
			Set_udp_port $j "$i" $s
		done
	done
}
Set_PORT(){
	if [[ -n "$v4iptables" ]] && [[ -n "$v6iptables" ]]; then
		Set_tcp_port $v4iptables $PORT $s
		Set_udp_port $v4iptables $PORT $s
		Set_tcp_port $v6iptables $PORT $s
		Set_udp_port $v6iptables $PORT $s
	elif [[ -n "$v4iptables" ]]; then
		Set_tcp_port $v4iptables $PORT $s
		Set_udp_port $v4iptables $PORT $s
	fi
	Save_iptables_v4_v6
}
Set_KEY_WORDS(){
	key_word_num=$(echo -e "${key_word}"|wc -l)
	for((integer = 1; integer <= ${key_word_num}; integer++))
		do
			i=$(echo -e "${key_word}"|sed -n "${integer}p")
			Set_key_word $v4iptables "$i" $s
			[[ ! -z "$v6iptables" ]] && Set_key_word $v6iptables "$i" $s
	done
	Save_iptables_v4_v6
}
Set_BT(){
	key_word=$(cat ${firewall_txt})
	Set_KEY_WORDS
	Save_iptables_v4_v6
}
Set_SPAM(){
	if [[ -n "$v4iptables" ]] && [[ -n "$v6iptables" ]]; then
		Set_SPAM_Code_v4_v6
	elif [[ -n "$v4iptables" ]]; then
		Set_SPAM_Code_v4
	fi
	Save_iptables_v4_v6
}
Set_ALL(){
	Set_BT
	Set_SPAM
}
Ban_BT(){
	check_BT
	s="A"
	Set_BT
	clear
	msg -bar
	View_KEY_WORDS
	msg -bar
	print_center -verd "Torrent bloqueados y Palabras Claves!"
	enter
	return
}
Ban_SPAM(){
	check_SPAM
	s="A"
	Set_SPAM
	clear
	msg -bar
	View_PORT
	msg -bar
	print_center -verd "Puertos SPAM Bloqueados !"
	enter
	return
}
UnBan_BT(){
	check_BT
	s="D"
	Set_BT
	clear
	msg -bar
	View_KEY_WORDS
	msg -bar
	print_center -verd "Torrent Desbloqueados y Palabras Claves!"
	enter
	return
}
UnBan_SPAM(){
	check_SPAM
	s="D"
	Set_SPAM
	clear
	msg -bar
	View_PORT
	msg -bar
	print_center -verd "Puertos de SPAM Desbloqueados !"
	enter
	return
}

ENTER_Ban_KEY_WORDS_type(){
	Cat_KEY_WORDS
	title -ama "AGREGAR/QUITAR PALABRAS/URL/ARCHIVO"

	if [[ "${op_1[1]}" = '1' ]]; then
		txt_list=${Ban_KEY_WORDS_list}
		print_center -azu "lista de palabras claves \e[32m[ON]"
		msg -bar3
		msg -azu "${txt_list}"
	else
		txt_list=$(cat ${firewall_txt})
		print_center -azu "lista de palabras claves \e[31m[OFF]"
		msg -bar3
		msg -azu "${txt_list}"
	fi
	msg -bar3
	msg -ama "Archivo local: --file /direcion/del/archivo.txt"
	msg -ama "Archivo online: --url http://direcion.del:archivo.txt"
	msg -bar3
	#echo -e " $(msg -verm3 "╭╼╼╼╼╼╼╼╼╼╼[")$(msg -azu "ingresa Palabra/url/archivo")$(msg -verm3 "]")"
	#echo -ne " $(msg -verm3 "╰╼")\033[37;1m> "
	#read option

	in_opcion_down 'ingresa Palabra/url/archivo'
	option=$opcion

	[[ -z $option ]] && return 1

	opt=$(echo "$option"|awk -F ' ' '{print $1}')

	case $opt in
		-u|--url) opn='' && opc=$(echo "$option"|awk -F ' ' '{print $2}') && link=$(wget --no-check-certificate -t3 -T5 -qO- "${opc}")
				    for i in `echo "${link}"`; do
				   		[[ $(echo "$txt_list"|grep -w "$i") ]] && continue
				   		opn+="$i\n"
				   	done
				   	echo -e "${opn}" >> firewall_txt
				   	sed -i '/^$/d' ${firewall_txt}
				   	key_word="$(echo -e "${opn}")";;
		-f|--file) opn='' && opc=$(echo "$option"|awk -F ' ' '{print $2}')
				    for i in `cat "${opc}"`; do
				   		[[ $(echo "$txt_list"|grep -w "$i") ]] && continue
				   		opn+="$i\n"
				   	done
				   	echo -e "${opn}" >> firewall_txt
				   	sed -i '/^$/d' ${firewall_txt}
				   	key_word="$(echo -e "${opn}")";;
		*)  if [[ $(echo "$txt_list"|grep -w "$option") ]]; then
				s="D"
				sed -i "/$option/d" ${firewall_txt}
			else
				echo "$option" >> firewall_txt
			fi
			sed -i '/^$/d' ${firewall_txt}
			key_word=$option;;
	esac
}

ENTER_Ban_PORT(){
	title -ama "AGREGAR/QUITAR PUERTOS"
	Cat_PORT
	if [[ ! -z ${Ban_PORT_list} ]]; then
		port_list=${Ban_PORT_list}
		print_center -azu "LISTA DE PUERTO BLOQUEADOS \e[32m[ON]"
		msg -bar3
		echo -e "\033[1;97m${port_list}"
		msg -bar3
	else
		port_list=$(cat $firewall_port)
		print_center -azu "LISTA DE PUERTO BLOQUEADOS \e[31m[OFF]"
		msg -bar3
		echo -e "\033[1;97m${port_list}"
		msg -bar3
	fi
	if [[ ${Ban_PORT_Type_1} != "1" ]]; then
		print_center -ama "modo de ingreso de puertos"
		msg -bar3
		msg -ama " Puerto único:     \e[32m25"
		msg -ama " Multiples pertos: \e[32m25,26,465,587"
		msg -ama " Rango de puertos: \e[32m25:587"
		msg -bar3
	fi
	
	PORT=$(in_opcion "Intro se cancela por defecto")
	[[ -z "${PORT}" ]] && return 1

	if [[ $(echo "${PORT:0:1}"|grep '0\|[A-Za-z]\|,\|:\|\$\|#\|\[\|\]\|/\|?\|@\|!\|&\|(\|)\|*\|+\|;\|=\|%\|"') ]]; then
		del 1
		print_center -verm2 'formato invalido!'
		sleep 2
		return 1
	elif [[ $(echo "${PORT}"|grep '[A-Za-z]\|\$\|#\|\[\|\]\|/\|?\|@\|!\|&\|(\|)\|*\|+\|;\|=\|%\|"') ]]; then
		del 1
		print_center -verm2 'formato invalido!'
		sleep 2
		return 1
	fi

	if [[ $(echo "${port_list}"|grep -w "$PORT") ]]; then
		s="D"
		delP="$PORT"
		delR=$(echo "${port_list}"|grep -w "$delP")


		if [[ $(echo "$delR"|grep ':') ]]; then
			sed -i "/:$delP/d" ${firewall_port}
			sed -i "/$delP:/d" ${firewall_port}
			PORT="$delR"
		elif [[ $(echo "$delR"|grep ',') ]]; then
			sed -i "s/,$delP//g" ${firewall_port}
			sed -i "s/$delP,//g" ${firewall_port}

			PORT="$delR"
			[[ "${op_2[1]}" = '1' ]] && Set_PORT

			PORT=$(echo "$delR"|sed "/,$delP/d"|sed "/$delP,/d")
			s="A"
		else
			sed -i "/$delP/d" ${firewall_port}
			PORT="$delR"
		fi
	else
		s="A"
		sed -i '/^$/d' ${firewall_port}
		echo "$PORT" >> ${firewall_port}
	fi
	return 0
}

Ban_PORT(){
	s="A"
	while true; do
		ENTER_Ban_PORT
		[[ $? -eq 1 ]] && break
		[[ "${op_2[1]}" = '1' ]] && [[ -z $PORT ]] && Set_PORT
	done
}

Ban_KEY_WORDS(){
	s="A"
	while true; do
		ENTER_Ban_KEY_WORDS_type
		[[ $? -eq 1 ]] && break
		[[ "${op_1[1]}" = '1' ]] && Set_KEY_WORDS
	done
}

check_iptables(){
	v4iptables=`iptables -V`
	v6iptables=`ip6tables -V`
	if [[ ! -z ${v4iptables} ]]; then
		v4iptables="iptables"
		if [[ ! -z ${v6iptables} ]]; then
			v6iptables="ip6tables"
		fi
	else
		print_center -ama "El firewall de iptables no está instalado!\nPor favor, instale el firewall de iptables：\nCentOS Sistema： yum install iptables -y\nDebian/Ubuntu Sistema： apt-get install iptables -y"
	fi
}

menu_fw(){
	check_sys
	check_iptables

	unset opcion

	check_BT; op_1=($([[ -z ${BT_KEY_WORDS} ]] && msg -verm2 "[OFF]" || msg -verd "[ON]") $([[ -z ${BT_KEY_WORDS} ]] && echo '0' || echo '1'))
	check_SPAM; op_2=($([[ -z ${SPAM_PORT} ]] && msg -verm2 "[OFF]" || msg -verd "[ON]") $([[ -z ${SPAM_PORT} ]] && echo '0' || echo '1'))

	title -ama "Panel Firewall By @Rufu99"
 menu_func "Bloq/Desbl Torrent, Palabras Clave ${op_1}" \
 "-bar Bloq/Desbl Puertos SPAM ${op_2}" \
 "Bloq/Desbl Puerto SPAM custom" \
 "-bar Bloq/Desbl Palabras Clave custom" \
 "Ver lista de reglas firewall"

 back

 	opcion=$(selection_fun 5)
 	case ${opcion} in
 		1)if [[ "${op_1[1]}" = '1' ]]; then UnBan_BT; else Ban_BT; fi;;
 		2)if [[ "${op_2[1]}" = '1' ]]; then UnBan_SPAM; else Ban_SPAM; fi;;
 		3)Ban_PORT;;
 		4)Ban_KEY_WORDS;;
 		5)View_ALL && enter;;
 		0)return 1;;
 	esac
}

while [[ $? -eq 0 ]]; do
	menu_fw
done
