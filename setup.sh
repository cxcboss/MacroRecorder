#!/bin/bash

set -e

echo "🔧 MacroRecorder 项目设置"
echo "========================="

cd "$(dirname "$0")"

if [ ! -d "MacroRecorder.xcodeproj" ]; then
    echo "❌ Xcode 项目文件不存在"
    exit 1
fi

echo "✅ 项目文件已就绪！"
echo ""
echo "📱 运行步骤："
echo "   1. 双击打开 MacroRecorder.xcodeproj"
echo "   2. 在 Xcode 中选择签名证书（如果需要）"
echo "   3. 按 Cmd+R 运行应用"
echo ""
echo "⚠️  重要说明："
echo "   首次运行时需要在系统设置中授予辅助功能权限："
echo "   系统设置 > 隐私与安全性 > 辅助功能"
echo "   添加 'MacroRecorder' 应用"
echo ""
echo "🎮 使用方法："
echo "   1. 点击 '开始录制' 按钮"
echo "   2. 执行鼠标操作（点击、拖动等）"
echo "   3. 点击 '停止录制'"
echo "   4. 点击 '播放操作' 回放"
echo ""
