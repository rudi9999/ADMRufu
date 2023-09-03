#!/bin/bash

cache_ram() {
	title -ama "REFRESCANDO CACHE Y RAM"
  (
    VE="\033[1;33m" && MA="\033[1;31m" && DE="\033[1;32m"

    while [[ ! -e /tmp/abc ]]; do
      A+="#"
      echo -e "${VE}[${MA}${A}${VE}]" >&2
      sleep 0.3s
      tput cuu1 && tput dl1
    done

    echo -e "${VE}[${MA}${A}${VE}] - ${DE}[100%]" >&2
    rm /tmp/abc
    ) &
  sudo echo 3 > /proc/sys/vm/drop_caches &>/dev/null
  sleep 1s
  sysctl -w vm.drop_caches=3 &>/dev/null
  apt-get autoclean -y &>/dev/null
  sleep 1s
  apt-get clean -y &>/dev/null
  rm /tmp/* &>/dev/null
  touch /tmp/abc
  sleep 0.5s
  msg -bar
  print_center -verd "Cache/Ram limpiada con Exito!"
  msg -bar

  if [[ ! -z $(crontab -l|grep -w "vm.drop_caches=3") ]]; then
    msg -azu " Tarea programada cada $(msg -verd "[ $(crontab -l|grep -w "vm.drop_caches=3"|awk '{print $2}'|sed $'s/[^[:alnum:]\t]//g')HS ]")"
    msg -bar
    while :
    do
    echo -ne "$(msg -azu " Quitar tarea programada [S/N]: ")" && read t_ram
    tput cuu1 && tput dl1
    case $t_ram in
      s|S) crontab -l > /root/cron && sed -i '/vm.drop_caches=3/ d' /root/cron && crontab /root/cron && rm /root/cron
           msg -azu " Tarea automatica removida!" && msg -bar && sleep 2
           return 1;;
      n|N)return 1;;
      *)msg -azu " Selecciona S para si, N para no" && sleep 2 && tput cuu1 && tput dl1;;
    esac
    done
  fi 

  echo -ne "$(msg -azu "Desea programar una tarea automatica [s/n]:") "
  read c_ram
  if [[ $c_ram = @(s|S|y|Y) ]]; then
    tput cuu1 && tput dl1
    echo -ne "$(msg -azu " PERIODO DE EJECUCION DE LA TAREA [1-12HS]:") "
    read ram_c
    if [[ $ram_c =~ $numero ]]; then
      crontab -l > /root/cron
      echo "0 */$ram_c * * * sudo sysctl -w vm.drop_caches=3 > /dev/null 2>&1" >> /root/cron
      crontab /root/cron
      rm /root/cron
      tput cuu1 && tput dl1
      msg -azu " Tarea automatica programada cada: $(msg -verd "${ram_c}HS")" && msg -bar && sleep 2
    else
      tput cuu1 && tput dl1
      msg -verm2 " ingresar solo numeros entre 1 y 12"
      sleep 2
      msg -bar
    fi
  fi
  return 1
}

new_banner(){
  clear
  local="/etc/bannerssh"
  chk=$(cat /etc/ssh/sshd_config | grep Banner)
  if [ "$(echo "$chk" | grep -v "#Banner" | grep Banner)" != "" ]; then
    local=$(echo "$chk" |grep -v "#Banner" | grep Banner | awk '{print $2}')
  else
    echo "" >> /etc/ssh/sshd_config
    echo "Banner /etc/bannerssh" >> /etc/ssh/sshd_config
    local="/etc/bannerssh"
  fi
  title -ama "Instalador del BANNER-SSH/DROPBEAR"
  in_opcion_down "Escriba el BANNER de preferencia en HTML"
  msg -bar
  if [[ "${opcion}" ]]; then
    rm -rf $local  > /dev/null 2>&1
    echo "$opcion" > $local
    [[ ! -e ${ADM_tmp}/message.txt ]] && echo "@Rufu99" > ${ADM_tmp}/message.txt
    credi="$(less ${ADM_tmp}/message.txt)"
    echo '<h4 style=text-align:center><font color="#047980">A</font><font color="#0d6e74">D</font><font color="#006462">M</font><font color="#185260">R</font><font color="#006462">u</font><font color="#0d6e74">f</font><font color="#047980">u</font><br><font color="#047980">'$credi'</font></h4>' >> $local
    service sshd restart 2>/dev/null
    service dropbear restart 2>/dev/null
    print_center -verd "Banner Agregado!!!"
    enter
    return 1
  fi
  print_center -ama "Edicion de Banner Canselada!"
  enter
  return 1
}

banner_edit(){
  clear
  chk=$(cat /etc/ssh/sshd_config | grep Banner)
  local=$(echo "$chk" |grep -v "#Banner" | grep Banner | awk '{print $2}')
  nano $local
  service sshd restart 2>/dev/null
  service dropbear restart 2>/dev/null
  msg -bar
  print_center -ama "Edicion de Banner Terminada!"
  enter
  return 1
}

banner_reset(){
  clear
  chk=$(cat /etc/ssh/sshd_config | grep Banner)
  local=$(echo "$chk" |grep -v "#Banner" | grep Banner | awk '{print $2}')
  rm -rf $local
  touch $local
  service sshd restart 2>/dev/null
  service dropbear restart 2>/dev/null
  msg -bar
  print_center -ama "EL BANNER SSH FUE LIMPIADO"
  enter
  return 1
}

baner_fun(){
  chk=$(cat /etc/ssh/sshd_config | grep Banner)
  local=$(echo "$chk" |grep -v "#Banner" | grep Banner | awk '{print $2}')
  n=1
  title -ama "MENU DE EDICION DE BANNER SSH"
  echo -e " $(msg -verd "[1]") $(msg -verm2 ">") $(msg -azu "NUEVO BANNER SSH")"
  if [[ -e "${local}" ]]; then
    echo -e " $(msg -verd "[2]") $(msg -verm2 ">") $(msg -azu "EDITAR BANNER CON NANO")"
    echo -e " $(msg -verd "[3]") $(msg -verm2 ">") $(msg -azu "RESET BANNER SSH")"
    n=3
  fi
  back
  opcion=$(selection_fun $n)
  case $opcion in
    1)new_banner;;
    2)banner_edit;;
    3)banner_reset;;
    0)return 1;;
  esac
}

fun_autorun () {
  clear
  msg -bar
if [[ $(cat /etc/ADMRufu/bashrc | grep -w /usr/bin/menu) ]]; then
  cat /etc/ADMRufu/bashrc | grep -v /usr/bin/menu > /tmp/bash
  mv -f /tmp/bash /etc/ADMRufu/bashrc
  msg -ama "               $(fun_trans "AUTO-INICIO REMOVIDO")"
  msg -bar
else
  cp /etc/ADMRufu/bashrc /tmp/bash
  echo '/usr/bin/menu' >> /tmp/bash
  mv -f /tmp/bash /etc/ADMRufu/bashrc
  msg -verd "              $(fun_trans "AUTO-INICIO AGREGADO")"
  msg -bar
fi
return 1
}

#       comfiguracion menu principal
#==================================================

C_MENU2(){
  unset m_conf
  m_conf="$(cat ${ADM_tmp}/style|grep -w "$1"|awk '{print $2}')"

  case $m_conf in
    0)sed -i "s;$1 0;$1 1;g" ${ADM_tmp}/style;;
    1)sed -i "s;$1 1;$1 0;g" ${ADM_tmp}/style;;
  esac
}

c_stat(){
  unset m_stat
  m_stat="$(cat ${ADM_tmp}/style|grep -w "$1"|awk '{print $2}')"
  case $m_stat in
    0)msg -verm2 "[OFF]";;
    1)msg -verd "[ON]";;
  esac
}

c_resel(){
  clear
  msg -bar
  msg -ama "               CAMBIAR RESELLER"
  msg -bar
  echo -ne "$(msg -azu " CAMBIAR RESELLER [S/N]:") "
  read txt_r
  if [[ $txt_r = @(s|S|y|Y) ]]; then
    tput cuu1 && tput dl1
    echo -ne "$(msg -azu " ESCRIBE TU RESELLER:") "
    read r_txt
    echo -e "$r_txt" > ${ADM_tmp}/message.txt
  fi
  C_MENU2 resel
}

conf_menu(){
  while :
  do
    clear
    title -ama 'CONFIGURACION DEL MENU PRINCIPAL'
    echo -ne "$(msg -verd " [1]") $(msg -verm2 ">") " && msg -azu "INF SISTEMA (SYS/MEM/CPU) $(c_stat infsys)"
    echo -ne "$(msg -verd " [2]") $(msg -verm2 ">") " && msg -azu "PUERTOS ACTIVOS           $(c_stat port)"
    echo -ne "$(msg -verd " [3]") $(msg -verm2 ">") " && msg -azu "RESELLER                  $(c_stat resel)"
    echo -ne "$(msg -verd " [4]") $(msg -verm2 ">") " && msg -azu "CONTADOR (Only/Exp/Total) $(c_stat contador)"
    msg -bar3
    print_center -ama 'CONFIGURACION DEL MENU PROTOCOLOS'
    msg -bar3
    echo -ne "$(msg -verd " [5]") $(msg -verm2 ">") " && msg -azu "INF SISTEMA (SYS/MEM/CPU) $(c_stat infsys2)"
    echo -ne "$(msg -verd " [6]") $(msg -verm2 ">") " && msg -azu "PUERTOS ACTIVOS           $(c_stat port2)"
    back
    opcion=$(selection_fun 6)

    case $opcion in
      1)C_MENU2 infsys;;
      2)C_MENU2 port;;
      3)c_resel;; #C_MENU2 resel;;
      4)C_MENU2 contador;;
      5)C_MENU2 infsys2;;
      6)C_MENU2 port2;;
      0)break;;
      esac
  done
  return 0
}
#================================================

root_acces () {
	sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
	echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

	sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config
	echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

	service sshd restart
}

root_pass () {
  clear
  msg -bar
  [[ -z $1 ]] && msg -ama "             CAMBIAR CONTRASEÑA ROOT" || msg -ama "               ACTIVAR ACCESO ROOT"
  msg -bar
  msg -azu "    Esto cambiara la contraseña de acceso root"
  msg -bar3
  msg -azu "    Esta contraseña podra ser utilizada para\n    acceder al vps como usuario root."
  msg -bar
  echo -ne " $(msg -azu "Cambiar contraseña root? [S/N]:") "; read x
  tput cuu1 && tput dl1
  [[ $x = @(n|N) ]] && msg -bar && return
  if [[ ! -z $1 ]]; then
    msg -azu "    Activando acceso root..."
    root_acces
    sleep 3
    tput cuu1 && tput dl1
    msg -azu "    Acceso root Activado..."
    msg -bar
  fi
  echo -ne "\033[1;37m Nueva contraseña: \033[0;31m"
  read pass
  tput cuu1 && tput dl1
  (echo $pass; echo $pass)|passwd root 2>/dev/null
  sleep 1s
  msg -azu "    Contraseña root actulizada!"
  msg -azu "    Contraseña actual:\033[0;31m $pass"
  msg -bar
  enter
  return 1
}

pid_inst(){
  v_node="$(which nodejs)" && v_node=$(ls -l "$v_node"|awk -F '/' '{print $NF}'|awk '{print $NF}')
  proto="dropbear python stunnel4 v2ray $v_node badvpn squid openvpn ttdns php psiphond ws-epro"
  portas=$(lsof -V -i -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND")
  for list in $proto; do
    case $list in
      ws-epro|dropbear|psiphond|python|stunnel4|v2ray|badvpn|squid|php|"$v_node") portas2=$(echo "$portas"|grep -w "LISTEN"|grep -w "$list") && [[ $(echo "${portas2}"|grep "$list") ]] && inst[$list]="\033[1;32m[ON] " || inst[$list]="\033[1;31m[OFF]";;
      ttdns|openvpn) portas2=$(echo "$portas"|grep -w "$list") && [[ $(echo "${portas2}"|grep "$list") ]] && inst[$list]="\033[1;32m[ON] " || inst[$list]="\033[1;31m[OFF]";;
    esac
  done
  [[ $(dpkg --get-selections|grep -w 'wireguard'|head -1) ]] && {
    if [[ $(wg|grep -w 'interface') = "" ]]; then inst[wg]="\033[1;31m[OFF]"; else inst[wg]="\033[1;32m[ON]"; fi
  } || {
    inst[wg]="\033[1;31m[OFF]"
  }

  inst[UDPS]="\033[1;31m[OFF]"
  if [[ $(systemctl is-active udprequest) = 'active' ]] || [[ $(systemctl is-active udpcustom) = 'active' ]] || [[ $(systemctl is-active zivpn) = 'active' ]] || [[ $(systemctl is-active udpmod) = 'active' ]]; then
    inst[UDPS]="\033[1;32m[ON]"
  fi


}

menu_inst () {
clear
declare -A inst
pid_inst

if [[ $(cat /etc/ADMRufu/bashrc | grep -w /usr/bin/menu) ]]; then
  AutoRun="\033[1;32m[ON]"
else
  AutoRun="\033[1;31m[OFF]"
fi

v=$(cat $ADMRufu/vercion)

title -ama 'INFORMACION DEL SISTEMA Y PUERTOS ACTIVOS'
if [[ $(cat ${ADM_tmp}/style|grep -w "infsys2"|awk '{print $2}') = "1" ]] ; then
  info_sys
  msg -bar
fi
if [[ $(cat ${ADM_tmp}/style|grep -w "port2"|awk '{print $2}') = "1" ]] ; then
  mine_port
fi
echo -e "\e[0m\e[31m================ \e[1;33mMENU DE PROTOCOLOS\e[0m\e[31m =================\e[0m"
echo -ne "$(msg -verd "  [1]")$(msg -verm2 ">") $(msg -azu "DROPBEAR      ${inst[dropbear]}")" && echo -e "$(msg -verd "  [8]")$(msg -verm2 ">") $(msg -azu "OPENVPN       ${inst[openvpn]}")"
echo -ne "$(msg -verd "  [2]")$(msg -verm2 ">") $(msg -azu "SOCKS PYTHON  ${inst[python]}")" && echo -e "$(msg -verd "  [9]")$(msg -verm2 ">") $(msg -azu "SLOWDNS       ${inst[ttdns]}")"
echo -ne "$(msg -verd "  [3]")$(msg -verm2 ">") $(msg -azu "SSL           ${inst[stunnel4]}")" && echo -e "$(msg -verd " [10]")$(msg -verm2 ">") $(msg -azu "WIREGUARD     ${inst[wg]}")" #&& echo -e "$(msg -verd "  [9]")$(msg -verm2 ">") $(msg -azu "SHADOW-LIBEV  $(pid_inst ss-server)")"
echo -ne "$(msg -verd "  [4]")$(msg -verm2 ">") $(msg -azu "V2RAY         ${inst[v2ray]}")" && echo -e "$(msg -verd " [11]")$(msg -verm2 ">") $(msg -azu "CHEKUS-ONLIAPP${inst[php]}")" #&& echo -e "$(msg -verd " [10]")$(msg -verm2 ">") $(msg -azu "SHADOW-NORMAL $(pid_inst ssserver)")"
echo -ne "$(msg -verd "  [5]")$(msg -verm2 ">") $(msg -azu "OVER WEBSOCKET${inst[$v_node]}")" && echo -e "$(msg -verd " [12]")$(msg -verm2 ">") $(msg -azu "PROTOCOLOS UDP${inst[UDPS]}")"
echo -ne "$(msg -verd "  [6]")$(msg -verm2 ">") $(msg -azu "BADVPN-UDP    ${inst[badvpn]}")" && echo -e "$(msg -verd " [13]")$(msg -verm2 ">") $(msg -azu "PSIPHON       ${inst[psiphond]}")"
echo -ne "$(msg -verd "  [7]")$(msg -verm2 ">") $(msg -azu "SQUID         ${inst[squid]}")"  && echo -e "$(msg -verd " [14]")$(msg -verm2 ">") $(msg -azu "WS-EPRO       ${inst['ws-epro']}")"

echo -e "\e[31m============== \e[1;33mCONFIGURACIONES RAPIDAS\e[0m\e[31m ==============\e[0m"
echo -ne "$(msg -verd " [15]")$(msg -verm2 ">") $(msg -azu "BANNER SSH")" && echo -e "$(msg -verd "          [20]")$(msg -verm2 ">") $(msg -azu "ACELERACION TCPBBR")"
echo -ne "$(msg -verd " [16]")$(msg -verm2 ">") $(msg -azu "REFREES CACHE/RAM") $(crontab -l|grep -w "vm.drop_caches=3" > /dev/null && echo -e "\033[1;32m◉ " || echo -e "\033[1;31m○ ")" && echo -e "$(msg -verd "[21]")$(msg -verm2 ">") $(msg -azu "CAMBIAR PASS ROOT")"
echo -ne "$(msg -verd " [17]")$(msg -verm2 ">") $(msg -azu "MEMORIA SWAP")  $([[ $(cat /proc/swaps | wc -l) -le 1 ]] && echo -e "\033[1;31m○ " || echo -e "\033[1;32m◉ ")" && echo -e "$(msg -verd "    [22]")$(msg -verm2 ">") $(msg -azu "ACTIVAR ACCESO ROOT")"
echo -ne "$(msg -verd " [18]")$(msg -verm2 ">") $(msg -azu "CONFIGURAR IP DNS")  " && echo -e "$(msg -verd " [23]")$(msg -verm2 ">") $(msg -azu "INTERFACES MENUES")"
echo "$(msg -verd " [19]")$(msg -verm2 ">") $(msg -azu "GEN DOMI/CERT-SSL") $([[ -z $(ls "${ADM_crt}") ]] && echo -e "\033[1;31m○ " || echo -e "\033[1;32m◉ ")"
msg -bar
echo -e "$(msg -verd " [24]") $(msg -verm2 ">") $(msg -blu "ADMINISTRADOR DE ARCHIVOS WEB")"
echo -e "$(msg -verd " [25]") $(msg -verm2 ">") $(msg -teal "HERRAMIENTAS y EXTRAS")"
msg -bar
echo -ne "$(msg -verd "  [0]") $(msg -verm2 ">") " && msg -bra "   \033[1;41m VOLVER \033[0m $(msg -verd "       [26]") $(msg -verm2 ">") $(msg -azu AUTO-INICIAR) ${AutoRun}" 
msg -bar
selection=$(selection_fun 26)
case $selection in
  0)return 0;;
  1)dropBear;;
  2)${ADM_inst}/sockspy.sh;;
  3)Stunnel;;
  4)${ADM_inst}/v2ray.sh;;
  5)${ADM_inst}/ws-cdn.sh;;
  6)${ADM_inst}/budp.sh;;
  7)${ADM_inst}/squid.sh;;
  8)${ADM_inst}/openvpn.sh;;
  9)Slowdns;;
  10)${ADM_inst}/wireguard.sh;;
  11)${ADM_inst}/chekuser.sh;;
  12)protocolsUDP;;
  #12)${ADM_inst}/UDPserver.sh;;
  #13)${ADM_inst}/udp-custom;;
  13)${ADM_inst}/psiphon-manager;;
  14)epro-ws;;
  15)baner_fun;;
  16)cache_ram;;
  17)${ADM_inst}/swapfile.sh;;
  18)${ADM_inst}/confDNS.sh;;
  19)${ADM_inst}/cert.sh;;
  20)${ADM_inst}/tcpbbr.sh;;
  21)root_pass;;
  22)root_pass 1;;
  23)conf_menu;;
  24)${ADM_inst}/filebrowser.sh;;
  25)${ADMRufu}/tool_extras.sh;;
  26)fun_autorun;;
esac
}

while [[ ${back} != @(0) ]]; do
  menu_inst
  back="$?"
  [[ ${back} != @(0|[1]) ]] && enter
done
