#!/bin/bash
#19/12/2019
declare -A cor=( [0]="\033[1;37m" [1]="\033[1;34m" [2]="\033[1;31m" [3]="\033[1;33m" [4]="\033[1;32m" )
SCPfrm="/etc/ger-frm" && [[ ! -d ${SCPfrm} ]] && exit
SCPinst="/etc/ger-inst" && [[ ! -d ${SCPinst} ]] && exit
fun_ip () {
MEU_IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
MEU_IP2=$(wget -qO- ipv4.icanhazip.com)
[[ "$MEU_IP" != "$MEU_IP2" ]] && echo "$MEU_IP2" || echo "$MEU_IP"
}
IP="$(fun_ip)"
clear
msg -bar
echo -e "\e[1;33m             Gestor de Archivos FTP"
msg -bar
echo -ne "$(msg -verd "  [1]") $(msg -verm2 ">") " && msg -azu "Colocar Archivo Online"
echo -ne "$(msg -verd "  [2]") $(msg -verm2 ">") " && msg -azu "Remover Archivo Online"
echo -ne "$(msg -verd "  [3]") $(msg -verm2 ">") " && msg -azu "Ver Links de Archivos Online"
msg -bar
echo -ne "$(msg -verd "  [0]") $(msg -verm2 ">") " && msg -bra " \033[1;41m VOLVER \033[0m"
msg -bar
while [[ ${arquivoonlineadm} != @(0|[1-3]) ]]; do
    echo -ne "$(msg -azu "opcion:") "
read arquivoonlineadm
tput cuu1 && tput dl1
done
case ${arquivoonlineadm} in
3)
[[ -z $(ls /var/www/html) ]] && echo -e "$barra"  || {
    for my_arqs in `ls /var/www/html`; do
    [[ "$my_arqs" = "index.html" ]] && continue
    [[ "$my_arqs" = "index.php" ]] && continue
    [[ -d "$my_arqs" ]] && continue
    echo -e "\033[1;31m[$my_arqs] \033[1;36mhttp://$IP:81/$my_arqs\033[0m"
    done
    msg -bar
    }
;;
2)
i=1
[[ -z $(ls /var/www/html) ]] && echo -e "$barra"  || {
    for my_arqs in `ls /var/www/html`; do
    [[ "$my_arqs" = "index.html" ]] && continue
    [[ "$my_arqs" = "index.php" ]] && continue
    [[ -d "$my_arqs" ]] && continue
    select_arc[$i]="$my_arqs"
    echo -e "${cor[2]}[$i] > ${cor[3]}$my_arqs - \033[1;36mhttp://$IP:81/$my_arqs\033[0m"
    let i++
    done
    msg -bar
    echo -e "${cor[5]}$(fun_trans "Seleccione el archivo que desea borrar")"
    msg -bar
    while [[ -z ${select_arc[$slct]} ]]; do
    read -p " [1-$i]: " slct
    tput cuu1 && tput dl1
    done
    arquivo_move="${select_arc[$slct]}"
    [[ -d /var/www/html ]] && [[ -e /var/www/html/$arquivo_move ]] && rm -rf /var/www/html/$arquivo_move > /dev/null 2>&1
    [[ -e /var/www/$arquivo_move ]] && rm -rf /var/www/$arquivo_move > /dev/null 2>&1
    echo -e "${cor[5]}$(fun_trans "Exito!")"
    msg -bar
    }
;;    
1)
i="1"
[[ -z $(ls $HOME) ]] && echo -e "$barra"  || {
    for my_arqs in `ls $HOME`; do
    [[ -d "$my_arqs" ]] && continue
    select_arc[$i]="$my_arqs"
    echo -e "${cor[2]} [$i] > ${cor[3]}$my_arqs"
    let i++
    done
    i=$(($i - 1))
	msg -bar
    echo -e "${cor[5]}$(fun_trans "Seleccione el archivo")"
    msg -bar
    while [[ -z ${select_arc[$slct]} ]]; do
    read -p " [1-$i]: " slct
    tput cuu1 && tput dl1
    done
    arquivo_move="${select_arc[$slct]}"
    [ ! -d /var ] && mkdir /var
    [ ! -d /var/www ] && mkdir /var/www
    [ ! -d /var/www/html ] && mkdir /var/www/html
    [ ! -e /var/www/html/index.html ] && touch /var/www/html/index.html
    [ ! -e /var/www/index.html ] && touch /var/www/index.html
    chmod -R 755 /var/www
    cp $HOME/$arquivo_move /var/www/$arquivo_move
    cp $HOME/$arquivo_move /var/www/html/$arquivo_move
    echo -e "\033[1;36m http://$IP:81/$arquivo_move\033[0m"
    msg -bar
    echo -e "${cor[5]}$(fun_trans "Exito!")"
     msg -bar
    }
;;
0)exit;;
esac