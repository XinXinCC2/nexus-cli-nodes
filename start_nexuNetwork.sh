#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查screen是否安装
check_screen() {
    if ! command -v screen &> /dev/null; then
        echo -e "${RED}错误: screen 未安装${NC}"
        echo "请先安装 screen:"
        echo "Ubuntu/Debian: sudo apt-get install screen"
        echo "CentOS/RHEL: sudo yum install screen"
        exit 1
    fi
}

# 显示菜单函数
show_menu() {
    clear
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}           Nexus 节点管理脚本            ${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo -e "1) ${YELLOW}启动所有节点${NC}"
    echo -e "2) ${YELLOW}停止所有节点${NC}"
    echo -e "3) ${YELLOW}查看节点日志${NC}"
    echo -e "4) ${YELLOW}查看节点状态${NC}"
    echo -e "5) ${YELLOW}进入节点会话${NC}"
    echo -e "6) ${YELLOW}退出脚本${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo -n "请选择操作 (1-6): "
}

# 启动所有节点的函数
start_all_nodes() {
    clear
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}开始启动所有节点...${NC}"
    echo -e "${GREEN}==========================================${NC}"
    
    NODE_FILE="node_ids.txt"
    if [ ! -f "$NODE_FILE" ]; then
        echo -e "${RED}错误：未找到 $NODE_FILE 文件${NC}"
        read -n 1 -s -r -p "按任意键继续..."
        return
    fi

    if [ ! -f "./nexus-network" ]; then
        echo -e "${RED}错误：未找到 nexus-network 可执行文件${NC}"
        read -n 1 -s -r -p "按任意键继续..."
        return
    fi

    # 统计变量
    total_nodes=0
    started_nodes=0
    running_nodes=0

    # 检查现有节点状态
    while IFS= read -r node_id || [ -n "$node_id" ]; do
        if [ -z "$node_id" ]; then
            continue
        fi
        total_nodes=$((total_nodes + 1))
        if screen -list | grep -q "node_${node_id}"; then
            running_nodes=$((running_nodes + 1))
        fi
    done < "$NODE_FILE"

    echo -e "当前状态："
    echo -e "总节点数: ${YELLOW}$total_nodes${NC}"
    echo -e "已在运行: ${GREEN}$running_nodes${NC}"
    echo -e "待启动数: ${YELLOW}$((total_nodes - running_nodes))${NC}"
    echo -e "${GREEN}==========================================${NC}"

    # 启动节点
    while IFS= read -r node_id || [ -n "$node_id" ]; do
        if [ -z "$node_id" ]; then
            continue
        fi

        if screen -list | grep -q "node_${node_id}"; then
            echo -e "[${YELLOW}$node_id${NC}] 已在运行"
            continue
        fi

        echo -n -e "[${YELLOW}$node_id${NC}] 正在启动... "
        
        # 使用screen启动节点，并设置日志轮转
        screen -dmS "node_${node_id}" bash -c "
            ./nexus-network start --node-id \"$node_id\" 2>&1 | \
            while read line; do
                echo \"\$(date '+%Y-%m-%d %H:%M:%S') \$line\" >> \"logs/node_${node_id}.log\"
                # 保持日志文件大小在100KB以内
                if [ \$(stat -f%z \"logs/node_${node_id}.log\" 2>/dev/null || stat -c%s \"logs/node_${node_id}.log\") -gt 102400 ]; then
                    tail -n 1000 \"logs/node_${node_id}.log\" > \"logs/node_${node_id}.log.tmp\"
                    mv \"logs/node_${node_id}.log.tmp\" \"logs/node_${node_id}.log\"
                fi
            done
        "

        if screen -list | grep -q "node_${node_id}"; then
            echo -e "${GREEN}成功${NC}"
            started_nodes=$((started_nodes + 1))
        else
            echo -e "${RED}失败${NC}"
        fi
    done < "$NODE_FILE"

    echo -e "${GREEN}==========================================${NC}"
    echo -e "启动完成统计："
    echo -e "总节点数: ${YELLOW}$total_nodes${NC}"
    echo -e "新启动节点: ${GREEN}$started_nodes${NC}"
    echo -e "已在运行节点: ${GREEN}$running_nodes${NC}"
    echo -e "${GREEN}==========================================${NC}"
    
    read -n 1 -s -r -p "按任意键继续..."
}

# 停止所有节点的函数
stop_all_nodes() {
    clear
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}正在停止所有节点...${NC}"
    echo -e "${GREEN}==========================================${NC}"

    # 获取所有nexus节点的screen会话
    sessions=$(screen -ls | grep "node_" | awk '{print $1}')
    
    if [ -z "$sessions" ]; then
        echo -e "${YELLOW}没有找到正在运行的节点${NC}"
    else
        for session in $sessions; do
            node_id=$(echo $session | cut -d'_' -f2)
            echo -n -e "[${YELLOW}$node_id${NC}] 正在停止... "
            screen -S $session -X quit
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}成功${NC}"
            else
                echo -e "${RED}失败${NC}"
            fi
        done
    fi

    echo -e "${GREEN}==========================================${NC}"
    read -n 1 -s -r -p "按任意键继续..."
}

# 查看节点日志的函数
view_all_logs() {
    clear
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}查看所有节点日志${NC}"
    echo -e "${GREEN}==========================================${NC}"

    NODE_FILE="node_ids.txt"
    if [ ! -f "$NODE_FILE" ]; then
        echo -e "${RED}错误：未找到 $NODE_FILE 文件${NC}"
        read -n 1 -s -r -p "按任意键继续..."
        return
    fi

    while IFS= read -r node_id || [ -n "$node_id" ]; do
        if [ -z "$node_id" ]; then
            continue
        fi

        # 检查节点是否运行
        if screen -list | grep -q "node_${node_id}"; then
            status="${GREEN}运行中${NC}"
        else
            status="${RED}未运行${NC}"
        fi

        echo -e "节点ID: ${YELLOW}$node_id${NC} (状态: $status)"
        echo -e "${GREEN}------------------------------------------${NC}"
        
        LOG_FILE="logs/node_${node_id}.log"
        if [ -f "$LOG_FILE" ]; then
            # 获取第5行日志，如果文件行数不足5行，则获取最后一行
            log_line=$(sed -n '5p' "$LOG_FILE" 2>/dev/null || tail -n 1 "$LOG_FILE")
            if [ ! -z "$log_line" ]; then
                echo -e "$log_line"
            else
                echo -e "${YELLOW}暂无日志${NC}"
            fi
        else
            echo -e "${YELLOW}日志文件不存在${NC}"
        fi
        echo -e "${GREEN}------------------------------------------${NC}"
    done < "$NODE_FILE"

    echo -e "${GREEN}==========================================${NC}"
    read -n 1 -s -r -p "按任意键继续..."
}

# 查看节点状态
view_node_status() {
    clear
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}节点运行状态${NC}"
    echo -e "${GREEN}==========================================${NC}"

    NODE_FILE="node_ids.txt"
    if [ ! -f "$NODE_FILE" ]; then
        echo -e "${RED}错误：未找到 $NODE_FILE 文件${NC}"
        read -n 1 -s -r -p "按任意键继续..."
        return
    fi

    echo -e "${YELLOW}节点ID\t状态\t\t运行时间${NC}"
    echo -e "${GREEN}------------------------------------------${NC}"

    while IFS= read -r node_id || [ -n "$node_id" ]; do
        if [ -z "$node_id" ]; then
            continue
        fi

        if screen -list | grep -q "node_${node_id}"; then
            status="${GREEN}运行中${NC}"
            # 获取screen会话的创建时间
            start_time=$(screen -list | grep "node_${node_id}" | awk '{print $3}')
            if [ ! -z "$start_time" ]; then
                runtime="$start_time"
            else
                runtime="未知"
            fi
        else
            status="${RED}未运行${NC}"
            runtime="-"
        fi

        echo -e "${YELLOW}$node_id${NC}\t$status\t$runtime"
    done < "$NODE_FILE"

    echo -e "${GREEN}==========================================${NC}"
    read -n 1 -s -r -p "按任意键继续..."
}

# 进入节点会话
enter_node_session() {
    clear
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}选择要进入的节点会话${NC}"
    echo -e "${GREEN}==========================================${NC}"

    # 获取所有运行的节点
    sessions=($(screen -ls | grep "node_" | awk '{print $1}'))
    
    if [ ${#sessions[@]} -eq 0 ]; then
        echo -e "${YELLOW}没有正在运行的节点${NC}"
        read -n 1 -s -r -p "按任意键继续..."
        return
    fi

    echo -e "可用的节点会话："
    for i in "${!sessions[@]}"; do
        node_id=$(echo ${sessions[$i]} | cut -d'_' -f2)
        echo -e "$((i+1))) ${YELLOW}节点 $node_id${NC}"
    done

    echo -e "${GREEN}==========================================${NC}"
    echo -n "请选择要进入的节点 (输入数字): "
    read choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#sessions[@]} ]; then
        selected_session=${sessions[$((choice-1))]}
        echo -e "${GREEN}正在进入节点会话...${NC}"
        echo -e "${YELLOW}提示: 使用 Ctrl+A+D 可以退出会话${NC}"
        sleep 1
        screen -r $selected_session
    else
        echo -e "${RED}无效的选择${NC}"
        read -n 1 -s -r -p "按任意键继续..."
    fi
}

# 主函数
main() {
    # 检查screen是否安装
    check_screen

    # 创建日志目录
    mkdir -p logs

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
                view_node_status
                ;;
            5)
                enter_node_session
                ;;
            6)
                echo -e "${GREEN}感谢使用，再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效的选择，请重新输入${NC}"
                read -n 1 -s -r -p "按任意键继续..."
                ;;
        esac
    done
}

# 启动主函数
main