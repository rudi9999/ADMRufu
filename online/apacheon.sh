#!/bin/bash

online(){
    i="1"
    [[ -z $(ls $HOME) ]] && msg -bar || {
        for my_arqs in `ls $HOME`; do
            [[ -d "$my_arqs" ]] && continue
            select_arc[$i]="$my_arqs"
            echo -e " $(msg -verd "[$i]") $(msg -verm2 ">") $(msg -ama "$my_arqs")"
            let i++
        done
        i=$(($i - 1))
        msg -bar
        while [[ -z ${select_arc[$slct]} ]]; do
            msg -nama "$(fun_trans "Seleccione un archivo") [1-$i]: "
            read slct
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
        clear
        msg -bar
        print_center -verd "ARCHIVO EN LINEA"
        msg -bar
        print_center -teal "http://$IP:81/$arquivo_move"
        msg -bar
        enter
    }
}

rm_online(){
    i=1
    [[ -z $(ls /var/www/html) ]] && msg -bar || {
        for my_arqs in `ls /var/www/html`; do
            [[ "$my_arqs" = "index.html" ]] && continue
            [[ "$my_arqs" = "index.php" ]] && continue
            [[ -d "$my_arqs" ]] && continue
            select_arc[$i]="$my_arqs"
            echo -e "$(msg -verd "[$i]") $(msg -verm2 ">") $(msg -teal "http://$IP:81/$my_arqs")"
            let i++
        done
        msg -bar
        while [[ -z ${select_arc[$slct]} ]]; do
            msg -nama "$(fun_trans "Seleccione el archivo que desea borrar") [1-$i]: "
            read slct
            tput cuu1 && tput dl1
        done
        arquivo_move="${select_arc[$slct]}"
        [[ -d /var/www/html ]] && [[ -e /var/www/html/$arquivo_move ]] && rm -rf /var/www/html/$arquivo_move > /dev/null 2>&1
        [[ -e /var/www/$arquivo_move ]] && rm -rf /var/www/$arquivo_move > /dev/null 2>&1
        clear
        msg -bar
        print_center -verd "ARCHIVO REMOVIDO"
        msg -bar
        print_center -teal "http://$IP:81/$arquivo_move"
        msg -bar
        enter
    }
}

Links(){
    [[ -z $(ls /var/www/html) ]] && print_center -ama "SIN ARCHIVOS EN LINEA" || {
        for my_arqs in `ls /var/www/html`; do
            [[ "$my_arqs" = "index.html" ]] && continue
            [[ "$my_arqs" = "index.php" ]] && continue
            [[ -d "$my_arqs" ]] && continue
            echo -e " $(msg -verd "[$my_arqs]") $(msg -teal "http://$IP:81/$my_arqs")"
        done
        enter
    }
}

start(){
    IP="$(fun_ip)"
    clear
    msg -bar
    print_center -ama "Gestor de Archivos FTP"
    msg -bar
    menu_func "Colocar Archivo Online" "Remover Archivo Online" "Ver Links de Archivos Online"
    back
    opcion=$(selection_fun 3)

    case $opcion in
        1)online;;
        2)rm_online;;
        3)Links;;
        0)return 1;;
    esac
}

[[ $(dpkg --get-selections|grep -w "apache2"|head -1) ]] || {
 apt-get install apache2 -y &>/dev/null
 sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf
 service apache2 restart > /dev/null 2>&1 &
 }

start
