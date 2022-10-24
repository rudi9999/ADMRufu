#!/bin/bash
clear
port(){
  local portas
  local portas_var=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN")
  i=0
  while read port; do
    var1=$(echo $port | awk '{print $1}') && var2=$(echo $port | awk '{print $9}' | awk -F ":" '{print $2}')
    [[ "$(echo -e ${portas}|grep -w "$var1 $var2")" ]] || {
      portas+="$var1 $var2 $portas"
      echo "$var1 $var2"
      let i++
    }
  done <<< "$portas_var"
}

verify_port () {
local SERVICE="$1"
local PORTENTRY="$2"
[[ ! $(echo -e $(port|grep -v ${SERVICE})|grep -w "$PORTENTRY") ]] && return 0 || return 1
}

edit_squid(){

  if [[ -e /etc/squid/squid.conf ]]; then
    local CONF="/etc/squid/squid.conf"
  elif [[ -e /etc/squid3/squid.conf ]]; then
    local CONF="/etc/squid3/squid.conf"
  fi

  local line="$(cat ${CONF}|sed -n '/http_port/='|head -1)"
  local NEWCONF="$(cat ${CONF}|sed "$line c ADMR_port"|sed '/http_port/d')"

  title "$(fun_trans "REDEFINIR PUERTOS SQUID")"
  msg -ne " $(fun_trans " Digite Puertos"): " && read DPORT
  tput cuu1 && tput dl1
  TTOTAL=($DPORT)
  for((i=0; i<${#TTOTAL[@]}; i++)); do

    [[ $(mportas|grep -v squid|grep -v '>'|grep -w "${TTOTAL[$i]}") = "" ]] && {
      echo -e "\033[1;33m Puerto Elegido:\033[1;32m ${TTOTAL[$i]} OK"
      PORT="$PORT ${TTOTAL[$i]}"
    } || {
      echo -e "\033[1;33m Puerto Elegido:\033[1;31m ${TTOTAL[$i]} FAIL"
    }
  done
  [[  -z $PORT ]] && {
    msg -bar
    print_center -verm2 "Ningun Puerto Valido"
    return 1
  }

  rm ${CONF}

  while read varline; do

    if [[ ! -z "$(echo "$varline"|grep 'ADMR_port')" ]]; then
      for i in `echo $PORT`; do
        echo -e "http_port ${i}" >> ${CONF}
        ufw allow $i/tcp &>/dev/null 2>&1
      done
      continue
    fi

    echo -e "${varline}" >> ${CONF}
  done <<< "${NEWCONF}"

  msg -bar
  print_center -azu "$(fun_trans "AGUARDE")"
  [[ -d "/etc/squid/" ]] && {
    service ssh restart > /dev/null 2>&1
    /etc/init.d/squid start > /dev/null 2>&1
    service squid restart > /dev/null 2>&1
  }

  [[ -d "/etc/squid3/" ]] && {
    service ssh restart > /dev/null 2>&1
    /etc/init.d/squid3 start > /dev/null 2>&1
    service squid3 restart > /dev/null 2>&1
  }
  sleep 2s
  tput cuu1 && tput dl1
  print_center -verd "$(fun_trans "PUERTOS REDEFINIDOS")"
}


edit_apache(){
  local CONF="/etc/apache2/ports.conf"
  local line="$(cat ${CONF}|sed -n '/Listen/='|head -1)"
  local NEWCONF="$(cat ${CONF}|sed "$line c ADMRufu")"
  let line++
  while [[ ! -z $(echo "$NEWCONF"|sed -n "${line}p"|grep 'Listen') ]]; do
    NEWCONF=$(echo "$NEWCONF"|sed "${line}d")
  done

  title "$(fun_trans "REDEFINIR PUERTOS APACHE")"
  msg -ne " $(fun_trans " Digite Puertos"): " && read DPORT
  tput cuu1 && tput dl1
  TTOTAL=($DPORT)
  for((i=0; i<${#TTOTAL[@]}; i++)); do

    [[ $(mportas|grep -v apache|grep -v '>'|grep -w "${TTOTAL[$i]}") = "" ]] && {
      echo -e "\033[1;33m Puerto Elegido:\033[1;32m ${TTOTAL[$i]} OK"
      PORT="$PORT ${TTOTAL[$i]}"
    } || {
      echo -e "\033[1;33m Puerto Elegido:\033[1;31m ${TTOTAL[$i]} FAIL"
    }
  done
  [[  -z $PORT ]] && {
    msg -bar
    print_center -verm2 "Ningun Puerto Valido"
    return 1
  }

  rm ${CONF}

  while read varline; do

    if [[ ! -z "$(echo "$varline"|grep 'ADMRufu')" ]]; then
      for i in `echo $PORT`; do
        echo -e "Listen ${i}" >> ${CONF}
      done
      continue
    fi

    echo -e "${varline}" >> ${CONF}
  done <<< "${NEWCONF}"

  msg -bar
  print_center -azu "$(fun_trans "AGUARDE")"
  service apache2 restart &>/dev/null
  sleep 2s
  tput cuu1 && tput dl1
  print_center -verd "$(fun_trans "PUERTOS REDEFINIDOS")"
}


edit_openvpn(){
msg -azu "$(fun_trans "REDEFINIR PUERTOS OPENVPN")"
msg -bar


local CONF="/etc/openvpn/server.conf"
local CONF2="/etc/openvpn/client-common.txt"

local NEWCONF="$(cat ${CONF}|grep -v [Pp]ort)"
local NEWCONF2="$(cat ${CONF2})"



msg -ne "$(fun_trans "Nuevos puertos"): "
read -p "" newports

for PTS in `echo ${newports}`; do
verify_port openvpn "${PTS}" && echo -e "\033[1;33mPort $PTS \033[1;32mOK" || {
echo -e "\033[1;33mPort $PTS \033[1;31mFAIL"
return 1
}
done

rm ${CONF}

while read varline; do
echo -e "${varline}" >> ${CONF}
if [[ ${varline} = "proto tcp" ]]; then
echo -e "port ${newports}" >> ${CONF}
fi
done <<< "${NEWCONF}"

rm ${CONF2}

while read varline; do
if [[ $(echo ${varline}|grep -v "remote-random"|grep "remote") ]]; then
echo -e "$(echo ${varline}|cut -d' ' -f1,2) ${newports} $(echo ${varline}|cut -d' ' -f4)" >> ${CONF2}
else
echo -e "${varline}" >> ${CONF2}
fi
done <<< "${NEWCONF2}"


msg -azu "$(fun_trans "AGUARDE")"
service openvpn restart &>/dev/null
/etc/init.d/openvpn restart &>/dev/null
sleep 1s
msg -bar
msg -azu "$(fun_trans "PUERTOS REDEFINIDOS")"
msg -bar
}

edit_dropbear(){
  title "$(fun_trans "REDEFINIR PUERTOS DROPBEAR")"
  msg -ne " $(fun_trans " Digite Puertos"): " && read DPORT
  tput cuu1 && tput dl1
  TTOTAL=($DPORT)
  for((i=0; i<${#TTOTAL[@]}; i++)); do

    [[ $(mportas|grep -v 'dropbear'|grep "${TTOTAL[$i]}") = "" ]] && {
      echo -e "\033[1;33m Puerto Elegido:\033[1;32m ${TTOTAL[$i]} OK"
      PORT="$PORT ${TTOTAL[$i]}"
    } || {
      echo -e "\033[1;33m Puerto Elegido:\033[1;31m ${TTOTAL[$i]} FAIL"
    }
  done
  [[  -z $PORT ]] && {
    echo -e "\033[1;31m Ningun Puerto Valida Fue Elegido\033[0m"
    return 1
  }

  cat <<EOF > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=VAR1
DROPBEAR_EXTRA_ARGS="VAR"
DROPBEAR_BANNER="/etc/dropbear/banner"
DROPBEAR_RECEIVE_WINDOW=65536
EOF

  n=0
  for i in $(echo $PORT); do
    p[$n]=$i
    let n++
  done

  sed -i "s/VAR1/${p[0]}/g" /etc/default/dropbear

  if [[ ! -z ${p[1]} ]]; then

    for (( i = 0; i < ${#p[@]}; i++ )); do
      [[ "$i" = "0" ]] && continue
      sed -i "s/VAR/-p ${p[$i]} VAR/g" /etc/default/dropbear
    done
  fi
  sed -i "s/VAR//g" /etc/default/dropbear
  msg -bar
  print_center -azu "$(fun_trans "AGUARDE")"
  service dropbear restart &>/dev/null
  sleep 2s
  tput cuu1 && tput dl1
  print_center -verd "$(fun_trans "PUERTOS REDEFINIDOS")"
}

edit_openssh(){
  local CONF="/etc/ssh/sshd_config"
  local line="$(cat ${CONF}|sed -n '/[Pp]ort/='|head -1)"
  local NEWCONF="$(cat ${CONF}|sed "$line c ADMRufu"|sed '/[Pp]ort/d')"

  title "$(fun_trans "REDEFINIR PUERTOS OPENSSH")"
  msg -ne " $(fun_trans " Digite Puertos"): " && read DPORT
  tput cuu1 && tput dl1
  TTOTAL=($DPORT)
  for((i=0; i<${#TTOTAL[@]}; i++)); do

    [[ $(mportas|grep -v ssh|grep -v '>'|grep -w "${TTOTAL[$i]}") = "" ]] && {
      echo -e "\033[1;33m Puerto Elegido:\033[1;32m ${TTOTAL[$i]} OK"
      PORT="$PORT ${TTOTAL[$i]}"
    } || {
      echo -e "\033[1;33m Puerto Elegido:\033[1;31m ${TTOTAL[$i]} FAIL"
    }
  done
  [[  -z $PORT ]] && {
    msg -bar
    print_center -verm2 "Ningun Puerto Valido"
    return 1
  }

  rm ${CONF}

  while read varline; do

    if [[ ! -z "$(echo "$varline"|grep 'ADMRufu')" ]]; then
      for i in `echo $PORT`; do
        echo -e "Port ${i}" >> ${CONF}
      done
      continue
    fi

    echo -e "${varline}" >> ${CONF}
  done <<< "${NEWCONF}"

  msg -bar
  print_center -azu "$(fun_trans "AGUARDE")"
  service ssh restart &>/dev/null
  service sshd restart &>/dev/null
  sleep 2s
  tput cuu1 && tput dl1
  print_center -verd "$(fun_trans "PUERTOS REDEFINIDOS")"
}

main_fun(){
  title "$(fun_trans "GESTOR DE PUERTOS")"
  unset newports

  i=0
  new=$(mportas|cut -d ' ' -f1|grep -E 'squid|apache|dropbear|ssh')

  [[ ! -z $(echo "$new"|grep squid) ]] && {
    let i++
    echo -e "$(msg -verd "[$i]") $(msg -verm2 ">") $(msg -azu "$(fun_trans "REDEFINIR PUERTOS SQUID")")"
    squid=$i
  }

  [[ ! -z $(echo "$new"|grep apache) ]] && {
    let i++
    echo -e "$(msg -verd "[$i]") $(msg -verm2 ">") $(msg -azu "$(fun_trans "REDEFINIR PUERTOS APACHE")")"
    apache=$i
  }

  #[[ ! -z $(echo "$new"|grep openvpn) ]] && {
  #  let i++
  #  echo -e "$(msg -verd "[$i]") $(msg -verm2 ">") $(msg -azu "$(fun_trans "REDEFINIR PUERTOS OPENVPN")")"
  #  openvpn=$i
  #}

  [[ ! -z $(echo "$new"|grep dropbear) ]] && {
    let i++
    echo -e "$(msg -verd "[$i]") $(msg -verm2 ">") $(msg -azu "$(fun_trans "REDEFINIR PUERTOS DROPBEAR")")"
    dropbear=$i
  }

  [[ ! -z $(echo "$new"|grep ssh) ]] && {
    let i++
    echo -e "$(msg -verd "[$i]") $(msg -verm2 ">") $(msg -azu "$(fun_trans "REDEFINIR PUERTOS SSH")")"
    ssh=$i
  }

  back
  opcion=$(selection_fun $i)

  case $opcion in
    $squid)edit_squid;;
    $apache)edit_apache;;
    #$openvpn)edit_openvpn;;
    $dropbear)edit_dropbear;;
    $ssh)edit_openssh;;
  esac

}

main_fun
enter
return 1