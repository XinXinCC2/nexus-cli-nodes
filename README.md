# Nexus CLI 多开脚本

这是一个用于管理多个 Nexus 节点的 Shell 脚本，可以方便地启动、停止和监控多个 Nexus 节点。

## 快速开始

使用以下命令一键下载并安装脚本：

```bash
# 下载脚本并添加执行权限
curl -L https://raw.githubusercontent.com/XinXinCC2/nexus-cli-nodes/main/start_nexusNodes.sh -o start_nexusNodes.sh && chmod +x start_nexusNodes.sh
```

## 功能特点

- 支持同时启动多个 Nexus 节点
- 使用 screen 会话管理，方便查看节点运行状态
- 提供简单的交互式菜单界面
- 支持批量启动和停止所有节点
- 支持查看和进入特定节点的会话

## 使用要求

- Bash 环境
- screen 工具（可通过以下命令安装）：
  - MacOS: `brew install screen`
  - Ubuntu/Debian: `apt-get install screen`

## 使用方法

1. 在脚本同目录下创建 `node_ids.txt` 文件：
   ```bash
   # 创建 node_ids.txt 文件
   touch node_ids.txt
   
   # 编辑文件，每行添加一个 node_id
   # 例如：
   # node_id_1
   # node_id_2
   # node_id_3
   ```
   > 注意：`node_ids.txt` 文件不会被提交到 Git 仓库，您需要在本地创建并维护该文件。

2. 运行脚本：`./start_nexusNodes.sh`

## 菜单选项

1. 开启所有 node_id
2. 关闭所有 node_id
3. 查看/进入会话
4. 退出脚本

## 注意事项

- 使用 screen 会话时，可以通过 `Ctrl+A` 然后按 `D` 来退出会话（保持服务运行）
- 确保 `node_ids.txt` 文件格式正确，每行一个 node_id
- 建议在使用前备份重要数据
- `node_ids.txt` 文件包含您的节点 ID，请妥善保管，不要分享给他人
- 如果使用 Docker 环境，请确保在本地创建 `node_ids.txt` 文件，该文件不会被包含在 Docker 镜像中 