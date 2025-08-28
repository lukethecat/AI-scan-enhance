#!/bin/bash

# AI扫描增强应用性能监控脚本
# 用于监控应用的性能和资源使用情况

set -e

echo "========================================"
echo "AI扫描增强应用性能监控"
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
MONITOR_DURATION=60  # 监控时长（秒）
LOG_FILE="/tmp/${APP_NAME}_performance.log"

echo -e "${BLUE}项目路径: $PROJECT_DIR${NC}"
echo -e "${BLUE}监控时长: $MONITOR_DURATION 秒${NC}"
echo -e "${BLUE}日志文件: $LOG_FILE${NC}"
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

# 启动应用
echo ""
echo -e "${YELLOW}启动应用${NC}"
open "$APP_BUNDLE"
sleep 5

# 检查应用是否正在运行
if ! pgrep -f "$APP_NAME" > /dev/null; then
    echo -e "${RED}❌ 应用启动失败${NC}"
    exit 1
fi

APP_PID=$(pgrep -f "$APP_NAME")
echo -e "${GREEN}✅ 应用启动成功，进程ID: $APP_PID${NC}"

# 初始化日志文件
echo "========================================" > "$LOG_FILE"
echo "AI扫描增强应用性能监控报告" >> "$LOG_FILE"
echo "开始时间: $(date)" >> "$LOG_FILE"
echo "应用PID: $APP_PID" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# 获取初始系统信息
echo -e "${YELLOW}收集系统信息${NC}"
echo "系统信息:" >> "$LOG_FILE"
echo "操作系统: $(sw_vers -productName) $(sw_vers -productVersion)" >> "$LOG_FILE"
echo "处理器: $(sysctl -n machdep.cpu.brand_string)" >> "$LOG_FILE"
echo "内存: $(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024 " GB"}')" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# 获取应用初始状态
echo "应用初始状态:" >> "$LOG_FILE"
ps -p $APP_PID -o pid,ppid,pcpu,pmem,vsz,rss,comm >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo -e "${GREEN}✅ 开始性能监控（${MONITOR_DURATION}秒）${NC}"
echo "监控期间请正常使用应用..."
echo ""

# 性能监控循环
START_TIME=$(date +%s)
COUNTER=0
MAX_CPU=0
MAX_MEMORY=0
TOTAL_CPU=0
TOTAL_MEMORY=0
SAMPLE_COUNT=0

echo "时间戳,CPU%,内存MB,虚拟内存MB,线程数" >> "$LOG_FILE"

while [ $COUNTER -lt $MONITOR_DURATION ]; do
    if pgrep -f "$APP_NAME" > /dev/null; then
        # 获取性能数据
        PERF_DATA=$(ps -p $APP_PID -o pcpu,pmem,vsz,rss,thcount | tail -1)
        
        if [ -n "$PERF_DATA" ]; then
            CPU=$(echo $PERF_DATA | awk '{print $1}')
            MEM_PERCENT=$(echo $PERF_DATA | awk '{print $2}')
            VSZ=$(echo $PERF_DATA | awk '{print $3}')
            RSS=$(echo $PERF_DATA | awk '{print $4}')
            THREADS=$(echo $PERF_DATA | awk '{print $5}')
            
            # 转换内存单位（KB to MB）
            MEM_MB=$(echo "scale=2; $RSS / 1024" | bc)
            VSZ_MB=$(echo "scale=2; $VSZ / 1024" | bc)
            
            # 记录到日志
            TIMESTAMP=$(date '+%H:%M:%S')
            echo "$TIMESTAMP,$CPU,$MEM_MB,$VSZ_MB,$THREADS" >> "$LOG_FILE"
            
            # 更新统计
            if (( $(echo "$CPU > $MAX_CPU" | bc -l) )); then
                MAX_CPU=$CPU
            fi
            
            if (( $(echo "$MEM_MB > $MAX_MEMORY" | bc -l) )); then
                MAX_MEMORY=$MEM_MB
            fi
            
            TOTAL_CPU=$(echo "$TOTAL_CPU + $CPU" | bc)
            TOTAL_MEMORY=$(echo "$TOTAL_MEMORY + $MEM_MB" | bc)
            SAMPLE_COUNT=$((SAMPLE_COUNT + 1))
            
            # 显示实时数据
            printf "\r时间: %02d:%02d | CPU: %5.1f%% | 内存: %6.1fMB | 线程: %2d" \
                   $((COUNTER / 60)) $((COUNTER % 60)) $CPU $MEM_MB $THREADS
        fi
    else
        echo -e "\n${RED}❌ 应用已停止运行${NC}"
        break
    fi
    
    sleep 1
    COUNTER=$((COUNTER + 1))
done

echo ""
echo ""

# 计算平均值
if [ $SAMPLE_COUNT -gt 0 ]; then
    AVG_CPU=$(echo "scale=2; $TOTAL_CPU / $SAMPLE_COUNT" | bc)
    AVG_MEMORY=$(echo "scale=2; $TOTAL_MEMORY / $SAMPLE_COUNT" | bc)
else
    AVG_CPU=0
    AVG_MEMORY=0
fi

# 生成性能报告
echo "" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
echo "性能统计摘要" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
echo "监控时长: $COUNTER 秒" >> "$LOG_FILE"
echo "采样次数: $SAMPLE_COUNT" >> "$LOG_FILE"
echo "平均CPU使用率: ${AVG_CPU}%" >> "$LOG_FILE"
echo "最大CPU使用率: ${MAX_CPU}%" >> "$LOG_FILE"
echo "平均内存使用: ${AVG_MEMORY}MB" >> "$LOG_FILE"
echo "最大内存使用: ${MAX_MEMORY}MB" >> "$LOG_FILE"
echo "结束时间: $(date)" >> "$LOG_FILE"

# 检查内存泄漏
echo "" >> "$LOG_FILE"
echo "内存泄漏检查:" >> "$LOG_FILE"
if [ $SAMPLE_COUNT -gt 10 ]; then
    # 获取前10%和后10%的内存使用情况
    EARLY_SAMPLES=$((SAMPLE_COUNT / 10))
    LATE_START=$((SAMPLE_COUNT * 9 / 10))
    
    EARLY_MEM=$(tail -n +2 "$LOG_FILE" | head -n $EARLY_SAMPLES | awk -F',' '{sum+=$3; count++} END {if(count>0) print sum/count; else print 0}')
    LATE_MEM=$(tail -n +2 "$LOG_FILE" | tail -n $EARLY_SAMPLES | awk -F',' '{sum+=$3; count++} END {if(count>0) print sum/count; else print 0}')
    
    MEM_INCREASE=$(echo "scale=2; $LATE_MEM - $EARLY_MEM" | bc)
    
    echo "初期平均内存: ${EARLY_MEM}MB" >> "$LOG_FILE"
    echo "后期平均内存: ${LATE_MEM}MB" >> "$LOG_FILE"
    echo "内存增长: ${MEM_INCREASE}MB" >> "$LOG_FILE"
    
    if (( $(echo "$MEM_INCREASE > 50" | bc -l) )); then
        echo "⚠️  检测到可能的内存泄漏" >> "$LOG_FILE"
    else
        echo "✅ 未检测到明显的内存泄漏" >> "$LOG_FILE"
    fi
else
    echo "样本数量不足，无法进行内存泄漏检查" >> "$LOG_FILE"
fi

# 显示性能报告
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}性能监控报告${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "监控时长: ${YELLOW}$COUNTER 秒${NC}"
echo -e "采样次数: ${YELLOW}$SAMPLE_COUNT${NC}"
echo -e "平均CPU使用率: ${YELLOW}${AVG_CPU}%${NC}"
echo -e "最大CPU使用率: ${YELLOW}${MAX_CPU}%${NC}"
echo -e "平均内存使用: ${YELLOW}${AVG_MEMORY}MB${NC}"
echo -e "最大内存使用: ${YELLOW}${MAX_MEMORY}MB${NC}"

# 性能评估
echo ""
echo -e "${BLUE}性能评估:${NC}"

# CPU性能评估
if (( $(echo "$AVG_CPU < 20" | bc -l) )); then
    echo -e "CPU使用率: ${GREEN}✅ 优秀 (平均 ${AVG_CPU}%)${NC}"
elif (( $(echo "$AVG_CPU < 50" | bc -l) )); then
    echo -e "CPU使用率: ${YELLOW}⚠️  良好 (平均 ${AVG_CPU}%)${NC}"
else
    echo -e "CPU使用率: ${RED}❌ 需要优化 (平均 ${AVG_CPU}%)${NC}"
fi

# 内存性能评估
if (( $(echo "$AVG_MEMORY < 100" | bc -l) )); then
    echo -e "内存使用: ${GREEN}✅ 优秀 (平均 ${AVG_MEMORY}MB)${NC}"
elif (( $(echo "$AVG_MEMORY < 200" | bc -l) )); then
    echo -e "内存使用: ${YELLOW}⚠️  良好 (平均 ${AVG_MEMORY}MB)${NC}"
else
    echo -e "内存使用: ${RED}❌ 需要优化 (平均 ${AVG_MEMORY}MB)${NC}"
fi

# 稳定性评估
if pgrep -f "$APP_NAME" > /dev/null; then
    echo -e "应用稳定性: ${GREEN}✅ 应用运行稳定${NC}"
else
    echo -e "应用稳定性: ${RED}❌ 应用运行期间崩溃${NC}"
fi

echo ""
echo -e "${GREEN}详细性能数据已保存到: $LOG_FILE${NC}"
echo ""
echo "建议:"
echo "- 如果CPU使用率过高，考虑优化图像处理算法"
echo "- 如果内存使用过多，检查是否存在内存泄漏"
echo "- 定期进行性能监控以确保应用性能稳定"
echo ""
echo -e "${GREEN}性能监控完成！${NC}"

# 关闭应用（可选）
echo ""
read -p "是否关闭应用？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "关闭应用..."
    pkill -f "$APP_NAME" || true
    echo -e "${GREEN}应用已关闭${NC}"
fi