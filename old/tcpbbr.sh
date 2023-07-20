#!/bin/bash

#PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
#export PATH

#if [[ -e ../module ]]; then
#  source ../module
#else
#  source ./module
#fi

sh_ver="100.0.1.10"
github="raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master"

imgurl=""
headurl=""

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Font_color_suffix="\033[0m"
Error="${Red_font_prefix}[error]${Font_color_suffix}"
Tip="${Green_font_prefix}[Aviso]${Font_color_suffix}"

if [ -f "/etc/sysctl.d/bbr.conf" ]; then
  rm -rf /etc/sysctl.d/bbr.conf
fi

checkurl() {
  url=$(curl --max-time 5 --retry 3 --retry-delay 2 --connect-timeout 2 -s --head $1 | head -n 1)
  if [[ ${url} == *200* || ${url} == *302* || ${url} == *308* ]]; then
    print_center -ama "Verificacion dirección de descarga ¡OK, continúe!"
  else
    print_center -ama "Error de verificación de descarga, ¡salga!"
    enter
  fi
}

check_cn() {
  geoip=$(wget --user-agent="Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36" --no-check-certificate -qO- https://api.ip.sb/geoip -T 10 | grep "\"country_code\":\"CN\"")
  if [[ "$geoip" != "" ]]; then
    echo https://endpoint.fastgit.org/$1
  else
    echo $1
  fi
}

installbbr() {
  kernel_version="5.9.6"
  bit=$(uname -m)
  rm -rf bbr
  mkdir bbr && cd bbr || exit

    if [[ "${release}" == "centos" ]]; then
      if [[ ${version} == "7" ]]; then
          if [[ ${bit} == "x86_64" ]]; then
            echo -e "Si la dirección de descarga es incorrecta, es posible que se esté actualizando. Si el error persiste después de medio día, infórmenos"
            github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Centos_Kernel' | grep '_latest_bbr_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
            github_ver=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}')
            echo -e "El número de versión obtenido es:${github_ver}"
            kernel_version=$github_ver
            detele_kernel_head
            headurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}')
            imgurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')

            headurl=$(check_cn $headurl)
            imgurl=$(check_cn $imgurl)
            echo -e "Comprobando enlace de descarga headers...."
            checkurl $headurl
            echo -e "Comprobando conexión de descarga del kernel...."
            checkurl $imgurl
            wget -N -O kernel-headers-c7.rpm $headurl
            wget -N -O kernel-c7.rpm $imgurl
            yum install -y kernel-c7.rpm
            yum install -y kernel-headers-c7.rpm
          else
            echo -e "${Error} ¡Los sistemas que no sean x86_64 no son compatibles!" && exit 1
          fi
      fi

    elif [[ "${release}" == "ubuntu" || "${release}" == "debian" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
          echo -e "Si la dirección de descarga es incorrecta, es posible que se esté actualizando. Si el error persiste después de medio día, infórmenos"
          github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Debian_Kernel' | grep '_latest_bbr_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
          github_ver=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}' | awk -F '[_]' '{print $1}')
          echo -e "El número de versión obtenido es:${github_ver}"
          kernel_version=$github_ver
          detele_kernel_head
          headurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}')
          imgurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')

          headurl=$(check_cn $headurl)
          imgurl=$(check_cn $imgurl)
          echo -e "Comprobando enlace de descarga headers...."
          checkurl $headurl
          echo -e "Comprobando conexión de descarga del kernel...."
          checkurl $imgurl
          wget -N -O linux-headers-d10.deb $headurl
          wget -N -O linux-image-d10.deb $imgurl
          dpkg -i linux-image-d10.deb
          dpkg -i linux-headers-d10.deb
      elif [[ ${bit} == "aarch64" ]]; then
          echo -e "Si la dirección de descarga es incorrecta, es posible que se esté actualizando. Si el error persiste después de medio día, infórmenos"
          github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Debian_Kernel' | grep '_arm64_' | grep '_bbr_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
          github_ver=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}' | awk -F '[_]' '{print $1}')
          echo -e "El número de versión obtenido es:${github_ver}"
          kernel_version=$github_ver
          detele_kernel_head
          headurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}')
          imgurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')

          headurl=$(check_cn $headurl)
          imgurl=$(check_cn $imgurl)
          echo -e "Comprobando enlace de descarga headers...."
          checkurl $headurl
          echo -e "Comprobando conexión de descarga del kernel."
          checkurl $imgurl
          wget -N -O linux-headers-d10.deb $headurl
          wget -N -O linux-image-d10.deb $imgurl
          dpkg -i linux-image-d10.deb
          dpkg -i linux-headers-d10.deb
      else
          echo -e "${Error} ¡Los sistemas que no sean x86_64 y arm64/aarch64 no son compatibles!" && exit 1
      fi
    fi

    cd .. && rm -rf bbr

    BBR_grub
    aviso
    check_kernel
}

installxanmod() {
  kernel_version="5.5.1-xanmod1"
  bit=$(uname -m)
  if [[ ${bit} != "x86_64" ]]; then
    msg -bar
    print_center -ama '¡Sistemas no x86_64, no son compatibles!'
    enter
    return
  fi
  rm -rf xanmod
  mkdir xanmod && cd xanmod || return
  msg -bar3
  print_center -ama "Si la dirección de descarga es incorrecta\nes posible que se esté actualizando.\nSi el error persiste, infórmenos."
  msg -bar3
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" ]]; then
        github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Centos_Kernel' | grep '_lts_latest_' | grep 'xanmod' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
        github_ver=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}')
        echo -e "Versión obtenida:${github_ver}"
        kernel_version=$github_ver
        detele_kernel_head
        headurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}')
        imgurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')

        headurl=$(check_cn $headurl)
        imgurl=$(check_cn $imgurl)
        print_center -ama  "Comprobando enlace de descarga, headers...."
        checkurl $headurl
        print_center -ama "Comprobando enlace de descarga, kernel...."
        checkurl $imgurl
        wget -N -O kernel-headers-c7.rpm $headurl
        wget -N -O kernel-c7.rpm $imgurl
        yum install -y kernel-c7.rpm
        yum install -y kernel-headers-c7.rpm
    elif [[ ${version} == "8" ]]; then
      github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Centos_Kernel' | grep '_lts_C8_latest_' | grep 'xanmod' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
      github_ver=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}')
      echo -e "Versión obtenida:${github_ver}"
      kernel_version=$github_ver
      detele_kernel_head
      headurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}')
      imgurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')

      headurl=$(check_cn $headurl)
      imgurl=$(check_cn $imgurl)
      print_center -ama  "Comprobando enlace de descarga, headers...."
      checkurl $headurl
      print_center -ama "Comprobando enlace de descarga, kernel...."
      checkurl $imgurl
      wget -N -O kernel-headers-c8.rpm $headurl
      wget -N -O kernel-c8.rpm $imgurl
      yum install -y kernel-c8.rpm
      yum install -y kernel-headers-c8.rpm
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
      github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Debian_Kernel' | grep '_lts_latest_' | grep 'xanmod' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
      github_ver=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}')
      echo -e "Versión xanmod lts es:${github_ver}"
      kernel_version=$github_ver
      detele_kernel_head
      headurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}')
      imgurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')

      headurl=$(check_cn $headurl)
      imgurl=$(check_cn $imgurl)
      print_center -ama  "Comprobando enlace de descarga, headers...."
      checkurl $headurl
      print_center -ama "Comprobando enlace de descarga, kernel...."
      checkurl $imgurl
      wget -N -O linux-headers-d10.deb $headurl
      wget -N -O linux-image-d10.deb $imgurl
      dpkg -i linux-image-d10.deb
      dpkg -i linux-headers-d10.deb
  fi
  cd .. && rm -rf xanmod
  BBR_grub
  aviso
  check_kernel
}

installbbrplusnew() {
  github_ver_plus=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-5.19/releases | grep /bbrplus-5.19/releases/tag/ | head -1 | awk -F "[/]" '{print $8}' | awk -F "[\"]" '{print $1}')
  github_ver_plus_num=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-5.19/releases | grep /bbrplus-5.19/releases/tag/ | head -1 | awk -F "[/]" '{print $8}' | awk -F "[\"]" '{print $1}' | awk -F "[-]" '{print $1}')
  msg -bar3
  print_center -ama "Vercion UJX6N de bbrplus-5.19: ${github_ver_plus}"
  msg -bar3
  print_center -ama "Si la dirección de descarga es incorrecta\nes posible que se esté actualizando.\nSi el error persiste, infórmenos."
  msg -bar3
  bit=$(uname -m)
  rm -rf bbrplusnew
  mkdir bbrplusnew && cd bbrplusnew || exit
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        kernel_version=${github_ver_plus_num}
        detele_kernel_head
        headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.19/releases' | grep ${github_ver_plus} | grep 'rpm' | grep 'headers' | grep 'el7' | awk -F '"' '{print $4}')
        imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.19/releases' | grep ${github_ver_plus} | grep 'rpm' | grep -v 'devel' | grep -v 'headers' | grep -v 'Source' | grep 'el7' | awk -F '"' '{print $4}')

        headurl=$(check_cn $headurl)
        imgurl=$(check_cn $imgurl)
        print_center -ama  "Comprobando enlace de descarga, headers...."
        checkurl $headurl
        print_center -ama "Comprobando enlace de descarga, kernel...."
        checkurl $imgurl
        wget -N -O kernel-c7.rpm $headurl
        wget -N -O kernel-headers-c7.rpm $imgurl
        yum install -y kernel-c7.rpm
        yum install -y kernel-headers-c7.rpm
      else
        msg -bar
        print_center -ama '¡Sistemas no x86_64, no son compatibles!'
        enter
        return
      fi
    fi
    if [[ ${version} == "8" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        kernel_version=${github_ver_plus_num}
        detele_kernel_head
        headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.19/releases' | grep ${github_ver_plus} | grep 'rpm' | grep 'headers' | grep 'el8' | awk -F '"' '{print $4}')
        imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.19/releases' | grep ${github_ver_plus} | grep 'rpm' | grep -v 'devel' | grep -v 'headers' | grep -v 'Source' | grep 'el8' | awk -F '"' '{print $4}')

        headurl=$(check_cn $headurl)
        imgurl=$(check_cn $imgurl)
        print_center -ama  "Comprobando enlace de descarga, headers...."
        checkurl $headurl
        print_center -ama "Comprobando enlace de descarga, kernel...."
        checkurl $imgurl
        wget -N -O kernel-c8.rpm $headurl
        wget -N -O kernel-headers-c8.rpm $imgurl
        yum install -y kernel-c8.rpm
        yum install -y kernel-headers-c8.rpm
      else
        msg -bar
        print_center -ama '¡Sistemas no x86_64, no son compatibles!'
        enter
        return
      fi
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    if [[ ${bit} == "x86_64" ]]; then
      kernel_version=${github_ver_plus_num}-bbrplus
      detele_kernel_head
      headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.19/releases' | grep ${github_ver_plus} | grep 'https' | grep 'amd64.deb' | grep 'headers' | awk -F '"' '{print $4}')
      imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.19/releases' | grep ${github_ver_plus} | grep 'https' | grep 'amd64.deb' | grep 'image' | awk -F '"' '{print $4}')

      headurl=$(check_cn $headurl)
      imgurl=$(check_cn $imgurl)
      print_center -ama  "Comprobando enlace de descarga, headers...."
      checkurl $headurl
      print_center -ama "Comprobando enlace de descarga, kernel...."
      checkurl $imgurl
      wget -N -O linux-headers-d10.deb $headurl
      wget -N -O linux-image-d10.deb $imgurl
      dpkg -i linux-image-d10.deb
      dpkg -i linux-headers-d10.deb
    elif [[ ${bit} == "aarch64" ]]; then
      kernel_version=${github_ver_plus_num}-bbrplus
      detele_kernel_head
      headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.19/releases' | grep ${github_ver_plus} | grep 'https' | grep 'arm64.deb' | grep 'headers' | awk -F '"' '{print $4}')
      imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.19/releases' | grep ${github_ver_plus} | grep 'https' | grep 'arm64.deb' | grep 'image' | awk -F '"' '{print $4}')

      headurl=$(check_cn $headurl)
      imgurl=$(check_cn $imgurl)
      print_center -ama  "Comprobando enlace de descarga, headers...."
      checkurl $headurl
      print_center -ama "Comprobando enlace de descarga, kernel...."
      checkurl $imgurl
      wget -N -O linux-headers-d10.deb $headurl
      wget -N -O linux-image-d10.deb $imgurl
      dpkg -i linux-image-d10.deb
      dpkg -i linux-headers-d10.deb
    else
      msg -bar
      print_center -ama '¡Sistemas no x86_64, no son compatibles!'
      enter
      return
    fi
  fi

  cd .. && rm -rf bbrplusnew
  BBR_grub
  aviso
  check_kernel
}

startbbrfq() {
  if [[ ! $1 = 'noclear' ]]; then
    remove_bbr_lotserver
  fi
  echo "net.core.default_qdisc=fq" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  msg -bar
  print_center -ama 'BBR+FQ aplicado con éxito\n¡reiniciar para que surta efecto!'
}

startbbrfqpie() {
  if [[ ! $1 = 'noclear' ]]; then
    remove_bbr_lotserver
  fi
  echo "net.core.default_qdisc=fq_pie" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  msg -bar
  print_center -ama 'BBR+FQ_PIE aplicado con éxito\n¡reiniciar para que surta efecto!'
}

startbbrcake() {
  if [[ ! $1 = 'noclear' ]]; then
    remove_bbr_lotserver
  fi
  echo "net.core.default_qdisc=cake" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  msg -bar
  print_center -ama 'BBR+cake aplicado con éxito\n¡reiniciar para que surta efecto!'
}

startbbrplus() {
  if [[ ! $1 = 'noclear' ]]; then
    remove_bbr_lotserver
  fi
  echo "net.core.default_qdisc=fq" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbrplus" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  msg -bar
  print_center -ama 'BBRplus aplicado con éxito\n¡reiniciar para que surta efecto!'
}

startbbr2fq() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=fq" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr2" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  msg -bar
  print_center -ama 'BBR2+FQ aplicado con éxito\n¡reiniciar para que surta efecto!'
}

startbbr2fqpie() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=fq_pie" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr2" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  msg -bar
  print_center -ama 'BBR+FQ_PIE aplicado con éxito\n¡reiniciar para que surta efecto!'
}

startbbr2cake() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=cake" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr2" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  msg -bar
  print_center -ama 'BBR+cake aplicado con éxito\n¡reiniciar para que surta efecto!'
}

remove_bbr_lotserver() {
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
  sysctl --system

  rm -rf bbrmod

  if [[ -e /appex/bin/lotServer.sh ]]; then
    echo | bash <(wget -qO- https://raw.githubusercontent.com/fei5seven/lotServer/master/lotServerInstall.sh) uninstall
  fi
  clear
}

remove_all() {
  rm -rf /etc/sysctl.d/*.conf
  #rm -rf /etc/sysctl.conf
  #touch /etc/sysctl.conf
  if [ ! -f "/etc/sysctl.conf" ]; then
    touch /etc/sysctl.conf
  else
    cat /dev/null >/etc/sysctl.conf
  fi
  sysctl --system
  sed -i '/DefaultTimeoutStartSec/d' /etc/systemd/system.conf
  sed -i '/DefaultTimeoutStopSec/d' /etc/systemd/system.conf
  sed -i '/DefaultRestartSec/d' /etc/systemd/system.conf
  sed -i '/DefaultLimitCORE/d' /etc/systemd/system.conf
  sed -i '/DefaultLimitNOFILE/d' /etc/systemd/system.conf
  sed -i '/DefaultLimitNPROC/d' /etc/systemd/system.conf

  sed -i '/soft nofile/d' /etc/security/limits.conf
  sed -i '/hard nofile/d' /etc/security/limits.conf
  sed -i '/soft nproc/d' /etc/security/limits.conf
  sed -i '/hard nproc/d' /etc/security/limits.conf

  sed -i '/ulimit -SHn/d' /etc/profile
  sed -i '/ulimit -SHn/d' /etc/profile
  sed -i '/required pam_limits.so/d' /etc/pam.d/common-session

  systemctl daemon-reload

  rm -rf bbrmod
  sed -i '/net.ipv4.tcp_retries2/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_slow_start_after_idle/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
  sed -i '/fs.file-max/d' /etc/sysctl.conf
  sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
  sed -i '/net.core.wmem_max/d' /etc/sysctl.conf
  sed -i '/net.core.rmem_default/d' /etc/sysctl.conf
  sed -i '/net.core.wmem_default/d' /etc/sysctl.conf
  sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
  sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_tw_recycle/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_keepalive_time/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_mtu_probing/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
  sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
  sed -i '/net.ipv4.route.gc_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syn_retries/d' /etc/sysctl.conf
  sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
  sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_orphans/d' /etc/sysctl.conf
  if [[ -e /appex/bin/lotServer.sh ]]; then
    bash <(wget -qO- https://raw.githubusercontent.com/fei5seven/lotServer/master/lotServerInstall.sh) uninstall
  fi
  msg -bar
  print_center -ama 'Para que los cambios surtan efecto\ndeve reiniciar el servidor'
  msg -bar
  read -rp "$(msg -ama " Reinciar vps [S/N]: ") " -e -i S reboot
  if [[ $reboot = @(s|S) ]]; then
    sudo reboot
  fi
}

optimizing_system() {
  if [ ! -f "/etc/sysctl.conf" ]; then
    touch /etc/sysctl.conf
  fi
  sed -i '/net.ipv4.tcp_retries2/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_slow_start_after_idle/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
  sed -i '/fs.file-max/d' /etc/sysctl.conf
  sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
  sed -i '/net.ipv4.route.gc_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syn_retries/d' /etc/sysctl.conf
  sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
  sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_orphans/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf

  echo "net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_slow_start_after_idle = 0
fs.file-max = 1000000
fs.inotify.max_user_instances = 8192
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_max_orphans = 32768
# forward ipv4
#net.ipv4.ip_forward = 1" >>/etc/sysctl.conf
  sysctl -p
  echo "*               soft    nofile           1000000
*               hard    nofile          1000000" >/etc/security/limits.conf
  echo "ulimit -SHn 1000000" >>/etc/profile
  msg -bar
  print_center -ama 'Para que los cambios surtan efecto\ndeve reiniciar el servidor'
  msg -bar
  read -rp "$(msg -ama " Reinciar vps [S/N]: ") " -e -i S reboot
  if [[ $reboot = @(s|S) ]]; then
    sudo reboot
  fi
}

optimizing_system_johnrosen1() {
  if [ ! -f "/etc/sysctl.d/99-sysctl.conf" ]; then
    touch /etc/sysctl.d/99-sysctl.conf
  fi
  sed -i 'net.ipv4.tcp_fack/d' /etc/sysctl.d/99-sysctl.conf
  sed -i 'net.ipv4.tcp_early_retrans/d' /etc/sysctl.d/99-sysctl.conf
  sed -i 'net.ipv4.neigh.default.unres_qlen/d' /etc/sysctl.d/99-sysctl.conf
  sed -i 'net.ipv4.tcp_max_orphans/d' /etc/sysctl.d/99-sysctl.conf
  sed -i 'net.netfilter.nf_conntrack_buckets/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/kernel.pid_max/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/vm.nr_hugepages/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.optmem_max/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.route_localnet/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.forwarding/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.default.forwarding/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.all.forwarding/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.default.forwarding/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.lo.forwarding/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.all.accept_ra/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.default.accept_ra/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.netdev_budget/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.netdev_budget_usecs/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/fs.file-max /d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.rmem_max/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.wmem_max/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.rmem_default/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.wmem_default/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.somaxconn/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.icmp_echo_ignore_all/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.icmp_echo_ignore_broadcasts/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.icmp_ignore_bogus_error_responses/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.accept_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.default.accept_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.secure_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.default.secure_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.send_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.default.send_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.default.rp_filter/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.rp_filter/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_keepalive_time/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_keepalive_intvl/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_keepalive_probes/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_rfc1337/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.udp_rmem_min/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.udp_wmem_min/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_mtu_probing/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.arp_ignore /d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.default.arp_ignore/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.arp_announce/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.default.arp_announce/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_autocorking/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_slow_start_after_idle/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_notsent_lowat/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_no_metrics_save/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_ecn_fallback/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_frto/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.all.accept_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.default.accept_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/vm.swappiness/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.ip_unprivileged_port_start/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/vm.overcommit_memory/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.neigh.default.gc_thresh3/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.neigh.default.gc_thresh2/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.neigh.default.gc_thresh1/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.neigh.default.gc_thresh3/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.neigh.default.gc_thresh2/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.neigh.default.gc_thresh1/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.netfilter.nf_conntrack_max/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.nf_conntrack_max/d' /etc/sysctl.d/99-sysctl.conf
  sed -i 'net.netfilter.nf_conntrack_tcp_timeout_fin_wait/d' /etc/sysctl.d/99-sysctl.conf
  sed -i 'net.netfilter.nf_conntrack_tcp_timeout_time_wait/d' /etc/sysctl.d/99-sysctl.conf
  sed -i 'net.netfilter.nf_conntrack_tcp_timeout_close_wait/d' /etc/sysctl.d/99-sysctl.conf
  sed -i 'net.netfilter.nf_conntrack_tcp_timeout_established/d' /etc/sysctl.d/99-sysctl.conf
  sed -i 'fs.inotify.max_user_instances/d' /etc/sysctl.d/99-sysctl.conf
  sed -i 'fs.inotify.max_user_watches/d' /etc/sysctl.d/99-sysctl.conf
  sed -i 'net.ipv4.tcp_low_latency/d' /etc/sysctl.d/99-sysctl.conf

  cat >'/etc/sysctl.d/99-sysctl.conf' <<EOF
net.ipv4.tcp_fack = 1
net.ipv4.tcp_early_retrans = 3
net.ipv4.neigh.default.unres_qlen=10000  
net.ipv4.conf.all.route_localnet=1
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.lo.forwarding = 1
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.default.accept_ra = 2
net.core.netdev_max_backlog = 100000
net.core.netdev_budget = 50000
net.core.netdev_budget_usecs = 5000
#fs.file-max = 51200
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 67108864
net.core.wmem_default = 67108864
net.core.optmem_max = 65536
net.core.somaxconn = 1000000
net.ipv4.icmp_echo_ignore_all = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 2
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rfc1337 = 0
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_tw_reuse = 0
net.ipv4.tcp_fin_timeout = 15
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_autocorking = 0
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_max_syn_backlog = 819200
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_no_metrics_save = 0
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_ecn_fallback = 1
net.ipv4.tcp_frto = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.neigh.default.gc_thresh3=8192
net.ipv4.neigh.default.gc_thresh2=4096
net.ipv4.neigh.default.gc_thresh1=2048
net.ipv6.neigh.default.gc_thresh3=8192
net.ipv6.neigh.default.gc_thresh2=4096
net.ipv6.neigh.default.gc_thresh1=2048
net.ipv4.tcp_orphan_retries = 1
net.ipv4.tcp_retries2 = 5
vm.swappiness = 1
vm.overcommit_memory = 1
kernel.pid_max=64000
net.netfilter.nf_conntrack_max = 262144
net.nf_conntrack_max = 262144
## Enable bbr
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_low_latency = 1
EOF
  sysctl -p
  sysctl --system
  echo always >/sys/kernel/mm/transparent_hugepage/enabled

  cat >'/etc/systemd/system.conf' <<EOF
[Manager]
#DefaultTimeoutStartSec=90s
DefaultTimeoutStopSec=30s
#DefaultRestartSec=100ms
DefaultLimitCORE=infinity
DefaultLimitNOFILE=infinity
DefaultLimitNPROC=infinity
DefaultTasksMax=infinity
EOF

  cat >'/etc/security/limits.conf' <<EOF
root     soft   nofile    1000000
root     hard   nofile    1000000
root     soft   nproc     unlimited
root     hard   nproc     unlimited
root     soft   core      unlimited
root     hard   core      unlimited
root     hard   memlock   unlimited
root     soft   memlock   unlimited
*     soft   nofile    1000000
*     hard   nofile    1000000
*     soft   nproc     unlimited
*     hard   nproc     unlimited
*     soft   core      unlimited
*     hard   core      unlimited
*     hard   memlock   unlimited
*     soft   memlock   unlimited
EOF

  sed -i '/ulimit -SHn/d' /etc/profile
  sed -i '/ulimit -SHu/d' /etc/profile
  echo "ulimit -SHn 1000000" >>/etc/profile

  if grep -q "pam_limits.so" /etc/pam.d/common-session; then
    :
  else
    sed -i '/required pam_limits.so/d' /etc/pam.d/common-session
    echo "session required pam_limits.so" >>/etc/pam.d/common-session
  fi
  systemctl daemon-reload
  msg -bar
  print_center -ama 'optimización johnrosen1 finalizado\nPara que los cambios surtan efecto\ndeve reiniciar el servidor'
  msg -bar
  read -rp "$(msg -ama " Reinciar vps [S/N]: ") " -e -i S reboot
  if [[ $reboot = @(s|S) ]]; then
    sudo reboot
  fi
}

Update_Shell() {
  echo -e "当前版本为 [ ${sh_ver} ]，开始检测最新版本..."
  sh_new_ver=$(wget -qO- "https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh" | grep 'sh_ver="' | awk -F "=" '{print $NF}' | sed 's/\"//g' | head -1)
  [[ -z ${sh_new_ver} ]] && echo -e "${Error} 检测最新版本失败 !" && start_menu
  if [ ${sh_new_ver} != ${sh_ver} ]; then
    echo -e "发现新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
    read -p "(默认: y):" yn
    [[ -z "${yn}" ]] && yn="y"
    if [[ ${yn} == [Yy] ]]; then
      wget -N "https://${github}/tcpx.sh" && chmod +x tcpx.sh && ./tcpx.sh
      echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !"
    else
      echo && echo "	已取消..." && echo
    fi
  else
    echo -e "当前已是最新版本[ ${sh_new_ver} ] !"
    sleep 2s && ./tcpx.sh
  fi
}

detele_kernel_head() {
  if [[ "${release}" == "centos" ]]; then
    rpm_total=$(rpm -qa | grep kernel-headers | grep -v "${kernel_version}" | grep -v "noarch" | wc -l)
    if [ "${rpm_total}" ] >"1"; then
      echo -e "detectado ${rpm_total} El resto del kernel principal, comienza a desinstalarlo..."
      for ((integer = 1; integer <= ${rpm_total}; integer++)); do
        rpm_del=$(rpm -qa | grep kernel-headers | grep -v "${kernel_version}" | grep -v "noarch" | head -${integer})
        echo -e "empezar a desinstalar ${rpm_del} Nucleo headers..."
        rpm --nodeps -e ${rpm_del}
        echo -e "desinstalar ${rpm_del} La descarga del núcleo está completa, continúa..."
      done
      echo --nodeps -e "El kernel está desinstalado, continuar..."
    else
      echo -e " Se detectó un número incorrecto de núcleos, verifíquelo." && exit 1
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    deb_total=$(dpkg -l | grep linux-headers | awk '{print $2}' | grep -v "${kernel_version}" | wc -l)
    if [ "${deb_total}" ] >"1"; then
      echo -e "detectado ${deb_total} El resto del kernel principal, comienza a desinstalarlo..."
      for ((integer = 1; integer <= ${deb_total}; integer++)); do
        deb_del=$(dpkg -l | grep linux-headers | awk '{print $2}' | grep -v "${kernel_version}" | head -${integer})
        echo -e "empezar a desinstalar ${deb_del} Nucleo headers..."
        apt-get purge -y ${deb_del}
        apt-get autoremove -y
        echo -e "desinstalar ${deb_del} La descarga del núcleo está completa, continúa..."
      done
      echo -e "El kernel está desinstalado, continuar..."
    else
      echo -e " Se detectó un número incorrecto de núcleos, verifíquelo." && return
    fi
  fi
}

BBR_grub() {
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "6" ]]; then
      if [ -f "/boot/grub/grub.conf" ]; then
        sed -i 's/^default=.*/default=0/g' /boot/grub/grub.conf
      elif [ -f "/boot/grub/grub.cfg" ]; then
        grub-mkconfig -o /boot/grub/grub.cfg
        grub-set-default 0
      elif [ -f "/boot/efi/EFI/centos/grub.cfg" ]; then
        grub-mkconfig -o /boot/efi/EFI/centos/grub.cfg
        grub-set-default 0
      elif [ -f "/boot/efi/EFI/redhat/grub.cfg" ]; then
        grub-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
        grub-set-default 0
      else
        echo -e "${Error} grub.conf/grub.cfg No se encontro, por favor verifique."
        exit
      fi
    elif [[ ${version} == "7" ]]; then
      if [ -f "/boot/grub2/grub.cfg" ]; then
        grub2-mkconfig -o /boot/grub2/grub.cfg
        grub2-set-default 0
      elif [ -f "/boot/efi/EFI/centos/grub.cfg" ]; then
        grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
        grub2-set-default 0
      elif [ -f "/boot/efi/EFI/redhat/grub.cfg" ]; then
        grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
        grub2-set-default 0
      else
        echo -e "${Error} grub.cfg No se encontro, por favor verifique."
        exit
      fi
    elif [[ ${version} == "8" ]]; then
      if [ -f "/boot/grub2/grub.cfg" ]; then
        grub2-mkconfig -o /boot/grub2/grub.cfg
        grub2-set-default 0
      elif [ -f "/boot/efi/EFI/centos/grub.cfg" ]; then
        grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
        grub2-set-default 0
      elif [ -f "/boot/efi/EFI/redhat/grub.cfg" ]; then
        grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
        grub2-set-default 0
      else
        echo -e "${Error} grub.cfg No se encontro, por favor verifique."
        exit
      fi
      grubby --info=ALL | awk -F= '$1=="kernel" {print i++ " : " $2}'
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    if _exists "update-grub"; then
      update-grub
    elif [ -f "/usr/sbin/update-grub" ]; then
      /usr/sbin/update-grub
    else
      apt install grub2-common -y
      update-grub
    fi
    #exit 1
  fi
}

check_kernel() {
  msg -bar
  if [[ $(ls /boot/vmlinuz-* -I rescue -1) ]]; then
    print_center "lista de kernel instalados"
    msg -bar
    ls /boot/vmlinuz-* -I rescue -1
  else
    print_center -verm2 "kernel no encontrado!"
    print_center -ama "Es probable que no haya kernel instalado\n
    si apagas el servidor es prosible\n
    que no vuelva a iniciar\n
    recomiendo que relizes la instalacion\ndel kernel oficial"
  fi
  return
}

check_sys() {
  if [[ -f /etc/redhat-release ]]; then
    release="centos"
  elif cat /etc/issue | grep -q -E -i "debian"; then
    release="debian"
  elif cat /etc/issue | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  elif cat /proc/version | grep -q -E -i "debian"; then
    release="debian"
  elif cat /proc/version | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  fi

  _exists() {
      local cmd="$1"
      if eval type type >/dev/null 2>&1; then
        eval type "$cmd" >/dev/null 2>&1
      elif command >/dev/null 2>&1; then
        command -v "$cmd" >/dev/null 2>&1
      else
        which "$cmd" >/dev/null 2>&1
      fi
      local rt=$?
      return ${rt}
  }

  get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
      [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
      [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
  }

  get_system_info() {
    opsy=$(get_opsy)
    arch=$(uname -m)
    kern=$(uname -r)
    virt_check
  }

  virt_check() {
      if [ -f "/usr/bin/systemd-detect-virt" ]; then
        Var_VirtType="$(/usr/bin/systemd-detect-virt)"
      if [ "${Var_VirtType}" = "qemu" ]; then
        virtual="QEMU"
      elif [ "${Var_VirtType}" = "kvm" ]; then
        virtual="KVM"
      elif [ "${Var_VirtType}" = "zvm" ]; then
        virtual="S390 Z/VM"
      elif [ "${Var_VirtType}" = "vmware" ]; then
        virtual="VMware"
      elif [ "${Var_VirtType}" = "microsoft" ]; then
        virtual="Microsoft Hyper-V"
      elif [ "${Var_VirtType}" = "xen" ]; then
        virtual="Xen Hypervisor"
      elif [ "${Var_VirtType}" = "bochs" ]; then
        virtual="BOCHS"
      elif [ "${Var_VirtType}" = "uml" ]; then
        virtual="User-mode Linux"
      elif [ "${Var_VirtType}" = "parallels" ]; then
        virtual="Parallels"
      elif [ "${Var_VirtType}" = "bhyve" ]; then
        virtual="FreeBSD Hypervisor"
      elif [ "${Var_VirtType}" = "openvz" ]; then
        virtual="OpenVZ"
      elif [ "${Var_VirtType}" = "lxc" ]; then
        virtual="LXC"
      elif [ "${Var_VirtType}" = "lxc-libvirt" ]; then
        virtual="LXC (libvirt)"
      elif [ "${Var_VirtType}" = "systemd-nspawn" ]; then
        virtual="Systemd nspawn"
      elif [ "${Var_VirtType}" = "docker" ]; then
        virtual="Docker"
      elif [ "${Var_VirtType}" = "rkt" ]; then
        virtual="RKT"
      elif [ -c "/dev/lxss" ]; then
        Var_VirtType="wsl"
        virtual="Windows Subsystem for Linux (WSL)"
      elif [ "${Var_VirtType}" = "none" ]; then
        Var_VirtType="dedicated"
        virtual="None"
        local Var_BIOSVendor
        Var_BIOSVendor="$(dmidecode -s bios-vendor)"
        if [ "${Var_BIOSVendor}" = "SeaBIOS" ]; then
            Var_VirtType="Unknown"
            virtual="Unknown with SeaBIOS BIOS"
        else
            Var_VirtType="dedicated"
            virtual="Dedicated with ${Var_BIOSVendor} BIOS"
        fi
      fi
      elif [ ! -f "/usr/sbin/virt-what" ]; then
        Var_VirtType="Unknown"
          virtual="[Error: virt-what not found !]"
      elif [ -f "/.dockerenv" ]; then
          Var_VirtType="docker"
          virtual="Docker"
      elif [ -c "/dev/lxss" ]; then
          Var_VirtType="wsl"
          virtual="Windows Subsystem for Linux (WSL)"
      else
          Var_VirtType="$(virt-what | xargs)"
          local Var_VirtTypeCount
          Var_VirtTypeCount="$(echo $Var_VirtTypeCount | wc -l)"
          if [ "${Var_VirtTypeCount}" -gt "1" ]; then
            virtual="echo ${Var_VirtType}"
            Var_VirtType="$(echo ${Var_VirtType} | head -n1)"
          elif [ "${Var_VirtTypeCount}" -eq "1" ] && [ "${Var_VirtType}" != "" ]; then
            virtual="${Var_VirtType}"
          else
            local Var_BIOSVendor
            Var_BIOSVendor="$(dmidecode -s bios-vendor)"
            if [ "${Var_BIOSVendor}" = "SeaBIOS" ]; then
                Var_VirtType="Unknown"
                virtual="Unknown with SeaBIOS BIOS"
            else
                Var_VirtType="dedicated"
                virtual="Dedicated with ${Var_BIOSVendor} BIOS"
            fi
          fi
      fi
  }

    if [[ "${release}" == "centos" ]]; then
      if (yum list installed ca-certificates | grep '202'); then
          echo 'Verificación de certificado CA OK'
      else
          echo 'Comprobación de certificado CA fallida, procesando'
          yum install ca-certificates -y
          update-ca-trust force-enable
      fi
      if ! type curl >/dev/null 2>&1; then
          echo 'curl no está instalado, instalando'
          yum install curl -y
      else
          echo 'curl está instalado, continuar'
      fi
      if ! type wget >/dev/null 2>&1; then
          echo 'wget no está instalado, instalando'
          yum install curl -y
      else
          echo 'wget instalado, continuar'
      fi
      if ! type dmidecode >/dev/null 2>&1; then
          echo 'dmidecode no instalado, Instalando'
          yum install dmidecode -y
      else
          echo 'dmidecode instalado, continuar'
      fi
    elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
      #if (apt list --installed | grep 'ca-certificates' | grep '202'); then
      if [[ ! $(dpkg -s ca-certificates|grep 'Status\|Version'|grep 'ok\|202') ]]; then
          echo 'Comprobación de certificado CA fallida, procesando'
          apt-get update || apt-get --allow-releaseinfo-change update && apt-get install ca-certificates -y
          update-ca-certificates
      fi
      if ! type curl >/dev/null 2>&1; then
          echo 'curl no está instalado, instalando'
          apt-get update || apt-get --allow-releaseinfo-change update && apt-get install curl -y
      fi
      if ! type wget >/dev/null 2>&1; then
          echo 'wget no está instalado, instalando'
          apt-get update || apt-get --allow-releaseinfo-change update && apt-get install wget -y
      fi
      if ! type dmidecode >/dev/null 2>&1; then
          echo 'dmidecode no instalado, Instalación'
          apt-get update || apt-get --allow-releaseinfo-change update && apt-get install dmidecode -y
      fi
    fi
}

check_version() {
  if [[ -s /etc/redhat-release ]]; then
    version=$(grep -oE "[0-9.]+" /etc/redhat-release | cut -d . -f 1)
  else
    version=$(grep -oE "[0-9.]+" /etc/issue | cut -d . -f 1)
  fi
  bit=$(uname -m)
}

check_sys_bbr() {
  check_version
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" ]]; then
      installbbr
    else
      echo -e "${Error} El kernel BBR no es compatible con el sistema actual ${release} ${version} ${bit} !" && exit 1
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    apt-get --fix-broken install -y && apt-get autoremove -y
    installbbr
  else
    msg -bar
    print_center -ama "kernel BBRplus no compatible!\nEl sistema actual ${release} ${version} ${bit}"
    enter
    return
  fi
}

check_sys_bbrplusnew() {
  check_version
  if [[ "${release}" == "centos" ]]; then
    #if [[ ${version} == "7" ]]; then
    if [[ ${version} == "7" || ${version} == "8" ]]; then
      installbbrplusnew
    else
      echo -e "${Error} El kernel BBRplus no es compatible con el sistema actual ${release} ${version} ${bit} !" && exit 1
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    apt-get --fix-broken install -y && apt-get autoremove -y
    installbbrplusnew
  else
    msg -bar
    print_center -ama "kernel BBRplus no compatible!\nEl sistema actual ${release} ${version} ${bit}"
    enter
    return
  fi
}

check_sys_xanmod() {
  check_version
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" || ${version} == "8" ]]; then
      installxanmod
    else
      echo -e "${Error} El kernel xanmod no es compatible con el sistema actual ${release} ${version} ${bit} !" && exit 1
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    apt-get --fix-broken install -y && apt-get autoremove -y
    installxanmod
  else
    msg -bar
    print_center -ama "kernel xanmod no compatible!\nEl sistema actual ${release} ${version} ${bit}"
    enter
    return
  fi
}

check_sys_official() {
  check_version
  bit=$(uname -m)
  if [[ "${release}" == "centos" ]]; then
    if [[ ${bit} != "x86_64" ]]; then
      echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
    fi
    if [[ ${version} == "7" ]]; then
      yum install kernel kernel-headers -y --skip-broken
    elif [[ ${version} == "8" ]]; then
      yum install kernel kernel-core kernel-headers -y --skip-broken
    else
      echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
    fi
  elif [[ "${release}" == "debian" ]]; then
    if [[ ${bit} == "x86_64" ]]; then
      apt-get install linux-image-amd64 linux-headers-amd64 -y
    elif [[ ${bit} == "aarch64" ]]; then
      apt-get install linux-image-arm64 linux-headers-arm64 -y
    fi
  elif [[ "${release}" == "ubuntu" ]]; then
    apt-get install linux-image-generic linux-headers-generic -y
  else
    msg -bar
    print_center -ama "kernel no compatible!\nEl sistema actual ${release} ${version} ${bit}"
    enter
    return
  fi
  BBR_grub
  aviso
  enter
}

# https://xanmod.org/
check_sys_official_xanmod() {
  check_version
  if [[ ${bit} != "x86_64" ]]; then
    msg -bar
    print_center -ama '¡Sistemas no x86_64, no son compatibles!'
    enter
    return
  fi
  if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    apt-get install gnupg gnupg2 gnupg1 sudo -y
    echo 'deb http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-kernel.list
    wget -qO - https://dl.xanmod.org/gpg.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/xanmod-kernel.gpg add -
    apt update && apt install linux-xanmod-x64v3 -y
    # linux-xanmod
    # linux-xanmod-x64v1
    # linux-xanmod-x64v2
    # linux-xanmod-x64v3
  else
    msg -bar
    print_center -ama "kernel no compatible!\nEl sistema actual ${release} ${version} ${bit}"
    enter
    return
  fi
  BBR_grub
  aviso
  enter
}

check_sys_official_zen() {
  check_version
  if [[ ${bit} != "x86_64" ]]; then
    msg -bar
    print_center -ama '¡Sistemas no x86_64, no son compatibles!'
    enter
    return
  fi
  if [[ "${release}" == "debian" ]]; then
    curl 'https://liquorix.net/add-liquorix-repo.sh' | sudo bash
    apt-get install linux-image-liquorix-amd64 linux-headers-liquorix-amd64 -y
  elif [[ "${release}" == "ubuntu" && ${version} -ge 20 ]]; then
    if ! type add-apt-repository >/dev/null 2>&1; then
      print_center 'add-apt-repository no instalado... Instalando'
      apt-get install software-properties-common -y
    else
      print_center 'add-apt-repository instalado'
    fi
    add-apt-repository ppa:damentz/liquorix && sudo apt-get update
    apt-get install linux-image-liquorix-amd64 linux-headers-liquorix-amd64 -y
  else
    msg -bar
    print_center -ama "kernel zen no compatible!\nRequiere de ubuntu 20 o superior\nEl sistema actual ${release} ${version} ${bit}"
    enter
    return
  fi
  BBR_grub
  aviso
  enter
}

check_status() {
  kernel_version=$(uname -r | awk -F "-" '{print $1}')
  kernel_version_full=$(uname -r)
  net_congestion_control=$(cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}')
  net_qdisc=$(cat /proc/sys/net/core/default_qdisc | awk '{print $1}')
  #kernel_version_r=$(uname -r | awk '{print $1}')
  # if [[ ${kernel_version_full} = "4.14.182-bbrplus" || ${kernel_version_full} = "4.14.168-bbrplus" || ${kernel_version_full} = "4.14.98-bbrplus" || ${kernel_version_full} = "4.14.129-bbrplus" || ${kernel_version_full} = "4.14.160-bbrplus" || ${kernel_version_full} = "4.14.166-bbrplus" || ${kernel_version_full} = "4.14.161-bbrplus" ]]; then
  if [[ ${kernel_version_full} == *bbrplus* ]]; then
    kernel_status="BBRplus"
    # elif [[ ${kernel_version} = "3.10.0" || ${kernel_version} = "3.16.0" || ${kernel_version} = "3.2.0" || ${kernel_version} = "4.4.0" || ${kernel_version} = "3.13.0"  || ${kernel_version} = "2.6.32" || ${kernel_version} = "4.9.0" || ${kernel_version} = "4.11.2" || ${kernel_version} = "4.15.0" ]]; then
    # kernel_status="Lotserver"
  elif [[ ${kernel_version_full} == *4.9.0-4* || ${kernel_version_full} == *4.15.0-30* || ${kernel_version_full} == *4.8.0-36* || ${kernel_version_full} == *3.16.0-77* || ${kernel_version_full} == *3.16.0-4* || ${kernel_version_full} == *3.2.0-4* || ${kernel_version_full} == *4.11.2-1* || ${kernel_version_full} == *2.6.32-504* || ${kernel_version_full} == *4.4.0-47* || ${kernel_version_full} == *3.13.0-29 || ${kernel_version_full} == *4.4.0-47* ]]; then
    kernel_status="Lotserver"
  elif [[ $(echo ${kernel_version} | awk -F'.' '{print $1}') == "4" ]] && [[ $(echo ${kernel_version} | awk -F'.' '{print $2}') -ge 9 ]] || [[ $(echo ${kernel_version} | awk -F'.' '{print $1}') == "5" ]] || [[ $(echo ${kernel_version} | awk -F'.' '{print $1}') == "6" ]]; then
    kernel_status="BBR"
  else
    kernel_status="noinstall"
  fi

  if [[ ${kernel_status} == "BBR" ]]; then
    run_status=$(cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}')
    if [[ ${run_status} == "bbr" ]]; then
      run_status=$(cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}')
      if [[ ${run_status} == "bbr" ]]; then
        run_status="BBR iniciado"
      else
        run_status="BBR no iniciado"
      fi
    elif [[ ${run_status} == "bbr2" ]]; then
      run_status=$(cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}')
      if [[ ${run_status} == "bbr2" ]]; then
        run_status="BBR2 iniciado"
      else
        run_status="BBR2 no iniciado"
      fi
    elif [[ ${run_status} == "tsunami" ]]; then
      run_status=$(lsmod | grep "tsunami" | awk '{print $1}')
      if [[ ${run_status} == "tcp_tsunami" ]]; then
        run_status="BBR魔改版启动成功"
      else
        run_status="BBR魔改版启动失败"
      fi
    elif [[ ${run_status} == "nanqinlang" ]]; then
      run_status=$(lsmod | grep "nanqinlang" | awk '{print $1}')
      if [[ ${run_status} == "tcp_nanqinlang" ]]; then
        run_status="暴力BBR魔改版启动成功"
      else
        run_status="暴力BBR魔改版启动失败"
      fi
    else
      run_status="No instalado"
    fi

  elif [[ ${kernel_status} == "Lotserver" ]]; then
    if [[ -e /appex/bin/lotServer.sh ]]; then
      run_status=$(bash /appex/bin/lotServer.sh status | grep "LotServer" | awk '{print $3}')
      if [[ ${run_status} == "running!" ]]; then
        run_status="启动成功"
      else
        run_status="启动失败"
      fi
    else
      run_status="No instalado"
    fi
  elif [[ ${kernel_status} == "BBRplus" ]]; then
    run_status=$(cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}')
    if [[ ${run_status} == "bbrplus" ]]; then
      run_status=$(cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}')
      if [[ ${run_status} == "bbrplus" ]]; then
        run_status="BBRplus inicido"
      else
        run_status="BBRplus no iniciado"
      fi
    elif [[ ${run_status} == "bbr" ]]; then
      run_status="BBR inicido"
    else
      run_status="No instalado"
    fi
  fi
}

#############系统检测组件#############

aviso(){
  msg -bar
  print_center -ama "Después de instalar el núcleo\nconsulte la información anterior\npara comprobar si la instalación\nse ha realizado correctamente.\nDe forma predeterminada, el sistema\ndesde el núcleo de versión superior"
}

aceleracion_default(){
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
  sysctl --system
  msg -bar
  print_center -ama 'Aceleracion Default, éxito\n¡reiniciar para que surta efecto!'
}

BBR_original(){
  unset opcion
  title 'Instalador de nucleo BBR original'
  echo " $(msg -verd "[1]") $(msg -verm2 '>') $(msg -azu 'Instalar nucleo BBR')"
  msg -bar3
  print_center -ama 'Aceleracion'
  msg -bar3
  echo " $(msg -verd "[2]") $(msg -verm2 '>') $(msg -azu 'Aceleracion BBR+FQ')"
  echo " $(msg -verd "[3]") $(msg -verm2 '>') $(msg -azu 'Aceleracion BBR+FQ_PIE')"
  echo " $(msg -verd "[4]") $(msg -verm2 '>') $(msg -azu 'Aceleracion BBR+CAKE')"
  echo " $(msg -verd "[5]") $(msg -verm2 '>') $(msg -azu 'Aceleracion default')"
  back
  opcion=$(selection_fun 5)
  if [[ $opcion = @([2-5]) ]]; then
    remove_bbr_lotserver
    title 'registro de implementacion'
  fi
  case $opcion in
    1)check_sys_bbr;;
    2)startbbrfq noclear;;
    3)startbbrfqpie noclear;;
    4)startbbrcake noclear;;
    5)aceleracion_default;;
    0)return;;
  esac
  if [[ $opcion = @([2-5]) ]]; then
    msg -bar
    read -rp "$(msg -ama " Reinciar vps [S/N]: ") " -e -i S reboot
    if [[ $reboot = @(s|S) ]]; then
      sudo reboot
    fi
  fi
  enter
}

BBR_Plus(){
  unset opcion
  title 'Instalador de nucleo BBR Plus'
  echo " $(msg -verd "[1]") $(msg -verm2 '>') $(msg -azu 'Instalar nucleo BBR Plus')"
  msg -bar3
  print_center -ama 'Aceleracion'
  msg -bar3
  echo " $(msg -verd "[2]") $(msg -verm2 '>') $(msg -azu 'Aceleracion BBRplus+FQ')"
  echo " $(msg -verd "[3]") $(msg -verm2 '>') $(msg -azu 'Aceleracion default')"
  back
  opcion=$(selection_fun 3)
  if [[ $opcion = @([2-3]) ]]; then
    remove_bbr_lotserver
    title 'registro de implementacion'
  fi
  case $opcion in
    1)check_sys_bbrplusnew;;
    2)startbbrplus noclear;;
    3)aceleracion_default;;
    0)return;;
  esac
  if [[ $opcion = @([2-3]) ]]; then
    msg -bar
    read -rp "$(msg -ama " Reinciar vps [S/N]: ") " -e -i S reboot
    if [[ $reboot = @(s|S) ]]; then
      sudo reboot
    fi
  fi
  enter
}

BBR2_xanmod(){
  unset opcion
  title 'Instalador de nucleo BBR2 XANMOD'
  echo " $(msg -verd "[1]") $(msg -verm2 '>') $(msg -azu 'Instalar nucleo BBR2 XANMOD')"
  echo " $(msg -verd "[2]") $(msg -verm2 '>') $(msg -azu 'Instalar nucleo BBR2 XANMOD oficial')"
  msg -bar3
  print_center -ama 'Aceleracion'
  msg -bar3
  echo " $(msg -verd "[3]") $(msg -verm2 '>') $(msg -azu 'Aceleracion BBR2+FQ')"
  echo " $(msg -verd "[4]") $(msg -verm2 '>') $(msg -azu 'Aceleracion BBR2+FQ_PIE')"
  echo " $(msg -verd "[5]") $(msg -verm2 '>') $(msg -azu 'Aceleracion BBR2+CAKE')"
  echo " $(msg -verd "[6]") $(msg -verm2 '>') $(msg -azu 'Aceleracion default')"
  back
  opcion=$(selection_fun 6)
  if [[ $opcion = @([2-6]) ]]; then
    remove_bbr_lotserver
    title 'registro de implementacion'
  fi
  case $opcion in
    1)check_sys_xanmod;;
    2)check_sys_official_xanmod;;
    3)startbbr2fq noclear;;
    4)startbbr2fqpie noclear;;
    5)startbbr2cake noclear;;
    6)aceleracion_default;;
    0)return;;
  esac
  if [[ $opcion = @([2-6]) ]]; then
    msg -bar
    read -rp "$(msg -ama " Reinciar vps [S/N]: ") " -e -i S reboot
    if [[ $reboot = @(s|S) ]]; then
      sudo reboot
    fi
  fi
  enter
}

detele_kernel_list(){
  kernels=($(dpkg -l | grep linux-image | awk '{print $2}'))
  n=0
  if [[ ${#kernels[@]} -gt 1 ]]; then
    title 'LISTA DE NUCLEOS INSTALADOS'
    for (( i = 0; i < ${#kernels[@]}; i++ )); do
      let n++
      name=$(echo ${kernels[$i]:12})
      echo " $(msg -verd "[$n]") $(msg -verm2 '>') $(msg -azu "$name")" 
    done
  else
    print_center 'NO HAY NUCLEOS PARA ELIMINAR'
    enter ; return
  fi
  back
  opc=$(selection_fun $n)
  [[ $opc = 0 ]] && return
  let opc--
  BBR_grub
  apt-get purge -y ${kernels[$opc]}
  apt-get autoremove -y
  BBR_grub
  header=$(dpkg -l | grep linux-headers | awk '{print $2}'|grep $(echo ${kernels[$opc]:12}))
  apt-get purge -y $header
  apt-get autoremove -y
  BBR_grub
  msg -bar
  print_center -ama "nucle ${kernels[$opc]} removido\ndeve reiniciar el servidor para\nque los cambos surtan efecto"
  enter
}

start_menu() {
  check_sys
  check_version
  [[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && print_center -ama "Este script no compatible!" && enter && return 1
  clear
  msg -bar
  print_center -verm2 "Funcion beta\nUsar bajo tu propio riesgo!!!"
  msg -bar3
  print_center -ama "Este script tcpbbr es una modificacion\nde la vercion original china\nante fallas reportar con @Rufu99"
  enter
  title 'MENU DE INSTALACION KERNEL TCPBBR'
  check_status
  get_system_info
  if [[ ${kernel_status} == "noinstall" ]]; then
    kernel_status='No instalado'
    run_status='Kernel bbr requerido'
  fi
  _info=" $(msg -teal "SO:") $(msg -azu "$opsy")#$(msg -teal "Arquitectura:") $(msg -azu "$arch")\n"
  _info+=" $(msg -teal "estado actual:") $(msg -azu "${kernel_status}")#$(msg -teal "Modulo:") $(msg -azu "${run_status}")\n"
  _info+=" $(msg -teal "Kernel:") $(msg -azu "$kern")\n"
  _info+=" $(msg -teal "control Congestión:") $(msg -azu "${net_congestion_control}")#$(msg -teal "algoritmo cola:") $(msg -azu "${net_qdisc}")"
  echo -e "$_info"|column -t -s '#'
  msg -bar
  echo " $(msg -verd "[1]") $(msg -verm2 '>') $(msg -verd 'Instalar nucleo estable oficial')"
  msg -bar3
  print_center -ama 'Nucleos de aceleración'
  msg -bar3
  echo " $(msg -verd "[2]") $(msg -verm2 '>') $(msg -azu 'Instalar nucleo BBR original')"
  echo " $(msg -verd "[3]") $(msg -verm2 '>') $(msg -azu 'Instalar nucleo BBRplus')"
  echo " $(msg -verd "[4]") $(msg -verm2 '>') $(msg -azu 'Instalar nucleo BBR2 XANMOD')"
  echo " $(msg -verd "[5]") $(msg -verm2 '>') $(msg -azu 'Instalar nucleo BBR2 Zen')"
  msg -bar3
  print_center -ama 'TCP SPEED'
  msg -bar3
  echo " $(msg -verd "[6]") $(msg -verm2 '>') $(msg -azu 'Optimización del sistema')"
  echo " $(msg -verd "[7]") $(msg -verm2 '>') $(msg -azu 'Optimización del sistema (esquema de johnrosen1)')"
  echo " $(msg -verd "[8]") $(msg -verm2 '>') $(msg -azu 'Desinstalar toda la aceleración')"
  msg -bar3
  echo " $(msg -verd "[9]") $(msg -verm2 '>') $(msg -verm2 'Remover nucleos (kernels)')"
  echo " $(msg -verd "[10]") $(msg -verm2 '>') $(msg -blu 'Recargar sistema de arranque (grub2)')"
  echo " $(msg -verd "[11]") $(msg -verm2 '>') $(msg -azu 'script original') $(msg -verm2 '(bajo tu propio riesgo)')"
  back
  opcion=$(selection_fun 11)
  case "$opcion" in
    1)check_sys_official;;
    2)BBR_original;;
    3)BBR_Plus;;
    4)BBR2_xanmod;;
    5)check_sys_official_zen;;
    6)optimizing_system;;
    7)optimizing_system_johnrosen1;;
    8)remove_all;;
    9)detele_kernel_list;;
    10)BBR_grub ; enter;;
    11)Update_Shell;;
    0)return 1;;
  esac
}

while [[  $? -eq 0 ]]; do
  start_menu
done