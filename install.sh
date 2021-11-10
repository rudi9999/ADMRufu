#!/bin/bash

ADMRufu="/etc/ADMRufu" && [[ ! -d ${ADMRufu} ]] && mkdir ${ADMRufu}
ADM_inst="${ADMRufu}/install" && [[ ! -d ${ADM_inst} ]] && mkdir ${ADM_inst}
SCPinstal="$HOME/install"

rm -rf /etc/localtime &>/dev/null
ln -s /usr/share/zoneinfo/America/Argentina/Tucuman /etc/localtime &>/dev/null
rm $(pwd)/$0 &> /dev/null

# Funcoes Globais
msg () {
local colors="${ADM_tmp}/ADM-color"

if [[ ! -e $colors ]]; then
COLOR[0]='\033[1;37m' #BRAN='\033[1;37m'
COLOR[1]='\e[31m' #VERMELHO='\e[31m'
COLOR[2]='\e[32m' #VERDE='\e[32m'
COLOR[3]='\e[33m' #AMARELO='\e[33m'
COLOR[4]='\e[34m' #AZUL='\e[34m'
COLOR[5]='\e[91m' #MAGENTA='\e[35m'
COLOR[6]='\033[1;97m' #MAG='\033[1;36m'
COLOR[7]='\e[36m' #teal='\e[36m'
COLOR[8]='\e[30m' #negro='\e[30m'
else
local COL=0
for number in $(cat $colors); do
case $number in
1)COLOR[$COL]='\033[1;37m';;
2)COLOR[$COL]='\e[31m';;
3)COLOR[$COL]='\e[32m';;
4)COLOR[$COL]='\e[33m';;
5)COLOR[$COL]='\e[34m';;
6)COLOR[$COL]='\e[35m';;
7)COLOR[$COL]='\033[1;36m';;
esac
let COL++
done
fi
NEGRITO='\e[1m'
SEMCOR='\e[0m'
 case $1 in
  -ne)   cor="${COLOR[1]}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
  -nazu) cor="${COLOR[6]}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
  -nverd)cor="${COLOR[2]}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
  -nama) cor="${COLOR[3]}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
  -ama)  cor="${COLOR[3]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -verm) cor="${COLOR[3]}${NEGRITO}[!] ${COLOR[1]}" && echo -e "${cor}${2}${SEMCOR}";;
  -verm2)cor="${COLOR[1]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -teal) cor="${COLOR[7]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -teal2)cor="${COLOR[7]}" && echo -e "${cor}${2}${SEMCOR}";;
  -blak) cor="${COLOR[8]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -blak2)cor="${COLOR[8]}" && echo -e "${cor}${2}${SEMCOR}";;
  -azu)  cor="${COLOR[6]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -verd) cor="${COLOR[2]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -bra)  cor="${COLOR[0]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -bar)  cor="${COLOR[1]}=====================================================" && echo -e "${SEMCOR}${cor}${SEMCOR}";;
  -bar2) cor="${COLOR[7]}=====================================================" && echo -e "${SEMCOR}${cor}${SEMCOR}";;
  -bar3) cor="${COLOR[1]}-----------------------------------------------------" && echo -e "${SEMCOR}${cor}${SEMCOR}";;
  -bar4) cor="${COLOR[7]}-----------------------------------------------------" && echo -e "${SEMCOR}${cor}${SEMCOR}";;
 esac
}

print_center(){
    local x
    local y
    #text="$*"
    text="$2"
    #x=$(( ($(tput cols) - ${#text}) / 2))
    x=$(( ( 54 - ${#text}) / 2))
    echo -ne "\E[6n";read -sdR y; y=$(echo -ne "${y#*[}" | cut -d';' -f1)
    #echo -e "\033[${y};${x}f$*"
    msg "$1" "\033[${y};${x}f$2"
}

title(){
    clear
    msg -bar
    print_center -azu "$1"
    msg -bar
 }

 stop_install(){
 	title "INSTALACION CANCELADA"
 	exit
 }

os_system(){
  system=$(cat -n /etc/issue |grep 1 |cut -d' ' -f6,7,8 |sed 's/1//' |sed 's/      //'|awk '{print $1, $2}')

  nombre=$(echo $system|awk '{print $1}')
  vercion=$(echo $system|awk '{print $2}'|cut -d '.' -f1)

  if [[ "$nombre" = "Ubuntu" ]]; then
  	if [[ "$vercion" = "14" ]]; then
  		ver="14"
  	elif [[ "$vercion" = "16" ]]; then
  		ver="16"
  	elif [[ "$vercion" = "18" ]]; then
  		ver="18"
  	elif [[ "$vercion" = "20" ]]; then
  		ver="20"
  	fi
  else
  	ver="otro"
  fi

  case $ver in
  	14);;
  	16)wget -O /etc/apt/sources.list https://github.com/rudi9999/VPS-MX-8.1/raw/master/Repositorios/16.04/sources.list &> /dev/null;;
  	18)wget -O /etc/apt/sources.list https://github.com/rudi9999/VPS-MX-8.1/raw/master/Repositorios/18.04/sources.list &> /dev/null;;
  	20);;
  esac
  print_center -ama "$system"
}

dependencias(){
  apt update -y &>/dev/null
	soft="zip unzip ufw curl python python3 python3-pip screen lsof nano at mlocate gawk grep bc jq curl npm nodejs socat netcat netcat-traditional net-tools cowsay figlet lolcat"

	for i in $soft; do
		leng="${#i}"
		puntos=$(( 21 - $leng))
		pts="."
		for (( a = 0; a < $puntos; a++ )); do
			pts+="."
		done

		msg -nazu "       instalando $i$(msg -ama "$pts")"
		if apt install $i -y &>/dev/null ; then
			msg -verd "INSTALL"
		else
			msg -verm2 "FAIL"
		fi
	done
}

ofus(){
	unset server
	server=$(echo ${txt_ofuscatw}|cut -d':' -f1)
	unset txtofus
	number=$(expr length $1)
	for((i=1; i<$number+1; i++)); do
		txt[$i]=$(echo "$1" | cut -b $i)
		case ${txt[$i]} in
			".")txt[$i]="*";;
			"*")txt[$i]=".";;
			"1")txt[$i]="@";;
			"@")txt[$i]="1";;
			"2")txt[$i]="?";;
			"?")txt[$i]="2";;
			"4")txt[$i]="%";;
			"%")txt[$i]="4";;
			"-")txt[$i]="K";;
			"K")txt[$i]="-";;
		esac
		txtofus+="${txt[$i]}"
	done
	echo "$txtofus" | rev
}

function_verify () {
  permited=$(curl -sSL "https://raw.githubusercontent.com/rudi9999/Control/master/Control-IP")
  [[ $(echo $permited|grep "${IP}") = "" ]] && {
  	echo -e "\n\n\n\033[1;31m====================================================="
  	echo -e "\033[1;31m       ¡LA IP $(wget -qO- ipv4.icanhazip.com) NO ESTA AUTORIZADA!"
  	echo -e "\033[1;31m                CONTACTE A @Rufu99"
  	echo -e "\033[1;31m=====================================================\n\n\n"
  	exit
  	echo "rm ${ADMRufu}"
  } || {
  ### INTALAR VERCION DE SCRIPT
  ver=$(curl -sSL "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/vercion.txt")
  echo "$ver" > ${ADMRufu}/vercion
  }
}

fun_ip(){
    MEU_IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
    MEU_IP2=$(wget -qO- ipv4.icanhazip.com)
    [[ "$MEU_IP" != "$MEU_IP2" ]] && IP="$MEU_IP2" || IP="$MEU_IP"
}

verificar_arq(){
	unset ARQ
	case $1 in
		menu|menu_inst.sh|tool_extras.sh)ARQ="${ADMRufu}";;
		*)ARQ="${ADM_inst}";;
	esac
	mv -f ${SCPinstal}/$1 ${ARQ}/$1
	chmod +x ${ARQ}/$1
}

error_fun(){
	msg -bar3
	print_center -verm "ERROR de enlace VPS<-->GENERADOR"
	msg -bar3
	[[ -d ${SCPinstal} ]] && rm -rf ${SCPinstal}
	exit
}

title "INSTALADOR ADMRufu"
msg -ama " A continuacion se procede a actualizar los paquetes
 del systema, esto podria tomar un tiempo y requerir
 algunas preguntas propias de las actualizaciones."
msg -bar3
msg -ne " Desea continuar? [S/N]: "
read opcion
[[ "$opcion" != @(s|S) ]] && stop_install
title "INSTALADOR ADMRufu"
add-apt-repository universe
apt update -y
apt upgrade -y
title "INSTALADOR ADMRufu"
os_system
print_center -verd "INSTALANDO DEPENDENCIAS"
msg -bar3
dependencias
msg -bar
msg -ama "       si algunas de las dependencias falla!!!
        al finalizar, puede intentar instalar
  la misma manualmente usando el siguiente comando"
print_center -ama "apt install nom_del_paquete"
msg -bar
print_center -verm2 "ENTER PARA CONTINUAR"
read foo
title "INSTALADOR ADMRufu"
fun_ip
while [[ ! $Key ]]; do
	print_center -teal "-INGRESA TU KEY-"
	echo -ne "\e[32m\e[1m    "
	read Key
done
msg -bar3
msg -ne " Verificando Key: "
cd $HOME
wget -O $HOME/lista-arq $(ofus "$Key")/$IP > /dev/null 2>&1 && msg -verd "Key Completa" || {
   msg -verm2 "Key Invalida"
   msg -bar
   [[ -e $HOME/lista-arq ]] && rm $HOME/lista-arq
   exit
   }
msg -bar3

IP=$(ofus "$Key" | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}') && echo "$IP" > /usr/bin/vendor_code
sleep 1s
function_verify

if [[ -e $HOME/lista-arq ]] && [[ ! $(cat $HOME/lista-arq|grep "KEY INVALIDA!") ]]; then

   msg -verd " INSTALANDO SCRIPT ADMRufu... $(msg -ama "[Proyect by @Rufu99]")"
   REQUEST=$(ofus "$Key"|cut -d'/' -f2)
   [[ ! -d ${SCPinstal} ]] && mkdir ${SCPinstal}

   for arqx in $(cat $HOME/lista-arq); do
   	echo -ne " $(msg -ama "Descargando:") $(msg -verm2 "[$arqx]") "
   	wget --no-check-certificate -O ${SCPinstal}/${arqx} ${IP}:81/${REQUEST}/${arqx} > /dev/null 2>&1 && {
    echo -e "$(msg -verm2 "-") $(msg -verd "INSTALL")"
    verificar_arq "${arqx}"
   } || {
    echo -e "$(msg -verm2 "-") $(msg -verd "FAIL")"
    error_fun
   }
   done

   sleep 1s
   rm $HOME/lista-arq
   [[ -d ${SCPinstal} ]] && rm -rf ${SCPinstal}
   rm -rf /usr/bin/menu
   rm -rf /usr/bin/adm
   rm -rf /usr/bin/ADMRufu
   echo "${ADMRufu}/menu" > /usr/bin/menu && chmod +x /usr/bin/menu
   echo "${ADMRufu}/menu" > /usr/bin/adm && chmod +x /usr/bin/adm
   echo "${ADMRufu}/menu" > /usr/bin/ADMRufu && chmod +x /usr/bin/ADMRufu

   echo '[[ -e "/etc/ADMRufu/tmp/message.txt" ]] && mess1="$(less /etc/ADMRufu/tmp/message.txt)"' >> /etc/bash.bashrc
   echo '[[ -z "$mess1" ]] && mess1="@Rufu99"' >> /etc/bash.bashrc
   echo 'clear && echo -e "\n$(figlet -f big.flf "  ADMRufu")\n        RESELLER : $mess1 \n\n   Para iniciar ADMRufu escriba:  menu \n\n"|lolcat' >> /etc/bash.bashrc

   clear
   title "-- ADMRufu INSTALADO --"
 else
    invalid_key
fi

REBOOT=1
REBOOT_TIMEOUT=20

if [ "$REBOOT" = "1" ]; then
	print_center -ama "REINICIANDO VPS EN 20 SEGUNDOS"
	
	while [ $REBOOT_TIMEOUT -gt 0 ]; do
	   print_center -ne "-$REBOOT_TIMEOUT-\r"
	   sleep 1
	   : $((REBOOT_TIMEOUT--))
	done
	reboot
fi
