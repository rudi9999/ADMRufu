# Limitador de conecciones multiples y expirados (ssh/dropbear)

## instalacion

rm -rf limit; wget --no-cache https://github.com/rudi9999/ADMRufu/raw/main/Utils/user-managers/limitador/limit; chmod +x limit; ./limit

## desinstalar

rm -rf unistall.sh; wget --no-cache https://github.com/rudi9999/ADMRufu/raw/main/Utils/user-managers/limitador/uninstall.sh; chmod +x unistall.sh; ./uninstall.sh

## ver el proceso en tiempo real

journalctl -u limitador -f

NOTA: solo compatible con la base de datos ADMRufu
