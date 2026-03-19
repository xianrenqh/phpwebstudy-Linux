#!/bin/bash
# PhpWebStudy AMD64 .deb 包构建脚本
# 用法：bash build-amd64-deb.sh

set -e

echo "=========================================="
echo "PhpWebStudy AMD64 .deb 包构建"
echo "=========================================="
echo ""

cd /mnt/works/www_vue/016phpwebstudy

# 1. 清理
echo "📦 步骤 1/5: 清理旧文件..."
rm -rf release dist/electron/main.js dist/electron/fork.js node_modules/node-pty/build/*
echo "✓ 清理完成"
echo ""

# 2. 编译源代码
echo "🔧 步骤 2/5: 编译源代码..."
if command -v yarn &> /dev/null; then
  echo "使用 yarn 编译..."
  cat scripts/args.esbuild.app-builder | xargs yarn run build-dev-runner 2>&1 | tail -5
else
  echo "使用 node_modules/.bin/esbuild 编译..."
  cat scripts/args.esbuild.app-builder | xargs node_modules/.bin/esbuild 2>&1 | tail -5
fi

if [ $? -ne 0 ]; then
  echo "❌ 编译失败"
  exit 1
fi
echo "✓ 编译完成"
echo ""

# 3. 运行 app-builder 打包
echo "📦 步骤 3/5: 运行 electron-app-builder..."
export NODE_ENV=production
export ARCH=amd64
export USE_SYSTEM_FPM=true  # 使用系统的 fpm 工具生成 .deb 包
node electron/app-builder.js

if [ $? -ne 0 ]; then
  echo "❌ app-builder 失败"
  exit 1
fi
echo "✓ app-builder 完成"
echo ""

# 4. 检查输出
echo "📋 步骤 4/5: 检查构建输出..."
if [ -d "release" ]; then
  echo "✓ release 目录已生成"
  ls -lh release/
else
  echo "⚠️  release 目录不存在"
fi
echo ""

# 5. 查找 .deb 文件
echo "📋 步骤 5/5: 查找 .deb 包..."
find release -name "*.deb" -type f 2>/dev/null | while read deb; do
  echo "✓ 找到: $deb"
  ls -lh "$deb"
done
echo ""

echo "=========================================="
echo "✅ 构建完成！"
echo "=========================================="
echo ""
echo "输出的 .deb 包位置：release/"
echo ""
echo "安装方法:"
echo "  sudo dpkg -i release/PhpWebStudy-*.deb"
echo ""
