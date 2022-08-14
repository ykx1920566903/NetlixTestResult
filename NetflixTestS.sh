#!/bin/bash
#获取当前IP编号
NUM=$(cat /root/netflix_server/current_id.txt)
echo "当前中转域名使用的是${NUM}号机器"

#读取解锁情况
#DOMAINS=(jcnetflix.yymood.top amdsg1.yymood.top amdsg2.yymood.top armsg3.yymood.top armsg4.yymood.top)
CODES=(0 1 2 3 4)
CODES[1]=$(cat /root/netflix_server/status/amd_sg1_status.txt)
CODES[2]=$(cat /root/netflix_server/status/amd_sg2_status.txt)
CODES[3]=$(cat /root/netflix_server/status/arm_sg3_status.txt)
CODES[4]=$(cat /root/netflix_server/status/arm_sg4_status.txt)

#判断当前IP是否解锁，解锁则退出
CODE=${CODES[NUM]}
if [[ ${CODE} != "404" ]]; then
  echo '-------------分界线--------------------'
  echo '当前IP解锁正常,脚本退出'
  exit 0
else
  echo "当前IP解锁失效,进行下一步骤 CODE:${CODE}"
fi

#读取IP列表
IPS=(0 1 2 3 4)
IPS[1]=$(cat /root/netflix_server/ip_list/amd_sg1_ip.txt)
IPS[2]=$(cat /root/netflix_server/ip_list/amd_sg2_ip.txt)
IPS[3]=$(cat /root/netflix_server/ip_list/arm_sg3_ip.txt)
IPS[4]=$(cat /root/netflix_server/ip_list/arm_sg4_ip.txt)
for ((i = 1; i <= 4; i++)); do
  echo "${i}号IP ${IPS[i]} 状态 ${CODES[i]}"
done

# API key, see https://www.cloudflare.com/a/account/my-account,
# incorrect api-key results in E_UNAUTH error
CFKEY=
# Username, eg: user@example.com
CFUSER=
# Zone name, eg: example.com
CFZONE_NAME=
# Hostname to update, eg: homeserver.example.com
CFRECORD_NAME=
# Record type, A(IPv4)|AAAA(IPv6), default IPv4
CFRECORD_TYPE=A
# Cloudflare TTL for record, between 120 and 86400 seconds
CFTTL=60
CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*' | head -1)

#进行更换IP和解析DNS
COUNT=1
for ((i = NUM; COUNT < ${#IPS[@]}; i++, COUNT++)); do
    printf "总第%s次判断\n" "${COUNT}"
    echo "当前判断${i}号IP"
    if [ "${CODES[i]}" = "404" ]; then
    #更换IP并通知
    printf "CODE为%s,更换%s号IP并调用TG机器人\n\n" "${CODES[i]}" "${i}"
    curl -s "https://api.telegram.org/bot2127424667:AAH1UiFuMBIhPXevSYI8QttJFWlfFT-Qpbg/sendMessage?chat_id=1191889094&text=${i}号机的IP被奈飞关小黑屋,已自动更换IP"
    curl -s "https://api.telegram.org/bot5310162411:AAHB4Cjh-oHJ4JbBZSrDkOlrwaSWtvZgouo/sendMessage?chat_id=1952026695&text=${i}号机的IP被奈飞关小黑屋,已自动更换IP"
    timeout 8s echo -e "1\n${i}\n5\ny\n" | ./oci-help -c /root/oci-help.ini
  elif   [ "${CODES[i]}" = "200" ]; then

    #解析IP并通知
    printf "CODE为%s,将%s号IP解析并通知\n" "${CODES[i]}" "${i}"
    echo "${i}" > /root/netflix_server/current_id.txt
    RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
      -H "X-Auth-Email: $CFUSER" \
      -H "X-Auth-Key: $CFKEY" \
      -H "Content-Type: application/json" \
      --data "{\"id\":\"$CFZONE_ID\",\"type\":\"$CFRECORD_TYPE\",\"name\":\"$CFRECORD_NAME\",\"content\":\"${IPS[i]}\", \"ttl\":$CFTTL}")

    #处理返回参数
    if [ "$RESPONSE" != "${RESPONSE%success*}" ] && [ "$(echo "$RESPONSE" | grep "\"success\":true")" != "" ]; then
      echo "Updated succesfuly!"
      curl -s "https://api.telegram.org/bot2127424667:/sendMessage?chat_id=&text=奈飞中转域名已更改为${i}号机IP,为${IPS[i]}"
      curl -s "https://api.telegram.org/bot5310162411:/sendMessage?chat_id=&text=奈飞中转域名已更改为${i}号机IP,为${IPS[i]}"
    else
      echo 'Something went wrong :('
      echo "Response: $RESPONSE"
    fi
    printf "脚本退出\n\n"
    exit 0
  fi
    if [ "${i}" = "$((${#IPS[@]} - 1))" ]; then
    i=0
  fi
done
