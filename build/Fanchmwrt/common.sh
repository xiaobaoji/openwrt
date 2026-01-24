#!/bin/bash
# 核心编译函数库（适配无上游同步工作流）

# Diy_menu1：本地初始化（工作流调用）
Diy_menu1() {
  echo "===== 执行本地初始化 ====="
  # 确认编译目录权限
  chmod -R +x ${GITHUB_WORKSPACE}/build/${FOLDER_NAME}
  echo "本地编译环境初始化完成"
}

# Diy_menu2：编译公告（工作流调用）
Diy_menu2() {
  echo "===== 编译公告 ====="
  echo "📢 正在编译 Fanchmwrt UGREEN x64 固件"
  echo "📦 配置：6.6内核 | squashfs格式 | 1024M分区 | LAN IP: ${LAN_IP} | 无密码"
  echo "🔧 集成：nikki插件 + passwall插件 + xiaobaoji配置"
  echo "⏰ 时间：${Tongzhi_Date}"
}

# Diy_menu3：更新插件源（工作流调用）
Diy_menu3() {
  echo "===== 更新所有插件源 ====="
  ./scripts/feeds update -a --force-update  # 强制更新插件源
}

# Diy_menu4：加载自定义配置（工作流调用）
Diy_menu4() {
  echo "===== 加载自定义配置 ====="
  # 缓存加速编译
  if [ "${INPUTS_CACHEWRTBUILD_SWITCH}" == "true" ]; then
    echo "启用编译缓存"
    export CONFIG_CACHEWRTBUILD=1
  fi
  # 在线更新功能
  if [ "${INPUTS_UPDATE_FIRMWARE_ONLINE}" == "true" ]; then
    echo "启用在线更新依赖"
    echo "CONFIG_PACKAGE_libustream-mbedtls=y" >> .config
    echo "CONFIG_PACKAGE_wget=y" >> .config
  fi
}

# Diy_menu5：安装插件（工作流调用）
Diy_menu5() {
  echo "===== 安装所有插件 ====="
  ./scripts/feeds install -a --force-install  # 强制安装插件（含nikki/passwall）
}

# Diy_menu6：生成配置文件（工作流调用）
Diy_menu6() {
  echo "===== 生成最终配置文件 ====="
  # 创建配置文件存储目录
  mkdir -p build_logo
  # 导出配置到config.txt
  cat .config > build_logo/config.txt
  echo "配置文件已导出至：build_logo/config.txt"
}

# Diy_xinxi：输出编译信息（工作流调用）
Diy_xinxi() {
  echo "===== 编译信息汇总 ====="
  echo "源码地址：${REPO_URL}"
  echo "配置地址：${CONFIG_REPO_URL}"
  echo "插件地址：${NIKKI_REPO_URL}"
  echo "内核版本：6.6"
  echo "目标架构：x86_64"
}

# build_openwrt：核心编译命令（工作流调用）
build_openwrt() {
  echo "===== 开始编译固件 ====="
  cd ${GITHUB_WORKSPACE}/openwrt
  # 多线程编译（CPU核心数+1）
  make -j$(($(nproc) + 1)) V=s || make -j1 V=s  # 失败时单线程排错

  # 校验固件是否生成
  FIRMWARE_PATH="bin/targets/x86/64"
  if [ -z "$(ls ${FIRMWARE_PATH}/*.img 2>/dev/null)" ]; then
    echo "❌ 编译失败：未生成img固件"
    exit 1
  fi

  # 上传到Releases（若启用）
  if [ "${INPUTS_UPLOAD_RELEASE}" == "true" ]; then
    echo "===== 发布固件到Releases ====="
    FIRMWARE_FILE=$(ls ${FIRMWARE_PATH}/*.img.gz)
    gh release create "v${Firmware_Date}" "${FIRMWARE_FILE}" \
      --title "Fanchmwrt-UGREEN-x64-${Firmware_Date}" \
      --notes "✅ 编译完成\n📅 日期：${Tongzhi_Date}\n⚙️ 配置：6.6内核 | squashfs | 1024M | ${LAN_IP}"
  fi
}
