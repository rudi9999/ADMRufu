#!/bin/bash

install_wg(){
	if readlink /proc/$$/exe | grep -q "dash"; then
		print_center -verm2 'Este instalador debe ejecutarse con "bash"\nno con "sh".'
		enter
		return 1
	fi

	read -N 999999 -t 0.001

	if [[ $(uname -r | cut -d "." -f 1) -eq 2 ]]; then
		print_center -verm2 "El sistema está ejecutando un kernel antiguo\nes incompatible con este instalador."
		enter
		return 1
	fi

	if grep -qs "ubuntu" /etc/os-release; then
		os="ubuntu"
		os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
	elif [[ -e /etc/debian_version ]]; then
		os="debian"
		os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
	elif [[ -e /etc/centos-release ]]; then
		os="centos"
		os_version=$(grep -oE '[0-9]+' /etc/centos-release | head -1)
	elif [[ -e /etc/fedora-release ]]; then
		os="fedora"
		os_version=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
	else
		print_center -verm2 "Este instalador parece estar ejecutándose\nen una distribución no compatible.\nLas distribuciones compatibles\nUbuntu, Debian, CentOS y Fedora."
		enter
		return 1
	fi

	if [[ "$os" == "ubuntu" && "$os_version" -lt 1804 ]]; then
		print_center -verm2 "Se requiere Ubuntu 18.04 o superior\nEsta versión de Ubuntu es demasiado antigua\nno es compatible"
		enter
		return 1
	fi

	if [[ "$os" == "debian" && "$os_version" -lt 10 ]]; then
		print_center -verm2 "Se requiere Debian 10 o superior\nEsta versión de Debian es demasiado antigua\nno tiene soporte"
		enter
		return 1
	fi

	if [[ "$os" == "centos" && "$os_version" -lt 7 ]]; then
		print_center -verm2 "Se requiere CentOS 7 o superior\nEsta versión de CentOS es demasiado antigua\nno es compatible."
		enter
		return 1
	fi

	if ! grep -q sbin <<< "$PATH"; then
		print_center -verm2 '$PATH no incluye sbin\nIntenta usar "su -" en lugar de "su"'
		enter
		return 1
	fi

	systemd-detect-virt -cq
	is_container="$?"

	if [[ ! "$os" == "fedora" && "$os_version" -eq 31 && $(uname -r | cut -d "." -f 2) -lt 6 && ! "$is_container" -eq 0 ]]; then
		print_center -ama 'Se admite Fedora 31\npero el kernel está desactualizado\nActualice el kernel usando "dnf upgrade kernel"\nreinicie el servidor vps'
		enter
		return 1
	fi

	if [[ "$EUID" -ne 0 ]]; then
		print_center -verm2 "Este instalador debe ejecutarse\ncon privilegios de superusuario"
		enter
		return 1
	fi

	if [[ "$is_container" -eq 0 ]]; then
		if [ "$(uname -m)" != "x86_64" ]; then
			print_center -verm2 "Este instalador solo admite la arquitectura x86_64\nEl sistema se ejecuta en $(uname -m) y no es compatible"
			enter
			return 1
		fi
		if [[ ! -e /dev/net/tun ]] || ! ( exec 7<>/dev/net/tun ) 2>/dev/null; then
			print_center -verm2 "El sistema no tiene disponible el dispositivo TUN\nTUN debe estar habilitado\nantes de ejecutar este instalador"
			enter
			return 1
		fi
	fi

	if [[ ! -e /etc/wireguard/wg0.conf ]]; then
		title "INSTALADOR WIREGUARD By @Rufu99"
		ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | sed -n 1p)
		public_ip=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$(wget -T 10 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/" || curl -m 10 -4Ls "http://ip1.dynupdate.no-ip.com/")")

		if [[ $(ip -6 addr | grep -c 'inet6 [23]') -eq 1 ]]; then
			ip6=$(ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}')
		fi

		if [[ $(ip -6 addr | grep -c 'inet6 [23]') -gt 1 ]]; then
			number_of_ip6=$(ip -6 addr | grep -c 'inet6 [23]')
			print_center -ama "¿Qué dirección IPv6 usara?"
			msg -bar3
			ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}' | nl -s ') '
			in_opcion -nama "IPv6 [1]"
			ip6_number=$opcion
			until [[ -z "$ip6_number" || "$ip6_number" =~ ^[0-9]+$ && "$ip6_number" -le "$number_of_ip6" ]]; do
				tput cuu1 && tput dl1 && tput cuu1 && tput dl1
				print_center -verm2 "Datos ingresados invalido"
				sleep 2
				tput cuu1 && tput dl1
				in_opcion -nama "IPv6 [1]"
				ip6_number=$opcion
			done
			[[ -z "$ip6_number" ]] && ip6_number="1"
			ip6=$(ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}' | sed -n "$ip6_number"p)
			msg -bar
		fi

		while [[ -z $port ]]; do
			echo -ne "\033[1;37m Ingrese un puerto para Wireguard [51820]: " && read port
			tput cuu1 && tput dl1

			if [[ -z "$port" ]]; then
				port="51820"
			elif [[ ! $port =~ $numero ]];then
				print_center -verm2 "Ingresa solo nuemeros"
				sleep 2
				tput cuu1 && tput dl1
				unset port
				continue
			elif [[ ! "$port" -le 65535 ]]; then
				print_center -verm2 "El puerto no puede superar 65535"
				sleep 2
				tput cuu1 && tput dl1
				unset port
				continue
			fi

			tput dl1

			[[ $(mportas|grep -w "${port}") = "" ]] && {
				echo -e "\033[1;33m $(fun_trans  "Puerto Wireguard:")\033[1;32m ${port} OK"
			} || {
				echo -e "\033[1;33m $(fun_trans  "Puerto Wireguard:")\033[1;31m ${port} FAIL" && sleep 2
				tput cuu1 && tput dl1
				unset port
			}
		done
		msg -bar

		if [[ "$is_container" -eq 0 ]]; then
			print_center -ama "Para configurar WireGuard en el sistema\nSe instalará BoringTun"
			msg -bar3
			in_opcion -ama "Activar actualizacion automatica [Y/n]"
			boringtun_updates=$opcion
			until [[ "$boringtun_updates" =~ ^[yYnN]*$ ]]; do
				tput cuu1 && tput dl1 && tput cuu1 && tput dl1
				print_center -verm2 "Datos ingresados invalido"
				sleep 2
				tput cuu1 && tput dl1
				in_opcion -ama "Activar actualizacion automatica [Y/n]"
				boringtun_updates=$opcion
			done
			if [[ "$boringtun_updates" =~ ^[yY]*$ ]]; then
				if [[ "$os" == "centos" || "$os" == "fedora" ]]; then
					cron="cronie"
				elif [[ "$os" == "debian" || "$os" == "ubuntu" ]]; then
					cron="cron"
				fi
			fi
			msg -bar
		fi

		if ! systemctl is-active --quiet firewalld.service && ! hash iptables 2>/dev/null; then
			if [[ "$os" == "centos" || "$os" == "fedora" ]]; then
				firewall="firewalld"
				print_center -ama "se instalará firewalld\nEs necesario para administrar las reglas"
			elif [[ "$os" == "debian" || "$os" == "ubuntu" ]]; then
				firewall="iptables"
			fi
		fi

		print_center -ama "La instalación de WireGuard\nestá lista para comenzar"
		enter
		title "INSTALANDO Y CONFIGURANDO WIREGUARD"
		# If not running inside a container, set up the WireGuard kernel module
		if [[ ! "$is_container" -eq 0 ]]; then
			if [[ "$os" == "ubuntu" ]]; then
				apt-get update
				apt-get install -y wireguard qrencode $firewall
			elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
				if ! grep -qs '^deb .* buster-backports main' /etc/apt/sources.list /etc/apt/sources.list.d/*.list; then
					echo "deb http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list
				fi
				apt-get update
				apt-get install -y linux-headers-"$(uname -r)"
				architecture=$(dpkg --get-selections 'linux-image-*-*' | cut -f 1 | grep -oE '[^-]*$' -m 1)
				apt-get install -y linux-headers-"$architecture"
				apt-get install -y wireguard qrencode $firewall
			elif [[ "$os" == "centos" && "$os_version" -eq 8 ]]; then
				dnf install -y epel-release elrepo-release
				dnf install -y kmod-wireguard wireguard-tools qrencode $firewall
				mkdir -p /etc/wireguard/
			elif [[ "$os" == "centos" && "$os_version" -eq 7 ]]; then
				yum install -y epel-release https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
				yum install -y yum-plugin-elrepo
				yum install -y kmod-wireguard wireguard-tools qrencode $firewall
				mkdir -p /etc/wireguard/
			elif [[ "$os" == "fedora" ]]; then
				dnf install -y wireguard-tools qrencode $firewall
				mkdir -p /etc/wireguard/
			fi
		else
			if [[ "$os" == "ubuntu" ]]; then
				apt-get update
				apt-get install -y qrencode ca-certificates $cron $firewall
				apt-get install -y wireguard-tools --no-install-recommends
			elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
				if ! grep -qs '^deb .* buster-backports main' /etc/apt/sources.list /etc/apt/sources.list.d/*.list; then
					echo "deb http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list
				fi
				apt-get update
				apt-get install -y qrencode ca-certificates $cron $firewall
				apt-get install -y wireguard-tools --no-install-recommends
			elif [[ "$os" == "centos" && "$os_version" -eq 8 ]]; then
				dnf install -y epel-release
				dnf install -y wireguard-tools qrencode ca-certificates tar $cron $firewall
				mkdir -p /etc/wireguard/
			elif [[ "$os" == "centos" && "$os_version" -eq 7 ]]; then
				yum install -y epel-release
				yum install -y wireguard-tools qrencode ca-certificates tar $cron $firewall
				mkdir -p /etc/wireguard/
			elif [[ "$os" == "fedora" ]]; then
				dnf install -y wireguard-tools qrencode ca-certificates tar $cron $firewall
				mkdir -p /etc/wireguard/
			fi
			{ wget -qO- https://github.com/sysadminsdecuba/wireguard-install/raw/main/boringtun-v0.3.0-x86_64-unknown-linux-musl.tar.gz 2>/dev/null || curl -sL https://github.com/sysadminsdecuba/wireguard-install/raw/main/boringtun-v0.3.0-x86_64-unknown-linux-musl.tar.gz ; } | tar xz -C /usr/local/sbin/ --wildcards 'boringtun-*/boringtun' --strip-components 1
			mkdir /etc/systemd/system/wg-quick@wg0.service.d/ 2>/dev/null
			echo "[Service]
Environment=WG_QUICK_USERSPACE_IMPLEMENTATION=boringtun
Environment=WG_SUDO=1" > /etc/systemd/system/wg-quick@wg0.service.d/boringtun.conf
			if [[ -n "$cron" ]] && [[ "$os" == "centos" || "$os" == "fedora" ]]; then
				systemctl enable --now crond.service
			fi
		fi

		if [[ "$firewall" == "firewalld" ]]; then
			systemctl enable --now firewalld.service
		fi

		# Generate wg0.conf
		cat << EOF > /etc/wireguard/wg0.conf
# Do not alter the commented lines
# They are used by wireguard-install
# ENDPOINT $([[ -n "$public_ip" ]] && echo "$public_ip" || echo "$ip")

[Interface]
Address = 10.7.0.1/24$([[ -n "$ip6" ]] && echo ", fddd:2c4:2c4:2c4::1/64")
PrivateKey = $(wg genkey)
ListenPort = $port

EOF

		chmod 600 /etc/wireguard/wg0.conf
		echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/30-wireguard-forward.conf
		echo 1 > /proc/sys/net/ipv4/ip_forward
		if [[ -n "$ip6" ]]; then
			echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.d/30-wireguard-forward.conf
			echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
		fi

		if systemctl is-active --quiet firewalld.service; then
			firewall-cmd --add-port="$port"/udp
			firewall-cmd --zone=trusted --add-source=10.7.0.0/24
			firewall-cmd --permanent --add-port="$port"/udp
			firewall-cmd --permanent --zone=trusted --add-source=10.7.0.0/24
			# Set NAT for the VPN subnet
			firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to "$ip"
			firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to "$ip"
			if [[ -n "$ip6" ]]; then
				firewall-cmd --zone=trusted --add-source=fddd:2c4:2c4:2c4::/64
				firewall-cmd --permanent --zone=trusted --add-source=fddd:2c4:2c4:2c4::/64
				firewall-cmd --direct --add-rule ipv6 nat POSTROUTING 0 -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to "$ip6"
				firewall-cmd --permanent --direct --add-rule ipv6 nat POSTROUTING 0 -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to "$ip6"
			fi
		else
			iptables_path=$(command -v iptables)
			ip6tables_path=$(command -v ip6tables)
			if [[ $(systemd-detect-virt) == "openvz" ]] && readlink -f "$(command -v iptables)" | grep -q "nft" && hash iptables-legacy 2>/dev/null; then
				iptables_path=$(command -v iptables-legacy)
				ip6tables_path=$(command -v ip6tables-legacy)
			fi
			echo "[Unit]
Before=network.target
[Service]
Type=oneshot
ExecStart=$iptables_path -t nat -A POSTROUTING -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to $ip
ExecStart=$iptables_path -I INPUT -p udp --dport $port -j ACCEPT
ExecStart=$iptables_path -I FORWARD -s 10.7.0.0/24 -j ACCEPT
ExecStart=$iptables_path -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=$iptables_path -t nat -D POSTROUTING -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to $ip
ExecStop=$iptables_path -D INPUT -p udp --dport $port -j ACCEPT
ExecStop=$iptables_path -D FORWARD -s 10.7.0.0/24 -j ACCEPT
ExecStop=$iptables_path -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" > /etc/systemd/system/wg-iptables.service
			if [[ -n "$ip6" ]]; then
				echo "ExecStart=$ip6tables_path -t nat -A POSTROUTING -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to $ip6
ExecStart=$ip6tables_path -I FORWARD -s fddd:2c4:2c4:2c4::/64 -j ACCEPT
ExecStart=$ip6tables_path -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=$ip6tables_path -t nat -D POSTROUTING -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to $ip6
ExecStop=$ip6tables_path -D FORWARD -s fddd:2c4:2c4:2c4::/64 -j ACCEPT
ExecStop=$ip6tables_path -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" >> /etc/systemd/system/wg-iptables.service
			fi
			echo "RemainAfterExit=yes
[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/wg-iptables.service
			systemctl enable --now wg-iptables.service
		fi

		systemctl enable --now wg-quick@wg0.service

		if [[ "$boringtun_updates" =~ ^[yY]*$ ]]; then
			cat << 'EOF' > /usr/local/sbin/boringtun-upgrade
#!/bin/bash
latest=$(wget -qO- https://github.com/sysadminsdecuba/wireguard-install/raw/main/boringtun-v0.3.0-x86_64-unknown-linux-musl.tar.gz 2>/dev/null || curl -sL https://github.com/sysadminsdecuba/wireguard-install/raw/main/boringtun-v0.3.0-x86_64-unknown-linux-musl.tar.gz 2>/dev/null)
# If server did not provide an appropriate response, exit
if ! head -1 <<< "$latest" | grep -qiE "^boringtun.+[0-9]+\.[0-9]+.*$"; then
	echo "Update server unavailable"
	exit
fi
current=$(boringtun -V)
if [[ "$current" != "$latest" ]]; then
	download="https://wg.nyr.be/1/latest/download"
	xdir=$(mktemp -d)
	# If download and extraction are successful, upgrade the boringtun binary
	if { wget -qO- "$download" 2>/dev/null || curl -sL "$download" ; } | tar xz -C "$xdir" --wildcards "boringtun-*/boringtun" --strip-components 1; then
		systemctl stop wg-quick@wg0.service
		rm -f /usr/local/sbin/boringtun
		mv "$xdir"/boringtun /usr/local/sbin/boringtun
		systemctl start wg-quick@wg0.service
		echo "Succesfully updated to $(boringtun -V)"
	else
		echo "boringtun update failed"
	fi
	rm -rf "$xdir"
else
	echo "$current is up to date"
fi
EOF
			chmod +x /usr/local/sbin/boringtun-upgrade
			{ crontab -l 2>/dev/null; echo "$(( $RANDOM % 60 )) $(( $RANDOM % 3 + 3 )) * * * /usr/local/sbin/boringtun-upgrade &>/dev/null" ; } | crontab -
		fi

		if [[ ! -e "${ADM_tmp}/wg_dns" ]]; then
			if grep -q '^nameserver 127.0.0.53' "/etc/resolv.conf"; then
				resolv_conf="/run/systemd/resolve/resolv.conf"
			else
				resolv_conf="/etc/resolv.conf"
			fi
			localdns=$(grep -v '^#\|^;' "$resolv_conf" | grep '^nameserver' | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | xargs | sed -e 's/ /, /g')
			echo "$localdns" > ${ADM_tmp}/wg_dns
		fi

		if [[ ! "$is_container" -eq 0 ]] && ! modprobe -nq wireguard; then
			clear
			msg -bar
			print_center -ama "Precaucion!\nLa instalación se terminó\npero el módulo kernel de WireGuard no se pudo cargar"
			msg -bar3
			if [[ "$os" == "ubuntu" && "$os_version" -eq 1804 ]]; then
				print_center -ama 'Actulize el kernel y headers\nUse "apt install linux-generic" y reinicie'
			elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
				print_center 'Actulize el kernel\nUse apt install linux-image-$architecture y reinicie'
			elif [[ "$os" == "centos" && "$os_version" -le 8 ]]; then
				echo "Reiniciar el sistema para cargar el kernel más reciente"
			fi
		else
			clear
			msg -bar
			print_center -verd "INSTALACION DE WIREGUARD CON EXITO!"
		fi
	else




		echo
		title "DESINSTALADOR WIREGUARD"
		in_opcion "Quiere remover wireguard? [y/N]"
		remove=$opcion

		until [[ "$remove" =~ ^[yYnN]*$ ]]; do
			tput cuu1 && tput dl1 && tput cuu1 && tput dl1
			print_center -verm2 "opcion invalida!"
			sleep 2
			tput cuu1 && tput dl1
			in_opcion "Quiere remover wireguard? [y/N]"
			remove=$opcion
		done
		if [[ "$remove" =~ ^[yY]$ ]]; then
			port=$(grep '^ListenPort' /etc/wireguard/wg0.conf | cut -d " " -f 3)
			if systemctl is-active --quiet firewalld.service; then
				ip=$(firewall-cmd --direct --get-rules ipv4 nat POSTROUTING | grep '\-s 10.7.0.0/24 '"'"'!'"'"' -d 10.7.0.0/24' | grep -oE '[^ ]+$')
				firewall-cmd --remove-port="$port"/udp
				firewall-cmd --zone=trusted --remove-source=10.7.0.0/24
				firewall-cmd --permanent --remove-port="$port"/udp
				firewall-cmd --permanent --zone=trusted --remove-source=10.7.0.0/24
				firewall-cmd --direct --remove-rule ipv4 nat POSTROUTING 0 -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to "$ip"
				firewall-cmd --permanent --direct --remove-rule ipv4 nat POSTROUTING 0 -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to "$ip"
				if grep -qs 'fddd:2c4:2c4:2c4::1/64' /etc/wireguard/wg0.conf; then
					ip6=$(firewall-cmd --direct --get-rules ipv6 nat POSTROUTING | grep '\-s fddd:2c4:2c4:2c4::/64 '"'"'!'"'"' -d fddd:2c4:2c4:2c4::/64' | grep -oE '[^ ]+$')
					firewall-cmd --zone=trusted --remove-source=fddd:2c4:2c4:2c4::/64
					firewall-cmd --permanent --zone=trusted --remove-source=fddd:2c4:2c4:2c4::/64
					firewall-cmd --direct --remove-rule ipv6 nat POSTROUTING 0 -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to "$ip6"
					firewall-cmd --permanent --direct --remove-rule ipv6 nat POSTROUTING 0 -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to "$ip6"
				fi
			else
				systemctl disable --now wg-iptables.service
				rm -f /etc/systemd/system/wg-iptables.service
			fi
			systemctl disable --now wg-quick@wg0.service
			rm -f /etc/systemd/system/wg-quick@wg0.service.d/boringtun.conf
			rm -f /etc/sysctl.d/30-wireguard-forward.conf
			if [[ ! "$is_container" -eq 0 ]]; then
				if [[ "$os" == "ubuntu" ]]; then
					rm -rf /etc/wireguard/
					apt-get remove --purge -y wireguard wireguard-tools
				elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
					rm -rf /etc/wireguard/
					apt-get remove --purge -y wireguard wireguard-dkms wireguard-tools
				elif [[ "$os" == "centos" && "$os_version" -eq 8 ]]; then
					rm -rf /etc/wireguard/
					dnf remove -y kmod-wireguard wireguard-tools
				elif [[ "$os" == "centos" && "$os_version" -eq 7 ]]; then
					rm -rf /etc/wireguard/
					yum remove -y kmod-wireguard wireguard-tools
				elif [[ "$os" == "fedora" ]]; then
					rm -rf /etc/wireguard/
					dnf remove -y wireguard-tools
				fi
			else
				{ crontab -l 2>/dev/null | grep -v '/usr/local/sbin/boringtun-upgrade' ; } | crontab -
				if [[ "$os" == "ubuntu" ]]; then
					rm -rf /etc/wireguard/
					apt-get remove --purge -y wireguard-tools
				elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
					rm -rf /etc/wireguard/
					apt-get remove --purge -y wireguard-tools
				elif [[ "$os" == "centos" && "$os_version" -eq 8 ]]; then
					rm -rf /etc/wireguard/
					dnf remove -y wireguard-tools
				elif [[ "$os" == "centos" && "$os_version" -eq 7 ]]; then
					rm -rf /etc/wireguard/
					yum remove -y wireguard-tools
				elif [[ "$os" == "fedora" ]]; then
					rm -rf /etc/wireguard/
					dnf remove -y wireguard-tools
				fi
				rm -f /usr/local/sbin/boringtun /usr/local/sbin/boringtun-upgrade
			fi
			rm -f ${ADM_tmp}/wg_dns
			clear
			msg -bar
			print_center -verd "WIREGUARD REMOVIDOCON EXITO!"
		else
			clear
			msg -bar
			print_center -verd "DESINSTALACION WIREGUARD ABORTADA!"
		fi
	fi
	enter
	return 1
}

port_wg(){
	title "MODIFICAR EL PUERTO WIREGUARD"
	r_port=$(grep '^ListenPort' /etc/wireguard/wg0.conf | cut -d " " -f 3)
	print_center -ama "Puerto actual: $r_port"
	msg -bar

	while [[ -z $port ]]; do
		echo -ne "\033[1;37m Redefinir puerto Wireguard [51820]: " && read port
			tput cuu1 && tput dl1

			if [[ -z "$port" ]]; then
				port="51820"
			elif [[ ! $port =~ $numero ]];then
				print_center -verm2 "Ingresa solo nuemeros"
				sleep 2
				tput cuu1 && tput dl1
				unset port
				continue
			elif [[ ! "$port" -le 65535 ]]; then
				print_center -verm2 "El puerto no puede superar 65535"
				sleep 2
				tput cuu1 && tput dl1
				unset port
				continue
			fi

			tput dl1

			[[ $(mportas|grep -w "${port}") = "" ]] && {
				echo -e "\033[1;33m $(fun_trans  "Puerto Wireguard:")\033[1;32m ${port} OK"
			} || {
				echo -e "\033[1;33m $(fun_trans  "Puerto Wireguard:")\033[1;31m ${port} FAIL" && sleep 2
				tput cuu1 && tput dl1
				unset port
			}
		done

		if systemctl is-active --quiet firewalld.service; then
			firewall-cmd --remove-port="$r_port"/udp
			firewall-cmd --permanent --remove-port="$r_port"/udp
		else
			systemctl disable --now wg-iptables.service &>/dev/null
		fi
		systemctl disable --now wg-quick@wg0.service &>/dev/null

		if systemctl is-active --quiet firewalld.service; then
			firewall-cmd --add-port="$port"/udp
			firewall-cmd --permanent --add-port="$port"/udp
		else
			sed -i "s/ListenPort = $r_port/ListenPort = $port/" /etc/wireguard/wg0.conf
			sed -i "s/$r_port/$port/" /etc/systemd/system/wg-iptables.service
			systemctl enable --now wg-iptables.service &>/dev/null
		fi
		systemctl enable --now wg-quick@wg0.service &>/dev/null

		msg -bar
		print_center -verd "Puerto WireGuard Redefinido [$port]"
		enter
		return 1
}

power_wg(){
	status=$(systemctl status wg-quick@wg0.service|grep -w 'Active'|awk -F ' ' '{print $2}')

	case $status in
		inactive) systemctl enable --now wg-iptables.service &>/dev/null
				  systemctl enable --now wg-quick@wg0.service &>/dev/null
				  sta="INICIADO";;
		  active) systemctl disable --now wg-iptables.service &>/dev/null
				  systemctl disable --now wg-quick@wg0.service &>/dev/null
				  sta="DETENIDO";;
	esac

	clear
	msg -bar
	print_center -ama "WIREGUARD $sta!"
	enter
	return 1
}

restart_wg(){
	status=$(systemctl status wg-quick@wg0.service|grep -w 'Active'|awk -F ' ' '{print $2}')

	case $status in
		inactive) systemctl enable --now wg-iptables.service &>/dev/null
				  systemctl enable --now wg-quick@wg0.service &>/dev/null
				  sta="INICIADO";;
		  active) systemctl restart --now wg-iptables.service &>/dev/null
				  systemctl restart --now wg-quick@wg0.service &>/dev/null
				  sta="REINICIADO";;
	esac

	clear
	msg -bar
	print_center -ama "WIREGUARD $sta!"
	enter
	return 1
}

dns_wg(){
	
	if [[ ! -e "${ADM_tmp}/wg_dns" ]]; then
		if grep -q '^nameserver 127.0.0.53' "/etc/resolv.conf"; then
			resolv_conf="/run/systemd/resolve/resolv.conf"
		else
			resolv_conf="/etc/resolv.conf"
		fi
		localdns=$(grep -v '^#\|^;' "$resolv_conf" | grep '^nameserver' | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | xargs | sed -e 's/ /, /g')
		echo "$localdns" > ${ADM_tmp}/wg_dns
	fi
	wg_dns=$(cat ${ADM_tmp}/wg_dns)
	title -ama "CONF DNS DE CLIENTES WIREGUARD"
	print_center -ama "DNS CONF ACTUAL $wg_dns"
	msg -bar
	menu_func "DNS del sistema" "Google" "Cloudflare" "OpenDNS" "Quad9" "AdGuard" "Etecsa"
	back
	opcion=$(selection_fun 7)

	case "$opcion" in
		1)	if grep -q '^nameserver 127.0.0.53' "/etc/resolv.conf"; then
				resolv_conf="/run/systemd/resolve/resolv.conf"
			else
				resolv_conf="/etc/resolv.conf"
			fi
			dns=$(grep -v '^#\|^;' "$resolv_conf" | grep '^nameserver' | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | xargs | sed -e 's/ /, /g')
			echo "$dns" > ${ADM_tmp}/wg_dns;;
		2)	dns="8.8.8.8, 8.8.4.4"
			echo "$dns" > ${ADM_tmp}/wg_dns;;
		3)	dns="1.1.1.1, 1.0.0.1"
			echo "$dns" > ${ADM_tmp}/wg_dns;;
		4)	dns="208.67.222.222, 208.67.220.220"
			echo "$dns" > ${ADM_tmp}/wg_dns;;
		5)	dns="9.9.9.9, 149.112.112.112"
			echo "$dns" > ${ADM_tmp}/wg_dns;;
		6)	dns="94.140.14.14, 94.140.15.15"
			echo "$dns" > ${ADM_tmp}/wg_dns;;
		7)	dns="200.55.128.3, 200.55.128.4"
			echo "$dns" > ${ADM_tmp}/wg_dns;;
		0)return 1;;
	esac

	wg_dns=$(cat ${ADM_tmp}/wg_dns)
	print_center -ama "Se reconfiguro DNS client Wireguard"
	print_center -verd "$wg_dns"
	enter
	return 1
}

hostIP(){
	hostIP=$(grep '^# ENDPOINT' /etc/wireguard/wg0.conf | cut -d " " -f 3)
	title -ama "MODIFICAR HOST/IP CLIENTES WIREGUARD"
	print_center -azu "HOST/IP ACTUAL: $hostIP"
	msg -bar
	print_center -ama "Enter para canselar"
	in_opcion_down "Ingresa un HOST/IP"
	[[ -z $opcion ]] && return 0
	hostIPnew=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/./g' <<< "$opcion")
	sed -i "s/$hostIP/$hostIPnew/g" /etc/wireguard/wg0.conf
	systemctl restart --now wg-iptables.service &>/dev/null
	systemctl restart --now wg-quick@wg0.service &>/dev/null
	clear
	msg -bar
	print_center -ama "HOST/IP MODIFICADO: $hostIPnew"
	enter
	return 1
}

wg_menu(){
	st_menu=$(systemctl status wg-quick@wg0.service|grep -w 'Active'|awk -F ' ' '{print $2}')
	nu=1
	title "INSTALADOR WIREGUARD"
	echo " $(msg -verd "[$nu]") $(msg -verm2 ">") $(msg -verd "INSTALAR")$(msg -azu "/")$(msg -verm2 "DESINSTALAR")"
	if [[ $(dpkg --get-selections|grep -w 'wireguard'|head -1) ]]; then
		msg -bar3
		let nu++
		echo " $(msg -verd "[$nu]") $(msg -verm2 ">") $(msg -verd "INICIAR")$(msg -azu "/")$(msg -verm2 "DETENER") $(msg -azu "WG")"
		let nu++
		echo " $(msg -verd "[$nu]") $(msg -verm2 ">") $(msg -ama "REINICIAR") $(msg -azu "WG")"
		if [[ "$st_menu" = "active" ]]; then
			msg -bar3
			let nu++
			echo " $(msg -verd "[$nu]") $(msg -verm2 ">") $(msg -azu "MODIFICAR PUERTO WG")"
			let nu++
			echo " $(msg -verd "[$nu]") $(msg -verm2 ">") $(msg -azu "MODIFICAR HOST/IP")"
			let nu++
			echo " $(msg -verd "[$nu]") $(msg -verm2 ">") $(msg -azu "SERVIDOR DNS CLIENTES")"
		fi	
	fi
	back
	opcion=$(selection_fun $nu)
	case ${opcion} in
		1)install_wg;;
		2)power_wg;;
		3)restart_wg;;
		4)port_wg;;
		5)hostIP;;
		6)dns_wg;;
		0)return 1;;
	esac
}
wg_menu
