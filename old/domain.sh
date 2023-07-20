#!/bin/bash

#source ../module
#ADMRufu="/etc/ADMRufu"
#ADM_src="${ADMRufu}/source"

ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | sed -n 1p)
public_ip=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$(wget -T 10 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/" || curl -m 10 -4Ls "http://ip1.dynupdate.no-ip.com/")")
ip_vps=$([[ -n "$public_ip" ]] && echo "$public_ip" || echo "$ip")

verific_ip(){
	title 'GENERADOR DE SUB-DOMINIOS'
	print_center -ama 'verificando ip del vps....'

	source <(curl -sSL "https://api.admrufu.ml/?request=info&salto=shell&dato=$ip_vps")
	del 1
	if [[ $status = 'true' ]]; then
		del 2
		print_center -ama 'tu direccion ip ya esta asociada al sub-dominio\n\n'
		print_center -verd "$name\n\n"
		print_center -ama 'se guardara para este servidor'
		enter
		echo "${name}" > ${ADM_src}/dominio.txt
		return 1
	elif [[ $status = 'false' ]]; then
		unset status
	else
		del 1
		print_center -ama 'oops!!!\nalgo salio mal, se cansela la operacion'
		enter
		return 1
	fi
}

getBase(){
	print_center -ama 'Verificando, dominio base....'
	source <(curl -sSL "https://api.admrufu.ml?salto=shell")
	del 1
	if [[ $status = 'false' ]]; then
		print_center -verm2 'Falla al verifcar el dominio base!\nEs posible que la funcion\nno se encuentre disponible'
		enter
		return 1
	elif [[ $status = 'true' ]]; then
		print_center -verd "Dominio base:  $dominio"
		msg -bar
		unset status
	else
		error
		return 1
	fi
	
}

getDatos(){
	print_center -ama "Igresa un nombre para tu sub-dominio, recuerda que\nel domino base se llama $dominio\ny solo deves escribir un nombre"
	in_opcion_down 'nombre para tu sub-dominio'
	name=$(echo "$opcion" | tr -d '[[:space:]]')
	del 5
	print_center -ama 'Verificando disponibilidad....'

	source <(curl -sSL "https://api.admrufu.ml/?request=info&salto=shell&dato=$name")
	del 1
	if [[ $status = 'true' ]]; then
		print_center -ama "el sub-dominio $name.$dominio\nno se encuentra disponible"
		enter
		return 1
	elif [[ $status = 'false' ]]; then
		unset status
	else
		error
		return 1
	fi
}

makeDomain(){
	print_center -ama "Generando sub-dominio $name.$dominio"

	source <(curl -sSL "https://api.admrufu.ml/?request=create&domi=$name&ip=$ip_vps")
	del 1
	if [[ $status = 'true' ]]; then
		echo "$name.$dominio" > ${ADM_src}/dominio.txt
		print_center -ama 'Se genero y guardo el sub-dominio\n'
		print_center -verd "$name.$dominio"
		enter
	elif [[ $status = 'false' ]]; then
		print_center -verm2 'falla al generar el sub-dominio'
		enter
	else
		error
	fi
}

error(){
	del 1
	print_center -verm2 'oops!!!\nalgo salio mal, se cansela la operacion'
	enter
}

words='verific_ip getBase getDatos makeDomain'
for i in $words; do
	$i
	[[ ! $? -eq 0 ]] && break
done