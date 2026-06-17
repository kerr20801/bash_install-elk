#!/bin/bash
# setup-kibana.sh — standalone Kibana setup

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'

ELK_VERSION="${ELK_VERSION:-8.18.0}"
KIBANA_DIR="/opt/kibana"
ES_HOST="${ES_HOST:-localhost}"

echo -e "${YELLOW}Setting up Kibana ${ELK_VERSION}...${NC}"

mkdir -p "${KIBANA_DIR}"/{data,config}
docker rm -f kibana 2>/dev/null || true

cat > "${KIBANA_DIR}/docker-compose.yml" <<EOF
services:
  kibana:
    image: docker.elastic.co/kibana/kibana:${ELK_VERSION}
    container_name: kibana
    network_mode: "host"
    environment:
      - ELASTICSEARCH_HOSTS=http://${ES_HOST}:9200
      - TELEMETRY_ENABLED=false
      - I18N_LOCALE=zh-TW
    volumes:
      - ${KIBANA_DIR}/data:/usr/share/kibana/data
      - ${KIBANA_DIR}/config/kibana.yml:/usr/share/kibana/config/kibana.yml
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:5601/api/status | grep -q '\"level\":\"available\"'"]
      interval: 20s
      timeout: 5s
      retries: 12
      start_period: 90s
    restart: unless-stopped
EOF

cat > "${KIBANA_DIR}/config/kibana.yml" <<EOF
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://${ES_HOST}:9200"]
telemetry.enabled: false
i18n.locale: "zh-TW"
EOF

chown -R 1000:1000 "${KIBANA_DIR}"
chmod -R 755 "${KIBANA_DIR}"
chmod 644 "${KIBANA_DIR}/config/kibana.yml"

echo -e "${GREEN}Kibana setup done.${NC}"
echo "Start: cd ${KIBANA_DIR} && docker compose up -d"
