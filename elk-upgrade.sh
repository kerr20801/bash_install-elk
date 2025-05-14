#!/bin/bash
# elk-upgrade.sh - 分散式ELK升級和清理腳本

# 顏色設定
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 配置 - 分開路徑
ES_DIR="/opt/elasticsearch/"
KIBANA_DIR="/opt/kibana"
LOGSTASH_DIR="/opt/logstash"


# 顯示說明
show_help() {
    echo "用法: $0 [選項]"
    echo "選項:"
    echo "  -h, --help             顯示說明"
    echo "  -u, --upgrade VERSION  升級到指定版本（例如: 8.19.0）"
    echo "  -c, --clean            清理舊版本的映像檔"
    echo "範例:"
    echo "  $0 --upgrade 8.19.0    升級到 ELK 8.19.0"
    echo "  $0 --clean             清理舊版本的資源"
}

# 獲取目前版本
get_current_version() {
    local component=$1
    local dir=""
    
    case "$component" in
        "elasticsearch") dir="$ES_DIR" ;;
        "kibana") dir="$KIBANA_DIR" ;;
        "logstash") dir="$LOGSTASH_DIR" ;;
    esac
    
    if [ -f "${dir}/docker-compose.yml" ]; then
        local CURRENT_VERSION=$(grep -o "${component}:[0-9.]*" "${dir}/docker-compose.yml" | cut -d ':' -f2)
        echo $CURRENT_VERSION
    else
        echo "未知"
    fi
}

# 升級指定組件到特定版本
upgrade_component() {
    local component=$1
    local dir=$2
    local new_version=$3
    local current_version=$(get_current_version $component)
    
    echo -e "${YELLOW}開始升級 $component 從 $current_version 到 $new_version${NC}"
    
    # 更新docker-compose.yml中的版本號
    if [ -f "${dir}/docker-compose.yml" ]; then
        echo -e "${YELLOW}更新 ${dir}/docker-compose.yml 中的版本號...${NC}"
        sed -i "s/${component}:${current_version}/${component}:${new_version}/g" ${dir}/docker-compose.yml
    else
        echo -e "${RED}錯誤: ${dir}/docker-compose.yml 不存在${NC}"
        return 1
    fi
    
    # 停止舊容器
    echo -e "${YELLOW}停止 $component 容器...${NC}"
    cd ${dir} && docker compose down
    
    # 啟動新容器
    echo -e "${YELLOW}啟動新版本 $component 容器...${NC}"
    cd ${dir} && docker compose up -d
    
    echo -e "${GREEN}$component 升級完成! 從 $current_version 到 $new_version${NC}"
}

# 升級全部組件
upgrade_all() {
    local new_version=$1
    
    # 依次升級各組件
    upgrade_component "elasticsearch" "$ES_DIR" "$new_version"
    upgrade_component "kibana" "$KIBANA_DIR" "$new_version"
    upgrade_component "logstash" "$LOGSTASH_DIR" "$new_version"
    
    echo -e "${GREEN}所有組件升級完成!${NC}"
    echo -e "${YELLOW}檢查各組件狀態:${NC}"
    echo "docker ps -a | grep elastic"
}

# 清理舊版本映像檔
clean() {
    echo -e "${YELLOW}開始清理舊版本映像檔...${NC}"
    
    # 獲取目前使用的映像檔
    local current_images=$(docker ps -a --format "{{.Image}}" | grep "elastic.co")
    
    # 刪除未使用的映像檔
    docker images | grep "elastic.co" | awk '{print $1":"$2}' | while read image; do
        if ! echo "$current_images" | grep -q "$image"; then
            echo "刪除映像檔: $image"
            docker rmi $image
        fi
    done
    
    echo -e "${GREEN}清理完成!${NC}"
}

# 主函數
main() {
    # 檢查是否有root權限
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}錯誤: 此腳本必須以root權限運行${NC}"
        exit 1
    fi
    
    # 處理命令行參數
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -u|--upgrade)
                if [ -z "$2" ]; then
                    echo -e "${RED}錯誤: 未指定版本號${NC}"
                    exit 1
                fi
                upgrade_all "$2"
                shift
                ;;
            -c|--clean)
                clean
                ;;
            *)
                echo -e "${RED}未知選項: $1${NC}"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# 執行主函數
main "$@"