#!/bin/bash

module="$(pwd)/module"
rm -rf ${module}
wget -O ${module} "https://raw.githubusercontent.com/rudi9999/Herramientas/main/module/module" &>/dev/null
[[ ! -e ${module} ]] && exit
chmod +x ${module} &>/dev/null
source ${module}

CTRL_C(){
  rm -rf ${module}; exit
}

if [[ ! $(id -u) = 0 ]]; then
  clear
  msg -bar
  print_center -ama "ERROR DE EJECUCION"
  msg -bar
  print_center -ama "DEVE EJECUTAR DESDE EL USUSRIO ROOT"
  msg -bar
  CTRL_C
fi

trap "CTRL_C" INT TERM EXIT

ADMRufu="/etc/ADMRufu" && [[ ! -d ${ADMRufu} ]] && mkdir ${ADMRufu}
ADM_inst="${ADMRufu}/install" && [[ ! -d ${ADM_inst} ]] && mkdir ${ADM_inst}
tmp="${ADMRufu}/tmp" && [[ ! -d ${tmp} ]] && mkdir ${tmp}
SCPinstal="$HOME/install"

#rm -rf /etc/localtime &>/dev/null
#ln -s /usr/share/zoneinfo/America/Argentina/Tucuman /etc/localtime &>/dev/null
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

repo_install(){
  link="https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Repositorios/$VERSION_ID.list"
  case $VERSION_ID in
    8*|9*|10*|11*|16.04*|18.04*|20.04*|20.10*|21.04*|21.10*|22.04*) [[ ! -e /etc/apt/sources.list.back ]] && cp /etc/apt/sources.list /etc/apt/sources.list.back
                                                                    wget -O /etc/apt/sources.list ${link} &>/dev/null;;
  esac
}

dependencias(){
	soft="sudo bsdmainutils zip unzip ufw curl python python3 python3-pip openssl screen cron iptables lsof nano at mlocate gawk grep bc jq curl npm nodejs socat netcat netcat-traditional net-tools cowsay figlet lolcat"

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
			if [[ $install = "python" ]]; then
				pts=$(echo ${pts:1})
				msg -nazu "      instalando python2 $(msg -ama "$pts")"
				if apt install python2 -y &>/dev/null ; then
					[[ ! -e /usr/bin/python ]] && ln -s /usr/bin/python2 /usr/bin/python
					msg -verd "INSTALL"
				else
					msg -verm2 "FAIL"
				fi
				continue
			fi
			print_center -ama "aplicando fix a $install"
			dpkg --configure -a &>/dev/null
			sleep 2
			del 1
			msg -nazu "      instalando $install $(msg -ama "$pts")"
			if apt install $install -y &>/dev/null ; then
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
      "_")txt[$i]="@";;
      "@")txt[$i]="_";;
      "-")txt[$i]="K";;
      "K")txt[$i]="-";;
      "1")txt[$i]="f";;
      "2")txt[$i]="e";;
      "3")txt[$i]="d";;
      "4")txt[$i]="c";;
      "5")txt[$i]="b";;
      "6")txt[$i]="a";;
      "7")txt[$i]="9";;
      "8")txt[$i]="8";;
      "9")txt[$i]="7";;
      "a")txt[$i]="6";;
      "b")txt[$i]="5";;
      "c")txt[$i]="4";;
      "d")txt[$i]="3";;
      "e")txt[$i]="2";;
      "f")txt[$i]="1";;
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
		menu|menu_inst.sh|tool_extras.sh|chekup.sh|bashrc)ARQ="${ADMRufu}";;
    ADMRufu)ARQ="/usr/bin";;
    message.txt)ARQ="${tmp}";;
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

post_reboot(){
  echo 'wget -O /root/install.sh "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/install.sh"; clear; sleep 2; chmod +x /root/install.sh; /root/install.sh --continue' >> /root/.bashrc
  title "INSTALADOR ADMRufu"
  print_center -ama "La instalacion continuara\ndespues del reinicio!!!"
  msg -bar
}

install_start(){
  title "INSTALADOR ADMRufu"
  print_center -ama "A continuacion se actualizaran los paquetes\ndel systema. Esto podria tomar tiempo,\ny requerir algunas preguntas\npropias de las actualizaciones."
  msg -bar3
  read -rp "$(msg -verm2 " Desea continuar? [S/N]:") " -e -i S opcion
  [[ "$opcion" != @(s|S) ]] && stop_install
  title "INSTALADOR ADMRufu"
  print_center -ama 'Esto modificara la hora y fecha automatica\nsegun la Zona horaria establecida.'
  msg -bar
  read -rp "$(msg -ama " Modificar la zona horaria? [S/N]:") " -e -i N opcion
  [[ "$opcion" != @(n|N) ]] && source <(curl -sSL "https://raw.githubusercontent.com/rudi9999/ADMRufu/main/online/timeZone.sh")
  title "INSTALADOR ADMRufu"
  repo_install
  mysis=$(echo "$VERSION_ID"|cut -d '.' -f1)
  #[[ ! $mysis = '22' ]] && add-apt-repository -y ppa:ondrej/php &>/dev/null
  apt update -y; apt upgrade -y
  [[ "$VERSION_ID" = '9' ]] && source <(curl -sL https://deb.nodesource.com/setup_10.x)
}

install_continue(){
  title "INSTALADOR ADMRufu"
  print_center -ama "$PRETTY_NAME"
  print_center -verd "INSTALANDO DEPENDENCIAS"
  msg -bar3
  dependencias
  msg -bar3
  print_center -azu "Removiendo paquetes obsoletos"
  apt autoremove -y &>/dev/null
  [[ "$VERSION_ID" = '9' ]] && apt remove unscd -y &>/dev/null
  sleep 2
  tput cuu1 && tput dl1
  print_center -ama "si algunas de las dependencias falla!!!\nal terminar, puede intentar instalar\nla misma manualmente usando el siguiente comando\napt install nom_del_paquete"
  enter
}

source /etc/os-release; export PRETTY_NAME

while :
do
  case $1 in
    -s|--start)install_start; post_reboot; time_reboot "15";;
    -c|--continue)rm /root/install.sh &> /dev/null
                  sed -i '/Rufu/d' /root/.bashrc
                  install_continue
                  break;;
    -u|--update)install_start
                rm -rf /etc/ADMRufu/tmp/style
                install_continue
                break;;
    -t|--test)break;;
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
  title -ama '[Proyect by @Rufu99]'
  print_center -ama 'INSTALANDO SCRIPT ADMRufu'
  sleep 2; del 1

   REQUEST=$(ofus "$Key"|cut -d'/' -f2)
   [[ ! -d ${SCPinstal} ]] && mkdir ${SCPinstal}
   print_center -ama 'Descarga de archivos.....'
   for arqx in $(cat $HOME/lista-arq); do
    wget --no-check-certificate -O ${SCPinstal}/${arqx} ${IP}:81/${REQUEST}/${arqx} > /dev/null 2>&1 && {
    verificar_arq "${arqx}"
   } || {
    del 1
    print_center -verm2 'Instalacion fallida'
    sleep 2s
    error_fun
   }
   done

   autoStart="${ADMRufu}/bin" && [[ ! -d $autoStart ]] && mkdir $autoStart
   varEntorno="${ADMRufu}/sbin" && [[ ! -d $varEntorno ]] && mkdir $varEntorno
   
   wget -O $autoStart/autoStart 'https://github.com/rudi9999/ADMRufu/raw/main/Utils/autoStart/autoStart' &>/dev/null; chmod +x $autoStart/autoStart
   wget -O $autoStart/auto-update 'https://github.com/rudi9999/ADMRufu/raw/main/Utils/auto-update/auto-update' &>/dev/null; chmod +x $autoStart/auto-update
   
   wget -O ${ADMRufu}/install/cmd 'https://github.com/rudi9999/ADMRufu/raw/main/Utils/mine_port/cmd' &>/dev/null; chmod +x ${ADMRufu}/install/cmd
   wget -O ${ADMRufu}/install/udp-custom 'https://github.com/rudi9999/ADMRufu/raw/main/Utils/udp-custom/udp-custom' &>/dev/null; chmod +x ${ADMRufu}/install/udp-custom
   wget -O ${ADMRufu}/install/psiphon-manager 'https://github.com/rudi9999/ADMRufu/raw/main/Utils/psiphon/psiphon-manager' &>/dev/null; chmod +x ${ADMRufu}/install/psiphon-manager
   wget -O ${varEntorno}/dropBear 'https://github.com/rudi9999/ADMRufu/raw/main/Utils/dropBear/dropBear' &>/dev/null; chmod +x ${varEntorno}/dropBear
   
   wget -O ${varEntorno}/monitor 'https://github.com/rudi9999/ADMRufu/raw/main/Utils/user-manager/monitor/monitor' &>/dev/null; chmod +x ${varEntorno}/monitor
   wget -O ${varEntorno}/online 'https://github.com/rudi9999/ADMRufu/raw/main/Utils/user-manager/monitor/online/online' &>/dev/null; chmod +x ${varEntorno}/online

   if [[ -e $autoStart/autoStart ]]; then
    $autoStart/autoStart -e /etc/ADMRufu/autoStart
   fi

   del 1

   data=$(ofus $Key|awk -F '/' '{print $2}')

   export IDTG=$(echo $data|cut -d '_' -f2)
   export IDKEY=$(echo $data|cut -d '_' -f1)

   ADMRufu -i &>/dev/null

   print_center -verd 'Instalacion completa'
   sleep 2s
   rm $HOME/lista-arq
   [[ -d ${SCPinstal} ]] && rm -rf ${SCPinstal}
   rm -rf /usr/bin/menu
   rm -rf /usr/bin/adm
   ln -s /usr/bin/ADMRufu /usr/bin/menu
   ln -s /usr/bin/ADMRufu /usr/bin/adm
   sed -i '/Rufu/d' /etc/bash.bashrc
   sed -i '/Rufu/d' /root/.bashrc
   echo '[[ -e /etc/ADMRufu/bashrc ]] && source /etc/ADMRufu/bashrc' >> /etc/bash.bashrc
   update-locale LANG=en_US.UTF-8 LANGUAGE=en
   [[ ! $(cat /etc/shells|grep "/bin/false") ]] && echo -e "/bin/false" >> /etc/shells
   clear
   title "-- ADMRufu INSTALADO --"
 else
  [[ -e $HOME/lista-arq ]] && rm $HOME/lista-arq
  title -verm2 'KEY INVALIDA'
  print_center -ama 'Esta key no es valida o ya fue usada\nContacta con @Rufu99'
  msg -bar
  rm -rf ${module}
  exit
fi
mv -f ${module} /etc/ADMRufu/module
time_reboot "10"
