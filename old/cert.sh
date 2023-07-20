#!/bin/bash
# CertGenDomi
#====FUNCIONES==========

cert_install(){
    #apt install socat netcat -y
    if [[ ! -e $HOME/.acme.sh/acme.sh ]];then
    	msg -bar3
    	msg -ama " Instalando script acme.sh"
    	curl -s "https://get.acme.sh" | sh &>/dev/null
    fi
    if [[ ! -z "${mail}" ]]; then
    	title "LOGEANDO EN Zerossl"
    	$HOME/.acme.sh/acme.sh --register-account  -m ${mail} --server zerossl
    	$HOME/.acme.sh/acme.sh --set-default-ca --server zerossl
    else
    	title "APLICANDO SERVIDOR letsencrypt"
    	$HOME/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    fi
    enter
    title "GENERANDO CERTIFICADO SSL"
    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force; then
    	"$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath ${ADM_crt}/${domain}.crt --keypath ${ADM_crt}/${domain}.key --ecc --force &>/dev/null
    	#rm -rf $HOME/.acme.sh/${domain}_ecc
    	msg -bar
    	print_center -verd "Certificado SSL se genero con éxito"
    	enter
    	return
    else
    	rm -rf "$HOME/.acme.sh/${domain}_ecc"
    	msg -bar
    	print_center -verm2 "Error al generar el certificado SSL"
    	msg -bar
    	print_center -ama 'verifique los posibles error\ne intente de nuevo'
    	enter
    	return
    fi
 }

ext_cert(){
	unset cert
	declare -A cert
	title "INTALADOR DE CERTIFICADO EXTERNO"
	print_center -azu "Requiere tener a mano su certificado ssl"
	print_center -azu "junto a su correspondiente clave privada"
	msg -bar
	msg -ne " Continuar...[S/N]: "
	read opcion
	[[ $opcion != @(S|s|Y|y) ]] && return


	title "INGRESE EL CONTENIDO DE SU CERTIFICADO SSL"
	msg -ama ' a continuacion se abrira el editor de texto nano 
 ingrese el contenido de su certificado
 guardar precionando "CTRL+x"
 luego "S o Y" segun el idioma
 y por ultimo "enter"'
 	msg -bar
 	msg -ne " Continuar...[S/N]: "
	read opcion
	[[ $opcion != @(S|s|Y|y) ]] && return
	rm -rf ${ADM_tmp}/tmp.crt
	clear
	nano ${ADM_tmp}/tmp.crt

	title "INGRESE EL CONTENIDO DE CLAVE PRIVADA"
	msg -ama ' a continuacion se abrira el editor de texto nano 
 ingrese el contenido de su clave privada.
 guardar precionando "CTRL+x"
 luego "S o Y" segun el idioma
 y por ultimo "enter"'
 	msg -bar
 	msg -ne " Continuar...[S/N]: "
	read opcion
	[[ $opcion != @(S|s|Y|y) ]] && return
	${ADM_tmp}/tmp.key
	clear
	nano ${ADM_tmp}/tmp.key

	if openssl x509 -in ${ADM_tmp}/tmp.crt -text -noout &>/dev/null ; then
		DNS=$(openssl x509 -in ${ADM_tmp}/tmp.crt -text -noout | grep 'DNS:'|sed 's/, /\n/g'|sed 's/DNS:\| //g')
		rm -rf ${ADM_crt}/*
		if [[ $(echo "$DNS"|wc -l) -gt "1" ]]; then
			DNS="multi-domain"
		fi
		mv ${ADM_tmp}/tmp.crt ${ADM_crt}/$DNS.crt
		mv ${ADM_tmp}/tmp.key ${ADM_crt}/$DNS.key

		title "INSTALACION COMPLETA"
		echo -e "$(msg -verm2 "Domi: ")$(msg -ama "$DNS")"
		echo -e "$(msg -verm2 "Emit: ")$(msg -ama "$(openssl x509 -noout -in ${ADM_crt}/$DNS.crt -startdate|sed 's/notBefore=//g')")"
		echo -e "$(msg -verm2 "Expi: ")$(msg -ama "$(openssl x509 -noout -in ${ADM_crt}/$DNS.crt -enddate|sed 's/notAfter=//g')")"
		echo -e "$(msg -verm2 "Cert: ")$(msg -ama "$(openssl x509 -noout -in ${ADM_crt}/$DNS.crt -issuer|sed 's/issuer=//g'|sed 's/ = /=/g'|sed 's/, /\n      /g')")"
		msg -bar
		echo "$DNS" > ${ADM_src}/dominio.txt
		read foo
	else
		rm -rf ${ADM_tmp}/tmp.crt
		rm -rf ${ADM_tmp}/tmp.key
		title -verm2 'ERROR DE DATOS'
		msg -ama " Los datos ingresados no son validos.\n por favor verifique.\n e intente de nuevo!!"
		enter
	fi
	return
}

stop_port(){
	msg -bar3
	msg -ama " Comprovando puertos..."
	ports=('80' '443')

	for i in ${ports[@]}; do
		if [[ 0 -ne $(lsof -i:$i | grep -i -c "listen") ]]; then
			msg -bar3
			echo -ne "$(msg -ama " Liberando puerto: $i")"
			lsof -i:$i | awk '{print $2}' | grep -v "PID" | xargs kill -9
			sleep 2s
			if [[ 0 -ne $(lsof -i:$i | grep -i -c "listen") ]];then
				del 1
				print_center -verm2 "ERROR AL LIBERAR PURTO $i"
				msg -bar3
				msg -ama " Puerto $i en uso."
				msg -ama " auto-liberacion fallida"
				msg -ama " detenga el puerto $i manualmente"
				msg -ama " e intentar nuevamente..."
				enter
				return		
			fi
		fi
	done
 }

ger_cert(){
	clear
	case $1 in
		1)title "Generador De Certificado Let's Encrypt";;
		2)title "Generador De Certificado Zerossl";;
	esac
	print_center -ama "Requiere ingresar un dominio.\nel mismo solo deve resolver DNS, y apuntar\na la direccion ip de este servidor."
	msg -bar3
	print_center -ama "Temporalmente requiere tener\nlos puertos 80 y 443 libres."
	[[ $1 = 2 ]] && msg -bar3 && print_center -ama "Requiere tener una cuenta Zerossl."
	msg -bar
	in_opcion -nama 'Continuar [S/N]'
	[[ $opcion != @(s|S|y|Y) ]] && return

	if [[ $1 = 2 ]]; then
     while [[ -z $mail ]]; do
     	clear
		msg -bar
		print_center -ama "ingresa tu correo usado en zerossl"
		msg -bar3
		msg -ne " >>> "
		read mail
	 done
	fi

	if [[ -e ${ADM_src}/dominio.txt ]]; then
		domain=$(cat ${ADM_src}/dominio.txt)
		[[ $domain = "multi-domain" ]] && unset domain
		if [[ ! -z $domain ]]; then
			title -ama 'Dominio asociado a esta ip'
			echo -e "$(msg -verm2 " >>> ") $(msg -ama "$domain")"
			in_opcion -nama 'Continuar, usando este dominio? [S/N]'
			del 2
			[[ $opcion != @(S|s|Y|y) ]] && unset domain
		fi
	fi

	while [[ -z $domain ]]; do
		clear
		msg -bar
		print_center -ama "ingresa tu dominio"
		msg -bar3
		msg -ne " >>> "
		read domain
	done
	msg -bar3
	msg -ama " Comprovando direccion IP ..."
	local_ip=$(wget -qO- ipv4.icanhazip.com)
    domain_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
    sleep 3
    [[ -z "${domain_ip}" ]] && domain_ip="ip no encontrada"
    if [[ $(echo "${local_ip}" | tr '.' '+' | bc) -ne $(echo "${domain_ip}" | tr '.' '+' | bc) ]]; then
    	title -verm2 'ERROR DE DIRECCION IP'
    	print_center -ama "La direccion ip del dominio\n no coincide con la del servidor."
    	msg -bar3
    	echo -e " $(msg -azu "IP dominio:  ")$(msg -verm2 "${domain_ip}")"
    	echo -e " $(msg -azu "IP servidor: ")$(msg -verm2 "${local_ip}")"
    	msg -bar3
    	msg -ama " Verifique su dominio, e intente de nuevo."
    	enter
    	return
    fi

    
    stop_port
    cert_install
    echo "$domain" > ${ADM_src}/dominio.txt
    return
}

#======MENU======
menu_cert(){
title "SUB-DOMINIO Y CERTIFICADO SSL"
menu_func "GENERAR CERT SSL (Let's Encrypt)" "GENERAR CERT SSL (Zerossl)" "INGRESAR CERT SSL EXTERNO" "GENERAR SUB-DOMINIO"
back

opcion=$(selection_fun 4)

case $opcion in
	1)ger_cert 1;;
	2)ger_cert 2;;
	3)ext_cert;;
	4)${ADM_inst}/domain.sh;;
	0)return 1;;
esac
}

while [[  $? -eq 0 ]]; do
	menu_cert
done


