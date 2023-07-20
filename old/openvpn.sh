#!/bin/bash

function isBash(){
	if readlink /proc/$$/exe | grep -q "dash"; then
		return 1
	fi
}

function isRoot() {
	if [ "$EUID" -ne 0 ]; then
		return 1
	fi
}

function tunAvailable() {
	if [ ! -e /dev/net/tun ]; then
		return 1
	fi
}

checkOS() {
	if [[ -e /etc/debian_version ]]; then
		OS="debian"
		source /etc/os-release

		if [[ $ID == "debian" || $ID == "raspbian" ]]; then
			if [[ $VERSION_ID -lt 9 ]]; then
				title "⚠️ Su versión de Debian no es compatible."
				print_center -ama "Sin embargo, si está utilizando\nDebian> = 9 o inestable/prueba\npuede continuar, bajo su propio riesgo."
				msg -bar
				until [[ $CONTINUE =~ (y|n) ]]; do
					in_opcion -nazu 'Continuar? [y/n]'
					CONTINUE=$opcion
				done
				if [[ $CONTINUE == "n" ]]; then
					return 1
				fi
			fi
		elif [[ $ID == "ubuntu" ]]; then
			OS="ubuntu"
			MAJOR_UBUNTU_VERSION=$(echo "$VERSION_ID" | cut -d '.' -f1)
			if [[ $MAJOR_UBUNTU_VERSION -lt 16 ]]; then
				title "⚠️ Su versión de Ubuntu no es compatible."
				print_center -ama "Sin embargo, si está utilizando\nUbuntu> = 16.04 o beta\npuede continuar, bajo su propio riesgo."
				msg -bar
				until [[ $CONTINUE =~ (y|n) ]]; do
					in_opcion -nazu 'Continuar? [y/n]'
					CONTINUE=$opcion
				done
				if [[ $CONTINUE == "n" ]]; then
					return 1
				fi
			fi
		fi
	elif [[ -e /etc/system-release ]]; then
		source /etc/os-release
		if [[ $ID == "fedora" || $ID_LIKE == "fedora" ]]; then
			OS="fedora"
		fi
		if [[ $ID == "centos" || $ID == "rocky" || $ID == "almalinux" ]]; then
			OS="centos"
			if [[ ! $VERSION_ID =~ (7|8) ]]; then
				title "⚠️ Su versión de CentOS no es compatible."
				echo ""
				print_center -ama "El script solo admite CentOS 7 y CentOS 8."
				enter
				return 1
			fi
		fi
		if [[ $ID == "ol" ]]; then
			OS="oracle"
			if [[ ! $VERSION_ID =~ (8) ]]; then
				title "⚠️ Su versión de Oracle Linux no es compatible."
				print_center -ama "El script solo admite Oracle Linux 8."
				enter
				return 1
			fi
		fi
		if [[ $ID == "amzn" ]]; then
			OS="amzn"
			if [[ $VERSION_ID != "2" ]]; then
				title "⚠️ Su versión de Amazon Linux no es compatible."
				print_center -ama "El script solo admite Amazon Linux 2."
				enter
				return 1
			fi
		fi
	elif [[ -e /etc/arch-release ]]; then
		OS=arch
	else
		msg -bar
		print_center -ama 'No está ejecutando este instal en Sistema\nDebian, Ubuntu, Fedora, Centos\nAmazon Linux 2, Oracle Linux 8 o Arch Linux Linux.'
		enter
		return 1
	fi
}

function initialCheck() {
	if ! isBash; then
		title -verm2 'Este script deve utilizarse con bash'
		enter
		return 1
	fi
	if ! isRoot; then
		title -verm2 'Lo siento, debes ejecutar esto como root'
		enter
		return 1
	fi
	if ! tunAvailable; then
		title -verm2 'Tun no está disponible'
		enter
		return 1
	fi
	checkOS
	GROUPNAME=nogroup
}

agrega_dns(){
	msg -ama " Escriba el HOST DNS que desea Agregar"
	read -p " [NewDNS]: " SDNS
	cat /etc/hosts|grep -v "$SDNS" > /etc/hosts.bak && mv -f /etc/hosts.bak /etc/hosts
	if [[ -e /etc/opendns ]]; then
		cat /etc/opendns > /tmp/opnbak
		mv -f /tmp/opnbak /etc/opendns
		echo "$SDNS" >> /etc/opendns 
	else
		echo "$SDNS" > /etc/opendns
	fi
	[[ -z $NEWDNS ]] && NEWDNS="$SDNS" || NEWDNS="$NEWDNS $SDNS"
	unset SDNS
}

dns_fun(){
	case $1 in
		1)
			if grep -q "127.0.0.53" "/etc/resolv.conf"; then
				RESOLVCONF='/run/systemd/resolve/resolv.conf'
			else
				RESOLVCONF='/etc/resolv.conf'
			fi 
			grep -v '#' $RESOLVCONF | grep 'nameserver' | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | while read line; do
				echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server.conf
			done;;
		2) #cloudflare
			echo 'push "dhcp-option DNS 1.1.1.1"' >> /etc/openvpn/server.conf
			echo 'push "dhcp-option DNS 1.0.0.1"' >> /etc/openvpn/server.conf;;
		3) #google
			echo 'push "dhcp-option DNS 8.8.8.8"' >> /etc/openvpn/server.conf
			echo 'push "dhcp-option DNS 8.8.4.4"' >> /etc/openvpn/server.conf;;
		4) #OpenDNS
			echo 'push "dhcp-option DNS 208.67.222.222"' >> /etc/openvpn/server.conf
			echo 'push "dhcp-option DNS 208.67.220.220"' >> /etc/openvpn/server.conf;;
		5) #Verisign
			echo 'push "dhcp-option DNS 64.6.64.6"' >> /etc/openvpn/server.conf
			echo 'push "dhcp-option DNS 64.6.65.6"' >> /etc/openvpn/server.conf;;
		6) #Quad9
			echo 'push "dhcp-option DNS 9.9.9.9"' >> /etc/openvpn/server.conf
			echo 'push "dhcp-option DNS 149.112.112.112"' >> /etc/openvpn/server.conf;;
		7) #Quad9 uncensored
			echo 'push "dhcp-option DNS 9.9.9.10"' >>/etc/openvpn/server.conf
			echo 'push "dhcp-option DNS 149.112.112.10"' >>/etc/openvpn/server.conf;;
		8) #UncensoredDNS
			echo 'push "dhcp-option DNS 91.239.100.100"' >> /etc/openvpn/server.conf
			echo 'push "dhcp-option DNS 89.233.43.71"' >> /etc/openvpn/server.conf;;
		9) #FDN
			echo 'push "dhcp-option DNS 80.67.169.40"' >>/etc/openvpn/server.conf
			echo 'push "dhcp-option DNS 80.67.169.12"' >>/etc/openvpn/server.conf;;
	   10) #DNS.WATCH
			echo 'push "dhcp-option DNS 84.200.69.80"' >>/etc/openvpn/server.conf
			echo 'push "dhcp-option DNS 84.200.70.40"' >>/etc/openvpn/server.conf;;
	   11) #Yandex Basic
			echo 'push "dhcp-option DNS 77.88.8.8"' >>/etc/openvpn/server.conf
			echo 'push "dhcp-option DNS 77.88.8.1"' >>/etc/openvpn/server.conf;;
	   12) #AdGuard DNS
			echo 'push "dhcp-option DNS 94.140.14.14"' >>/etc/openvpn/server.conf
			echo 'push "dhcp-option DNS 94.140.15.15"' >>/etc/openvpn/server.conf;;	
	   12) #NextDNS
			echo 'push "dhcp-option DNS 45.90.28.167"' >>/etc/openvpn/server.conf
			echo 'push "dhcp-option DNS 45.90.30.167"' >>/etc/openvpn/server.conf;;
	esac
}

instala_ovpn(){
	clear
	msg -bar
	print_center -ama "INSTALADOR DE OPENVPN"
	msg -bar
	# OpenVPN setup and first user creation
	msg -ama " Algunos ajustes son necesario para conf OpenVPN"
	msg -bar
	# Autodetect IP address and pre-fill for the user
	IP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | head -1)
	if echo "$IP" | grep -qE '^(10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|192\.168)'; then
		PUBLICIP=$(curl -s https://api.ipify.org)
	fi
	print_center -ama "Ingresa un puerto OpenVPN (Default 1194)"
	msg -bar
	while [[ -z $PORT ]]; do
		read -rp "$(msg -verm2 "Digite el Puerto:") " -e -i 1194 PORT
		if [[ -z $PORT ]]; then
			PORT="1194"
		elif [[ ! $PORT =~ $numero ]]; then
			tput cuu1 && tput dl1
			print_center -verm2 "ingresa solo numeros"
			sleep 2s
			tput cuu1 && tput dl1
			unset PORT
		fi
		[[ $(mportas|grep -w "${PORT}") ]] && {
			tput cuu1 && tput dl1
			print_center -verm2 "Puerto en uso"
			sleep 2s
			tput cuu1 && tput dl1
			unset PORT
        }
	done
	del "3"
	msg -nazu " PUERTO: "; msg -verd "$PORT"
	msg -bar
	print_center -ama "Seleccione el protocolo de conexiones OpenVPN"
	msg -bar
	menu_func "UDP" "TCP"
	msg -bar
	while [[ -z $PROTOCOL ]]; do
		read -rp "$(msg -verm2 "Digite una opcion:") " -e -i 1 PROTOCOL
		case $PROTOCOL in
			1)PROTOCOL=udp; del "6"; msg -nazu " PROTOCOLO: "; msg -verd "UDP";;
			2)PROTOCOL=tcp; del "6"; msg -nazu " PROTOCOLO: "; msg -verd "TCP";;
			*)tput cuu1 && tput dl1; print_center -verm2 "selecciona una opcion entre 1 y 2"; sleep 2s; tput cuu1 && tput dl1; unset PROTOCOL;;
		esac
	done
	msg -bar
	print_center -ama "Seleccione DNS (default VPS)"
	msg -bar
	menu_func "DNS del Sistema" "Cloudflare" "Google" "OpenDNS" "Verisign" "Quad9" "Quad9 uncensored" "UncensoredDNS" "FDN" "DNS.WATCH" "Yandex Basic" "AdGuard DNS" "NextDNS"
	msg -bar
	while [[ -z $DNS ]]; do
		read -rp "$(msg -verm2 "Digite una opcion:") " -e -i 1 DNS
		if [[ -z $DNS ]]; then
			DNS="1"
		elif [[ ! $DNS =~ $numero ]]; then
			tput cuu1 && tput dl1
			print_center -verm2 "ingresa solo numeros"
			sleep 2s
			tput cuu1 && tput dl1
			unset DNS
		elif [[ $DNS != @([1-13]) ]]; then
			tput cuu1 && tput dl1
			print_center -ama "solo numeros entre 1 y 7"
			sleep 2s
			tput cuu1 && tput dl1
			unset DNS
		fi
	done
	case $DNS in
		1)P_DNS="DNS del Sistema";;
		2)P_DNS="Cloudflare";;
		3)P_DNS="Google";;
		4)P_DNS="OpenDNS";;
		5)P_DNS="Verisign";;
		6)P_DNS="Quad9";;
		7)P_DNS="Quad9 uncensored";;
		8)P_DNS="UncensoredDNS";;
		9)P_DNS="FDN";;
		10)P_DNS="DNS.WATCH";;
		11)P_DNS="Yandex Basic";;
		12)P_DNS="AdGuard DNS";;
		13)P_DNS="NextDNS";;
	esac
	del "17"
	msg -nazu " DNS: "; msg -verd "$P_DNS"
	msg -bar
	print_center -ama " Seleccione la codificacion para el canal de datos"
	msg -bar
	menu_func "AES-128-CBC" "AES-192-CBC" "AES-256-CBC" "AES-128-GCM" "AES-192-GCM" "AES-256-GCM"
	msg -bar
	while [[ -z $CIPHER ]]; do
		read -rp "$(msg -verm2 "Digite una opcion:") " -e -i 1 CIPHER
		if [[ -z $CIPHER ]]; then
			CIPHER="1"
		elif [[ ! $CIPHER =~ $numero ]]; then
			tput cuu1 && tput dl1
			print_center -verm2 "ingresa solo numeros"
			sleep 2s
			tput cuu1 && tput dl1
			unset CIPHER
		elif [[ $CIPHER != @([1-6]) ]]; then
			tput cuu1 && tput dl1
			print_center -ama "solo numeros entre 1 y 6"
			sleep 2s
			tput cuu1 && tput dl1
			unset CIPHER
		fi
	done
	case $CIPHER in
		1) CIPHER="AES-128-CBC";;
		2) CIPHER="AES-192-CBC";;
		3) CIPHER="AES-256-CBC";;
		4) CIPHER="AES-128-GCM";;
		5) CIPHER="AES-192-GCM";;
		6) CIPHER="AES-256-GCM";;
	esac
	del "10"
	msg -nazu " CODIFICACION: "; msg -verd "$CIPHER"
	msg -bar
	msg -ama " Estamos listos para configurar su servidor OpenVPN"
	enter

	NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
	if [[ -z $NIC ]]; then
		clear
		msg -bar
		print_center "No puede detectar la interfaz pública.\nEsto necesita una MASQUERADE de configuración."
		msg -bar
		until [[ $CONTINUE =~ (y|n) ]]; do
			read -rp "$(msg -verm "Continuar? [y/n]:") " -e -i n CONTINUE
		done
		if [[ $CONTINUE == "n" ]]; then
			return 1
		fi
	fi

	if [[ ! -e /etc/openvpn/server.conf ]]; then
		if [[ $OS =~ (debian|ubuntu) ]]; then
			apt-get update
			apt-get -y install ca-certificates gnupg
			if [[ $VERSION_ID == "16.04" ]]; then
				echo "deb http://build.openvpn.net/debian/openvpn/stable xenial main" >/etc/apt/sources.list.d/openvpn.list
				wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add -
				apt-get update
			fi
			apt-get install -y openvpn iptables openssl wget ca-certificates curl
		elif [[ $OS == 'centos' ]]; then
			yum install -y epel-release
			yum install -y openvpn iptables openssl wget ca-certificates curl tar 'policycoreutils-python*'
		elif [[ $OS == 'oracle' ]]; then
			yum install -y oracle-epel-release-el8
			yum-config-manager --enable ol8_developer_EPEL
			yum install -y openvpn iptables openssl wget ca-certificates curl tar policycoreutils-python-utils
		elif [[ $OS == 'amzn' ]]; then
			amazon-linux-extras install -y epel
			yum install -y openvpn iptables openssl wget ca-certificates curl
		elif [[ $OS == 'fedora' ]]; then
			dnf install -y openvpn iptables openssl wget ca-certificates curl policycoreutils-python-utils
		elif [[ $OS == 'arch' ]]; then
			pacman --needed --noconfirm -Syu openvpn iptables openssl wget ca-certificates curl
		fi
		if [[ -d /etc/openvpn/easy-rsa/ ]]; then
			rm -rf /etc/openvpn/easy-rsa/
		fi
	fi
	# Get easy-rsa
	local version="3.1.0"
	wget -O ~/easy-rsa.tgz https://github.com/OpenVPN/easy-rsa/releases/download/v${version}/EasyRSA-${version}.tgz
	mkdir -p /etc/openvpn/easy-rsa
	tar xzf ~/easy-rsa.tgz --strip-components=1 --directory /etc/openvpn/easy-rsa
	chown -R root:root /etc/openvpn/easy-rsa/
	rm -f ~/easy-rsa.tgz
	cd /etc/openvpn/easy-rsa/
	# 
	./easyrsa init-pki
	./easyrsa --batch build-ca nopass
	./easyrsa gen-dh
	./easyrsa build-server-full server nopass
	EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
	# 
	cp pki/ca.crt pki/private/ca.key pki/dh.pem pki/issued/server.crt pki/private/server.key pki/crl.pem /etc/openvpn
	# 
	chown nobody:$GROUPNAME /etc/openvpn/crl.pem
	# 
	openvpn --genkey --secret /etc/openvpn/ta.key
	# 
	echo "port $PORT
proto $PROTOCOL
dev tun
sndbuf 0
rcvbuf 0
ca ca.crt
cert server.crt
key server.key
dh dh.pem
auth SHA512
tls-auth ta.key 0
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt" > /etc/openvpn/server.conf
	echo 'push "redirect-gateway def1 bypass-dhcp"' >> /etc/openvpn/server.conf
	# DNS

	dns_fun "$DNS"
	
	echo "keepalive 10 120
cipher ${CIPHER}
user nobody
group $GROUPNAME
persist-key
persist-tun
status openvpn-status.log
verb 3
crl-verify crl.pem" >> /etc/openvpn/server.conf
updatedb
PLUGIN=$(locate openvpn-plugin-auth-pam.so | head -1)
[[ ! -z $(echo ${PLUGIN}) ]] && {
echo "client-to-client
verify-client-cert none
#client-cert-not-required
username-as-common-name
plugin $PLUGIN login" >> /etc/openvpn/server.conf
}

	echo 'net.ipv4.ip_forward=1' >/etc/sysctl.d/99-openvpn.conf
	echo 1 > /proc/sys/net/ipv4/ip_forward
	sysctl --system

	if hash sestatus 2>/dev/null; then
		if sestatus | grep "Current mode" | grep -qs "enforcing"; then
			if [[ $PORT != '1194' ]]; then
				semanage port -a -t openvpn_port_t -p "$PROTOCOL" "$PORT"
			fi
		fi
	fi

	if [[ $OS == 'arch' || $OS == 'fedora' || $OS == 'centos' || $OS == 'oracle' ]]; then
		cp /usr/lib/systemd/system/openvpn-server@.service /etc/systemd/system/openvpn-server@.service
		sed -i 's|LimitNPROC|#LimitNPROC|' /etc/systemd/system/openvpn-server@.service
		sed -i 's|/etc/openvpn/server|/etc/openvpn|' /etc/systemd/system/openvpn-server@.service
		systemctl daemon-reload
		systemctl enable openvpn-server@server
		systemctl restart openvpn-server@server
	elif [[ $OS == "ubuntu" ]] && [[ $VERSION_ID == "16.04" ]]; then
		systemctl enable openvpn
		systemctl start openvpn
	else
		cp /lib/systemd/system/openvpn\@.service /etc/systemd/system/openvpn\@.service
		sed -i 's|LimitNPROC|#LimitNPROC|' /etc/systemd/system/openvpn\@.service
		sed -i 's|/etc/openvpn/server|/etc/openvpn|' /etc/systemd/system/openvpn\@.service
		systemctl daemon-reload
		systemctl enable openvpn@server
		systemctl restart openvpn@server
	fi

	mkdir -p /etc/iptables

	echo "#!/bin/sh
iptables -t nat -I POSTROUTING 1 -s 10.8.0.0/24 -o $NIC -j MASQUERADE
iptables -I INPUT 1 -i tun0 -j ACCEPT
iptables -I FORWARD 1 -i $NIC -o tun0 -j ACCEPT
iptables -I FORWARD 1 -i tun0 -o $NIC -j ACCEPT
iptables -I INPUT 1 -i $NIC -p $PROTOCOL --dport $PORT -j ACCEPT" >/etc/iptables/add-openvpn-rules.sh

	echo "#!/bin/sh
iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o $NIC -j MASQUERADE
iptables -D INPUT -i tun0 -j ACCEPT
iptables -D FORWARD -i $NIC -o tun0 -j ACCEPT
iptables -D FORWARD -i tun0 -o $NIC -j ACCEPT
iptables -D INPUT -i $NIC -p $PROTOCOL --dport $PORT -j ACCEPT" >/etc/iptables/rm-openvpn-rules.sh

	chmod +x /etc/iptables/add-openvpn-rules.sh
	chmod +x /etc/iptables/rm-openvpn-rules.sh

		echo "[Unit]
Description=iptables rules for OpenVPN
Before=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/etc/iptables/add-openvpn-rules.sh
ExecStop=/etc/iptables/rm-openvpn-rules.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target" >/etc/systemd/system/iptables-openvpn.service

	systemctl daemon-reload
	systemctl enable iptables-openvpn
	systemctl start iptables-openvpn
	# 
	if [[ "$PUBLICIP" != "" ]]; then
		IP=$PUBLICIP
	fi
	# 
	echo "# OVPN_ACCESS_SERVER_PROFILE=ADMRufu
client
dev tun
proto $PROTOCOL
sndbuf 0
rcvbuf 0
remote $IP $PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
cipher ${CIPHER}
setenv opt block-outside-dns
key-direction 1
verb 3
auth-user-pass" > /etc/openvpn/client-common.txt
clear
msg -bar
print_center -verd "Configuracion Finalizada!"
msg -bar
print_center -ama " Crear un usuario SSH para generar el (.ovpn)!"
enter
}

edit_ovpn_host(){
	msg -ama " CONFIGURACION HOST DNS OPENVPN"
	msg -bar
	while [[ $DDNS != @(n|N) ]]; do
		echo -ne "\033[1;33m"
		read -p " Agregar host [S/N]: " -e -i n DDNS
		[[ $DDNS = @(s|S|y|Y) ]] && agrega_dns
	done
	[[ ! -z $NEWDNS ]] && sed -i "/127.0.0.1[[:blank:]]\+localhost/a 127.0.0.1 $NEWDNS" /etc/hosts
	msg -bar
	msg -ama " Es Necesario el Reboot del Servidor Para"
	msg -ama " Para que las configuraciones sean efectudas"
	enter
}

function removeOpenVPN() {
	clear
	msg -bar
	echo -ne "\033[1;97m"
	read -rp "$(msg -ama "QUIERES DESINTALAR OPENVPN? [Y/N]:") " -e -i n REMOVE
	msg -bar
	if [[ $REMOVE == 'y' ]]; then
		# Get OpenVPN port from the configuration
		PORT=$(grep '^port ' /etc/openvpn/server.conf | cut -d " " -f 2)
		PROTOCOL=$(grep '^proto ' /etc/openvpn/server.conf | cut -d " " -f 2)

		# Stop OpenVPN
		if [[ $OS =~ (fedora|arch|centos|oracle) ]]; then
			systemctl disable openvpn-server@server
			systemctl stop openvpn-server@server
			# Remove customised service
			rm /etc/systemd/system/openvpn-server@.service
		elif [[ $OS == "ubuntu" ]] && [[ $VERSION_ID == "16.04" ]]; then
			systemctl disable openvpn
			systemctl stop openvpn
		else
			systemctl disable openvpn@server
			systemctl stop openvpn@server
			# Remove customised service
			rm /etc/systemd/system/openvpn\@.service
		fi

		# Remove the iptables rules related to the script
		systemctl stop iptables-openvpn
		# Cleanup
		systemctl disable iptables-openvpn
		rm /etc/systemd/system/iptables-openvpn.service
		systemctl daemon-reload
		rm /etc/iptables/add-openvpn-rules.sh
		rm /etc/iptables/rm-openvpn-rules.sh

		# SELinux
		if hash sestatus 2>/dev/null; then
			if sestatus | grep "Current mode" | grep -qs "enforcing"; then
				if [[ $PORT != '1194' ]]; then
					semanage port -d -t openvpn_port_t -p "$PROTOCOL" "$PORT"
				fi
			fi
		fi

		if [[ $OS =~ (debian|ubuntu) ]]; then
			apt-get remove --purge -y openvpn
			if [[ -e /etc/apt/sources.list.d/openvpn.list ]]; then
				rm /etc/apt/sources.list.d/openvpn.list
				apt-get update
			fi
		elif [[ $OS == 'arch' ]]; then
			pacman --noconfirm -R openvpn
		elif [[ $OS =~ (centos|amzn|oracle) ]]; then
			yum remove -y openvpn
		elif [[ $OS == 'fedora' ]]; then
			dnf remove -y openvpn
		fi

		# Cleanup
		find /home/ -maxdepth 2 -name "*.ovpn" -delete
		find /root/ -maxdepth 1 -name "*.ovpn" -delete
		rm -rf /etc/openvpn
		rm -rf /usr/share/doc/openvpn*
		rm -f /etc/sysctl.d/99-openvpn.conf
		rm -rf /var/log/openvpn
		clear
		msg -bar
		print_center -ama "OpenVPN removido!"
		enter
		return 1
	else
		clear
		msg -bar
		print_center -ama "Desinstalacion canselada!"
		enter
	fi
}

on_off(){
	[[ $(mportas|grep -w openvpn) ]] && {
		if [[ $OS =~ (fedora|arch|centos|oracle) ]]; then
			systemctl disable openvpn-server@server &>/dev/null
			systemctl stop openvpn-server@server &>/dev/null
		elif [[ $OS == "ubuntu" ]] && [[ $VERSION_ID == "16.04" ]]; then
			systemctl disable openvpn &>/dev/null
			systemctl stop openvpn &>/dev/null
		else
			systemctl disable openvpn@server &>/dev/null
			systemctl stop openvpn@server &>/dev/null
		fi
		systemctl stop iptables-openvpn &>/dev/null
		systemctl disable iptables-openvpn &>/dev/null
	} || {
		if [[ $OS =~ (fedora|arch|centos|oracle) ]]; then
			systemctl enable openvpn-server@server &>/dev/null
			systemctl start openvpn-server@server &>/dev/null
		elif [[ $OS == "ubuntu" ]] && [[ $VERSION_ID == "16.04" ]]; then
			systemctl enable openvpn &>/dev/null
			systemctl start openvpn &>/dev/null
		else
			systemctl enable openvpn@server &>/dev/null
			systemctl start openvpn@server &>/dev/null
		fi
		systemctl enable iptables-openvpn &>/dev/null
		systemctl start iptables-openvpn &>/dev/null
	}
	print_center -ama "Procedimiento con Exito"
	enter
}

fun_openvpn(){
	if [[ -e /etc/openvpn/server.conf ]];then
		[[ $(mportas|grep -w "openvpn") ]] && OPENBAR="\033[1;32m [ONLINE]" || OPENBAR="\033[1;31m [OFFLINE]"
		title -ama "CONFIGURACION OPENVPN"
		menu_func "$(msg -verd "INICIAR O PARAR OPENVPN") $OPENBAR" "EDITAR CONFIGURACION CLIENTE $(msg -ama "(MEDIANTE NANO)")" "EDITAR CONFIGURACION SERVIDOR $(msg -ama "(MEDIANTE NANO)")" "CAMBIAR HOST DE OPENVPN" "$(msg -verm2 "DESINSTALAR OPENVPN")"
		back
		xption=$(selection_fun 5)
		case $xption in 
			5)  removeOpenVPN ;;
			2)	nano /etc/openvpn/client-common.txt ;;
			3)	nano /etc/openvpn/server.conf ;;
			4)	edit_ovpn_host ;;
			1)	on_off ;;
			0)return 1 ;;
		esac
	else
		instala_ovpn
	fi
}

initialCheck

while [[  $? -eq 0 ]]; do
	fun_openvpn
done