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

echo -e "${YELLOW}開始設置 Elasticsearch...${NC}"

# 檢查系統設定
if [ $(sysctl -n vm.max_map_count) -lt 262144 ]; then
    echo -e "${YELLOW}設置系統參數 vm.max_map_count=262144${NC}"
    sysctl -w vm.max_map_count=262144
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf
fi

# 創建目錄結構並確保乾淨的狀態
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
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    volumes:
      - ${ES_DIR}/data:/usr/share/elasticsearch/data
      - ${ES_DIR}/logs:/usr/share/elasticsearch/logs
      - ${ES_DIR}/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
    ports:
      - 9200:9200
    restart: on-failure
EOF

# 創建 elasticsearch.yml 配置文件
echo -e "${YELLOW}創建 elasticsearch.yml 配置文件...${NC}"
cat > ${ES_DIR}/config/elasticsearch.yml << EOF
# ======================== Elasticsearch Configuration =========================
cluster.name: "elk-cluster"
node.name: "node-1"
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
xpack.security.enabled: false
path.data: /usr/share/elasticsearch/data
path.logs: /usr/share/elasticsearch/logs
# 禁用默認的GC日誌配置
logger.org.elasticsearch.bootstrap.Bootstrap.level: info
EOF

# 重置並設定適當的權限
echo -e "${YELLOW}設定權限...${NC}"
# 清理目錄内容以避免舊文件權限問題
rm -rf ${ES_DIR}/data/*
rm -rf ${ES_DIR}/logs/*

# 設置權限 - 重要: elasticsearch容器通常以用戶ID 1000運行
chown -R 1000:1000 ${ES_DIR}
chmod -R 755 ${ES_DIR}/data   # 改為 755 而不是 777
chmod -R 755 ${ES_DIR}/logs   # 改為 755 而不是 777
chmod -R 750 ${ES_DIR}/config
chmod 644 ${ES_DIR}/config/elasticsearch.yml
chmod 644 ${ES_DIR}/docker-compose.yml

echo -e "${GREEN}Elasticsearch 設置完成!${NC}"
echo "配置文件: ${ES_DIR}/config/elasticsearch.yml"
echo "Docker Compose: ${ES_DIR}/docker-compose.yml"
echo -e "${YELLOW}執行以下命令啟動:${NC}"
echo "cd ${ES_DIR} && docker compose down -v && docker compose up -d"
echo -e "${YELLOW}查看日誌:${NC}"
echo "docker logs -f elasticsearch"
