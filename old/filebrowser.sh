#!/bin/bash

install_file(){
	filemanager_os="unsupported"
	filemanager_arch="unknown"

	filemanager_bin="filebrowser"
	filemanager_dl_ext=".tar.gz"

	unamem="$(uname -m)"
	case $unamem in
		*64*)filemanager_arch="amd64";;
		*86*)filemanager_arch="386";;
		   *) clear
		   	  msg -bar
		   	  print_center -ama "instalacion conselada\narquitectura $unamem no soportada"
		   	  enter
		   	  return;;
	esac

	unameu="$(tr '[:lower:]' '[:upper:]' <<<$(uname))"
	if [[ $unameu == *LINUX* ]]; then
		filemanager_os="linux"
	else
		clear
		msg -bar
		print_center -ama "instalacion conselada\nSistema $unameu no soportada"
		enter
		return
	fi

	if type -p curl >/dev/null 2>&1; then
		net_getter="curl -fsSL"
	elif type -p wget >/dev/null 2>&1; then
		net_getter="wget -qO-"
	else
		clear
		print_center -ama "instalacion canselada\nNo se encontro curl o wget"
		return
	fi

	filemanager_file="${filemanager_os}-$filemanager_arch-filebrowser$filemanager_dl_ext"
	filemanager_tag="$(${net_getter}  https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep -o '"tag_name": ".*"' | sed 's/"//g' | sed 's/tag_name: //g')"
	filemanager_url="https://github.com/filebrowser/filebrowser/releases/download/$filemanager_tag/$filemanager_file"

	rm -rf "/tmp/$filemanager_file"

	${net_getter} "$filemanager_url" > "/tmp/$filemanager_file"

	tar -xzf "/tmp/$filemanager_file" -C "/tmp/" "$filemanager_bin"

	chmod +x "/tmp/$filemanager_bin"

	mv "/tmp/$filemanager_bin" "$install_path/$filemanager_bin"

	if setcap_cmd=$(PATH+=$PATH:/sbin type -p setcap); then
		$sudo_cmd $setcap_cmd cap_net_bind_service=+ep "$install_path/$filemanager_bin"
	fi

	rm -- "/tmp/$filemanager_file"

	if [[ -d /etc/filebrowser ]]; then
		rm -rf /etc/filebrowser
	fi

	adduser --system --group --HOME /etc/filebrowser/ --shell /usr/sbin/nologin --no-create-home filebrowser &>/dev/null
	mkdir -p /etc/filebrowser/style
	chown -Rc filebrowser:filebrowser /etc/filebrowser &>/dev/null
	chmod -R +x /etc/filebrowser
	touch /etc/filebrowser/filebrowser.log
	chown -c filebrowser:filebrowser /etc/filebrowser/filebrowser.log &>/dev/null

	ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | sed -n 1p)

	cat <<EOF > /etc/filebrowser/.filebrowser.toml
address = "$ip"
port = 8000
root = "/root"
database = "/etc/filebrowser/filebrowser.db"
log = "/etc/filebrowser/filebrowser.log"
EOF

cat <<EOF > /etc/filebrowser/style/custom.css
:root {
  --background: #141D24;
  --surfacePrimary: #20292F;
  --surfaceSecondary: #3A4147;
  --divider: rgba(255, 255, 255, 0.12);
  --icon: #ffffff;
  --textPrimary: rgba(255, 255, 255, 0.87);
  --textSecondary: rgba(255, 255, 255, 0.6);
}

body {
  background: var(--background);
  color: var(--textPrimary);
}

#loading {
  background: var(--background);
}
#loading .spinner div, main .spinner div {
  background: var(--icon);
}

#login {
  background: var(--background);
}

header {
  background: var(--surfacePrimary);
}

#search #input {
  background: var(--surfaceSecondary);
  border-color: var(--surfacePrimary);
}
#search #input input::placeholder {
  color: var(--textSecondary);
}
#search.active #input {
  background: var(--surfacePrimary);
}
#search.active input {
  color: var(--textPrimary);
}
#search #result {
  background: var(--background);
  color: var(--textPrimary);
}
#search .boxes {
  background: var(--surfaceSecondary);
}
#search .boxes h3 {
  color: var(--textPrimary);
}

.action {
  color: var(--textPrimary) !important;
}
.action:hover {
  background-color: rgba(255, 255, 255, .1);
}
.action i {
  color: var(--icon) !important;
}
.action .counter {
  border-color: var(--surfacePrimary);
}

nav > div {
  border-color: var(--divider);
}

.breadcrumbs {
  border-color: var(--divider);
  color: var(--textPrimary) !important;
}
.breadcrumbs span {
  color: var(--textPrimary) !important;
}
.breadcrumbs a:hover {
  background-color: rgba(255, 255, 255, .1);
}

#listing .item {
  background: var(--surfacePrimary);
  color: var(--textPrimary);
  border-color: var(--divider) !important;
}
#listing .item i {
  color: var(--icon);
}
#listing .item .modified {
  color: var(--textSecondary);
}
#listing h2,
#listing.list .header span {
  color: var(--textPrimary) !important;
}
#listing.list .header span {
  color: var(--textPrimary);
}
#listing.list .header i {
  color: var(--icon);
}
#listing.list .item.header {
  background: var(--background);
}

.message {
  color: var(--textPrimary);
}

.card {
  background: var(--surfacePrimary);
  color: var(--textPrimary);
}
.button--flat:hover {
  background: var(--surfaceSecondary);
}

.dashboard #nav ul li {
  color: var(--textSecondary);
}
.dashboard #nav ul li:hover {
  background: var(--surfaceSecondary);
}

.card h3,
.dashboard #nav,
.dashboard p label {
  color: var(--textPrimary);
}
.card#share input,
.card#share select,
.input {
  background: var(--surfaceSecondary);
  color: var(--textPrimary);
  border: 1px solid rgba(255, 255, 255, 0.05);
}
.input:hover,
.input:focus {
  border-color: rgba(255, 255, 255, 0.15);
}
.input--red {
  background: #73302D;
}

.input--green {
  background: #147A41;
}

.dashboard #nav .wrapper,
.collapsible {
  border-color: var(--divider);
}
.collapsible > label * {
  color: var(--textPrimary);
}

table th {
  color: var(--textSecondary);
}

.file-list li:hover {
  background: var(--surfaceSecondary);
}
.file-list li:before {
  color: var(--textSecondary);
}
.file-list li[aria-selected=true]:before {
  color: var(--icon);
}

.shell {
  background: var(--surfacePrimary);
  color: var(--textPrimary);
}
.shell__result {
  border-top: 1px solid var(--divider);
}

#editor-container {
  background: var(--background);
}

#editor-container .bar {
  background: var(--surfacePrimary);
}

@media (max-width: 736px) {
  #file-selection {
    background: var(--surfaceSecondary) !important;
  }
  #file-selection span {
    color: var(--textPrimary) !important;
  }
  nav {
    background: var(--surfaceSecondary) !important;
  }
  #dropdown {
    background: var(--surfaceSecondary) !important;
  }
}

.share__box {
  background: var(--surfacePrimary) !important;
  color: var(--textPrimary);
}

.share__box__element {
  border-top-color: var(--divider);
}
EOF

cat <<EOF > /etc/systemd/system/filebrowser.service
[Unit]
Description=Web File Browser
After=network.target

[Service]
SuccessExitStatus=1
Type=simple
ExecStart=/usr/local/bin/filebrowser

[Install]
WantedBy=multi-user.target
EOF

	chmod +x /etc/filebrowser/.filebrowser.toml
	chmod +x /etc/filebrowser/style/custom.css
	chmod +x /etc/systemd/system/filebrowser.service

	if type -p $filemanager_bin >/dev/null 2>&1; then
		set_autoport
		set_user
		set_password
		filebrowser config init --branding.name 'ADMRufu' --locale es --branding.disableExternal --branding.files '/etc/filebrowser/style' &>/dev/null
		filebrowser users add "$user" "$pass" --locale es --perm.admin &>/dev/null
		systemctl enable filebrowser &>/dev/null
		systemctl start filebrowser &>/dev/null
		ufw allow $port_f/tcp &>/dev/null
		print_center -verd "instalacion completa!!!"
		enter
	else
		rm -rf /etc/filebrowser
		rm -rf /usr/local/bin/filebrowser
		rm -rf /etc/systemd/system/filebrowser.service
		print_center -verm2 "falla de instalacion!!!"
		enter
	fi
}

set_user(){
	while [[ -z $user ]]; do
		in_opcion -nama "Nombre de usuario [admin]"
		tput cuu1 && tput dl1
		user="$opcion"
		if [[ "$user" =~ "$tx_num"  ]]; then
			print_center -verm2 'ingresa solo numeros y letras'
			sleep 2
			unset user
		fi
	done
}

set_password(){
	while [[ -z $pass ]]; do
		in_opcion -nama "Contraseña de usuario [admin]"
		tput cuu1 && tput dl1
		pass=$opcion
		if [[ "$pass" =~ "$tx_num"  ]]; then
			print_center -verm2 'ingresa solo numeros y letras'
			sleep 2
			unset pass
		fi
	done
}

set_autoport(){
	port_f=8000
	while [[ -z $opc ]]; do
        if [[ $(mportas|grep -w "$port_f") = '' ]]; then
        	opc=$port_f
        else
        	let port_f++
        fi
    done
    port_f=$port_f
    oldP=$(grep 'port' /etc/filebrowser/.filebrowser.toml)
	sed -i "s/$oldP/port = $port_f/g" /etc/filebrowser/.filebrowser.toml
}

desinstal_file(){
	if [[ $(systemctl is-active filebrowser) = 'active' ]]; then
		systemctl stop filebrowser &>/dev/null
	fi
	if [[ $(systemctl is-enabled filebrowser) = 'enabled' ]]; then
		systemctl disable filebrowser &>/dev/null
	fi
	userdel filebrowser &>/dev/null
	rm -rf /etc/filebrowser
	rm -rf /usr/local/bin/filebrowser
	rm -rf /etc/systemd/system/filebrowser.service
	print_center -ama "filebrowser desinstalado!!!!"
	enter
}

on(){
	set_autoport
	systemctl start filebrowser &>/dev/null
	ufw allow $port_f/tcp &>/dev/null
	if [[ $(systemctl is-enabled filebrowser) = 'disabled' ]]; then
		systemctl enable filebrowser &>/dev/null
	fi
	print_center -verd "filebrowser iniciado!!!"
}

off(){
	systemctl stop filebrowser &>/dev/null
	if [[ $(systemctl is-enabled filebrowser) = 'enabled' ]]; then
		systemctl disable filebrowser &>/dev/null
	fi
	print_center -ama "filebrowser detenido!!!"
}

on_off_file(){
	sta=$(systemctl is-active filebrowser)
	case $sta in
		active)off;;
		failed|inactive)on;;
	esac
	enter
}

reload_file(){
	set_autoport
	systemctl restart filebrowser &>/dev/null
	ufw allow $port_f/tcp &>/dev/null
	print_center -ama "servicio filebrowser reiniciado!!!"
	enter
}

set_name_user(){
	set_user
	act=0
	if [[ $(systemctl is-active filebrowser) = 'active' ]]; then
		systemctl stop filebrowser &>/dev/null
		act=1
	fi
	filebrowser users update 1 --username "$user" &>/dev/null
	if [[ $act = 1 ]]; then
		systemctl start filebrowser &>/dev/null
	fi
	print_center -ama "nombre actualizado!!!"
	enter
}

set_pass(){
	set_password
	act=0
	if [[ $(systemctl is-active filebrowser) = 'active' ]]; then
		systemctl stop filebrowser &>/dev/null
		act=1
	fi
	filebrowser users update 1 --password "$pass" &>/dev/null
	if [[ $act = 1 ]]; then
		systemctl start filebrowser &>/dev/null
	fi
	print_center -ama "Contraseña actualizada!!!"
	enter
}

act_root(){
	act=0
	if [[ $(systemctl is-active filebrowser) = 'active' ]]; then
		systemctl stop filebrowser &>/dev/null
		act=1
	fi
	opcion=$(filebrowser users ls|grep '1'|awk -F ' ' '{print $3}')
	case $opcion in
		.)filebrowser users update 1 --scope '/' &>/dev/null
		  print_center -verd 'acceso root activo!!!!';;
		/)filebrowser users update 1 --scope '.' &>/dev/null
		  print_center -ama 'acceso root desavilitado!!!!';;
	esac
	if [[ $act = 1 ]]; then
		systemctl start filebrowser &>/dev/null
	fi
	enter
}

menu_file(){
	install_path="/usr/local/bin"
	if [[ ! -d $install_path ]]; then
		install_path="/usr/bin"
	fi

	title "ADMINISTRADOR DE ARCHIVOS WEB"
	nu=1
	if [[ -e "$install_path/filebrowser" ]]; then

		std='\e[1m\e[31m[OFF]'
		if [[ $(systemctl is-active filebrowser) = 'active' ]]; then
			port=$(grep 'port' /etc/filebrowser/.filebrowser.toml|cut -d ' ' -f3)
			print_center -ama 'En tu navegador web usa este url'
			print_center -teal "http://$(fun_ip):$port"
			msg -bar
			std='\e[1m\e[32m[ON]'
		fi
		echo " $(msg -verd '[1]') $(msg -verm2 '>') $(msg -verm2 'DESINSTALAR FILEBROWSER')" && de="$nu"; in='a'
		echo -e " $(msg -verd '[2]') $(msg -verm2 '>') $(msg -verd 'INICIAR')$(msg -ama '/')$(msg -verm2 'DETENER') $std"
		echo " $(msg -verd '[3]') $(msg -verm2 '>') $(msg -azu 'REINICIAR')"
		msg -bar3
		echo " $(msg -verd '[4]') $(msg -verm2 '>') $(msg -ama 'MODIFICAR NOMBRE DE USUARIO')"
		echo " $(msg -verd '[5]') $(msg -verm2 '>') $(msg -ama 'MODIFICAR CONTRASEÑA')"
		msg -bar3
		echo " $(msg -verd '[6]') $(msg -verm2 '>') $(msg -verd 'ACTIVAR')$(msg -ama '/')$(msg -verm2 'DESACTIVAR') $(msg -azu 'ACCESO ROOT')" && nu=6
	else
		echo " $(msg -verd '[1]') $(msg -verm2 '>') $(msg -verd 'INSTALAR FILEBROWSER')" && in="$nu"; de='a'
	fi
	back
	opcion=$(selection_fun $nu)
	case $opcion in
		"$in")install_file;;
		"$de")desinstal_file;;
			2)on_off_file;;
			3)reload_file;;
			4)set_name_user;;
			5)set_pass;;
			6)act_root;;
			0)return 1;;
	esac
}

while [[  $? -eq 0 ]]; do
	menu_file
done