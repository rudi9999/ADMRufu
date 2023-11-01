if [[ $(echo $PATH|grep "/usr/games") = "" ]]; then PATH=$PATH:/usr/games; fi
# export PATH=$PATH:/etc/ADMRufu/sbin
[[ $UID = 0 ]] && screen -dmS up /etc/ADMRufu/chekup.sh
v=$(cat /etc/ADMRufu/vercion)
[[ -e /etc/ADMRufu/new_vercion ]] && up=$(cat /etc/ADMRufu/new_vercion) || up=$v
[[ $(date '+%s' -d $up) -gt $(date '+%s' -d $(cat /etc/ADMRufu/vercion)) ]] && v2="Nueva Version disponible: $v >>> $up" || v2="Script Version: $v"
[[ -e "/etc/ADMRufu/tmp/message.txt" ]] && mess1="$(less /etc/ADMRufu/tmp/message.txt)"
[[ -z "$mess1" ]] && mess1="@Rufu99"
clear && echo -e "\n$(figlet -f big.flf "  ADMRufu")\n        RESELLER : $mess1 \n\n   Para iniciar ADMRufu escriba:  menu \n   Para ver lista de comandos escriba:  ls-cmd \n\n   $v2\n\n"|lolcat
[[ -e /usr/lib/update-notifier/update-motd-reboot-required ]] && /usr/lib/update-notifier/update-motd-reboot-required   #ADMRufu
