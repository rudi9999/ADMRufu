#!/bin/bash

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
            cupsd|systemd-r|exim4|stunnel4|stunnel)continue;;
            *)DPB+=" $reQ:$Port";;
        esac
    done <<< "${portasVAR}"
 }

ssl_stunel(){
    [[ $(mportas|grep stunnel4|head -1) ]] && {
        title -ama 'Parando Stunnel'
        int stop
        fun_bar 'apt-get purge stunnel4 -y' 'UNINSTALL STUNNEL4 '
        if crontab -l|grep '@reboot'|grep 'service'|grep 'stunnel4' &>/dev/null; then
            crontab -l > /root/cron
            sed -i '/@reboot service stunnel4 start/d' /root/cron
            crontab /root/cron
            rm /root/cron
        fi
        msg -bar
        print_center -verd "Stunnel removido con Exito!"
        msg -bar
        enter
        return
     }
    title "INSTALADOR SSL By @Rufu99"
    print_center -azu "Seleccione puerto de redireccion de trafico"
    msg -bar
    slec_port 1
    title "INSTALADOR SSL By @Rufu99"
    echo " $(msg -ama "Puerto de redireccion de trafico:") $(msg -verd "${drop[$opc]}")"
    msg -bar3
    _opc2

    # openssl x509 -in 2.crt -text -noout |grep -w 'Issuer'|awk -F 'O = ' '{print $2}'|cut -d ',' -f1

    msg -bar
    fun_bar 'apt-get install stunnel4 -y' 'INSTALL STUNNEL4 '
    cat <<EOF > /etc/stunnel/stunnel.conf
client = no
[SSL+]
cert = /etc/stunnel/stunnel.pem
accept = ${opc2}
connect = 127.0.0.1:${drop[$opc]}
EOF
    db="$(ls ${ADM_crt})"
    opcion="n"
    if [[ ! "$(echo "$db"|grep ".crt")" = "" ]]; then
        cert=$(echo "$db"|grep ".crt")
        key=$(echo "$db"|grep ".key")
        msg -bar
        print_center -azu "CERTIFICADO SSL ENCONTRADO"
        msg -bar
        echo -e "$(msg -azu "CERT:") $(msg -ama "$cert")"
        echo -e "$(msg -azu "KEY:")  $(msg -ama "$key")"
        msg -bar
        read -rp " $(msg -ama "Usando este certificado? [S/N]:") " -e -i S opcion
        if [[ $opcion != @(n|N) ]]; then
            cp ${ADM_crt}/$cert ${ADM_tmp}/stunnel.crt
            cp ${ADM_crt}/$key ${ADM_tmp}/stunnel.key
        fi
    fi
    if [[ $opcion != @(s|S) ]]; then
        openssl genrsa -out ${ADM_tmp}/stunnel.key 2048 > /dev/null 2>&1
        (echo "" ; echo "" ; echo "" ; echo "" ; echo "" ; echo "" ; echo "@cloudflare" )|openssl req -new -key ${ADM_tmp}/stunnel.key -x509 -days 1000 -out ${ADM_tmp}/stunnel.crt > /dev/null 2>&1
    fi
    cat ${ADM_tmp}/stunnel.key ${ADM_tmp}/stunnel.crt > /etc/stunnel/stunnel.pem
    sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
    del 1
    int restart
    for ufww in `echo $opc2`; do
    	ufw allow $ufww/tcp > /dev/null 2>&1
    done
    rm -rf ${ADM_tmp}/stunnel.crt > /dev/null 2>&1
    rm -rf ${ADM_tmp}/stunnel.key > /dev/null 2>&1
    msg -bar
    print_center -verd "INSTALADO CON EXITO"
    enter
 }

add_port(){
    title "INSTALADOR SSL By @Rufu99"
    print_center -azu "Seleccione puerto de redireccion de trafico"
    msg -bar
    slec_port 1
    title "INSTALADOR SSL By @Rufu99"
    echo " $(msg -ama "Puerto de redireccion de trafico:") $(msg -verd "${drop[$opc]}")"
    msg -bar3
    _opc2
    cat <<EOF >> /etc/stunnel/stunnel.conf
client = no
[SSL+]
cert = /etc/stunnel/stunnel.pem
accept = ${opc2}
connect = 127.0.0.1:${drop[$opc]}
EOF
    int restart
    for ufww in `echo $opc2`; do
        ufw allow $ufww/tcp > /dev/null 2>&1
    done
    msg -bar
    print_center -verd "PUERTO AGREGADO CON EXITO"
    enter
 }

start-stop(){
	if [[ $(service stunnel4 status|grep -w 'Active'|awk -F ' ' '{print $2}') = 'inactive' ]]; then
		int restart
	else
		int stop
	fi
	enter
 }

del_port(){
	sslport=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN"|grep -E 'stunnel|stunnel4')
	if [[ $(echo "$sslport"|wc -l) -lt '2' ]];then
        title -ama 'Un solo puerto para eliminar!'
        read -rp " $(msg -ama "Usando este certificado? [S/N]:") " -e -i S a
		if [[ "$a" = @(S|s) ]]; then
			clear
			msg -bar
			int stop		
		fi
		enter
		return
	fi
    _slec_port quitar
    in=$(( $(cat "/etc/stunnel/stunnel.conf"|grep -n "accept = ${drop[$opc]}"|cut -d ':' -f1) - 3 ))
    en=$(( $in + 4))
    sed -i "$in,$en d" /etc/stunnel/stunnel.conf
    sed -i '2 s/\[SSL+\]/\[SSL\]/' /etc/stunnel/stunnel.conf
    print_center "Puerto ssl ${drop[$opc]} eliminado"
    msg -bar
    int restart
	enter
 }

edit_port(){
	sslport=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN"|grep -E 'stunnel|stunnel4')
    _slec_port editar
    title "Configuracion actual"
    in=$(( $(cat "/etc/stunnel/stunnel.conf"|grep -n "accept = ${drop[$opc]}"|cut -d ':' -f1) + 1 ))
    en=$(sed -n "${in}p" /etc/stunnel/stunnel.conf|cut -d ':' -f2)
    print_center -ama "${drop[$opc]} >>> $en"
    msg -bar
    slec_port
    sed -i "$in s/$en/${drop[$opc]}/" /etc/stunnel/stunnel.conf
    print_center "Puerto de redirecion modificado"
    msg -bar
    int restart
	enter
 }

_slec_port(){
    title "seleccione el num de puerto a $1"
    n=1
    while read i; do
        port=$(echo $i|awk -F ' ' '{print $9}'|cut -d ':' -f2)
        echo " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -azu "$port")"
        drop[$n]=$port; num_opc="$n" ; let n++ 
    done <<< $(echo "$sslport")
    back
    _opc
 }

slec_port(){
    drop_port
    n=1
    for i in $DPB; do
        port=$(echo $i|awk -F ":" '{print $2}')
        [[ $1 = 1 ]] && [[ "$port" = "$en" ]] && continue
        proto=$(echo $i|awk -F ":" '{print $1}')
        proto2=$(printf '%-12s' "$proto")
        echo -e " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -ama "$proto2")$(msg -azu "$port")"
        drop[$n]=$port ; num_opc="$n" ; let n++ 
    done
    msg -bar
    _opc
 }

_opc(){
    unset opc
    while [[ -z $opc ]]; do
        in_opcion 'opcion'; opc=$opcion ; del 2
        if [[ -z $opc ]]; then
            print_center -verm2 " selecciona una opcion entre 1 y $num_opc"
            unset opc ; sleep 2 ; del 1 ; continue
        elif [[ ! $opc =~ $numero ]]; then
            print_center -verm2 " selecciona solo numeros entre 1 y $num_opc"
            unset opc ; sleep 2 ; del 1 ; continue
        elif [[ "$opc" -gt "$num_opc" ]]; then
            print_center -verm2 " selecciona una opcion entre 1 y $num_opc"
            unset opc ; sleep 2 ; del 1 ; continue
        fi
    done
 }

_opc2(){
    unset opc2
    while [[ -z $opc2 ]]; do
        in_opcion 'Ingrese un puerto para SSL'
        opc2=$opcion ; del 2
        [[ $(mportas|grep -w "${opc2}") = "" ]] && {
            echo " $(msg -ama 'Puerto de ssl:') $(msg -verd "${opc2} OK")"
        } || {
            echo " $(msg -ama 'Puerto de ssl:') $(msg -verm2 "${opc2} FAIL")"
            sleep 2 ; del 1; unset opc2
        }
    done
    msg -bar
 }

int(){
    case $1 in
        restart)
                if service stunnel4 restart &> /dev/null ; then
                    print_center -verd "Servicio stunnel4 reiniciado"
                else
                    print_center -verm2 "Falla al reiniciar Servicio stunnel4"
                fi;;
        stop)
                if service stunnel4 stop &> /dev/null ; then
                    print_center -verd "Servicio stunnel4 detenido"
                else
                    print_center -verm2 "Falla al detener Servicio stunnel4"
                fi;;
    esac
 }

edit_nano(){
	nano /etc/stunnel/stunnel.conf
	int restart
    enter
 }

fix_boot(){
  unset fix
  title 'FIX EN INICIO DEL SISTEMA'
  print_center -ama 'Si el servicio stunnel4 no inicia en el\narranque de su sistema aplique este fix!'
  msg -bar
  if crontab -l|grep '@reboot'|grep 'service'|grep 'stunnel4' &>/dev/null; then
    print_center -verd 'fix activo'
    msg -bar
    read -rp "$(msg -ama "Remover fix [S/N]:") " -e -i S fix
    del 1
    if [[ $fix = @(S|s) ]]; then
      crontab -l > /root/cron
      sed -i '/@reboot service stunnel4 start/d' /root/cron
      crontab /root/cron
      rm /root/cron
      del 2
      print_center -ama 'fix removido!' 
      enter
      return
    fi
  else
    read -rp "$(msg -ama "Aplicar fix [S/N]:") " -e -i S fix
    del 1
    if [[ $fix = @(S|s) ]]; then
      crontab -l > /root/cron
      echo '@reboot service stunnel4 start' >> /root/cron
      crontab /root/cron
      rm /root/cron
      print_center -verd 'fix stunnel4 en el inicio de sistema aplicado!'
      enter
      return
    fi
  fi
  del 1
  enter
 }

menuSSL(){
    [[ $(crontab -l|grep '@reboot'|grep 'service'|grep 'stunnel4') ]] && actfix='\e[1m\e[32m[ON]' || actfix='\e[1m\e[31m[OFF]'
    title "INSTALADOR SSL By @Rufu99"
    if [[ $(dpkg -l|grep 'stunnel'|awk -F ' ' '{print $2}') ]]; then
        echo -e "$(msg -verd " [1]") $(msg -verm2 ">") $(msg -verm2 "DESINSTALAR STUNNEL4")"
        msg -bar3
        echo -e "$(msg -verd " [2]") $(msg -verm2 ">") $(msg -verd "AGREGAR PUERTOS SSL")"
        echo -e "$(msg -verd " [3]") $(msg -verm2 ">") $(msg -verm2 "QUITAR PUERTOS SSL")"
        msg -bar3
        echo -e "$(msg -verd " [4]") $(msg -verm2 ">") $(msg -ama "EDITAR PUERTO DE REDIRECCION")"
        echo -e "$(msg -verd " [5]") $(msg -verm2 ">") $(msg -azu "EDITAR MANUAL (NANO)")"
        msg -bar3
        echo -e "$(msg -verd " [6]") $(msg -verm2 ">") $(msg -ama 'FIX DE INICIO CON EL SISTEMA') $actfix"
        msg -bar3
        echo -e "$(msg -verd " [7]") $(msg -verm2 ">") $(msg -azu "INICIAR/PARAR SERVICIO SSL")"
        echo -e "$(msg -verd " [8]") $(msg -verm2 ">") $(msg -azu "REINICIAR SERVICIO SSL")"
        n=8
    else
        echo "$(msg -verd " [1]") $(msg -verm2 ">") $(msg -verd "INSTALAR STUNNEL4")"
        n=1
    fi
    back
    opcion=$(selection_fun $n)
    case $opcion in
        1)ssl_stunel;;
        2)add_port;;
        3)del_port;;
        4)edit_port;;
        5)edit_nano;;
        6)fix_boot;;
        7)start-stop;;
        8)int restart ; enter;;
        0)return 1;;
    esac
 }

while [[  $? -eq 0 ]]; do
  menuSSL
done
