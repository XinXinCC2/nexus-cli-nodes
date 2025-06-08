#!/bin/bash

# 显示菜单函数
show_menu() {
    clear
    echo "=========================================="
    echo "           nexus-cli多开脚本             "
    echo "=========================================="
    echo "1) 开启所有node_id"
    echo "2) 关闭所有node_id"
    echo "3) 查看/进入会话"
    echo "4) 退出脚本"
    echo "=========================================="
    echo -n "请选择操作 (1-4): "
}

# 列出会话并处理进入会话的函数
handle_sessions() {
    while true; do
        clear
        echo "当前所有 nexus 会话列表："
        echo "=========================================="
        sessions=$(screen -ls | grep "nexu_" | awk '{print $1}')
        
        if [ -z "$sessions" ]; then
            echo "没有找到正在运行的 nexus 会话"
            echo "=========================================="
            read -p "按回车键返回主菜单..."
            return
        fi
        
        # 显示会话列表并编号
        echo "会话列表："
        echo "$sessions" | nl
        echo "=========================================="
        echo "输入会话编号进入对应会话"
        echo "输入 0 返回主菜单"
        echo -n "请选择: "
        
        read choice
        
        if [ "$choice" = "0" ]; then
            return
        fi
        
        # 获取选择的会话名称
        selected_session=$(echo "$sessions" | sed -n "${choice}p")
        
        if [ -z "$selected_session" ]; then
            echo "无效的会话编号"
            read -p "按回车键继续..."
            continue
        fi
        
        echo "正在进入会话: $selected_session"
        echo "提示：使用 Ctrl+A 然后按 D 可以退出会话（保持服务运行）"
        read -p "按回车键继续..."
        
        # 进入会话
        screen -r "$selected_session"
    done
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

    # 检查是否安装了 screen
    if ! command -v screen &> /dev/null; then
        echo "错误：未安装 screen，请先安装 screen"
        echo "可以使用命令：brew install screen (MacOS) 或 apt-get install screen (Ubuntu/Debian)"
        read -p "按回车键继续..."
        return
    fi

    while IFS= read -r node_id || [ -n "$node_id" ]; do
        # 跳过空行
        if [ -z "$node_id" ]; then
            continue
        fi
        
        # 创建会话名称
        session_name="nexu_${node_id}"
        echo "正在为 node_id: $node_id 创建会话 $session_name"
        
        # 创建新的 screen 会话
        screen -S "$session_name" -dm
        if [ $? -ne 0 ]; then
            echo "错误：创建会话 $session_name 失败"
            continue
        fi
        
        # 在会话中启动服务
        screen -S "$session_name" -X stuff "nexus-network start --node-id $node_id$(printf '\r')"
        if [ $? -ne 0 ]; then
            echo "错误：在会话 $session_name 中启动服务失败"
            continue
        fi
        
        echo "成功启动 node_id: $node_id 的服务"
    done < "$NODE_FILE"

    echo "所有 node_ids 启动完成"
    echo "可以使用 'screen -ls' 查看所有会话"
    echo "使用 'screen -r 会话名' 进入特定会话查看详情"
    read -p "按回车键继续..."
}

# 关闭所有节点的函数
stop_all_nodes() {
    echo "正在关闭所有 nexus 节点..."
    
    # 获取所有 nexus 相关的 screen 会话
    sessions=$(screen -ls | grep "nexu_" | awk '{print $1}')
    
    if [ -z "$sessions" ]; then
        echo "没有找到正在运行的 nexus 节点"
    else
        for session in $sessions; do
            echo "正在停止会话: $session 的服务"
            # 发送 q 命令停止服务
            screen -S "$session" -X stuff "q$(printf '\r')"
            # 等待服务停止
            sleep 2
            # 关闭会话
            screen -S "$session" -X quit
            if [ $? -eq 0 ]; then
                echo "成功关闭会话: $session"
            else
                echo "关闭会话失败: $session"
            fi
        done
    fi
    
    echo "所有节点关闭操作完成"
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
            handle_sessions
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

