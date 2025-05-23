#!/bin/bash

interface="eth0"

current_ip=$(ip -o -4 addr show dev $interface | awk '{split($4,a,"/"); print a[1]}')

if [ -f "last_ip.txt" ]; then
  last_ip=$(cat last_ip.txt)
else
  last_ip=""
fi

if [ "$current_ip" != "$last_ip" ]; then
  echo "Detected IP address change: $last_ip -> $current_ip"

  curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "text=OP:$last_ip -> $current_ip" https://sc.ftqq.com/server酱推送token.send

  echo "$current_ip" > last_ip.txt
else
  echo "No IP address change detected."
fi