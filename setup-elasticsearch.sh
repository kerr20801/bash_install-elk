#!/bin/bash
# setup-elasticsearch.sh - Elasticsearch 設置腳本

# 顏色設定
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 共用設定
ELK_VERSION="8.18.0"
ES_DIR="/opt/elasticsearch"
ES_CONTAINER_DATA_DIR="/usr/share/elasticsearch/data"
ES_CONTAINER_LOGS_DIR="/usr/share/elasticsearch/logs"
ES_CONTAINER_CONFIG_DIR="/usr/share/elasticsearch/config"

echo -e "${YELLOW}開始設置 Elasticsearch...${NC}"

# 檢查系統設定
if [ $(sysctl -n vm.max_map_count) -lt 262144 ]; then
    echo -e "${YELLOW}設置系統參數 vm.max_map_count=262144${NC}"
    sysctl -w vm.max_map_count=262144
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf
fi

# 創建目錄結構
echo -e "${YELLOW}創建目錄結構...${NC}"
mkdir -p ${ES_DIR}/{data,logs,config}

# 清理舊的容器（如果存在）
if [ "$(docker ps -a -q -f name=elasticsearch)" ]; then
    echo -e "${YELLOW}移除舊的 Elasticsearch 容器...${NC}"
    docker stop elasticsearch > /dev/null 2>&1
    docker rm elasticsearch > /dev/null 2>&1
fi

# 創建 docker-compose.yml
echo -e "${YELLOW}創建 docker-compose.yml...${NC}"
cat > ${ES_DIR}/docker-compose.yml << EOF
version: '3'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:${ELK_VERSION}
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - bootstrap.memory_lock=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - xpack.security.enabled=false
      - cluster.name=elk-cluster
      - node.name=node-1
    volumes:
      - ${ES_DIR}/data:${ES_CONTAINER_DATA_DIR}
      - ${ES_DIR}/logs:${ES_CONTAINER_LOGS_DIR}
    ports:
      - 9200:9200
      - 9300:9300
    restart: always
EOF

# 設定適當的權限
echo -e "${YELLOW}設定權限...${NC}"

# 確保目錄存在
mkdir -p ${ES_DIR}/{data,logs,config}

# 創建所需的子目錄
mkdir -p ${ES_DIR}/data/nodes
mkdir -p ${ES_DIR}/logs/gc.log

# 設置權限（elasticsearch 通常使用 uid:gid = 1000:1000）
chown -R 1000:1000 ${ES_DIR}
chmod -R 750 ${ES_DIR}/data
chmod -R 750 ${ES_DIR}/logs
chmod -R 750 ${ES_DIR}/config

echo -e "${GREEN}Elasticsearch 設置完成!${NC}"
echo "數據目錄: ${ES_DIR}/data"
echo "日誌目錄: ${ES_DIR}/logs"
echo "配置目錄: ${ES_DIR}/config"
echo "Docker Compose: ${ES_DIR}/docker-compose.yml"
echo -e "${YELLOW}啟動命令: cd ${ES_DIR} && docker compose up -d${NC}"