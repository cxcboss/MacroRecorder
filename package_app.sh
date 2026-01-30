#!/bin/bash

set -e

APP_NAME="行为录制精灵"
EXECUTABLE_NAME="MacroRecorder"
BUILD_DIR=".build/debug"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
VERSION="2.0"

echo "=== 打包 ${APP_NAME} 应用 v${VERSION} ==="

# 清理旧的 app
if [ -d "${APP_DIR}" ]; then
    echo "清理旧的 app..."
    rm -rf "${APP_DIR}"
fi

# 检查图标文件
if [ ! -f "AppIcon.icns" ]; then
    echo "⚠️  未找到 AppIcon.icns，正在生成..."
    
    # 复制原始图标
    cp "Assets.xcassets/AppIcon.appiconset/AppIcon.png" /tmp/AppIcon.png
    
    # 创建临时 iconset 目录
    mkdir -p /tmp/AppIcon.iconset
    
    # 生成不同尺寸
    sips -z 16 16 /tmp/AppIcon.png --out /tmp/AppIcon.iconset/icon_16x16.png
    sips -z 32 32 /tmp/AppIcon.png --out /tmp/AppIcon.iconset/icon_16x16@2x.png
    sips -z 32 32 /tmp/AppIcon.png --out /tmp/AppIcon.iconset/icon_32x32.png
    sips -z 64 64 /tmp/AppIcon.png --out /tmp/AppIcon.iconset/icon_32x32@2x.png
    sips -z 128 128 /tmp/AppIcon.png --out /tmp/AppIcon.iconset/icon_128x128.png
    sips -z 256 256 /tmp/AppIcon.png --out /tmp/AppIcon.iconset/icon_128x128@2x.png
    sips -z 256 256 /tmp/AppIcon.png --out /tmp/AppIcon.iconset/icon_256x256.png
    sips -z 512 512 /tmp/AppIcon.png --out /tmp/AppIcon.iconset/icon_256x256@2x.png
    sips -z 512 512 /tmp/AppIcon.png --out /tmp/AppIcon.iconset/icon_512x512.png
    sips -z 1024 1024 /tmp/AppIcon.png --out /tmp/AppIcon.iconset/icon_512x512@2x.png
    
    # 生成 icns
    iconutil --convert icns --output AppIcon.icns /tmp/AppIcon.iconset
    
    # 清理临时文件
    rm -rf /tmp/AppIcon.iconset /tmp/AppIcon.png
    
    echo "✅ AppIcon.icns 生成完成"
fi

# 构建项目
echo "构建项目..."
swift build

# 获取可执行文件路径
EXECUTABLE_PATH=$(swift build --show-bin-path)/${EXECUTABLE_NAME}

if [ ! -f "${EXECUTABLE_PATH}" ]; then
    echo "错误: 找不到可执行文件 ${EXECUTABLE_PATH}"
    exit 1
fi

echo "可执行文件: ${EXECUTABLE_PATH}"

# 创建 app bundle 结构
echo "创建 app bundle..."
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 复制可执行文件
cp "${EXECUTABLE_PATH}" "${MACOS_DIR}/${EXECUTABLE_NAME}"
chmod +x "${MACOS_DIR}/${EXECUTABLE_NAME}"

# 复制图标文件
echo "复制图标文件..."
cp "AppIcon.icns" "${RESOURCES_DIR}/"
echo "✅ 图标已复制: ${RESOURCES_DIR}/AppIcon.icns"

# 复制 entitlements 文件
cp "MacroRecorder.entitlements" "${CONTENTS_DIR}/"

# 创建 Info.plist
cat > "${CONTENTS_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>${EXECUTABLE_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.macro.MacroRecorder</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
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
    <string>AppIcon</string>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF

# 使用 SetFile 设置自定义图标（备用方法）
if command -v SetFile &> /dev/null; then
    echo "设置自定义图标..."
    SetFile -t ICNS "${RESOURCES_DIR}/AppIcon.icns" 2>/dev/null || true
    SetFile -a C "${APP_DIR}" 2>/dev/null || true
    echo "✅ 自定义图标设置完成"
fi

echo ""
echo "==========================================="
echo "     打包完成! ✅"
echo "==========================================="
echo ""
echo "📦 应用位置: $(pwd)/${APP_DIR}"
echo "📱 应用名称: ${APP_NAME}"
echo "🎨 图标文件: ${RESOURCES_DIR}/AppIcon.icns"
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
