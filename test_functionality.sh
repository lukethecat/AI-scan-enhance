#!/bin/bash

# AI扫描增强应用功能测试脚本
# 用于测试图片处理的实际功能

set -e

echo "========================================"
echo "AI扫描增强应用功能测试"
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目路径
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="AIScanEnhance"
TEST_DIR="$PROJECT_DIR/test_images"
OUTPUT_DIR="$PROJECT_DIR/test_output"

echo -e "${BLUE}项目路径: $PROJECT_DIR${NC}"
echo -e "${BLUE}测试图片目录: $TEST_DIR${NC}"
echo -e "${BLUE}输出目录: $OUTPUT_DIR${NC}"
echo ""

# 创建测试目录
echo -e "${YELLOW}准备测试环境${NC}"
mkdir -p "$TEST_DIR"
mkdir -p "$OUTPUT_DIR"

# 创建一个简单的测试图片（使用ImageMagick或系统工具）
echo "创建测试图片..."
if command -v convert >/dev/null 2>&1; then
    # 使用ImageMagick创建测试图片
    convert -size 800x600 xc:white \
        -fill black -pointsize 24 \
        -draw "text 50,100 'AI扫描增强测试文档'" \
        -draw "text 50,150 '这是一个测试文档，用于验证'" \
        -draw "text 50,200 '图片处理和角点检测功能'" \
        -draw "text 50,250 '请确保应用能够正确处理此图片'" \
        -draw "rectangle 30,80 770,280" \
        "$TEST_DIR/test_document.jpg"
    echo -e "${GREEN}✅ 使用ImageMagick创建测试图片${NC}"
elif command -v sips >/dev/null 2>&1; then
    # 使用macOS的sips工具创建简单的测试图片
    # 先创建一个白色背景
    python3 -c "
import os
from PIL import Image, ImageDraw, ImageFont

# 创建白色背景图片
img = Image.new('RGB', (800, 600), 'white')
draw = ImageDraw.Draw(img)

# 绘制文本
try:
    font = ImageFont.truetype('/System/Library/Fonts/Arial.ttf', 24)
except:
    font = ImageFont.load_default()

draw.text((50, 100), 'AI扫描增强测试文档', fill='black', font=font)
draw.text((50, 150), '这是一个测试文档，用于验证', fill='black', font=font)
draw.text((50, 200), '图片处理和角点检测功能', fill='black', font=font)
draw.text((50, 250), '请确保应用能够正确处理此图片', fill='black', font=font)

# 绘制边框
draw.rectangle([30, 80, 770, 280], outline='black', width=2)

# 保存图片
img.save('$TEST_DIR/test_document.jpg', 'JPEG')
print('测试图片创建成功')
" 2>/dev/null && echo -e "${GREEN}✅ 使用Python PIL创建测试图片${NC}" || {
        # 如果Python PIL不可用，创建一个简单的纯色图片
        echo -e "${YELLOW}⚠️  创建简单测试图片${NC}"
        # 复制系统图标作为测试图片
        cp "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/DocumentIcon.icns" "$TEST_DIR/test_document.icns" 2>/dev/null || {
            # 如果都不行，创建一个空文件提示用户
            echo "请手动添加测试图片到 $TEST_DIR 目录" > "$TEST_DIR/README.txt"
            echo -e "${YELLOW}⚠️  请手动添加测试图片到测试目录${NC}"
        }
    }
else
    echo -e "${YELLOW}⚠️  未找到图片处理工具，请手动添加测试图片${NC}"
    echo "请将测试图片放入: $TEST_DIR"
fi

# 检查是否有测试图片
echo ""
echo -e "${YELLOW}检查测试图片${NC}"
TEST_IMAGES=()
for ext in jpg jpeg png heic tiff bmp; do
    while IFS= read -r -d '' file; do
        TEST_IMAGES+=("$file")
    done < <(find "$TEST_DIR" -name "*.$ext" -print0 2>/dev/null)
done

if [ ${#TEST_IMAGES[@]} -eq 0 ]; then
    echo -e "${RED}❌ 未找到测试图片${NC}"
    echo "请将测试图片（jpg, png, heic等格式）放入: $TEST_DIR"
    echo "然后重新运行此脚本"
    exit 1
else
    echo -e "${GREEN}✅ 找到 ${#TEST_IMAGES[@]} 个测试图片${NC}"
    for img in "${TEST_IMAGES[@]}"; do
        echo "  - $(basename "$img")"
    done
fi

echo ""

# 查找应用
echo -e "${YELLOW}查找应用${NC}"
APP_BUNDLE=$(find $HOME/Library/Developer/Xcode/DerivedData -name "$APP_NAME.app" -path "*/Build/Products/Debug/*" | head -1)

if [ -d "$APP_BUNDLE" ]; then
    echo -e "${GREEN}✅ 找到应用: $APP_BUNDLE${NC}"
else
    echo -e "${RED}❌ 未找到应用，请先编译项目${NC}"
    exit 1
fi

echo ""

# 启动应用进行功能测试
echo -e "${YELLOW}启动应用进行功能测试${NC}"
echo "启动应用..."

# 启动应用
open "$APP_BUNDLE"
sleep 5

# 检查应用是否正在运行
if pgrep -f "$APP_NAME" > /dev/null; then
    echo -e "${GREEN}✅ 应用启动成功${NC}"
    
    APP_PID=$(pgrep -f "$APP_NAME")
    echo "应用进程ID: $APP_PID"
    
    # 启动日志监控
    echo "开始监控应用日志..."
    log stream --predicate 'process == "'$APP_NAME'"' --info --debug > "/tmp/${APP_NAME}_function_test.log" 2>&1 &
    LOG_PID=$!
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}手动功能测试指南${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo "应用已启动，请按照以下步骤进行功能测试："
    echo ""
    echo "1. 📁 添加测试图片："
    echo "   - 点击工具栏中的'添加文件'按钮"
    echo "   - 选择测试图片目录: $TEST_DIR"
    echo "   - 选择一个或多个测试图片"
    echo ""
    echo "2. ⚙️ 开始处理："
    echo "   - 点击'开始处理'按钮"
    echo "   - 观察处理进度和状态"
    echo ""
    echo "3. 👀 查看结果："
    echo "   - 在队列中选择处理完成的图片"
    echo "   - 在详情面板查看处理结果"
    echo "   - 使用'对比原图'功能查看前后对比"
    echo ""
    echo "4. 💾 保存结果："
    echo "   - 点击'保存图片'按钮"
    echo "   - 选择保存位置（建议保存到: $OUTPUT_DIR）"
    echo ""
    echo "5. 🔄 测试其他功能："
    echo "   - 尝试'重新处理'功能"
    echo "   - 测试多张图片的批量处理"
    echo "   - 验证错误处理（尝试添加非图片文件）"
    echo ""
    echo -e "${YELLOW}请完成上述测试后按任意键继续...${NC}"
    read -n 1 -s
    
    echo ""
    echo "检查应用状态..."
    
    # 检查应用是否仍在运行
    if pgrep -f "$APP_NAME" > /dev/null; then
        echo -e "${GREEN}✅ 应用仍在正常运行${NC}"
        
        # 停止日志监控
        kill $LOG_PID 2>/dev/null || true
        sleep 1
        
        # 分析日志
        if [ -f "/tmp/${APP_NAME}_function_test.log" ]; then
            echo "分析应用日志..."
            
            # 检查处理相关的日志
            PROCESSING_LOGS=$(grep -i "处理\|processing\|detect\|enhance" "/tmp/${APP_NAME}_function_test.log" | wc -l)
            ERROR_LOGS=$(grep -i "error\|exception\|failed\|❌" "/tmp/${APP_NAME}_function_test.log" | wc -l)
            SUCCESS_LOGS=$(grep -i "success\|completed\|✅" "/tmp/${APP_NAME}_function_test.log" | wc -l)
            
            echo "日志统计："
            echo "  - 处理相关日志: $PROCESSING_LOGS 条"
            echo "  - 成功日志: $SUCCESS_LOGS 条"
            echo "  - 错误日志: $ERROR_LOGS 条"
            
            if [ $ERROR_LOGS -gt 0 ]; then
                echo -e "${YELLOW}⚠️  发现错误日志，详细信息：${NC}"
                grep -i "error\|exception\|failed\|❌" "/tmp/${APP_NAME}_function_test.log" | head -5
            fi
            
            if [ $SUCCESS_LOGS -gt 0 ]; then
                echo -e "${GREEN}✅ 发现成功处理日志${NC}"
            fi
        fi
        
        # 检查输出目录
        echo ""
        echo "检查输出结果..."
        if [ -d "$OUTPUT_DIR" ] && [ "$(ls -A "$OUTPUT_DIR" 2>/dev/null)" ]; then
            OUTPUT_COUNT=$(ls -1 "$OUTPUT_DIR" | wc -l)
            echo -e "${GREEN}✅ 找到 $OUTPUT_COUNT 个输出文件${NC}"
            echo "输出文件："
            ls -la "$OUTPUT_DIR"
        else
            echo -e "${YELLOW}⚠️  输出目录为空，请检查是否成功保存了处理结果${NC}"
        fi
        
    else
        echo -e "${RED}❌ 应用已停止运行，可能发生了崩溃${NC}"
    fi
    
else
    echo -e "${RED}❌ 应用启动失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}功能测试总结${NC}"
echo -e "${BLUE}========================================${NC}"
echo "测试图片目录: $TEST_DIR"
echo "输出目录: $OUTPUT_DIR"
echo "应用日志: /tmp/${APP_NAME}_function_test.log"
echo ""
echo "请根据测试结果评估应用功能："
echo "✅ 应用能否正常启动"
echo "✅ 能否成功添加图片到队列"
echo "✅ 图片处理是否正常工作"
echo "✅ 处理结果是否正确显示"
echo "✅ 能否成功保存处理后的图片"
echo "✅ 错误处理是否合理"
echo ""
echo -e "${GREEN}功能测试完成！${NC}"