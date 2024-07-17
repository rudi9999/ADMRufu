
#!/bin/bash

rm -rf $(pwd)/$0

file="/etc/ADMRufu/sbin/userHWID"

[[ -f ${file} ]] && rm $file

wget --no-cache -O $file "https://github.com/rudi9999/ADMRufu/raw/main/Utils/user-managers/userHWID/userHWID"

chmod +x $file

rm -rf /usr/bin/userHWID

ln -s $file /usr/bin/userHWID

echo "==========================="
echo "   instalacion completa"
echo "==========================="
echo "  use el comando: userHWID"
echo "==========================="
