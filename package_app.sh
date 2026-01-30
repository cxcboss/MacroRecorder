#!/bin/bash

set -e

APP_NAME="MacroRecorder"
BUILD_DIR=".build/debug"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
VERSION="2.0"

echo "=== 打包 MacroRecorder 应用 v${VERSION} ==="

# 清理旧的 app
if [ -d "${APP_DIR}" ]; then
    echo "清理旧的 app..."
    rm -rf "${APP_DIR}"
fi

# 构建项目
echo "构建项目..."
swift build

# 获取可执行文件路径
EXECUTABLE_PATH=$(swift build --show-bin-path)/${APP_NAME}

if [ ! -f "${EXECUTABLE_PATH}" ]; then
    echo "错误: 找不到可执行文件 ${EXECUTABLE_PATH}"
    exit 1
fi

echo "可执行文件: ${EXECUTABLE_PATH}"

# 创建 app bundle 结构
echo "创建 app bundle..."
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"
mkdir -p "${RESOURCES_DIR}/Assets.xcassets/AppIcon.appiconset"

# 复制可执行文件
cp "${EXECUTABLE_PATH}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# 复制图标资源
cp "Assets.xcassets/Contents.json" "${RESOURCES_DIR}/Assets.xcassets/"
cp "Assets.xcassets/AppIcon.appiconset/Contents.json" "${RESOURCES_DIR}/Assets.xcassets/AppIcon.appiconset/"
if [ -f "Assets.xcassets/AppIcon.appiconset/Frame 74.png" ]; then
    cp "Assets.xcassets/AppIcon.appiconset/Frame 74.png" "${RESOURCES_DIR}/Assets.xcassets/AppIcon.appiconset/"
fi

# 复制 entitlements 文件
cp "${APP_NAME}.entitlements" "${CONTENTS_DIR}/"

# 创建 Info.plist
cat > "${CONTENTS_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>MacroRecorder</string>
    <key>CFBundleIdentifier</key>
    <string>com.macro.MacroRecorder</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MacroRecorder</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024-2025. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>CFBundleIconFile</key>
    <string></string>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF

# 创建默认的Assets.car（空图标）
echo "创建应用图标资源..."

echo ""
echo "==========================================="
echo "     打包完成! ✅"
echo "==========================================="
echo ""
echo "📦 应用位置: $(pwd)/${APP_DIR}"
echo ""
echo "✨ 新功能:"
echo "   • 支持深色模式自动适配"
echo "   • 录制结果自动保存"
echo "   • 支持宏重命名和删除"
echo "   • 可选择保存的宏进行播放"
echo "   • 支持无限循环和指定次数循环"
echo ""
echo "📝 使用说明:"
echo "   1. 双击打开 ${APP_NAME}.app"
echo "   2. 如果出现安全提示，请右键点击 app 选择'打开'"
echo "   3. 首次运行需要在'系统设置 > 隐私与安全性 > 辅助功能'中授予权限"
echo ""
echo "💡 提示: 按住 Ctrl 点击 app，选择'显示包内容'可查看内部结构"
echo ""
