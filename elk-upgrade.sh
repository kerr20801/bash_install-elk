#!/bin/bash
# elk-upgrade.sh — upgrade ELK components

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'

ES_DIR="${ES_DIR:-/opt/elasticsearch}"
KIBANA_DIR="${KIBANA_DIR:-/opt/kibana}"
LOGSTASH_DIR="${LOGSTASH_DIR:-/opt/logstash}"

show_help() {
    echo "Usage: $0 [options]"
    echo "  -u, --upgrade VERSION   Upgrade all components to VERSION (e.g. 8.19.0)"
    echo "  -c, --clean             Remove unused Elastic images"
    echo "  -h, --help              Show this help"
}

current_version() {
    local dir="$1"
    grep -oP 'elasticsearch:\K[0-9]+\.[0-9]+\.[0-9]+' "${dir}/docker-compose.yml" 2>/dev/null \
        || grep -oP 'kibana:\K[0-9]+\.[0-9]+\.[0-9]+' "${dir}/docker-compose.yml" 2>/dev/null \
        || grep -oP 'logstash:\K[0-9]+\.[0-9]+\.[0-9]+' "${dir}/docker-compose.yml" 2>/dev/null \
        || echo "unknown"
}

upgrade_component() {
    local name="$1" dir="$2" new_ver="$3"
    local compose="${dir}/docker-compose.yml"

    [ -f "$compose" ] || { echo -e "${RED}${compose} not found, skipping${NC}"; return 1; }

    local cur_ver; cur_ver=$(current_version "$dir")
    echo -e "${YELLOW}Upgrading ${name}: ${cur_ver} → ${new_ver}${NC}"

    sed -i "s|elastic\.co/${name}:.*|elastic.co/${name}:${new_ver}|g" "$compose"

    cd "$dir"
    docker compose pull
    docker compose down
    docker compose up -d
    echo -e "${GREEN}${name} upgraded to ${new_ver}${NC}"
}

clean_images() {
    echo -e "${YELLOW}Removing unused Elastic images...${NC}"
    local in_use; in_use=$(docker ps -a --format "{{.Image}}" | grep "elastic.co" || true)
    docker images --format "{{.Repository}}:{{.Tag}}" | grep "elastic.co" | while read -r img; do
        if ! echo "$in_use" | grep -qF "$img"; then
            echo "  removing $img"
            docker rmi "$img"
        fi
    done
    echo -e "${GREEN}Done.${NC}"
}

[ "$(id -u)" = "0" ] || { echo -e "${RED}Run as root${NC}"; exit 1; }
[ $# -eq 0 ] && { show_help; exit 0; }

while [ $# -gt 0 ]; do
    case "$1" in
        -u|--upgrade)
            [ -n "${2:-}" ] || { echo -e "${RED}Version required${NC}"; exit 1; }
            upgrade_component elasticsearch "$ES_DIR"      "$2"
            upgrade_component kibana       "$KIBANA_DIR"   "$2"
            upgrade_component logstash     "$LOGSTASH_DIR" "$2"
            shift ;;
        -c|--clean) clean_images ;;
        -h|--help)  show_help; exit 0 ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; show_help; exit 1 ;;
    esac
    shift
done
