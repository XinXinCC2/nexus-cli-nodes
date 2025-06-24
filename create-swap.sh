#!/bin/bash

echo "👉 开始创建 5GB Swap 文件..."

# 步骤 1：创建 swap 文件
if sudo fallocate -l 5G /swapfile; then
    echo "✅ 已成功创建 5GB /swapfile"
else
    echo "⚠️ fallocate 失败，改用 dd 创建..."
    sudo dd if=/dev/zero of=/swapfile bs=1M count=5120 status=progress
fi

# 步骤 2：设置权限
sudo chmod 600 /swapfile
echo "🔒 权限设置为 600"

# 步骤 3：设置为 swap 区
sudo mkswap /swapfile
echo "⚙️ 格式化为 swap"

# 步骤 4：启用 swap
sudo swapon /swapfile
echo "🚀 swap 已启用"

# 步骤 5：写入 /etc/fstab 实现开机自动挂载
if ! grep -q "/swapfile" /etc/fstab; then
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    echo "📌 已写入 /etc/fstab"
else
    echo "📌 /etc/fstab 已存在 /swapfile 条目，跳过"
fi

# 步骤 6：调节 swap 使用策略
sudo sysctl vm.swappiness=10
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo "🎯 设置 vm.swappiness=10，降低 swap 使用频率"

# 验证结果
echo
echo "✅ swap 使用情况如下："
free -h
swapon --show
