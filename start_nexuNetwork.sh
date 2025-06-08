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
    echo "开始读取node_ids.txt..."
    NODE_FILE="node_ids.txt"
    if [ ! -f "$NODE_FILE" ]; then
        echo "错误：未找到 $NODE_FILE 文件，请在脚本同目录下放置 node_ids.txt，每行一个 node_id"
        read -p "按回车键继续..."
        return
    fi

    # 检查是否安装了 tmux
    if ! command -v tmux &> /dev/null; then
        echo "错误：未安装 tmux，请先安装 tmux"
        echo "可以使用命令：brew install tmux (MacOS) 或 apt-get install tmux (Ubuntu/Debian)"
        read -p "按回车键继续..."
        return
    fi

    # 检查当前目录下是否存在 nexus-network
    if [ ! -f "./nexus-network" ]; then
        echo "错误：当前目录下未找到 nexus-network 可执行文件"
        read -p "按回车键继续..."
        return
    fi

    # 创建主会话（如果不存在）
    if ! tmux has-session -t nexus 2>/dev/null; then
        tmux new-session -d -s nexus
    fi

    while IFS= read -r node_id || [ -n "$node_id" ]; do
        # 跳过空行
        if [ -z "$node_id" ]; then
            continue
        fi
        
        # 创建新的窗口
        window_name="node_${node_id}"
        echo "正在为 node_id: $node_id 创建窗口 $window_name"
        
        # 在tmux会话中创建新窗口并启动服务
        tmux new-window -t nexus -n "$window_name" "./nexus-network start --node-id $node_id"
        
        if [ $? -eq 0 ]; then
            echo "成功启动 node_id: $node_id 的服务"
        else
            echo "启动 node_id: $node_id 的服务失败"
        fi
    done < "$NODE_FILE"

    echo "所有 node_ids 启动完成"
    echo "使用 'tmux attach -t nexus' 查看所有节点"
    read -p "按回车键继续..."
}

# 关闭所有节点的函数
stop_all_nodes() {
    echo "正在关闭所有 nexus 节点..."
    
    # 检查tmux会话是否存在
    if ! tmux has-session -t nexus 2>/dev/null; then
        echo "没有找到正在运行的 nexus 节点"
        read -p "按回车键继续..."
        return
    fi
    
    # 获取所有窗口（除了第一个窗口）
    windows=$(tmux list-windows -t nexus -F '#{window_index}' | tail -n +2)
    
    for window in $windows; do
        # 获取窗口名称
        window_name=$(tmux display-message -t "nexus:$window" -p '#{window_name}')
        echo "正在停止窗口: $window_name 的服务"
        
        # 发送 Ctrl+C 到窗口
        tmux send-keys -t "nexus:$window" C-c
        sleep 1
        # 关闭窗口
        tmux kill-window -t "nexus:$window"
        
        if [ $? -eq 0 ]; then
            echo "成功关闭窗口: $window_name"
        else
            echo "关闭窗口失败: $window_name"
        fi
    done
    
    # 如果只剩下第一个窗口，也关闭它
    if [ $(tmux list-windows -t nexus | wc -l) -eq 1 ]; then
        tmux kill-session -t nexus
    fi
    
    echo "所有节点关闭操作完成"
    read -p "按回车键继续..."
}

# 查看所有节点日志的函数
view_all_logs() {
    clear
    echo "正在获取所有节点的日志信息..."
    echo "=========================================="
    
    # 检查tmux会话是否存在
    if ! tmux has-session -t nexus 2>/dev/null; then
        echo "没有找到正在运行的 nexus 节点"
        read -p "按回车键继续..."
        return
    fi
    
    # 获取所有窗口（除了第一个窗口）
    windows=$(tmux list-windows -t nexus -F '#{window_index}' | tail -n +2)
    
    for window in $windows; do
        # 获取窗口名称
        window_name=$(tmux display-message -t "nexus:$window" -p '#{window_name}')
        node_id=$(echo "$window_name" | sed 's/node_//')
        
        # 获取窗口内容的第五行
        fifth_line=$(tmux capture-pane -pt "nexus:$window" | sed -n '5p')
        
        echo "节点ID: $node_id"
        echo "日志信息: $fifth_line"
        echo "------------------------------------------"
    done
    
    echo "=========================================="
    read -p "按回车键继续..."
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

