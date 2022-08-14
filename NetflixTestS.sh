#!/bin/bash
#请预先配置好oci-help,存放目录地址为/root/oci-help
#判断当前IP是否解锁，解锁则退出
STATUS=$(curl -x 'http://0kgxvLLr5L:WUMzjNDTrv@cc.yymood.top:47794' --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567")

if [[ ${STATUS} == "200" ]]; then
  echo "当前IP解锁正常,脚本退出"
  exit 0
fi
if [[ ${STATUS} == "404" ]]; then
  NUM=$(cat /root/netflix_server/current_id.txt)
  echo "${NUM}"
  timeout 10s  echo -e "1\n${NUM}\n5\nn\n" | ./oci-help -c /root/oci-help.ini
  curl -s "https://api.telegram.org/bot2127424667:AAH1UiFuMBIhPXevSYI8QttJFWlfFT-Qpbg/sendMessage?chat_id=1191889094&text=检测到${NUM}号机IP已被更换。" > /dev/null
  curl -s "https://api.telegram.org/bot5310162411:AAHB4Cjh-oHJ4JbBZSrDkOlrwaSWtvZgouo/sendMessage?chat_id=1952026695&text=检测到${NUM}号机IP已被更换。" > /dev/null
fi
# API key, see https://www.cloudflare.com/a/account/my-account,
# incorrect api-key results in E_UNAUTH error
CFKEY=b1446c285b2d53c6b7c9fea5f09daff9eb37e
# Username, eg: user@example.com
CFUSER=ykx990505@gmail.com
# Zone name, eg: example.com
CFZONE_NAME=yymood.top
# Hostname to update, eg: homeserver.example.com
CFRECORD_NAME=jcnetflix.yymood.top
# Record type, A(IPv4)|AAAA(IPv6), default IPv4
CFRECORD_TYPE=A
# Cloudflare TTL for record, between 120 and 86400 seconds
CFTTL=60
########获取当前IP
CURRENTIP=$(cat /root/netflix_server/current_ip.txt)
echo "当前IP为${CURRENTIP}"
########读取所有解锁机IP
IPS=(0 1 2 3 4)
IPS[1]=$(ping amdsg1.yymood.top -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
IPS[2]=$(ping amdsg2.yymood.top -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
IPS[3]=$(ping armsg3.yymood.top -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
IPS[4]=$(ping armsg4.yymood.top -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
########遍历解锁情况

if [[ ${NUM} == "1" ]]; then
  for i in 2 3 4; do
    IP=${IPS[i]}
    echo "${IPS[i]}"
    CODE=$(curl -x "http://0kgxvLLr5L:WUMzjNDTrv@${IP}:47794" --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567")
    echo "当前CODE为${CODE}"
    if [[ ${CODE} == "404" ]]; then
      timeout 10s echo -e "1\n${i}\n5\nn\n" | ./oci-help -c /root/oci-help.ini
      curl -s "https://api.telegram.org/bot2127424667:AAH1UiFuMBIhPXevSYI8QttJFWlfFT-Qpbg/sendMessage?chat_id=1191889094&text=检测到${i}号机IP已被更换。" > /dev/null
      curl -s "https://api.telegram.org/bot5310162411:AAHB4Cjh-oHJ4JbBZSrDkOlrwaSWtvZgouo/sendMessage?chat_id=1952026695&text=检测到${i}号机IP已被更换。" > /dev/null
      echo "更换IP"
    fi

    if [[ ${CODE} == "200" ]]; then
      echo "调用CF的API进行解析"
      CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
      CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
      #更新DNS记录
      RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
        -H "X-Auth-Email: $CFUSER" \
        -H "X-Auth-Key: $CFKEY" \
        -H "Content-Type: application/json" \
        --data "{\"id\":\"$CFZONE_ID\",\"type\":\"$CFRECORD_TYPE\",\"name\":\"$CFRECORD_NAME\",\"content\":\"$IP\", \"ttl\":$CFTTL}")
      echo "${CURRENTIP}变为${IP},调用TG机器人"
      echo "${IP}" > /root/netflix_server/current_ip.txt
      echo "${i}" > /root/netflix_server/current_id.txt
      curl -s "https://api.telegram.org/bot2127424667:AAH1UiFuMBIhPXevSYI8QttJFWlfFT-Qpbg/sendMessage?chat_id=1191889094&text=检测到${NUM}号机原IP${CURRENTIP}被Netflix关小黑屋,已自动为机器更换IP,新的IP地址是${IP}，中转域名当前使用的是${i}号机。" > /dev/null
      curl -s "https://api.telegram.org/bot5310162411:AAHB4Cjh-oHJ4JbBZSrDkOlrwaSWtvZgouo/sendMessage?chat_id=1952026695&text=检测到${NUM}号机原IP${CURRENTIP}被Netflix关小黑屋,已自动为机器更换IP,新的IP地址是${IP}，中转域名当前使用的是${i}号机。" > /dev/null
      echo "脚本退出"
      exit 0
    fi
  done
fi

if [[ ${NUM} == "2" ]]; then
  for i in 3 4 1; do
    IP=${IPS[i]}
    echo "${IPS[i]}"
    CODE=$(curl -x "http://0kgxvLLr5L:WUMzjNDTrv@${IP}:47794" --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567")
    echo "当前CODE为${CODE}"
    if [[ ${CODE} == "404" ]]; then
      timeout 10s echo -e "1\n${i}\n5\nn\n" | ./oci-help -c /root/oci-help.ini
      curl -s "https://api.telegram.org/bot2127424667:AAH1UiFuMBIhPXevSYI8QttJFWlfFT-Qpbg/sendMessage?chat_id=1191889094&text=检测到${i}号机IP已被更换。" > /dev/null
      curl -s "https://api.telegram.org/bot5310162411:AAHB4Cjh-oHJ4JbBZSrDkOlrwaSWtvZgouo/sendMessage?chat_id=1952026695&text=检测到${i}号机IP已被更换。" > /dev/null
      echo "更换IP"
    fi

    if [[ ${CODE} == "200" ]]; then
      echo "调用CF的API进行解析"
      CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
      CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
      #更新DNS记录
      RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
        -H "X-Auth-Email: $CFUSER" \
        -H "X-Auth-Key: $CFKEY" \
        -H "Content-Type: application/json" \
        --data "{\"id\":\"$CFZONE_ID\",\"type\":\"$CFRECORD_TYPE\",\"name\":\"$CFRECORD_NAME\",\"content\":\"$IP\", \"ttl\":$CFTTL}")
      echo "${CURRENTIP}变为${IP},调用TG机器人"
      echo "${IP}" > /root/netflix_server/current_ip.txt
      echo "${i}" > /root/netflix_server/current_id.txt
      curl -s "https://api.telegram.org/bot2127424667:AAH1UiFuMBIhPXevSYI8QttJFWlfFT-Qpbg/sendMessage?chat_id=1191889094&text=检测到${NUM}号机原IP${CURRENTIP}被Netflix关小黑屋，已自动为机器更换IP,新的IP地址是${IP}，中转域名当前使用的是${i}号机。" > /dev/null
      curl -s "https://api.telegram.org/bot5310162411:AAHB4Cjh-oHJ4JbBZSrDkOlrwaSWtvZgouo/sendMessage?chat_id=1952026695&text=检测到${NUM}号机原IP${CURRENTIP}被Netflix关小黑屋，已自动为机器更换IP,新的IP地址是${IP}，中转域名当前使用的是${i}号机。" > /dev/null
      echo "脚本退出"
      exit 0
    fi
  done
fi

if [[ ${NUM} == "3" ]]; then
  for i in 4 1 2; do
    IP=${IPS[i]}
    echo "${IPS[i]}"
    CODE=$(curl -x "http://0kgxvLLr5L:WUMzjNDTrv@${IP}:47794" --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567")
    echo "当前CODE为${CODE}"
    if [[ ${CODE} == "404" ]]; then
      timeout 10s echo -e "1\n${i}\n5\nn\n" | ./oci-help -c /root/oci-help.ini
      curl -s "https://api.telegram.org/bot2127424667:AAH1UiFuMBIhPXevSYI8QttJFWlfFT-Qpbg/sendMessage?chat_id=1191889094&text=检测到${i}号机IP已被更换。" > /dev/null
      curl -s "https://api.telegram.org/bot5310162411:AAHB4Cjh-oHJ4JbBZSrDkOlrwaSWtvZgouo/sendMessage?chat_id=1952026695&text=检测到${i}号机IP已被更换。" > /dev/null
      echo "更换IP"
    fi

    if [[ ${CODE} == "200" ]]; then
      echo "调用CF的API进行解析"
      CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
      CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
      #更新DNS记录
      RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
        -H "X-Auth-Email: $CFUSER" \
        -H "X-Auth-Key: $CFKEY" \
        -H "Content-Type: application/json" \
        --data "{\"id\":\"$CFZONE_ID\",\"type\":\"$CFRECORD_TYPE\",\"name\":\"$CFRECORD_NAME\",\"content\":\"$IP\", \"ttl\":$CFTTL}")
      echo "${CURRENTIP}变为${IP},调用TG机器人"
      echo "${IP}" > /root/netflix_server/current_ip.txt
      echo "${i}" > /root/netflix_server/current_id.txt
      curl -s "https://api.telegram.org/bot2127424667:AAH1UiFuMBIhPXevSYI8QttJFWlfFT-Qpbg/sendMessage?chat_id=1191889094&text=检测到${NUM}号机原IP${CURRENTIP}被Netflix关小黑屋，已自动为机器更换IP,新的IP地址是${IP}，中转域名当前使用的是${i}号机。" > /dev/null
      curl -s "https://api.telegram.org/bot5310162411:AAHB4Cjh-oHJ4JbBZSrDkOlrwaSWtvZgouo/sendMessage?chat_id=1952026695&text=检测到${NUM}号机原IP${CURRENTIP}被Netflix关小黑屋，已自动为机器更换IP,新的IP地址是${IP}，中转域名当前使用的是${i}号机。" > /dev/null
      echo "脚本退出"
      exit 0
    fi
  done
fi

if [[ ${NUM} == "4" ]]; then
  for i in 1 2 3; do
    IP=${IPS[i]}
    echo "${IPS[i]}"
    CODE=$(curl -x "http://0kgxvLLr5L:WUMzjNDTrv@${IP}:47794" --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567")
    echo "当前CODE为${CODE}"
    if [[ ${CODE} == "404" ]]; then
      timeout 10s echo -e "1\n${i}\n5\nn\n" | ./oci-help -c /root/oci-help.ini
      curl -s "https://api.telegram.org/bot2127424667:AAH1UiFuMBIhPXevSYI8QttJFWlfFT-Qpbg/sendMessage?chat_id=1191889094&text=检测到${i}号机IP已被更换。" > /dev/null
      curl -s "https://api.telegram.org/bot5310162411:AAHB4Cjh-oHJ4JbBZSrDkOlrwaSWtvZgouo/sendMessage?chat_id=1952026695&text=检测到${i}号机IP已被更换。" > /dev/null
      echo "更换IP"
    fi

    if [[ ${CODE} == "200" ]]; then
      echo "调用CF的API进行解析"
      CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
      CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
      #更新DNS记录
      RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
        -H "X-Auth-Email: $CFUSER" \
        -H "X-Auth-Key: $CFKEY" \
        -H "Content-Type: application/json" \
        --data "{\"id\":\"$CFZONE_ID\",\"type\":\"$CFRECORD_TYPE\",\"name\":\"$CFRECORD_NAME\",\"content\":\"$IP\", \"ttl\":$CFTTL}")
      echo "${RESPONSE}"
      echo "${CURRENTIP}变为${IP},调用TG机器人"
      echo "${IP}" > /root/netflix_server/current_ip.txt
      echo "${i}" > /root/netflix_server/current_id.txt
      curl -s "https://api.telegram.org/bot2127424667:AAH1UiFuMBIhPXevSYI8QttJFWlfFT-Qpbg/sendMessage?chat_id=1191889094&text=检测到${NUM}号机原IP${CURRENTIP}被Netflix关小黑屋，已自动为机器更换IP,新的IP地址是${IP}，中转域名当前使用的是${i}号机。" > /dev/null
      curl -s "https://api.telegram.org/bot5310162411:AAHB4Cjh-oHJ4JbBZSrDkOlrwaSWtvZgouo/sendMessage?chat_id=1952026695&text=检测到${NUM}号机原IP${CURRENTIP}被Netflix关小黑屋，已自动为机器更换IP,新的IP地址是${IP}，中转域名当前使用的是${i}号机。" > /dev/null
      echo "脚本退出"
      exit 0
    fi
  done
fi
