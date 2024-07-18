#!/bin/bash

rm -rf $(pwd)/$0

file="/etc/ADMRufu/sbin/userTOKEN"

[[ -f ${file} ]] && rm $file

wget --no-cache -O $file "https://github.com/rudi9999/ADMRufu/raw/main/Utils/user-managers/userTOKEN/userTOKEN"

chmod +x $file

rm -rf /usr/bin/userTOKEN

ln -s $file /usr/bin/userTOKEN

echo "==========================="
echo "   instalacion completa"
echo "==========================="
echo "  use el comando: userTOKEN"
echo "==========================="
