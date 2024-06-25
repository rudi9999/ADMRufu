#!/bin/bash

rm -rf $(pwd)/$0

systemctl stop limiador
systemctl disable limitador
rm -rf /etc/systemd/system/limitador.service
rm -rf /etc/ADMRufu/bin/limit