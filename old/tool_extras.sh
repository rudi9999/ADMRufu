#!/bin/bash

install_h(){
  clear
  msg -bar
  [[ -z $1 ]] && print_center -ama "INTALANDO ARCHIVO ONLINE" || print_center -ama "ACTUALIZANDO ARCHIVOS ONLINE"
  msg -bar
  arq=$(curl -sSL https://raw.githubusercontent.com/rudi9999/ADMRufu/main/online/list-arq)
  mkdir ${ADM_src}/tool

  while IFS= read -r line
  do
    line2=$(echo "$line"|cut -d "=" -f1)
    line3="$(echo "$line"|cut -d "=" -f2|tr -d '[[:space:]]')"

    if echo -ne $(msg -azu "  Descargando $line3....") && wget -O ${ADM_src}/tool/$line3 https://raw.githubusercontent.com/rudi9999/ADMRufu/main/online/$line3 &>/dev/null; then
      chmod +x ${ADM_src}/tool/$line3
      echo "$line" >> ${ADM_src}/tool/tool
      msg -verd "[ok]"
    else
      msg -verm2 "[fail]"
      rm ${ADM_src}/tool/$line3
    fi
    
  done <<< $arq
  msg -bar
  [[ -z $1 ]] && print_center -verd "INSTALACION COMPLETA" || print_center -verd "ACTULIZACION COMPLETA"
  enter
}

ferramentas_fun () {
clear
msg -bar
print_center -ama "MENU DE HERRAMIENTAS ONLINE"
msg -bar
if [[ ! -d ${ADM_src}/tool ]]; then
	print_center -ama "NO HAY HERRAMINETAS INSTALADAS"
else

	local Numb=1
	while IFS= read -r line
	do
		line2=$(echo "$line"|cut -d "=" -f1)
		line3="$(echo "$line"|cut -d "=" -f2)"

		echo -ne "  $(msg -verd "[$Numb]") $(msg -verm2 ">") " && msg -azu "$line2"
		script[$Numb]="$line3"

		let Numb++
	done <<< $(cat ${ADM_src}/tool/tool)

	msg -bar
	echo -ne "  $(msg -verd "[$Numb]") $(msg -verm2 ">") " && msg -verm2 "LIMPIAR LISTA DE HERRAMIENTAS"
  script[$Numb]="clear_h"
	let Numb++
fi

msg -bar
echo -ne "$(msg -verd "  [0]") $(msg -verm2 ">") $(msg -bra "   \033[1;41m VOLVER \033[0m")"

if [[ ! -d ${ADM_src}/tool ]]; then
	echo -e " $(msg -verd "   [1]") $(msg -verm2 ">") $(msg -azu "INSTALAR HERRAMIENTAS")"
  local Numb=1
  script[$Numb]="install_h"
else
	echo -e " $(msg -verd "   [$Numb]") $(msg -verm2 ">") $(msg -azu "ACTUALIZAR HERRAMIENTAS")"
  script[$Numb]="up_h"
fi
msg -bar
script[0]="volver"
selection=$(selection_fun $Numb)
if [[ -e "${ADM_src}/tool/$(echo ${script[$selection]}|tr -d '[[:space:]]')" ]]; then
  ${ADM_src}/tool/$(echo ${script[$selection]}|tr -d '[[:space:]]')
elif [[ ${script[1]} = "install_h" ]]; then
  install_h
elif [[ ${script[$selection]} = "clear_h" ]]; then
  rm -rf ${ADM_src}/tool
  clear
  msg -bar
  print_center -ama "ALMACEN DE HERRAMIENTAS ONLINES ELIMINADO"
  enter
elif [[ ${script[$selection]} = "up_h" ]]; then
  rm -rf ${ADM_src}/tool
  install_h up
fi

return 1
}

ferramentas_fun
