# Contest HQ Monitoring Stack

Prometheus + Grafana monitoring for Contest HQ production.

## Quick Start

1. Create `.env` file:
   ```bash
   cp .env.example .env
   # Edit .env and set GRAFANA_ADMIN_PASSWORD
   ```

2. Update `prometheus.yml` with your server IP:
   ```bash
   sed -i "s/<HETZNER_IP>/$(curl -s ifconfig.me)/g" prometheus.yml
   ```

3. Deploy:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

4. Access Grafana:
   - URL: http://localhost:3001
   - Username: admin
   - Password: (from .env)

## Management

```bash
# View logs
docker compose logs -f

# Restart services
docker compose restart

# Stop services
docker compose down

# Update services
docker compose pull
docker compose up -d
```

## Dashboards

Import these Grafana dashboard IDs:
- 14133 - Yabeda Rails Metrics
- 14134 - Yabeda Puma Metrics

## Troubleshooting

### Prometheus not scraping

Check targets: http://localhost:9090/targets

### Grafana not accessible

```bash
docker compose logs grafana
docker compose restart grafana
```
