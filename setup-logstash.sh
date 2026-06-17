#!/bin/bash
# setup-logstash.sh — standalone Logstash setup

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'

ELK_VERSION="${ELK_VERSION:-8.18.0}"
LOGSTASH_DIR="/opt/logstash"
ES_HOST="${ES_HOST:-localhost}"
LS_MEM_MIN="${LS_MEM_MIN:-256m}"
LS_MEM_MAX="${LS_MEM_MAX:-512m}"

echo -e "${YELLOW}Setting up Logstash ${ELK_VERSION}...${NC}"

mkdir -p "${LOGSTASH_DIR}"/{data,config,pipeline}
docker rm -f logstash 2>/dev/null || true

cat > "${LOGSTASH_DIR}/docker-compose.yml" <<EOF
services:
  logstash:
    image: docker.elastic.co/logstash/logstash:${ELK_VERSION}
    container_name: logstash
    network_mode: "host"
    environment:
      - LS_JAVA_OPTS=-Xms${LS_MEM_MIN} -Xmx${LS_MEM_MAX}
      - XPACK_MONITORING_ENABLED=false
    volumes:
      - ${LOGSTASH_DIR}/config/logstash.yml:/usr/share/logstash/config/logstash.yml:ro
      - ${LOGSTASH_DIR}/pipeline:/usr/share/logstash/pipeline:ro
      - ${LOGSTASH_DIR}/data:/usr/share/logstash/data
    ports:
      - "5044:5044"
      - "9600:9600"
    restart: unless-stopped
EOF

cat > "${LOGSTASH_DIR}/config/logstash.yml" <<EOF
http.host: "0.0.0.0"
xpack.monitoring.enabled: false
config.reload.automatic: true
config.reload.interval: 3s
pipeline.workers: 2
pipeline.batch.size: 125
EOF

cat > "${LOGSTASH_DIR}/pipeline/logstash.conf" <<EOF
input {
  beats {
    port => 5044
  }
}

filter {
  # Add your filter rules here
}

output {
  elasticsearch {
    hosts => ["${ES_HOST}:9200"]
    index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
  }
}
EOF

chown -R 1000:1000 "${LOGSTASH_DIR}"
chmod -R 755 "${LOGSTASH_DIR}"
chmod 644 "${LOGSTASH_DIR}/config/logstash.yml"

echo -e "${GREEN}Logstash setup done.${NC}"
echo "Start: cd ${LOGSTASH_DIR} && docker compose up -d"
echo "Edit pipeline: ${LOGSTASH_DIR}/pipeline/logstash.conf"
