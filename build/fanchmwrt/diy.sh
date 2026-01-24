#!/bin/bash
# 适配 xiaobaoji 格式，整合 Passwall + Nikki 双插件
cd $BUILD_DIR || exit 1

echo "===== 开始执行自定义配置 ====="

# 1. 基础系统配置
# 替换默认 IP 为 192.168.123.2
sed -i 's/192.168.1.1/192.168.123.2/g' package/base-files/files/bin/config_generate
# 修改设备名为 UGREEN
sed -i 's/OpenWrt/UGREEN/g' package/base-files/files/bin/config_generate
# 清空 root 密码（无需密码登录）
sed -i 's/root::0:0:99999:7:::/root::$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' package/base-files/files/etc/shadow
sed -i 's/root:!:0:0:99999:7:::/root::$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' package/base-files/files/etc/shadow

# 2. 系统性能优化
cat >> package/base-files/files/etc/sysctl.conf <<EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.ip_local_port_range = 1024 65535
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.forwarding = 1
EOF

# 3. 安装 Argon 主题
if [ ! -d "package/luci-theme-argon" ]; then
    git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
    git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config
fi
echo "CONFIG_PACKAGE_luci-theme-argon=y" >> .config
echo "CONFIG_PACKAGE_luci-app-argon-config=y" >> .config

# 4. 配置 Passwall 插件（官方双源 + 依赖修复）
# 添加 Passwall 官方双源（顶部插入避免冲突）
sed -i '1i src-git passwall_pkgs https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' feeds.conf.default
sed -i '2i src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' feeds.conf.default
# 去重并更新 feeds
awk '!a[$0]++' feeds.conf.default > tmp && mv tmp feeds.conf.default
./scripts/feeds update -a
# 移除系统自带冲突包
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
rm -rf feeds/luci/applications/luci-app-passwall
# 安装 Passwall 及依赖
./scripts/feeds install -a -f -p passwall_pkgs
./scripts/feeds install -a -f -p passwall_luci
# 强制启用 Passwall 核心组件
echo "CONFIG_PACKAGE_luci-app-passwall=y" >> .config
echo "CONFIG_PACKAGE_passwall=y" >> .config
echo "CONFIG_PACKAGE_geoview=y" >> .config  # 适配 Sing-box 1.12.0+

# 5. 配置 Nikki 插件（官方源 + 依赖）
# 添加 Nikki 插件源
echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >> feeds.conf.default
# 更新并安装 Nikki
./scripts/feeds update nikki
./scripts/feeds install -a -f -p nikki
# 强制启用 Nikki 核心组件
echo "CONFIG_PACKAGE_luci-app-nikki=y" >> .config
echo "CONFIG_PACKAGE_nikki=y" >> .config
# 安装 Nikki 依赖包
echo "CONFIG_PACKAGE_ca-bundle=y" >> .config
echo "CONFIG_PACKAGE_curl=y" >> .config
echo "CONFIG_PACKAGE_yq=y" >> .config
echo "CONFIG_PACKAGE_firewall4=y" >> .config
echo "CONFIG_PACKAGE_ip-full=y" >> .config
echo "CONFIG_PACKAGE_kmod-inet-diag=y" >> .config
echo "CONFIG_PACKAGE_kmod-nft-socket=y" >> .config
echo "CONFIG_PACKAGE_kmod-nft-tproxy=y" >> .config
echo "CONFIG_PACKAGE_kmod-tun=y" >> .config

# 6. 安装常用工具
echo "CONFIG_PACKAGE_wget=y" >> .config
echo "CONFIG_PACKAGE_openssh-server=y" >> .config
echo "CONFIG_PACKAGE_ping=y" >> .config
echo "CONFIG_PACKAGE_traceroute=y" >> .config
echo "CONFIG_PACKAGE_htop=y" >> .config
echo "CONFIG_PACKAGE_dosfstools=y" >> .config
echo "CONFIG_PACKAGE_e2fsprogs=y" >> .config

# 7. 清理冗余包（减少固件体积）
sed -i '/CONFIG_PACKAGE_luci-app-ddns/d' .config
sed -i '/CONFIG_PACKAGE_luci-app-pptp-server/d' .config
sed -i '/CONFIG_PACKAGE_luci-app-vpnc/d' .config

echo "===== 自定义配置执行完成 ====="
