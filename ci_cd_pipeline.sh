#!/bin/bash

# AI扫描增强应用 CI/CD 验证管道
# 完整的自动化验证工具链

set -e

echo "========================================"
echo "AI扫描增强应用 CI/CD 验证管道"
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目路径
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="AIScanEnhance"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
REPORT_DIR="$PROJECT_DIR/ci_reports_$TIMESTAMP"
LOG_FILE="$REPORT_DIR/ci_cd_pipeline.log"

echo -e "${BLUE}项目路径: $PROJECT_DIR${NC}"
echo -e "${BLUE}报告目录: $REPORT_DIR${NC}"
echo -e "${BLUE}时间戳: $TIMESTAMP${NC}"
echo ""

# 创建报告目录
mkdir -p "$REPORT_DIR"

# 初始化日志
echo "========================================" > "$LOG_FILE"
echo "AI扫描增强应用 CI/CD 验证报告" >> "$LOG_FILE"
echo "开始时间: $(date)" >> "$LOG_FILE"
echo "项目路径: $PROJECT_DIR" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# 验证步骤计数器
STEP=1
TOTAL_STEPS=8
FAILED_STEPS=()
SUCCESS_STEPS=()

# 辅助函数
log_step() {
    local step_name="$1"
    local status="$2"
    local details="$3"
    
    echo "步骤 $STEP/$TOTAL_STEPS: $step_name - $status" >> "$LOG_FILE"
    if [ -n "$details" ]; then
        echo "详情: $details" >> "$LOG_FILE"
    fi
    echo "" >> "$LOG_FILE"
    
    if [ "$status" = "成功" ]; then
        SUCCESS_STEPS+=("$step_name")
    else
        FAILED_STEPS+=("$step_name")
    fi
    
    STEP=$((STEP + 1))
}

run_step() {
    local step_name="$1"
    local command="$2"
    local success_msg="$3"
    local error_msg="$4"
    
    echo -e "${CYAN}步骤 $STEP/$TOTAL_STEPS: $step_name${NC}"
    echo "执行: $command"
    
    if eval "$command" >> "$REPORT_DIR/step_${STEP}_$(echo $step_name | tr ' ' '_').log" 2>&1; then
        echo -e "${GREEN}✅ $success_msg${NC}"
        log_step "$step_name" "成功" "$success_msg"
        return 0
    else
        echo -e "${RED}❌ $error_msg${NC}"
        log_step "$step_name" "失败" "$error_msg"
        return 1
    fi
}

# 步骤1: 环境检查
echo -e "${PURPLE}========== 步骤 $STEP/$TOTAL_STEPS: 环境检查 ==========${NC}"
echo "检查开发环境..."

# 检查Xcode
if command -v xcodebuild >/dev/null 2>&1; then
    XCODE_VERSION=$(xcodebuild -version | head -1)
    echo -e "${GREEN}✅ Xcode已安装: $XCODE_VERSION${NC}"
    log_step "环境检查" "成功" "Xcode已安装: $XCODE_VERSION"
else
    echo -e "${RED}❌ Xcode未安装${NC}"
    log_step "环境检查" "失败" "Xcode未安装"
    exit 1
fi

# 检查项目文件
if [ -f "$PROJECT_DIR/$APP_NAME.xcodeproj/project.pbxproj" ]; then
    echo -e "${GREEN}✅ 项目文件存在${NC}"
else
    echo -e "${RED}❌ 项目文件不存在${NC}"
    log_step "环境检查" "失败" "项目文件不存在"
    exit 1
fi

echo ""

# 步骤2: 代码质量检查
if ! run_step "代码质量检查" \
    "find '$PROJECT_DIR/$APP_NAME' -name '*.swift' -exec swift -frontend -parse {} \;" \
    "Swift代码语法检查通过" \
    "Swift代码存在语法错误"; then
    echo -e "${YELLOW}⚠️  继续执行，但建议修复语法问题${NC}"
fi
echo ""

# 步骤3: 清理构建环境
run_step "清理构建环境" \
    "rm -rf ~/Library/Developer/Xcode/DerivedData && xcodebuild clean -project '$PROJECT_DIR/$APP_NAME.xcodeproj'" \
    "构建环境清理完成" \
    "构建环境清理失败" || exit 1
echo ""

# 步骤4: 项目编译
run_step "项目编译" \
    "xcodebuild -project '$PROJECT_DIR/$APP_NAME.xcodeproj' -scheme '$APP_NAME' -configuration Debug build" \
    "项目编译成功" \
    "项目编译失败" || exit 1
echo ""

# 步骤5: 应用包验证
echo -e "${PURPLE}========== 步骤 $STEP/$TOTAL_STEPS: 应用包验证 ==========${NC}"
APP_BUNDLE=$(find $HOME/Library/Developer/Xcode/DerivedData -name "$APP_NAME.app" -path "*/Build/Products/Debug/*" | head -1)

if [ -d "$APP_BUNDLE" ]; then
    echo -e "${GREEN}✅ 应用包存在: $APP_BUNDLE${NC}"
    
    # 检查应用包结构
    if [ -f "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ] && [ -f "$APP_BUNDLE/Contents/Info.plist" ]; then
        echo -e "${GREEN}✅ 应用包结构正确${NC}"
        log_step "应用包验证" "成功" "应用包结构正确"
    else
        echo -e "${RED}❌ 应用包结构不完整${NC}"
        log_step "应用包验证" "失败" "应用包结构不完整"
        exit 1
    fi
else
    echo -e "${RED}❌ 应用包不存在${NC}"
    log_step "应用包验证" "失败" "应用包不存在"
    exit 1
fi
echo ""

# 步骤6: 启动测试
echo -e "${PURPLE}========== 步骤 $STEP/$TOTAL_STEPS: 启动测试 ==========${NC}"
echo "启动应用进行测试..."

# 启动应用
open "$APP_BUNDLE"
sleep 5

if pgrep -f "$APP_NAME" > /dev/null; then
    APP_PID=$(pgrep -f "$APP_NAME")
    echo -e "${GREEN}✅ 应用启动成功，进程ID: $APP_PID${NC}"
    
    # 稳定性测试
    echo "进行10秒稳定性测试..."
    sleep 10
    
    if pgrep -f "$APP_NAME" > /dev/null; then
        echo -e "${GREEN}✅ 应用运行稳定${NC}"
        log_step "启动测试" "成功" "应用启动并稳定运行"
    else
        echo -e "${RED}❌ 应用运行期间崩溃${NC}"
        log_step "启动测试" "失败" "应用运行期间崩溃"
        exit 1
    fi
else
    echo -e "${RED}❌ 应用启动失败${NC}"
    log_step "启动测试" "失败" "应用启动失败"
    exit 1
fi
echo ""

# 步骤7: 性能测试
echo -e "${PURPLE}========== 步骤 $STEP/$TOTAL_STEPS: 性能测试 ==========${NC}"
echo "进行30秒性能监控..."

# 性能监控
PERF_LOG="$REPORT_DIR/performance_test.log"
echo "时间戳,CPU%,内存MB" > "$PERF_LOG"

for i in {1..30}; do
    if pgrep -f "$APP_NAME" > /dev/null; then
        PERF_DATA=$(ps -p $APP_PID -o pcpu,rss | tail -1)
        CPU=$(echo $PERF_DATA | awk '{print $1}')
        RSS=$(echo $PERF_DATA | awk '{print $2}')
        MEM_MB=$(echo "scale=2; $RSS / 1024" | bc)
        
        TIMESTAMP=$(date '+%H:%M:%S')
        echo "$TIMESTAMP,$CPU,$MEM_MB" >> "$PERF_LOG"
        
        printf "\r进度: %2d/30 | CPU: %5.1f%% | 内存: %6.1fMB" $i $CPU $MEM_MB
    else
        echo -e "\n${RED}❌ 应用在性能测试期间停止运行${NC}"
        log_step "性能测试" "失败" "应用在性能测试期间停止运行"
        break
    fi
    sleep 1
done

echo ""

# 分析性能数据
if [ -f "$PERF_LOG" ] && [ $(wc -l < "$PERF_LOG") -gt 1 ]; then
    AVG_CPU=$(tail -n +2 "$PERF_LOG" | awk -F',' '{sum+=$2; count++} END {if(count>0) print sum/count; else print 0}')
    AVG_MEM=$(tail -n +2 "$PERF_LOG" | awk -F',' '{sum+=$3; count++} END {if(count>0) print sum/count; else print 0}')
    
    echo -e "${GREEN}✅ 性能测试完成${NC}"
    echo "平均CPU使用率: ${AVG_CPU}%"
    echo "平均内存使用: ${AVG_MEM}MB"
    
    log_step "性能测试" "成功" "平均CPU: ${AVG_CPU}%, 平均内存: ${AVG_MEM}MB"
else
    echo -e "${RED}❌ 性能数据收集失败${NC}"
    log_step "性能测试" "失败" "性能数据收集失败"
fi
echo ""

# 步骤8: 清理和报告生成
echo -e "${PURPLE}========== 步骤 $STEP/$TOTAL_STEPS: 清理和报告生成 ==========${NC}"

# 关闭应用
echo "关闭应用..."
pkill -f "$APP_NAME" || true
sleep 2

# 生成最终报告
FINAL_REPORT="$REPORT_DIR/final_report.md"
cat > "$FINAL_REPORT" << EOF
# AI扫描增强应用 CI/CD 验证报告

## 基本信息
- **项目名称**: $APP_NAME
- **验证时间**: $(date)
- **项目路径**: $PROJECT_DIR
- **报告目录**: $REPORT_DIR

## 验证结果摘要
- **总步骤数**: $TOTAL_STEPS
- **成功步骤**: ${#SUCCESS_STEPS[@]}
- **失败步骤**: ${#FAILED_STEPS[@]}
- **成功率**: $(echo "scale=1; ${#SUCCESS_STEPS[@]} * 100 / $TOTAL_STEPS" | bc)%

## 成功的步骤
EOF

for step in "${SUCCESS_STEPS[@]}"; do
    echo "- ✅ $step" >> "$FINAL_REPORT"
done

if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
    echo "" >> "$FINAL_REPORT"
    echo "## 失败的步骤" >> "$FINAL_REPORT"
    for step in "${FAILED_STEPS[@]}"; do
        echo "- ❌ $step" >> "$FINAL_REPORT"
    done
fi

cat >> "$FINAL_REPORT" << EOF

## 性能数据
EOF

if [ -f "$PERF_LOG" ]; then
    echo "- **平均CPU使用率**: ${AVG_CPU:-N/A}%" >> "$FINAL_REPORT"
    echo "- **平均内存使用**: ${AVG_MEM:-N/A}MB" >> "$FINAL_REPORT"
fi

cat >> "$FINAL_REPORT" << EOF

## 建议
- 定期运行此验证管道确保应用质量
- 监控性能指标，及时优化
- 修复任何失败的验证步骤

## 文件清单
- 详细日志: ci_cd_pipeline.log
- 性能数据: performance_test.log
- 各步骤日志: step_*.log
EOF

echo -e "${GREEN}✅ 报告生成完成${NC}"
log_step "清理和报告生成" "成功" "最终报告已生成"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CI/CD 验证管道完成${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "总步骤数: ${YELLOW}$TOTAL_STEPS${NC}"
echo -e "成功步骤: ${GREEN}${#SUCCESS_STEPS[@]}${NC}"
echo -e "失败步骤: ${RED}${#FAILED_STEPS[@]}${NC}"
echo -e "成功率: ${YELLOW}$(echo "scale=1; ${#SUCCESS_STEPS[@]} * 100 / $TOTAL_STEPS" | bc)%${NC}"
echo ""
echo -e "${GREEN}📊 详细报告已保存到: $REPORT_DIR${NC}"
echo -e "${GREEN}📋 查看最终报告: $FINAL_REPORT${NC}"
echo ""

if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
    echo -e "${GREEN}🎉 所有验证步骤都成功完成！应用可以安全部署。${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  有 ${#FAILED_STEPS[@]} 个步骤失败，请检查并修复问题。${NC}"
    exit 1
fi