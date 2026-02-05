# Contest HQ Architecture

## System Overview

Contest HQ runs on a single Hetzner CX32 server with two independent stacks:

1. **Rails Application** (managed by Kamal)
2. **Monitoring Stack** (managed by Docker Compose)

```
┌─────────────────────────────────────────────────────────────┐
│ Hetzner CX32 Server                                         │
│ 4 vCPU, 8GB RAM, 80GB SSD                                   │
│ Location: Falkenstein (fsn1)                                │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Kamal Proxy (Traefik)                                │   │
│  │ - SSL termination (Let's Encrypt)                    │   │
│  │ - contesthq.app → Rails app                          │   │
│  │ - metrics.contesthq.app → Grafana                    │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌────────────────────────┐  ┌─────────────────────────┐    │
│  │ Rails Application      │  │ Monitoring Stack        │    │
│  │ (Kamal/Docker)         │  │ (Docker Compose)        │    │
│  │                        │  │                         │    │
│  │ ┌────────────────────┐ │  │ ┌─────────────────────┐ │    │
│  │ │ Web Container      │ │  │ │ Prometheus          │ │    │
│  │ │ - Rails 8.1        │ │  │ │ - Metrics storage   │ │    │
│  │ │ - Puma server      │ │  │ │ - 30-day retention  │ │    │
│  │ │ - Solid Queue      │ │  │ │ - Port 9090         │ │    │
│  │ │ - Yabeda metrics   │ │  │ └─────────────────────┘ │    │
│  │ │ - Port 3000        │ │  │                         │    │
│  │ │ - Port 9394        │ │  │ ┌─────────────────────┐ │    │
│  │ └────────────────────┘ │  │ │ Grafana             │ │    │
│  │                        │  │ │ - Dashboards        │ │    │
│  │ ┌────────────────────┐ │  │ │ - Visualization     │ │    │
│  │ │ OTel Collector     │ │  │ │ - Port 3001         │ │    │
│  │ │ - Aggregates       │ │  │ └─────────────────────┘ │    │
│  │ │   metrics          │ │  │                         │    │
│  │ │ - Port 9394        │ │  └─────────────────────────┘    │
│  │ └────────────────────┘ │                                 │
│  │                        │                                 │
│  │ Volume:                │  Volumes:                       │
│  │ - contest_hq_storage   │  - prometheus_data              │
│  │   (SQLite databases)   │  - grafana_data                 │
│  └────────────────────────┘                                 │
│                                                              │
│  External Services:                                          │
│  - Hetzner Object Storage (backups)                         │
│  - AWS SES (email)                                           │
└──────────────────────────────────────────────────────────────┘
```

---

## Component Details

### Rails Application Stack

**Deployment:** Kamal (Docker-based)  
**Management:** `kamal` CLI from local machine  
**Configuration:** `config/deploy.yml`

**Components:**
- **Web Container:** Rails app with Puma server
- **OTel Collector:** Metrics aggregation accessory
- **Kamal Proxy:** Traefik reverse proxy with SSL

**Data Storage:**
- SQLite databases in Docker volume `contest_hq_storage`
- Backed up daily to Hetzner Object Storage

**Secrets:**
- Stored in: `config/credentials/production.yml.enc`
- Contains: Database config, AWS SES, Hetzner Object Storage
- Accessed via: `Rails.application.credentials`

---

### Monitoring Stack

**Deployment:** Docker Compose  
**Management:** SSH to server, `docker compose` commands  
**Configuration:** `monitoring/docker-compose.yml`  
**Location on server:** `/opt/monitoring/`

**Components:**
- **Prometheus:** Metrics storage and querying
- **Grafana:** Dashboard visualization

**Data Storage:**
- Prometheus data in Docker volume `prometheus_data`
- Grafana data in Docker volume `grafana_data`

**Secrets:**
- Stored in: `/opt/monitoring/.env` (on server only)
- Contains: Grafana admin password
- Master copy: 1Password
- **NOT in Rails credentials** (monitoring is independent)

---

## Why Two Separate Stacks?

### Rails Application (Kamal)
- **Purpose:** Run the web application
- **Lifecycle:** Deployed frequently (code changes)
- **Managed by:** Developers via `kamal deploy`
- **Secrets:** Rails credentials (encrypted, version controlled)

### Monitoring Stack (Docker Compose)
- **Purpose:** Observe the application
- **Lifecycle:** Deployed once, rarely changes
- **Managed by:** Ops via SSH + `docker compose`
- **Secrets:** `.env` file (not version controlled)

**Benefits of separation:**
- ✅ Monitoring survives app deployments
- ✅ Can monitor app even if app is broken
- ✅ Independent scaling and management
- ✅ Clear separation of concerns
- ✅ Simpler secret management (no cross-dependencies)

---

## Data Flow

### Application Metrics Flow

```
Rails App (Yabeda)
    ↓ exposes metrics on port 9394
OTel Collector
    ↓ scrapes via Docker service discovery
    ↓ aggregates from all containers
    ↓ exposes on port 9394
Prometheus
    ↓ scrapes every 15 seconds
    ↓ stores for 30 days
Grafana
    ↓ queries Prometheus
    ↓ displays dashboards
User Browser
```

### Backup Flow

```
Rails App
    ↓ daily at 3am UTC
BackupJob (Solid Queue)
    ↓ runs BackupService
SQLite VACUUM INTO
    ↓ creates consistent backup
Upload to Hetzner Object Storage
    ↓ stored for 30 days
BackupCleanupJob (weekly)
    ↓ deletes old backups
```

---

## Secret Management

### Rails Application Secrets

**Storage:** `config/credentials/production.yml.enc`  
**Encryption:** Rails master key  
**Access:** `bin/rails credentials:edit --environment production`

**Contains:**
```yaml
backup:
  s3_access_key_id: xxx
  s3_secret_access_key: xxx
  s3_bucket: contest-hq-backups
  s3_endpoint: https://fsn1.your-objectstorage.com
  s3_region: auto

aws_ses:
  user_name: xxx
  password: xxx
```

### Monitoring Stack Secrets

**Storage:** `/opt/monitoring/.env` (on server only)  
**Encryption:** None (file permissions only)  
**Access:** SSH to server, `cat /opt/monitoring/.env`

**Contains:**
```bash
GRAFANA_ADMIN_PASSWORD=K7mP9xR2vN8qL4wE6tY3sA1zF5hJ0uC9
```

**Master Copy:** 1Password

**Why separate?**
- Monitoring stack runs via Docker Compose (not Kamal)
- Docker Compose needs environment variables
- No need to couple monitoring secrets to Rails app
- Simpler: one source of truth (1Password → `.env`)

---

## Network Ports

| Port | Service | Access | Purpose |
|------|---------|--------|---------|
| 22 | SSH | Restricted | Server management |
| 80 | HTTP | Public | Redirects to HTTPS |
| 443 | HTTPS | Public | Rails app (contesthq.app) |
| 443 | HTTPS | Public | Grafana (metrics.contesthq.app) |
| 3000 | Rails | Internal | Puma server (behind proxy) |
| 3001 | Grafana | Internal | Grafana UI (behind proxy) |
| 9090 | Prometheus | Internal | Metrics storage |
| 9394 | Metrics | Internal | OTel Collector endpoint |

**Firewall (ufw):**
- Allow: 22, 80, 443, 9394
- Deny: All other inbound

---

## Deployment Workflows

### Deploy Application Updates

```bash
# From local machine
git push
kamal deploy
```

**What happens:**
1. Builds Docker image locally
2. Pushes to Docker Hub
3. Pulls on server
4. Runs database migrations
5. Starts new container
6. Stops old container (zero-downtime)
7. OTel Collector continues running

**Monitoring:** Unaffected, continues collecting metrics

---

### Deploy Monitoring Updates

```bash
# SSH to server
ssh deploy@<SERVER_IP>
cd /opt/monitoring

# Update configuration
nano docker-compose.yml  # or prometheus.yml, etc.

# Restart
docker compose restart

# Or full redeploy
docker compose down
docker compose up -d
```

**Application:** Unaffected, continues running

---

## Scaling Strategy

### Current: CX32 (4 vCPU, 8GB RAM)
- **Good for:** Development, beta testing, first customers
- **Cost:** €10.19/month

### Future: CX42 (8 vCPU, 16GB RAM)
- **When:** First paying customer goes live
- **Cost:** €16.49/month
- **Upgrade:** Zero-downtime via Kamal

### Horizontal Scaling (Future)
When single server isn't enough:

1. **Add job server:**
   ```yaml
   servers:
     web:
       - server1.example.com
     job:
       - server2.example.com
   ```

2. **Move monitoring to separate server:**
   - Dedicated monitoring server
   - Scrapes multiple app servers
   - Centralized observability

3. **Add load balancer:**
   - Multiple web servers
   - Hetzner Load Balancer
   - Session affinity via Solid Cable

---

## Backup & Recovery

### What Gets Backed Up

**Automated (Daily):**
- SQLite database → Hetzner Object Storage
- Server snapshot → Hetzner Backups

**Manual (On-demand):**
- Grafana dashboards → Export JSON
- Prometheus data → Not backed up (can be regenerated)

### Recovery Scenarios

**Scenario 1: Database corruption**
```bash
kamal app exec -i 'bin/rails backup:restore[TIMESTAMP]'
kamal app restart
```

**Scenario 2: Server failure**
1. Provision new server
2. Deploy via Kamal
3. Restore database from Hetzner Object Storage
4. Update DNS

**Scenario 3: Monitoring failure**
```bash
ssh deploy@<SERVER_IP>
cd /opt/monitoring
docker compose down
docker compose up -d
```

---

## Monitoring & Observability

### What We Monitor

**Application Metrics (Yabeda):**
- Request rate, latency, errors
- Database query performance
- Puma thread pool usage
- Background job queue depth

**System Metrics (Future):**
- CPU, memory, disk usage
- Network I/O
- Container health

### Dashboards

**Pre-built (Grafana):**
- ID 14133: Rails Application Metrics
- ID 14134: Puma Server Metrics

**Custom (Future):**
- Contest submissions per hour
- Active user sessions
- Judge activity
- School participation

### Alerts (Future)

To be configured via Prometheus Alertmanager:
- Error rate >1%
- Response time p95 >1s
- Worker saturation >80%
- Disk space >80%
- Job queue >100

---

## Cost Breakdown

| Item | Monthly Cost |
|------|--------------|
| Hetzner CX32 Server | €8.49 |
| Hetzner Server Backups | €1.70 |
| Hetzner Object Storage | ~€0.50 (estimated) |
| **Total** | **~€10.69 (~$11.50)** |

**Compared to DigitalOcean:** ~$1-13/month savings

---

## Technology Stack

**Application:**
- Ruby 3.3.5
- Rails 8.1.2
- SQLite 3 (multi-database)
- Puma (web server)
- Solid Queue (background jobs)
- Solid Cache (caching)
- Solid Cable (WebSockets)

**Monitoring:**
- Yabeda (metrics collection)
- OpenTelemetry Collector (aggregation)
- Prometheus (storage)
- Grafana (visualization)

**Infrastructure:**
- Hetzner Cloud (hosting)
- Kamal (deployment)
- Docker (containerization)
- Traefik (reverse proxy)
- Let's Encrypt (SSL)

**External Services:**
- Hetzner Object Storage (backups)
- AWS SES (email)

---

## Security

### Application Security
- SSL/TLS via Let's Encrypt
- Encrypted credentials (Rails)
- Session-based authentication
- CSRF protection
- SQL injection prevention (ActiveRecord)

### Server Security
- Firewall (ufw)
- SSH key authentication only
- Non-root deploy user
- Regular security updates
- Automated backups

### Monitoring Security
- Grafana password authentication
- Internal-only Prometheus access
- No public metrics endpoint
- File permissions on `.env`

---

## Maintenance

### Regular Tasks

**Daily (Automated):**
- Database backups (3am UTC)
- Security updates (unattended-upgrades)

**Weekly (Automated):**
- Backup cleanup (Sundays 4am UTC)

**Monthly (Manual):**
- Review Grafana dashboards
- Check disk usage
- Review error logs
- Verify backup integrity

**Quarterly (Manual):**
- Test disaster recovery
- Review and optimize queries
- Update dependencies
- Security audit

---

## Future Enhancements

**Short-term:**
- Configure Prometheus alerts
- Add custom Grafana dashboards
- Set up uptime monitoring (Better Uptime)

**Medium-term:**
- Implement log aggregation
- Add APM (Scout or Skylight)
- Configure automated testing in CI/CD

**Long-term:**
- Multi-region deployment
- CDN for static assets
- Read replicas for database
- Kubernetes migration (if needed)

---

## Support & Documentation

**Operational Guides:**
- `docs/DEPLOYMENT-GUIDE.md` - Full deployment procedure
- `docs/QUICK-REFERENCE.md` - Common commands
- `docs/monitoring-runbook.md` - Monitoring operations
- `docs/disaster-recovery.md` - Backup/restore procedures

**Architecture:**
- `docs/ARCHITECTURE.md` - This document
- `docs/hetzner-migration.md` - Migration history

**Configuration:**
- `config/deploy.yml` - Kamal deployment
- `monitoring/docker-compose.yml` - Monitoring stack
- `config/otel_collector.yml` - Metrics collection
