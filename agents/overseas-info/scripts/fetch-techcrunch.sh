#!/bin/bash
# 海外信息Agent - TechCrunch RSS 采集脚本
# 定时：每2小时执行

CACHE_DIR="/root/.openclaw/workspace/agents/overseas-info/cache"
TIMESTAMP=$(date +%Y%m%d_%H%M)

echo "[$(date)] 采集 TechCrunch RSS..."

# TechCrunch RSS
curl -s "https://techcrunch.com/feed/" > "$CACHE_DIR/tc_raw_$TIMESTAMP.xml"

echo "[$(date)] TechCrunch 采集完成"
