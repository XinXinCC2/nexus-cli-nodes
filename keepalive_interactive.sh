#!/bin/bash

# 可选命令池
commands=("pwd" "ls" "tty" "")

while true; do
  # 随机等待 180~300 秒
  sleep_time=$(( RANDOM % 120 + 180 ))

  # 从命令池随机选择
  cmd=${commands[$RANDOM % ${#commands[@]}]}

  # 输出并执行命令
  echo -e "\n>>> Running command: $cmd"
  eval "$cmd"

  # 打印模拟交互提示符
  echo -n "$USER@$(hostname):$PWD$ "
  
  # 等待随机秒数后继续
  sleep "$sleep_time"
done
