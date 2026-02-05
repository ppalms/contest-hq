# Quick Reference - Production Operations

## Server Details

- **Provider:** Hetzner Cloud
- **Type:** CX32 (4 vCPU, 8GB RAM)
- **Location:** Falkenstein (fsn1)
- **IP:** Update after provisioning
- **Cost:** €10.19/month

## Access

| Service | URL | Credentials |
|---------|-----|-------------|
| Application | https://contesthq.app | User accounts |
| Grafana | https://metrics.contesthq.app | admin / (in 1Password) |
| Prometheus | http://SERVER_IP:9090 | No auth |
| SSH | ssh deploy@SERVER_IP | SSH key |

## Common Commands

### Application Management

```bash
# Deploy updates
git push
kamal deploy

# View logs
kamal app logs -f

# Restart application
kamal app restart

# Open Rails console
kamal app exec -i 'bin/rails console'

# Run database migrations
kamal app exec -i 'bin/rails db:migrate'
```

### Backup Operations

```bash
# Run manual backup
kamal app exec -i 'bin/rails backup:run'

# List backups
kamal app exec -i 'bin/rails backup:list'

# Restore backup
kamal app exec -i 'bin/rails backup:restore[TIMESTAMP]'

# Verify backup
kamal app exec -i 'bin/rails backup:verify[TIMESTAMP]'
```

### Monitoring Operations

```bash
# SSH to server
ssh deploy@SERVER_IP

# View monitoring logs
cd /opt/monitoring
docker compose logs -f

# Restart monitoring
docker compose restart

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
```

### Health Checks

```bash
# Application health
curl https://contesthq.app/up

# Metrics endpoint
curl http://SERVER_IP:9394/metrics | head -20

# Prometheus health
curl http://SERVER_IP:9090/-/healthy

# Grafana health
curl http://SERVER_IP:3001/api/health
```

## Grafana Dashboards

**Imported Dashboards:**
- ID 14133 - Rails Application Metrics
- ID 14134 - Puma Server Metrics

**Key Metrics to Watch:**
- Request rate
- Error rate (should be <1%)
- Response time (p95 should be <1s)
- Puma thread pool usage
- Background job queue depth

## Troubleshooting

### App Not Responding

```bash
kamal app logs --tail 100
kamal app restart
```

### High Memory Usage

```bash
# Check container stats
kamal app exec 'ps aux --sort=-%mem | head -10'

# Restart if needed
kamal app restart
```

### Metrics Not Updating

```bash
# Check OTel Collector
kamal accessory logs otel_collector
kamal accessory restart otel_collector

# Check metrics endpoint
curl http://SERVER_IP:9394/metrics
```

### Background Jobs Stuck

```bash
# Check Solid Queue
kamal app exec -i 'bin/rails runner "puts SolidQueue::Job.count"'

# View failed jobs
kamal app exec -i 'bin/rails runner "puts SolidQueue::FailedExecution.last(10).map(&:error)"'
```

## Emergency Contacts

- **Primary:** [Your contact info]
- **Hetzner Support:** https://console.hetzner.cloud/support
- **DNS Provider:** [Your DNS provider]

## Important Files

| File | Purpose |
|------|---------|
| `config/deploy.yml` | Kamal deployment config |
| `config/credentials/production.yml.enc` | Rails app secrets (encrypted) |
| `/opt/monitoring/.env` | Monitoring stack secrets (on server) |
| `docs/DEPLOYMENT-GUIDE.md` | Full deployment guide |
| `docs/hetzner-migration.md` | Migration procedure |
| `docs/monitoring-runbook.md` | Monitoring operations |
| `docs/disaster-recovery.md` | Backup/restore procedures |

## Credential Management

**Rails Application Secrets:**
- Location: `config/credentials/production.yml.enc`
- Contains: Database, AWS SES, Hetzner Object Storage credentials
- Access: `bin/rails credentials:show --environment production`

**Monitoring Stack Secrets:**
- Location: `/opt/monitoring/.env` (on server only)
- Contains: Grafana admin password
- Master copy: 1Password
- Note: Monitoring runs independently via Docker Compose

## Monitoring Alerts (Future)

To be configured:
- Error rate >1%
- Response time p95 >1s
- Worker saturation >80%
- Disk space >80%
- Job queue >100

## Backup Schedule

- **Daily:** 3am UTC (automated)
- **Cleanup:** Sundays 4am UTC (automated)
- **Retention:** 30 days
- **Location:** Hetzner Object Storage

## Maintenance Windows

- **Preferred:** Sundays 2-4am UTC
- **Emergency:** Anytime with notification

## Scaling Plan

**When to scale to CX42:**
- First paying customer goes live
- CPU usage consistently >70%
- Memory usage consistently >80%
- Response times degrading

**CX42 Specs:**
- 8 vCPU, 16GB RAM
- Cost: €16.49/month
- Zero-downtime upgrade via Kamal
