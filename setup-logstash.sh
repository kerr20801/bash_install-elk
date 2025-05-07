#!/bin/bash
# setup-logstash.sh - Logstash 設置腳本

# 顏色設定
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 共用設定
ELK_VERSION="8.18.0"
LOGSTASH_DIR="/opt/logstash"
ES_HOST="localhost" # 若需更改，請修改此處

echo -e "${YELLOW}開始設置 Logstash...${NC}"

# 創建目錄結構
echo -e "${YELLOW}創建目錄結構...${NC}"
mkdir -p ${LOGSTASH_DIR}/{data,config,pipeline}

# 清理舊的容器（如果存在）
if [ "$(docker ps -a -q -f name=logstash)" ]; then
    echo -e "${YELLOW}移除舊的 Logstash 容器...${NC}"
    docker stop logstash > /dev/null 2>&1
    docker rm logstash > /dev/null 2>&1
fi

# 創建 docker-compose.yml
echo -e "${YELLOW}創建 docker-compose.yml...${NC}"
cat > ${LOGSTASH_DIR}/docker-compose.yml << EOF
services:
  logstash:
    image: docker.elastic.co/logstash/logstash:${ELK_VERSION}
    container_name: logstash
    network_mode: "host"
    environment:
      - "LS_JAVA_OPTS=-Xms256m -Xmx512m"
    volumes:
      - ${LOGSTASH_DIR}/config:/usr/share/logstash/config
      - ${LOGSTASH_DIR}/pipeline:/usr/share/logstash/pipeline
      - ${LOGSTASH_DIR}/data:/usr/share/logstash/data
    restart: always
EOF

# 創建 logstash.yml 配置文件
echo -e "${YELLOW}創建 logstash.yml 配置文件...${NC}"
cat > ${LOGSTASH_DIR}/config/logstash.yml << EOF
# ======================== Logstash Configuration =========================
path.config: /usr/share/logstash/pipeline
path.logs: /usr/share/logstash/logs
path.data: /usr/share/logstash/data
http.host: "0.0.0.0"
http.port: 9600
xpack.monitoring.elasticsearch.hosts: ["http://${ES_HOST}:9200"]
config.reload.automatic: true
config.reload.interval: 3s
pipeline.workers: 2
pipeline.batch.size: 125
pipeline.batch.delay: 50
EOF

# 創建 jvm.options 配置文件
echo -e "${YELLOW}創建 jvm.options 配置文件...${NC}"
cat > ${LOGSTASH_DIR}/config/jvm.options << EOF
## JVM configuration

# Xms represents the initial size of total heap space
# Xmx represents the maximum size of total heap space

-Xms256m
-Xmx512m

## GC configuration
-XX:+UseG1GC
-XX:InitiatingHeapOccupancyPercent=75

## Basic Safety
-XX:+DisableExplicitGC

## Locale
# Set the locale language
-Duser.language=en

# Set the locale country
-Duser.country=US

# Set the locale variant, if any
-Duser.variant=

## Network
# Ensure IPv4 is used instead of IPv6
-Djava.net.preferIPv4Stack=true
EOF

# 創建簡單的測試管道配置
echo -e "${YELLOW}創建測試管道配置...${NC}"
cat > ${LOGSTASH_DIR}/pipeline/logstash.conf << EOF
# 簡單的測試配置
input {
  heartbeat {
    interval => 5
    message => "Logstash is alive!"
  }
}

output {
  elasticsearch {
    hosts => ["${ES_HOST}:9200"]
    index => "logstash-%{+YYYY.MM.dd}"
  }
  stdout { codec => rubydebug }
}
EOF

# 設定適當的權限
echo -e "${YELLOW}設定權限...${NC}"
chown -R 1000:1000 ${LOGSTASH_DIR}
chmod -R 755 ${LOGSTASH_DIR}
chmod 644 ${LOGSTASH_DIR}/config/logstash.yml
chmod 644 ${LOGSTASH_DIR}/config/jvm.options
chmod 644 ${LOGSTASH_DIR}/pipeline/logstash.conf

echo -e "${GREEN}Logstash 設置完成!${NC}"
echo "配置文件: ${LOGSTASH_DIR}/config/logstash.yml"
echo "JVM 配置: ${LOGSTASH_DIR}/config/jvm.options"
echo "管道配置: ${LOGSTASH_DIR}/pipeline/logstash.conf"
echo "Docker Compose: ${LOGSTASH_DIR}/docker-compose.yml"
echo -e "${YELLOW}啟動命令: cd ${LOGSTASH_DIR} && docker compose up -d${NC}"