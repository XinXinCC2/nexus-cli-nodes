#!/bin/bash

URL="https://www.google.com"
INTERVAL=300  # 每 300 秒（5 分钟）执行一次

while true; do
  TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[保活] $TIMESTAMP - 正在访问 $URL ..."
  HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" "$URL")

  if [[ "$HTTP_CODE" == "200" ]]; then
    echo "[成功] HTTP 状态码: $HTTP_CODE ✅"
  else
    echo "[失败] HTTP 状态码: $HTTP_CODE ❌"
  fi

  echo "-----------------------------"
  sleep $INTERVAL
done
