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
創建簡單的 docker-compose.yml
cat > /opt/elasticsearch/docker-compose.yml << EOF
version: '3'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.18.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - bootstrap.memory_lock=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - xpack.security.enabled=false
      - cluster.name=elk-cluster
      - node.name=node-1
    volumes:
      - /opt/elasticsearch/data:/usr/share/elasticsearch/data
      - /opt/elasticsearch/logs:/usr/share/elasticsearch/logs
    ports:
      - 9200:9200
    restart: always
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
action.destructive_requires_name: false
EOF

# 創建 jvm.options 配置文件
echo -e "${YELLOW}創建 jvm.options 配置文件...${NC}"
cat > ${ES_DIR}/config/jvm.options << EOF
-Xms512m
-Xmx512m
EOF

# 創建 log4j2.properties 配置文件
echo -e "${YELLOW}創建 log4j2.properties 配置文件...${NC}"
cat > ${ES_DIR}/config/log4j2.properties << EOF
status = error
appender.console.type = Console
appender.console.name = console
appender.console.layout.type = PatternLayout
appender.console.layout.pattern = [%d{ISO8601}][%-5p][%-25c{1.}] [%node_name]%marker %m%n
rootLogger.level = info
rootLogger.appenderRef.console.ref = console
EOF

# 設定適當的權限
echo -e "${YELLOW}設定權限...${NC}"
# 確保目錄存在
mkdir -p ${ES_DIR}/{data,logs,config}

# 設置權限
chown -R 1000:1000 ${ES_DIR}
chmod -R 750 ${ES_DIR}/data
chmod -R 750 ${ES_DIR}/logs
chmod -R 750 ${ES_DIR}/config
chmod 644 ${ES_DIR}/config/elasticsearch.yml
chmod 644 ${ES_DIR}/config/jvm.options
chmod 644 ${ES_DIR}/config/log4j2.properties

echo -e "${GREEN}Elasticsearch 設置完成!${NC}"
echo "配置文件: ${ES_DIR}/config/elasticsearch.yml"
echo "Docker Compose: ${ES_DIR}/docker-compose.yml"
echo -e "${YELLOW}啟動命令: cd ${ES_DIR} && docker compose up -d${NC}"