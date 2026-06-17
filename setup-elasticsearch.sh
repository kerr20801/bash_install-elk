#!/bin/bash
# setup-elasticsearch.sh — standalone Elasticsearch setup

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'

ELK_VERSION="${ELK_VERSION:-8.18.0}"
ES_DIR="/opt/elasticsearch"
ES_MEM="${ES_MEM:-512m}"

echo -e "${YELLOW}Setting up Elasticsearch ${ELK_VERSION}...${NC}"

# vm.max_map_count
if [ "$(sysctl -n vm.max_map_count)" -lt 262144 ]; then
    sysctl -w vm.max_map_count=262144
    grep -q vm.max_map_count /etc/sysctl.conf \
        || echo "vm.max_map_count=262144" >> /etc/sysctl.conf
fi

mkdir -p "${ES_DIR}"/{data,logs,config}

# Remove stale container
docker rm -f elasticsearch 2>/dev/null || true

cat > "${ES_DIR}/docker-compose.yml" <<EOF
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:${ELK_VERSION}
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms${ES_MEM} -Xmx${ES_MEM}
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
      - "9200:9200"
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:9200/_cluster/health | grep -qv '\"status\":\"red\"'"]
      interval: 15s
      timeout: 5s
      retries: 12
      start_period: 60s
    restart: unless-stopped
EOF

cat > "${ES_DIR}/config/elasticsearch.yml" <<EOF
cluster.name: "elk-cluster"
node.name: "node-1"
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
xpack.security.enabled: false
path.data: /usr/share/elasticsearch/data
path.logs: /usr/share/elasticsearch/logs
EOF

rm -rf "${ES_DIR}"/data/* "${ES_DIR}"/logs/*
chown -R 1000:1000 "${ES_DIR}"
chmod -R 755 "${ES_DIR}/data" "${ES_DIR}/logs"
chmod -R 750 "${ES_DIR}/config"
chmod 644 "${ES_DIR}/config/elasticsearch.yml" "${ES_DIR}/docker-compose.yml"

echo -e "${GREEN}Elasticsearch setup done.${NC}"
echo "Start: cd ${ES_DIR} && docker compose up -d"
echo "Logs:  docker logs -f elasticsearch"
