#!/bin/sh
#更新DNS解析记录
#IP=
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
 # curl -s "https://api.telegram.org/bot2127424667:AAH1UiFuMBIhPXevSYI8QttJFWlfFT-Qpbg/sendMessage?chat_id=1191889094&text=检测到原IP${CURRENTIP}被Netflix关小黑屋，已自动为机器更换IP,新的IP地址是${IP}"
curl -s "https://api.telegram.org/bot5310162411:AAHB4Cjh-oHJ4JbBZSrDkOlrwaSWtvZgouo/sendMessage?chat_id=1952026695&text=检测到原IP${CURRENTIP}被Netflix关小黑屋，已自动为机器更换IP,新的IP地址是${IP}"
else
  echo 'Something went wrong :('
  echo "Response: $RESPONSE"
fi