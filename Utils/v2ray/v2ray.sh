#!/bin/bash

BEIJING_UPDATE_TIME=3
BEGIN_PATH=$(pwd)
BASE_SOURCE_PATH="https://multi.netlify.app"
UTIL_PATH="/etc/v2ray_util/util.cfg"
UTIL_CFG="$BASE_SOURCE_PATH/v2ray_util/util_core/util.cfg"
BASH_COMPLETION_SHELL="$BASE_SOURCE_PATH/v2ray"
CLEAN_IPTABLES_SHELL="$BASE_SOURCE_PATH/v2ray_util/global_setting/clean_iptables.sh"

[[ -f /etc/redhat-release && -z $(echo $SHELL|grep zsh) ]] && unalias -a
[[ -z $(echo $SHELL|grep zsh) ]] && ENV_FILE=".bashrc" || ENV_FILE=".zshrc"

dependencias(){
	soft="socat cron bash-completion ntpdate gawk jq uuid-runtime python-pip python3 python3-pip"

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

	if [[ ! -e '/usr/bin/pip' ]]; then
		_pip=$(type -p pip)
		ln -s "$_pip" /usr/bin/pip
	fi
	if [[ ! -e '/usr/bin/pip3' ]]; then
		_pip3=$(type -p pip3)
		ln -s "$_pip3" /usr/bin/pip3
	fi
	msg -bar
}

closeSELinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

timeSync(){
	print_center -blu "Sincronización de tiempo ..."
	if [[ `command -v ntpdate` ]];then
		ntpdate pool.ntp.org
	elif [[ `command -v chronyc` ]];then
		chronyc -a makestep
	fi

	if [[ $? -eq 0 ]];then 
		print_center -blu "Éxito de sincronización de tiempo"
		print_center -ama "Actual : `date -R`"
	fi
	msg -bar
}

updateProject(){
	if [[ ! $(type pip 2>/dev/null) ]]; then
		print_center -ama 'Falta en la dependencia pip\nNo se puede continuar con la instalacion'
		enter
		return 1
	fi
    pip3 install -U v2ray_util
    if [[ -e $UTIL_PATH ]];then
        [[ -z $(cat $UTIL_PATH|grep lang) ]] && echo "lang=en" >> $UTIL_PATH
    else
        mkdir -p /etc/v2ray_util
        curl $UTIL_CFG > $UTIL_PATH
    fi
    rm -f /usr/local/bin/v2ray >/dev/null 2>&1
    ln -s $(which v2ray-util) /usr/local/bin/v2ray
    rm -f /usr/local/bin/xray >/dev/null 2>&1
    ln -s $(which v2ray-util) /usr/local/bin/xray
    [[ -e /etc/bash_completion.d/v2ray.bash ]] && rm -f /etc/bash_completion.d/v2ray.bash
    [[ -e /usr/share/bash-completion/completions/v2ray.bash ]] && rm -f /usr/share/bash-completion/completions/v2ray.bash
    curl $BASH_COMPLETION_SHELL > /usr/share/bash-completion/completions/v2ray
    curl $BASH_COMPLETION_SHELL > /usr/share/bash-completion/completions/xray
    if [[ -z $(echo $SHELL|grep zsh) ]];then
        source /usr/share/bash-completion/completions/v2ray
        source /usr/share/bash-completion/completions/xray
    fi
    # bash <(curl -L -s https://multi.netlify.app/go.sh)
    bash <(curl -L -s https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Utils/v2ray/go.sh) --version v4.45.2
}

profileInit(){
    [[ $(grep v2ray ~/$ENV_FILE) ]] && sed -i '/v2ray/d' ~/$ENV_FILE && source ~/$ENV_FILE
    [[ -z $(grep PYTHONIOENCODING=utf-8 ~/$ENV_FILE) ]] && echo "export PYTHONIOENCODING=utf-8" >> ~/$ENV_FILE && source ~/$ENV_FILE
    v2ray new &>/dev/null
}

installFinish(){
    cd ${BEGIN_PATH}

    config='/etc/v2ray/config.json'
    tmp='/etc/v2ray/temp.json'
    jq 'del(.inbounds[].streamSettings.kcpSettings[])' < /etc/v2ray/config.json >> /etc/v2ray/tmp.json
    rm -rf /etc/v2ray/config.json
    jq '.inbounds[].streamSettings += {"network":"ws","wsSettings":{"path": "/ADMRufu/","headers": {"Host": "ejemplo.com"}}}' < /etc/v2ray/tmp.json >> /etc/v2ray/config.json
    chmod 777 /etc/v2ray/config.json
    msg -bar
    if [[ $(v2ray restart|grep success) ]]; then
    	v2ray info
    	msg -bar
        print_center -verd "INSTALACION FINALIZADA"
    else
    	v2ray info
    	msg -bar
        print_center -verd "INSTALACION FINALIZADA"
        print_center -verm2 'Pero fallo el reinicio del servicio v2ray'
    fi
    print_center -ama "Por favor verifique el log"
    enter
}

main(){
	title 'INSTALADO DEPENDENCIAS V2RAY'

    dependencias
    closeSELinux
    timeSync
    updateProject
    profileInit
    installFinish
}

main
