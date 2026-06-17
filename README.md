# ELK Stack Install Scripts

Bash scripts to deploy an ELK (Elasticsearch + Logstash + Kibana) stack via Docker Compose on Ubuntu.

## Quick Start (all-in-one)

```bash
# 1. Clone
git clone https://github.com/kerr20801/bash_install-elk.git
cd bash_install-elk

# 2. Adjust version / memory in .env (optional)
cp .env .env.local   # or edit .env directly

# 3. Start everything
docker compose up -d

# 4. Check status
docker compose ps
docker compose logs -f
```

Access:
- Elasticsearch: `http://localhost:9200`
- Kibana: `http://localhost:5601`
- Logstash API: `http://localhost:9600`

> **Note:** `xpack.security.enabled=false` — suitable for internal/dev environments only. For production, enable security and configure TLS + enrollment tokens.

## Per-Component Install (standalone)

Use if you want to run each service on a different host:

```bash
# Run as root or with sudo
bash setup-elasticsearch.sh
bash setup-kibana.sh
bash setup-logstash.sh
```

Each script generates its own `docker-compose.yml` under `/opt/{elasticsearch,kibana,logstash}/`.

Override defaults via environment variables before running:

```bash
ELK_VERSION=8.18.0 ES_HOST=192.168.1.10 bash setup-kibana.sh
```

## Files

| File | Description |
|------|-------------|
| `docker-compose.yml` | All-in-one stack (ES + Kibana + Logstash) |
| `.env` | Version and memory defaults |
| `logstash/pipeline/logstash.conf` | Logstash pipeline (edit to fit your inputs) |
| `logstash/config/logstash.yml` | Logstash settings |
| `setup-elasticsearch.sh` | Standalone ES install |
| `setup-kibana.sh` | Standalone Kibana install |
| `setup-logstash.sh` | Standalone Logstash install |
| `elk-upgrade.sh` | Upgrade components to a new version |
| `cleanup-elk.sh` | Remove ELK stack and data |

## Upgrade

```bash
# Upgrade all components to a specific version
sudo bash elk-upgrade.sh --upgrade 8.19.0

# Remove unused images after upgrade
sudo bash elk-upgrade.sh --clean
```

## Requirements

- Ubuntu 20.04 / 22.04 / 24.04
- Docker Engine 24+ with Compose plugin (`docker compose`)
- 4 GB+ RAM (8 GB+ recommended for all three services)
- `vm.max_map_count=262144` (setup scripts set this automatically)

## License

MIT
