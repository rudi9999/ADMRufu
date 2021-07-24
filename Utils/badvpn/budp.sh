#!/bin/bash
#19/12/2019
clear
msg () {
local colors=""
if [[ ! -e $colors ]]; then
COLOR[0]='\033[1;37m' #BRAN='\033[1;37m'
COLOR[1]='\e[31m' #VERMELHO='\e[31m'
COLOR[2]='\e[32m' #VERDE='\e[32m'
COLOR[3]='\e[33m' #AMARELO='\e[33m'
COLOR[4]='\e[34m' #AZUL='\e[34m'
COLOR[5]='\e[91m' #MAGENTA='\e[35m'
COLOR[6]='\033[1;97m' #MAG='\033[1;36m'
else
local COL=0
for number in $(cat $colors); do
case $number in
1)COLOR[$COL]='\033[1;37m';;
2)COLOR[$COL]='\e[31m';;
3)COLOR[$COL]='\e[32m';;
4)COLOR[$COL]='\e[33m';;
5)COLOR[$COL]='\e[34m';;
6)COLOR[$COL]='\e[35m';;
7)COLOR[$COL]='\033[1;36m';;
esac
let COL++
done
fi
NEGRITO='\e[1m'
SEMCOR='\e[0m'
 case $1 in
  -ne)cor="${COLOR[1]}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
  -ama)cor="${COLOR[3]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -verm)cor="${COLOR[3]}${NEGRITO}[!] ${COLOR[1]}" && echo -e "${cor}${2}${SEMCOR}";;
  -verm2)cor="${COLOR[1]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -azu)cor="${COLOR[6]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -verd)cor="${COLOR[2]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -bra)cor="${COLOR[0]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  "-bar2"|"-bar")cor="${COLOR[1]}=====================================================" && echo -e "${SEMCOR}${cor}${SEMCOR}";;
  -bar3)cor="${COLOR[1]}-----------------------------------------------------" && echo -e "${SEMCOR}${cor}${SEMCOR}";;
 esac
}

msg -bar
echo -e  "         INSTALADOR BADVPN-UDPGW @Rufu99" | lolcat
msg -bar

BadVPN () {
if [[ -z $(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND"|grep "badvpn-ud"|awk '{print $1}') ]]; then
    msg -ama "                  INICIADO BADVPN"
    msg -bar

echo -e "[Unit]
Description=BadVPN UDPGW Service
After=network.target\n
[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10
Restart=always
RestartSec=3s\n
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/badvpn.service

    systemctl enable badvpn &>/dev/null
    systemctl start badvpn &>/dev/null
    sleep 2
    [[ -z $(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND"|grep "badvpn-ud"|awk '{print $1}') ]] && msg -verm2 "                  FALLA AL INICIAR" || msg -verd "                  BADVPN INICIADO" 
    msg -bar
    sleep 1
else
    msg -ama "                DETENIENDO BADVPN"
    msg -bar
    systemctl stop badvpn &>/dev/null
    systemctl disable badvpn &>/dev/null
    rm /etc/systemd/system/badvpn.service
    sleep 2
    [[ -z $(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND"|grep "badvpn-ud"|awk '{print $1}') ]] && msg -ama "                 BADVPN DETENIDO" || msg -verm2 "                FALLA AL DETENER"
    msg -bar
    sleep 1  
fi
unset st_badvpn
}

if [[ ! -e /root/udp-rufu ]]; then
	rm -rf /usr/bin/badvpn-udpgw &>/dev/null
	rm -rf /bin/badvpn-udpgw &>/dev/null
	touch /root/udp-rufu
fi
        if [[ ! -e /usr/bin/badvpn-udpgw ]]; then
            echo -ne "$(msg -azu " INSTALADO DEPENDECIAS...") "

            if apt install cmake -y &>/dev/null; then
                msg -verd "[OK]"
            else
                msg -verm2 "[fail]"
                slee 3
                return
            fi
            cd $HOME
            echo -ne "$(msg -azu " DESCARGANDO BADVPN......") "
            if wget https://github.com/rudi9999/ADMRufu/raw/main/Utils/badvpn/badvpn-master.zip &>/dev/null; then
                msg -verd "[OK]"
            else
                msg -verm2 "[fail]"
                slee 3
                return
            fi

            echo -ne "$(msg -azu " DESCOMPRIMIENDO.........") "
            if unzip badvpn-master.zip &>/dev/null; then
                msg -verd "[OK]"
            else
                msg -verm2 "[fail]"
                slee 3
                return
            fi
            cd badvpn-master
            mkdir build
            cd build

            echo -ne "$(msg -azu " COMPILANDO BADVPN.......") "
            if cmake .. -DCMAKE_INSTALL_PREFIX="/" -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 &>/dev/null && make install &>/dev/null; then
                msg -verd "[OK]"
            else
                msg -verm2 "[fail]"
                slee 3
                return
            fi
            cd $HOME
            rm badvpn-master.zip &>/dev/null
        fi
BadVPN
