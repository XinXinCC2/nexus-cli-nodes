#!/bin/bash

# 显示菜单函数
show_menu() {
    clear
    echo "=========================================="
    echo "           nexus-cli多开脚本             "
    echo "=========================================="
    echo "1) 开启所有node_id"
    echo "2) 关闭所有node_id"
    echo "3) 查看所有节点日志"
    echo "4) 退出脚本"
    echo "=========================================="
    echo -n "请选择操作 (1-4): "
}

# 启动所有节点的函数
start_all_nodes() {
    clear
    echo "=========================================="
    echo "开始启动所有节点..."
    echo "=========================================="
    
    NODE_FILE="node_ids.txt"
    if [ ! -f "$NODE_FILE" ]; then
        echo "错误：未找到 $NODE_FILE 文件，请在脚本同目录下放置 node_ids.txt，每行一个 node_id"
        read -p "按回车键继续..."
        return
    fi

    # 检查当前目录下是否存在 nexus-network
    if [ ! -f "./nexus-network" ]; then
        echo "错误：当前目录下未找到 nexus-network 可执行文件"
        read -p "按回车键继续..."
        return
    fi

    # 创建日志目录
    mkdir -p logs

    # 统计变量
    total_nodes=0
    started_nodes=0
    failed_nodes=0
    running_nodes=0

    while IFS= read -r node_id || [ -n "$node_id" ]; do
        if [ -z "$node_id" ]; then
            continue
        fi
        
        total_nodes=$((total_nodes + 1))
        echo -n "正在启动 node_id: $node_id ... "
        
        # 检查是否已经存在该节点的进程
        existing_pid=$(pgrep -f "nexus-network.*start.*node-id $node_id")
        if [ ! -z "$existing_pid" ]; then
            echo "已在运行 (PID: $existing_pid)"
            running_nodes=$((running_nodes + 1))
            continue
        fi

        # 使用 nohup 启动服务，确保进程在后台运行
        nohup ./nexus-network start --node-id "$node_id" > "logs/node_${node_id}.log" 2>&1 &
        pid=$!
        
        # 等待一小段时间确保进程正常启动
        sleep 1
        
        # 检查进程是否还在运行
        if ps -p $pid > /dev/null; then
            echo "成功 (PID: $pid)"
            echo $pid > "node_${node_id}.pid"
            started_nodes=$((started_nodes + 1))
        else
            echo "失败"
            failed_nodes=$((failed_nodes + 1))
        fi
    done < "$NODE_FILE"

    echo "=========================================="
    echo "启动完成统计："
    echo "总节点数: $total_nodes"
    echo "新启动节点: $started_nodes"
    echo "已在运行节点: $running_nodes"
    echo "启动失败节点: $failed_nodes"
    echo "=========================================="
    echo "使用 'ps aux | grep nexus-network' 查看所有进程"
    echo "使用功能3查看节点日志"
    echo "=========================================="
    
    # 使用 -n 参数确保 read 命令不会显示提示符
    read -n 1 -s -r -p "按任意键继续..."
    # 清除输入缓冲区
    while read -t 0; do read -n 1; done
}

# 关闭所有节点的函数
stop_all_nodes() {
    echo "正在关闭所有 nexus 节点..."
    
    pids=$(pgrep -f "nexus-network.*start")
    
    if [ -z "$pids" ]; then
        echo "没有找到正在运行的 nexus 节点"
    else
        for pid in $pids; do
            node_id=$(ps -p $pid -o command= | grep -o "node-id [0-9]*" | awk '{print $2}')
            echo "正在停止 node_id: $node_id (PID: $pid)"
            
            kill $pid
            if [ $? -eq 0 ]; then
                echo "成功停止 node_id: $node_id"
                rm -f "node_${node_id}.pid"
            else
                echo "停止 node_id: $node_id 失败"
            fi
        done
    fi
    
    echo "所有节点关闭操作完成"
    read -p "按回车键继续..."
}

# 查看所有节点日志的函数
view_all_logs() {
    clear
    echo "=========================================="
    echo "查看所有节点日志的第5行"
    echo "=========================================="

    NODE_FILE="node_ids.txt"
    if [ ! -f "$NODE_FILE" ]; then
        echo "错误：未找到 $NODE_FILE 文件"
        read -n 1 -s -r -p "按任意键继续..."
        return
    fi

    while IFS= read -r node_id || [ -n "$node_id" ]; do
        if [ -z "$node_id" ]; then
            continue
        fi

        LOG_FILE="logs/node_${node_id}.log"
        if [ ! -f "$LOG_FILE" ]; then
            echo "节点ID: $node_id - 日志文件不存在"
            continue
        fi

        # 检查进程是否在运行
        pid=$(pgrep -f "nexus-network.*start.*node-id $node_id")
        status="运行中"
        if [ -z "$pid" ]; then
            status="未运行"
        fi

        echo "节点ID: $node_id (状态: $status)"
        echo "------------------------------------------"
        if [ -s "$LOG_FILE" ]; then
            sed -n '5p' "$LOG_FILE"
        else
            echo "日志文件为空"
        fi
        echo "------------------------------------------"
    done < "$NODE_FILE"

    echo "=========================================="
    read -n 1 -s -r -p "按任意键继续..."
    # 清除输入缓冲区
    while read -t 0; do read -n 1; done
}

# 主循环
while true; do
    show_menu
    read choice
    
    case $choice in
        1)
            start_all_nodes
            ;;
        2)
            stop_all_nodes
            ;;
        3)
            view_all_logs
            ;;
        4)
            echo "感谢使用，再见！"
            exit 0
            ;;
        *)
            echo "无效的选择，请重新输入"
            read -p "按回车键继续..."
            ;;
    esac
done