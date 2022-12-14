#!/bin/bash
#请预先配置好oci-help,存放目录地址为/root/oci-help
#判断当前IP是否解锁，解锁则退出
CODE=$(curl -x 'http://0kgxvLLr5L:WUMzjNDTrv@jcnetflix.yymood.top:47794' --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567")
if [[ ${CODE} == "200" ]]; then
  exit 0
fi
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
########获取当前IP
CURRENTIP=$(ping jcnetflix.yymood.top -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
echo "当前IP为${CURRENTIP}"
########读取所有解锁机IP
IPS=(1 2 3 4 5)
IPS[1]=$(ping amdsg1.yymood.top -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
IPS[2]=$(ping amdsg2.yymood.top -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
IPS[3]=$(ping armsg3.yymood.top -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
IPS[4]=$(ping armsg4.yymood.top -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
LASTIP=${IPS[${#IPS[@]} - 1]}
########更换IP的机器编号,初始值为当前IP编号
for ((i = 1; i <= ${#IPS[@]}; i++)); do
  if [ "${CURRENTIP}" == "${IPS[i]}" ]; then
    num=$i
    echo "当前IP为${IPS[i]}，为${num}号机器"
  fi
done
########遍历解锁情况
for ((i = num; i < ${#IPS[@]}; i++)); do
  IP=${IPS[i]}
  echo "${IPS[i]}"
  CODE=$(curl -x "http://0kgxvLLr5L:WUMzjNDTrv@${IP}:47794" --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567")
  echo "当前CODE为${CODE}"
  if [[ ${CODE} == "404" ]]; then
    if [ "${CODE}" == "404" ] && [ "${CURRENTIP}" == "${LASTIP}" ]; then
      i=0
    fi
    timeout 10s echo -e "1\n${num}\n5\ny\n" | ./oci-help -c /root/oci-help.ini
    echo "更换IP"
  else
    echo "调用CF的API进行解析"
	
CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*' | head -1 )
#更新DNS记录
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
  -H "X-Auth-Email: $CFUSER" \
  -H "X-Auth-Key: $CFKEY" \
  -H "Content-Type: application/json" \
  --data "{\"id\":\"$CFZONE_ID\",\"type\":\"$CFRECORD_TYPE\",\"name\":\"$CFRECORD_NAME\",\"content\":\"$IP\", \"ttl\":$CFTTL}")
#处理返回参数
if [ "$RESPONSE" != "${RESPONSE%success*}" ] && [ "$(echo "$RESPONSE" | grep "\"success\":true")" != "" ]; then
  echo "Updated succesfuly!"
  echo "${CURRENTIP}变为${IP}，调用TG机器人"
  curl -s "https://api.telegram.org/bot2127424667:AAH1UiFuMBIhPXevSYI8QttJFWlfFT-Qpbg/sendMessage?chat_id=1191889094&text=检测到原IP${CURRENTIP}被Netflix关小黑屋，已自动为机器更换IP,新的IP地址是${IP}"
curl -s "https://api.telegram.org/bot5310162411:AAHB4Cjh-oHJ4JbBZSrDkOlrwaSWtvZgouo/sendMessage?chat_id=1952026695&text=检测到原IP${CURRENTIP}被Netflix关小黑屋，已自动为机器更换IP,新的IP地址是${IP}"
else
  echo 'Something went wrong :('
  echo "Response: $RESPONSE"
fi
    echo "脚本退出"
	exit 0
  fi
done
