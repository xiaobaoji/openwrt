#!/bin/bash
# Fanchmwrt自定义操作脚本（适配无上游同步）
set -e

echo "===== 执行diy-part.sh自定义初始化 ====="
# 输出当前编译信息
echo "编译分支：${INPUTS_REPO_BRANCH_MAIN} + ${INPUTS_REPO_BRANCH_OPENWRT}"
echo "目标设备：${DEVICE_NAME}（x86_64）"
echo "固件格式：${FILESYSTEM} | 分区大小：${ROOTFS_SIZE}M"
echo "LAN地址：${LAN_IP} | 无密码登录"

# 可添加额外自定义操作（如源码补丁、插件调整等）
