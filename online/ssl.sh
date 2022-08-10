#!/bin/bash

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
            cupsd|systemd-r|exim4|stunnel4|stunnel)continue;;
            *)DPB+=" $reQ:$Port";;
        esac
    done <<< "${portasVAR}"
 }

ssl_stunel(){
    [[ $(mportas|grep stunnel4|head -1) ]] && {
        clear
        msg -bar
        print_center -ama "Parando Stunnel"
        msg -bar
        service stunnel4 stop & >/dev/null 2>&1
        fun_bar 'apt-get purge stunnel4 -y' 'UNINSTALL STUNNEL4 '
        if crontab -l|grep '@reboot'|grep 'service'|grep 'stunnel4' &>/dev/null; then
            crontab -l > /root/cron
            sed -i '/@reboot service stunnel4 start/d' /root/cron
            crontab /root/cron
            rm /root/cron
        fi
        msg -bar
        print_center -verd "Stunnel detenido con Exito!"
        msg -bar
        sleep 2
        return
    }

    title "INSTALADOR SSL By @Rufu99"
    print_center -azu "Seleccione puerto de redireccion de trafico"
    msg -bar
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

    while [[ -z $opc ]]; do
        msg -ne " opcion: "
        read opc
        tput cuu1 && tput dl1

        if [[ -z $opc ]]; then
            msg -verm2 " selecciona una opcion entre 1 y $num_opc"
            unset opc
            sleep 2
            tput cuu1 && tput dl1
            continue
        elif [[ ! $opc =~ $numero ]]; then
            msg -verm2 " selecciona solo numeros entre 1 y $num_opc"
            unset opc
            sleep 2
            tput cuu1 && tput dl1
            continue
        elif [[ "$opc" -gt "$num_opc" ]]; then
            msg -verm2 " selecciona una opcion entre 1 y $num_opc"
            sleep 2
            tput cuu1 && tput dl1
            unset opc
            continue
        fi
    done

    title "INSTALADOR SSL By @Rufu99"
    echo -e "\033[1;33m Puerto de redireccion de trafico: \033[1;32m${drop[$opc]}"
    msg -bar
    while [[ -z $opc2 ]]; do
        echo -ne "\033[1;37m Ingrese un puerto para SSL: " && read opc2
        tput cuu1 && tput dl1

        [[ $(mportas|grep -w "${opc2}") = "" ]] && {
            echo -e "\033[1;33m $(fun_trans  "Puerto de ssl:")\033[1;32m ${opc2} OK"
        } || {
            echo -e "\033[1;33m $(fun_trans  "Puerto de ssl:")\033[1;31m ${opc2} FAIL" && sleep 2
            tput cuu1 && tput dl1
            unset opc2
        }
    done

    # openssl x509 -in 2.crt -text -noout |grep -w 'Issuer'|awk -F 'O = ' '{print $2}'|cut -d ',' -f1

    msg -bar
    fun_bar 'apt-get install stunnel4 -y' 'INSTALL STUNNEL4 '
    echo -e "client = no\ndelay = yes\nciphers = ALL\nsslVersion = ALL\nsocket = a:SO_REUSEADDR=1\nsocket = l:TCP_NODELAY=1\nsocket = r:TCP_NODELAY=1\n[SSL]\ncert = /etc/stunnel/stunnel.pem\naccept = ${opc2}\nconnect = 127.0.0.1:${drop[$opc]}" > /etc/stunnel/stunnel.conf

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
        msg -ne "Continuar, usando estre certificado [S/N]: "
        read opcion
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
    service stunnel4 restart > /dev/null 2>&1
    for ufww in `echo $opc2`; do
    	ufw allow $ufww/tcp > /dev/null 2>&1
    done
    msg -bar
    print_center -verd "INSTALADO CON EXITO"
    msg -bar
    rm -rf ${ADM_tmp}/stunnel.crt > /dev/null 2>&1
    rm -rf ${ADM_tmp}/stunnel.key > /dev/null 2>&1
    sleep 3
    return
}

add_port(){
    title "INSTALADOR SSL By @Rufu99"
    print_center -azu "Seleccione puerto de redireccion de trafico"
    msg -bar
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

    while [[ -z $opc ]]; do
        msg -ne " opcion: "
        read opc
        tput cuu1 && tput dl1

        if [[ -z $opc ]]; then
            msg -verm2 " selecciona una opcion entre 1 y $num_opc"
            unset opc
            sleep 2
            tput cuu1 && tput dl1
            continue
        elif [[ ! $opc =~ $numero ]]; then
            msg -verm2 " selecciona solo numeros entre 1 y $num_opc"
            unset opc
            sleep 2
            tput cuu1 && tput dl1
            continue
        elif [[ "$opc" -gt "$num_opc" ]]; then
            msg -verm2 " selecciona una opcion entre 1 y $num_opc"
            sleep 2
            tput cuu1 && tput dl1
            unset opc
            continue
        fi
    done

    title "INSTALADOR SSL By @Rufu99"
    echo -e "\033[1;33m Puerto de redireccion de trafico: \033[1;32m${drop[$opc]}"
    msg -bar
    while [[ -z $opc2 ]]; do
        echo -ne "\033[1;37m Ingrese un puerto para SSL: " && read opc2
        tput cuu1 && tput dl1

        [[ $(mportas|grep -w "${opc2}") = "" ]] && {
            echo -e "\033[1;33m $(fun_trans  "Puerto de ssl:")\033[1;32m ${opc2} OK"
        } || {
            echo -e "\033[1;33m $(fun_trans  "Puerto de ssl:")\033[1;31m ${opc2} FAIL" && sleep 2
            tput cuu1 && tput dl1
            unset opc2
        }
    done
    echo -e "client = no\n[SSL+]\ncert = /etc/stunnel/stunnel.pem\naccept = ${opc2}\nconnect = 127.0.0.1:${drop[$opc]}" >> /etc/stunnel/stunnel.conf
    service stunnel4 restart > /dev/null 2>&1
    msg -bar
    print_center -verd "PUERTO AGREGADO CON EXITO"
    enter
    return
}

start-stop(){
	clear
	msg -bar
	if [[ $(service stunnel4 status|grep -w 'Active'|awk -F ' ' '{print $2}') = 'inactive' ]]; then
		if service stunnel4 start &> /dev/null ; then
			print_center -verd "Servicio stunnel4 iniciado"
		else
			print_center -verm2 "Falla al iniciar Servicio stunnel4"
		fi
	else
		if service stunnel4 stop &> /dev/null ; then
			print_center -verd "Servicio stunnel4 detenido"
		else
			print_center -verm2 "Falla al detener Servicio stunnel4"
		fi
	fi
	enter
	return
}

del_port(){
	sslport=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN"|grep -E 'stunnel|stunnel4')
	if [[ $(echo "$sslport"|wc -l) -lt '2' ]];then
		clear
		msg -bar
		print_center -ama "Un solo puerto para eliminar\ndesea detener el servicio?	"
		msg -bar
		msg -ne " opcion [S/N]: " && read a

		if [[ "$a" = @(S|s) ]]; then
			clear
			msg -bar
			if service stunnel4 stop &> /dev/null ; then
				print_center -verd "Servicio stunnel4 detenido"
			else
				print_center -verm2 "Falla al detener Servicio stunnel4"
			fi		
		fi
		enter
		return
	fi

	title "seleccione el num de puerto a quitar"
    n=1
    while read i; do
        port=$(echo $i|awk -F ' ' '{print $9}'|cut -d ':' -f2)
        echo -e " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -azu "$port")"
        drop[$n]=$port
        num_opc="$n"
        let n++ 
    done <<< $(echo "$sslport")
    back

    while [[ -z $opc ]]; do
        msg -ne " opcion: "
        read opc
        tput cuu1 && tput dl1

        if [[ -z $opc ]]; then
            msg -verm2 " selecciona una opcion entre 1 y $num_opc"
            unset opc
            sleep 2
            tput cuu1 && tput dl1
            continue
        elif [[ ! $opc =~ $numero ]]; then
            msg -verm2 " selecciona solo numeros entre 1 y $num_opc"
            unset opc
            sleep 2
            tput cuu1 && tput dl1
            continue
        elif [[ "$opc" -gt "$num_opc" ]]; then
            msg -verm2 " selecciona una opcion entre 1 y $num_opc"
            sleep 2
            tput cuu1 && tput dl1
            unset opc
            continue
        fi
    done

    in=$(( $(cat "/etc/stunnel/stunnel.conf"|grep -n "accept = ${drop[$opc]}"|cut -d ':' -f1) - 3 ))
    en=$(( $in + 4))
    sed -i "$in,$en d" /etc/stunnel/stunnel.conf
    sed -i '2 s/\[SSL+\]/\[SSL\]/' /etc/stunnel/stunnel.conf

    title "Puerto ssl ${drop[$opc]} eliminado"

    if service stunnel4 restart &> /dev/null ; then
    	print_center -verd "Servicio stunnel4 reiniciado"
	else
		print_center -verm2 "Falla al reiniciar Servicio stunnel4"
	fi
	enter
	return
}

edit_port(){
	sslport=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN"|grep -E 'stunnel|stunnel4')
	title "seleccione el num de puerto a editar"
    n=1
    while read i; do
        port=$(echo $i|awk -F ' ' '{print $9}'|cut -d ':' -f2)
        echo -e " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -azu "$port")"
        drop[$n]=$port
        num_opc="$n"
        let n++ 
    done <<< $(echo "$sslport")
    back
    while [[ -z $opc ]]; do
        msg -ne " opcion: "
        read opc
        tput cuu1 && tput dl1
        if [[ -z $opc ]]; then
            msg -verm2 " selecciona una opcion entre 1 y $num_opc"
            unset opc
            sleep 2
            tput cuu1 && tput dl1
            continue
        elif [[ ! $opc =~ $numero ]]; then
            msg -verm2 " selecciona solo numeros entre 1 y $num_opc"
            unset opc
            sleep 2
            tput cuu1 && tput dl1
            continue
        elif [[ "$opc" -gt "$num_opc" ]]; then
            msg -verm2 " selecciona una opcion entre 1 y $num_opc"
            sleep 2
            tput cuu1 && tput dl1
            unset opc
            continue
        fi
    done
    title "Configuracion actual"
    in=$(( $(cat "/etc/stunnel/stunnel.conf"|grep -n "accept = ${drop[$opc]}"|cut -d ':' -f1) + 1 ))
    en=$(sed -n "${in}p" /etc/stunnel/stunnel.conf|cut -d ':' -f2)
    print_center -ama "${drop[$opc]} >>> $en"
    msg -bar
    drop_port
    n=1
    for i in $DPB; do
    	port=$(echo $i|awk -F ":" '{print $2}')
        [[ "$port" = "$en" ]] && continue
        proto=$(echo $i|awk -F ":" '{print $1}')
        proto2=$(printf '%-12s' "$proto")
        echo -e " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -ama "$proto2")$(msg -azu "$port")"
        drop[$n]=$port
        num_opc="$n"
        let n++ 
    done
    msg -bar
    unset opc
    while [[ -z $opc ]]; do
        msg -ne " opcion: "
        read opc
        tput cuu1 && tput dl1

        if [[ -z $opc ]]; then
            msg -verm2 " selecciona una opcion entre 1 y $num_opc"
            unset opc
            sleep 2
            tput cuu1 && tput dl1
            continue
        elif [[ ! $opc =~ $numero ]]; then
            msg -verm2 " selecciona solo numeros entre 1 y $num_opc"
            unset opc
            sleep 2
            tput cuu1 && tput dl1
            continue
        elif [[ "$opc" -gt "$num_opc" ]]; then
            msg -verm2 " selecciona una opcion entre 1 y $num_opc"
            sleep 2
            tput cuu1 && tput dl1
            unset opc
            continue
        fi
    done
    sed -i "$in s/$en/${drop[$opc]}/" /etc/stunnel/stunnel.conf
    title "Puerto de redirecion modificado"
    if service stunnel4 restart &> /dev/null ; then
    	print_center -verd "Servicio stunnel4 reiniciado"
	else
		print_center -verm2 "Falla al reiniciar Servicio stunnel4"
	fi
	enter
	return
}

restart(){
	if service stunnel4 restart &> /dev/null ; then
    	print_center -verd "Servicio stunnel4 reiniciado"
	else
		print_center -verm2 "Falla al reiniciar Servicio stunnel4"
	fi
	enter
}

edit_nano(){
	nano /etc/stunnel/stunnel.conf
	restart
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
    echo -e "$(msg -verd " [1]") $(msg -verm2 ">") $(msg -verd "INSTALAR") $(msg -ama "-") $(msg -verm2 "DESINSTALAR")"
    n=1
    if [[ $(dpkg -l|grep 'stunnel'|awk -F ' ' '{print $2}') ]]; then
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
        8)restart;;
        0)return 1;;
    esac
}

while [[  $? -eq 0 ]]; do
  menuSSL
done
