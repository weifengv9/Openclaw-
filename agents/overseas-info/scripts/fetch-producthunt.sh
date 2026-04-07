#!/bin/bash
# 海外信息Agent - Product Hunt 采集脚本
# 定时：每4小时执行

CACHE_DIR="/root/.openclaw/workspace/agents/overseas-info/cache"
TIMESTAMP=$(date +%Y%m%d_%H%M)

echo "[$(date)] 采集 Product Hunt..."

# Product Hunt RSS
curl -s "https://www.producthunt.com/feed" > "$CACHE_DIR/ph_raw_$TIMESTAMP.html"

echo "[$(date)] Product Hunt 采集完成"
