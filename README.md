# 🔍 ELK Stack Install Scripts

Bash scripts to install and manage an ELK (Elasticsearch + Logstash + Kibana) stack on Ubuntu.

## Scripts

| Script | Description |
|--------|-------------|
| `setup-elasticsearch.sh` | Install & configure Elasticsearch |
| `setup-logstash.sh` | Install & configure Logstash |
| `setup-kibana.sh` | Install & configure Kibana |
| `elk-upgrade.sh` | Upgrade ELK components |
| `cleanup-elk.sh` | Remove ELK stack |

## Usage

```bash
# Install in order
bash setup-elasticsearch.sh
bash setup-logstash.sh
bash setup-kibana.sh
```

## Requirements

- Ubuntu 20.04 / 22.04
- 4GB+ RAM recommended

## License

MIT
