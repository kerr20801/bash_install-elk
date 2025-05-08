#!/bin/bash
# cleanup-elk.sh - 清除 ELK 堆疊的腳本

# 顏色設定
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}開始清除 ELK 堆疊...${NC}"

# 停止並刪除相關容器
echo -e "${YELLOW}停止並刪除 Docker 容器...${NC}"
docker stop elasticsearch kibana logstash 2>/dev/null
docker rm elasticsearch kibana logstash 2>/dev/null

# 可選：刪除相關網絡
echo -e "${YELLOW}刪除相關 Docker 網絡...${NC}"
docker network rm elasticsearch_default kibana_default logstash_default 2>/dev/null

# 刪除 /opt 下的 ELK 相關目錄
echo -e "${YELLOW}刪除 /opt 下的 ELK 文件...${NC}"
rm -rf /opt/elasticsearch
rm -rf /opt/kibana
rm -rf /opt/logstash

# 驗證刪除操作
if [ ! -d "/opt/elasticsearch" ] && [ ! -d "/opt/kibana" ] && [ ! -d "/opt/logstash" ]; then
    echo -e "${GREEN}ELK 堆疊文件已成功刪除${NC}"
else
    echo -e "${RED}刪除操作未完全成功，可能有一些文件仍然存在${NC}"
fi

# 檢查 Docker 容器是否已刪除
if [ -z "$(docker ps -a -q -f name=elasticsearch)" ] && [ -z "$(docker ps -a -q -f name=kibana)" ] && [ -z "$(docker ps -a -q -f name=logstash)" ]; then
    echo -e "${GREEN}所有 ELK 容器已成功刪除${NC}"
else
    echo -e "${RED}容器刪除操作未完全成功，可能有一些容器仍然存在${NC}"
    docker ps -a | grep -E 'elasticsearch|kibana|logstash'
fi

echo -e "${GREEN}清除操作完成！${NC}"
echo -e "${YELLOW}現在您可以重新運行設置腳本來重新安裝 ELK 堆疊。${NC}"