#!/bin/bash
# setup-kibana.sh - Kibana 設置腳本

# 顏色設定
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 共用設定
ELK_VERSION="8.18.0"
KIBANA_DIR="/opt/kibana"
ES_HOST="localhost" # 若需更改，請修改此處

echo -e "${YELLOW}開始設置 Kibana...${NC}"

# 創建目錄結構
echo -e "${YELLOW}創建目錄結構...${NC}"
mkdir -p ${KIBANA_DIR}/{data,config}

# 清理舊的容器（如果存在）
if [ "$(docker ps -a -q -f name=kibana)" ]; then
    echo -e "${YELLOW}移除舊的 Kibana 容器...${NC}"
    docker stop kibana > /dev/null 2>&1
    docker rm kibana > /dev/null 2>&1
fi

# 創建 docker-compose.yml
echo -e "${YELLOW}創建 docker-compose.yml...${NC}"
cat > ${KIBANA_DIR}/docker-compose.yml << EOF
services:
  kibana:
    image: docker.elastic.co/kibana/kibana:${ELK_VERSION}
    container_name: kibana
    network_mode: "host"
    environment:
      - ELASTICSEARCH_HOSTS=http://${ES_HOST}:9200
    volumes:
      - ${KIBANA_DIR}/data:/usr/share/kibana/data
      - ${KIBANA_DIR}/config:/usr/share/kibana/config
    restart: always
EOF

# 創建 kibana.yml 配置文件
echo -e "${YELLOW}創建 kibana.yml 配置文件...${NC}"
cat > ${KIBANA_DIR}/config/kibana.yml << EOF
# ======================== Kibana Configuration =========================
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://${ES_HOST}:9200"]
monitoring.ui.container.elasticsearch.enabled: true
telemetry.enabled: false
i18n.locale: "zh-TW"
EOF

# 設定適當的權限
echo -e "${YELLOW}設定權限...${NC}"
chown -R 1000:1000 ${KIBANA_DIR}
chmod -R 755 ${KIBANA_DIR}
chmod 644 ${KIBANA_DIR}/config/kibana.yml

echo -e "${GREEN}Kibana 設置完成!${NC}"
echo "配置文件: ${KIBANA_DIR}/config/kibana.yml"
echo "Docker Compose: ${KIBANA_DIR}/docker-compose.yml"
echo -e "${YELLOW}啟動命令: cd ${KIBANA_DIR} && docker compose up -d${NC}"
