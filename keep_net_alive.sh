#!/bin/bash

# 基础配置 (ipv4变量的获取由于设备差异可能需要改动代码)
user_account=""
user_password=""
ISP=""  # {联通:unicom, 移动:cmcc, 电信:telecom}
ipv4=$(ip -o -4 addr show dev eth0 | awk '{split($4,a,"/"); print a[1]}')

login_url="http://192.168.200.2:801/eportal/?c=Portal&a=login&callback=dr1003&login_method=1&user_account=%2C0%2C$user_account%40$ISP&user_password=$user_password&wlan_user_ip=$ipv4"
log_file="keep_net_alive.log"

# 输出日志
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$log_file"
}

# 获取登录状态并提取 result 和 ret_code
get_login_status() {
    local response
    response=$(curl -sL "$login_url")

    # 去除 dr1003(...) 的包装部分，保留 JSON 内容
    json_content=$(echo "$response" | sed 's/^dr1003(\(.*\))$/\1/')

    # 使用 jq 提取 result 和 ret_code
    result=$(echo "$json_content" | jq -r '.result')
    ret_code=$(echo "$json_content" | jq -r '.ret_code')

    echo "$result,$ret_code"
}

# 初始化网络状态
login_status=$(get_login_status)
IFS=',' read -r result ret_code <<< "$login_status"

log_message "Login status - result: $result, ret_code: $ret_code"

# 判断登录状态
for (( i=0; i<5; i=i+1 )); do
    if [[ "$result" == "1" || "$result" == "ok" ]]; then
        log_message "Login successful."
        break
    elif [[ "$result" == "0" && "$ret_code" != "0" ]]; then
        log_message "Already logged in, no need to login again."
        break
    else
        log_message "Login failed, retrying..."

        # 生成随机MAC地址
        mac="a2:75:ed"
        rand=$(openssl rand -hex 3 | sed 's/\(..\)/\1:/g; s/.$//')
        mac="$mac:$rand"
        log_message "Generated MAC address: $mac"

        # 替换网卡MAC地址
        ifconfig eth0 down
        ifconfig eth0 hw ether "$mac"
        ifconfig eth0 up

        # 轮询IP地址,匹配到10.0.0.0/8结束
        for (( j=0; j<5; j=j+1 )); do
            sleep 10
            ip=$(ip -o -4 addr show dev eth0 | awk '{split($4,a,"/"); print a[1]}')
            log_message "Getting IP address: $ip"
            if [[ "$ip" =~ ^10\. ]]; then
                break
            fi
        done

        # 获取新的登录状态
        login_status=$(get_login_status)
        IFS=',' read -r result ret_code <<< "$login_status"  # 重新获取 result 和 ret_code
        log_message "Login status after MAC change - result: $result, ret_code: $ret_code"
    fi
done