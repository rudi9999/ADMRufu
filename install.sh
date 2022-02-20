#!/bin/bash

module="$(pwd)/module"
rm -rf ${module}
wget -O ${module} "https://raw.githubusercontent.com/rudi9999/Herramientas/main/module/module" &>/dev/null
[[ ! -e ${module} ]] && exit
chmod +x ${module} &>/dev/null
source ${module}

ADMRufu="/etc/ADMRufu" && [[ ! -d ${ADMRufu} ]] && mkdir ${ADMRufu}
ADM_inst="${ADMRufu}/install" && [[ ! -d ${ADM_inst} ]] && mkdir ${ADM_inst}
SCPinstal="$HOME/install"

rm -rf /etc/localtime &>/dev/null
ln -s /usr/share/zoneinfo/America/Argentina/Tucuman /etc/localtime &>/dev/null
rm $(pwd)/$0 &> /dev/null

stop_install(){
 	title "INSTALACION CANCELADA"
 	exit
 }

time_reboot(){
  print_center -ama "REINICIANDO VPS EN $1 SEGUNDOS"
  REBOOT_TIMEOUT="$1"
  
  while [ $REBOOT_TIMEOUT -gt 0 ]; do
     print_center -ne "-$REBOOT_TIMEOUT-\r"
     sleep 1
     : $((REBOOT_TIMEOUT--))
  done
  reboot
}

os_system(){
  system=$(cat -n /etc/issue |grep 1 |cut -d ' ' -f6,7,8 |sed 's/1//' |sed 's/      //')
  distro=$(echo "$system"|awk '{print $1}')

  case $distro in
    Debian)vercion=$(echo $system|awk '{print $3}'|cut -d '.' -f1);;
    Ubuntu)vercion=$(echo $system|awk '{print $2}'|cut -d '.' -f1,2);;
  esac
}

repo(){
  link="https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Repositorios/$1.list"
  case $1 in
    8|9|10|11|16.04|18.04|20.04|20.10|21.04|21.10|22.04)wget -O /etc/apt/sources.list ${link} &>/dev/null;;
  esac
}

dependencias(){
	soft="sudo zip unzip ufw curl python python3 python3-pip openssl screen cron iptables lsof nano at mlocate gawk grep bc jq curl npm nodejs socat netcat netcat-traditional net-tools cowsay figlet lolcat"

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
			sleep 2
			tput cuu1 && tput dl1
			print_center -ama "aplicando fix a $i"
			dpkg --configure -a &>/dev/null
			sleep 2
			tput cuu1 && tput dl1

			msg -nazu "       instalando $i$(msg -ama "$pts")"
			if apt install $i -y &>/dev/null ; then
				msg -verd "INSTALL"
			else
				msg -verm2 "FAIL"
			fi
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
    clear
    msg -bar
    print_center -verm2 "¡LA IP $(wget -qO- ipv4.icanhazip.com) NO ESTA AUTORIZADA!"
    print_center -ama "CONTACTE A @Rufu99"
    msg -bar
  	rm ${ADMRufu}
    [[ -e $HOME/lista-arq ]] && rm $HOME/lista-arq
    exit
  } || {
  ### INTALAR VERCION DE SCRIPT
  ver=$(curl -sSL "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/vercion")
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
		menu|menu_inst.sh|tool_extras.sh|chekup.sh)ARQ="${ADMRufu}";;
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

install_start(){
  title "INSTALADOR ADMRufu"
  print_center -ama "A continuacion se actualizaran los paquetes\ndel systema. Esto podria tomar tiempo,\ny requerir algunas preguntas\npropias de las actualizaciones."
  msg -bar3
  msg -ne " Desea continuar? [S/N]: "
  read opcion
  [[ "$opcion" != @(s|S) ]] && stop_install
  title "INSTALADOR ADMRufu"
  os_system
  repo "${vercion}"
  apt update -y; apt upgrade -y
  echo 'wget -O /root/install.sh "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/install.sh"; chmod +x /root/install.sh; /root/install.sh --continue' >> /root/.bashrc
  title "INSTALADOR ADMRufu"
  print_center -ama "La instalacion continuara\ndespues del reinicio!!!"
  msg -bar
  time_reboot "15"
}

install_continue(){
  sed -i '/Rufu/d' /root/.bashrc
  sleep 2
  os_system
  title "INSTALADOR ADMRufu"
  print_center -ama "$distro $vercion"
  print_center -verd "INSTALANDO DEPENDENCIAS"
  msg -bar3
  dependencias
  msg -bar3
  print_center -azu "Removiendo paquetes obsoletos"
  apt autoremove -y &>/dev/null
  sleep 2
  tput cuu1 && tput dl1
  print_center -ama "si algunas de las dependencias falla!!!\nal terminar, puede intentar instalar\nla misma manualmente usando el siguiente comando\napt install nom_del_paquete"
  enter
}

while :
do
  case $1 in
    -s|--start)install_start;;
    -c|--continue)install_continue; break;;
    *)exit;;
  esac
done

title "INSTALADOR ADMRufu"
fun_ip
while [[ ! $Key ]]; do
	echo -e "  $(msg -verm3 "╭╼╼╼╼╼╼╼╼╼╼╼╼╼╼╼╼[")$(msg -azu "INGRESA TU KEY")$(msg -verm3 "]")"
	echo -ne "  $(msg -verm3 "╰╼")\033[37;1m>\e[32m\e[1m "
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
   msg -nama "Descarga de archivos...  "
   for arqx in $(cat $HOME/lista-arq); do
    wget --no-check-certificate -O ${SCPinstal}/${arqx} ${IP}:81/${REQUEST}/${arqx} > /dev/null 2>&1 && {
    verificar_arq "${arqx}"
   } || {
    msg -verm2 "fallida!!!"
    sleep 2s
    error_fun
   }
   done
   msg -verd "completa!!!"
   sleep 2s
   rm $HOME/lista-arq
   [[ -d ${SCPinstal} ]] && rm -rf ${SCPinstal}
   rm -rf /usr/bin/menu
   rm -rf /usr/bin/adm
   rm -rf /usr/bin/ADMRufu
   echo "${ADMRufu}/menu" > /usr/bin/menu && chmod +x /usr/bin/menu
   echo "${ADMRufu}/menu" > /usr/bin/adm && chmod +x /usr/bin/adm
   echo "${ADMRufu}/menu" > /usr/bin/ADMRufu && chmod +x /usr/bin/ADMRufu
   echo 'if [[ $(echo $PATH|grep "/usr/games") = "" ]]; then
PATH=$PATH:/usr/games
fi' >> /etc/bash.bashrc

   echo '[[ $UID = 0 ]] && screen -dmS up /etc/ADMRufu/chekup.sh' >> /etc/bash.bashrc
   echo 'v=$(cat /etc/ADMRufu/vercion)' >> /etc/bash.bashrc
   echo '[[ -e /etc/ADMRufu/new_vercion ]] && up=$(cat /etc/ADMRufu/new_vercion) || up=$v' >> /etc/bash.bashrc
   echo -e "[[ \$(date '+%s' -d \$up) -gt \$(date '+%s' -d \$(cat /etc/ADMRufu/vercion)) ]] && v2=\"Nueva Vercion disponible: \$v >>> \$up\" || v2=\"Script Vercion: \$v\"" >> /etc/bash.bashrc
   echo '[[ -e "/etc/ADMRufu/tmp/message.txt" ]] && mess1="$(less /etc/ADMRufu/tmp/message.txt)"' >> /etc/bash.bashrc
   echo '[[ -z "$mess1" ]] && mess1="@Rufu99"' >> /etc/bash.bashrc
   echo 'clear && echo -e "\n$(figlet -f big.flf "  ADMRufu")\n        RESELLER : $mess1 \n\n   Para iniciar ADMRufu escriba:  menu \n\n   $v2\n\n"|lolcat' >> /etc/bash.bashrc

   update-locale LANG=en_US.UTF-8 LANGUAGE=en
   clear
   title "-- ADMRufu INSTALADO --"
 else
  [[ -e $HOME/lista-arq ]] && rm $HOME/lista-arq
  clear
  msg -bar
  print_center -verm2 "KEY INVALIDA"
  msg -bar
  print_center -ama "Esta key no es valida o ya fue usada"
  print_center -ama "Contacta con @Rufu99"
  msg -bar
  rm -rf ${module}
  exit
fi
mv -f ${module} /etc/ADMRufu/module
time_reboot "10"