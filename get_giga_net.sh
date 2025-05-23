#!/bin/bash

# 基础配置 (ipv4变量的获取由于设备差异可能需要改动代码)
user_account=""
user_password=""
ISP=""  # {联通:unicom, 移动:cmcc, 电信:telecom}
ipv4=$(ip -o -4 addr show dev eth0 | awk '{split($4,a,"/"); print a[1]}')

while [[ $(curl -s "在线控制地址") = "1" ]]; do
  # 生成随机MAC地址
  mac="a2:75:ed"
  rand=$(openssl rand -hex 3 | sed 's/\(..\)/\1:/g; s/.$//')
  mac="$mac:$rand"

  # 替换网卡MAC地址
  ifconfig eth0 down
  ifconfig eth0 hw ether $mac
  ifconfig eth0 up
  echo "MAC $mac"

  # 循环获取IP地址,匹配10.0.0.0/8结束
  while true; do
    ip=$(ip -o -4 addr show dev eth0 | awk '{split($4,a,"/"); print a[1]}')
    echo "Getting IP $ip"
    if [[ $ip =~ ^10\. ]]; then
      break
    fi
    sleep 3
  done

  while true; do
    res=$(curl -sL "http://192.168.200.2:801/eportal/?c=Portal&a=login&callback=dr1003&login_method=1&user_account=%2C0%2C$user_account%40$ISP&user_password=$user_password&wlan_user_ip=$ipv4")
    echo "Login" $res
    if [[ $res == 'dr1003({"result":"0","msg":"","ret_code":2})' || $res == 'dr1003({"result":"1","msg":"\u8ba4\u8bc1\u6210\u529f"})' || $res = 'dr1003({"result":"0","msg":"","ret_code":1})']]; then
      break;
    fi
  done

  # 测速并判断
  speed=$(curl https://mirrors.ustc.edu.cn/centos/7/updates/x86_64/Packages/firefox-78.5.0-1.el7.centos.i686.rpm -o /dev/null --connect-timeout 5 --max-time 15 -w %{speed_download} | awk -F\. '{printf ("%d\n",$1/1024)}')
  echo "Speed test passed: $speed Kb/s"
  if [ $speed -gt 20000 ]; then
    break
  fi
done

echo "Script finished"