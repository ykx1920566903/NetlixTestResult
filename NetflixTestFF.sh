#!/bin/bash
#判断当前IP是否解锁，解锁则退出
DOMAIN=yy.com
CODE=$(curl -x "http://0kgxvLLr5L:WUMzjNDTrv@${DOMAIN}:47794" --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567")
if [[ ${CODE} == "200" ]]; then
  echo '-------------分界线--------------------'
  echo '当前IP解锁正常,脚本退出'
  exit 0
else
  echo '当前IP解锁失效,进行下一步骤'
fi
# API key, see https://www.cloudflare.com/a/account/my-account,
# incorrect api-key results in E_UNAUTH error
CFKEY=
# Username, eg: user@example.com
CFUSER=
# Zone name, eg: example.com
CFZONE_NAME=yymood.top
# Hostname to update, eg: homeserver.example.com
CFRECORD_NAME=jcnetflix.yymood.top
# Record type, A(IPv4)|AAAA(IPv6), default IPv4
CFRECORD_TYPE=A
# Cloudflare TTL for record, between 120 and 86400 seconds
CFTTL=60
CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*' | head -1)
TG_BOT_TOKEN=your tgbot token
TG_UID= you tg uid
#遍历IP和解锁情况
DOMAINS=(jcnetflix.yymood.top amdsg1.yymood.top amdsg2.yymood.top armsg3.yymood.top armsg4.yymood.top)
IPS=(0 1 2 3 4)
CODES=(0 1 2 3 4)
for ((i = 0; i < ${#DOMAINS[@]}; i++)); do
    IPS[i]=$(ping "${DOMAINS[i]}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
    CODES[i]=$(curl -x "http://0kgxvLLr5L:WUMzjNDTrv@${IPS[i]}:47794" --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567")
  echo "${i}号IP为${IPS[i]},CODE为${CODES[i]}"
  if [ "${IPS[0]}" = "${IPS[i]}" ] && [ "${i}" != "0" ]; then
    NUM=${i}
    echo "当前中转域名使用的是${NUM}号机器"
  fi
done
if [ "${NUM}" = "4" ]; then
  echo "当前为最后一台机器"
fi
#进行更换IP和解析DNS
COUNT=1
for ((i = NUM; COUNT < ${#DOMAINS[@]}; i++, COUNT++)); do
    printf "总第%s次判断\n" "${COUNT}"
    echo "当前判断${i}号IP"
    if [ "${CODES[i]}" = "404" ]; then
    #更换IP并通知
    printf "CODE为%s,更换%s号IP并调用TG机器人\n\n" "${CODES[i]}" "${i}"
    curl -s "https://api.telegram.org/bot2127424667:${TG_BOT_TOKEN}/sendMessage?chat_id=${TG_UID}&text=${i}号机IP被奈飞关小黑屋,已自动更换IP"
    curl -s "https://api.telegram.org/bot5310162411:${TG_BOT_TOKEN}/sendMessage?chat_id=${TG_UID}&text=${i}号机IP被奈飞关小黑屋,已自动更换IP"
    timeout 8s echo -e "1\n${i}\n5\ny\n" | ./oci-help -c /root/oci-help.ini
  elif   [ "${CODES[i]}" = "200" ]; then
    #解析IP并通知
    printf "CODE为%s,将%s号IP解析并通知\n" "${CODES[i]}" "${i}"
    RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
      -H "X-Auth-Email: $CFUSER" \
      -H "X-Auth-Key: $CFKEY" \
      -H "Content-Type: application/json" \
      --data "{\"id\":\"$CFZONE_ID\",\"type\":\"$CFRECORD_TYPE\",\"name\":\"$CFRECORD_NAME\",\"content\":\"${IPS[i]}\", \"ttl\":$CFTTL}")
    #处理返回参数
    if [ "$RESPONSE" != "${RESPONSE%success*}" ] && [ "$(echo "$RESPONSE" | grep "\"success\":true")" != "" ]; then
      echo "Updated succesfuly!"
      curl -s "https://api.telegram.org/bot2127424667:${TG_BOT_TOKEN}/sendMessage?chat_id=${TG_UID}&text=奈飞中转域名已更改为${i}号机IP,为${IPS[i]}"
      curl -s "https://api.telegram.org/bot5310162411:${TG_BOT_TOKEN}/sendMessage?chat_id=${TG_UID}&text=奈飞中转域名已更改为${i}号机IP,为${IPS[i]}"
    else
      echo 'Something went wrong :('
      echo "Response: $RESPONSE"
    fi
    printf "脚本退出\n\n"
    exit 0
  fi
    if [ "${i}" = "$((${#DOMAINS[@]} - 1))" ]; then
    i=0
  fi
done
