# Hetzner Migration Guide

## Server Details

- **Provider:** Hetzner Cloud
- **Location:** Falkenstein (fsn1)
- **Type:** CX32 (4 vCPU, 8GB RAM, 80GB SSD)
- **IP:** Update after provisioning
- **Cost:** €10.19/month (€8.49 server + €1.70 backups)

## Services Running

| Service | Port | Access |
|---------|------|--------|
| Contest HQ | 80/443 | https://contesthq.app |
| OTel Collector | 9394 | Internal metrics aggregation |
| Prometheus | 9090 | http://SERVER_IP:9090 |
| Grafana | 3001 | https://metrics.contesthq.app |

## Architecture

```
Hetzner CX32
├── Contest HQ (Kamal/Docker)
│   ├── Web container (port 3000)
│   └── OTel Collector (port 9394)
└── Monitoring Stack (Docker Compose)
    ├── Prometheus (port 9090)
    └── Grafana (port 3001)
```

## Migration Steps

### 1. Provision Hetzner Server

1. Go to https://console.hetzner.cloud
2. Create server:
   - Location: Falkenstein (fsn1)
   - Image: Ubuntu 24.04
   - Type: CX32
   - SSH Keys: Add your key
   - Firewalls: Allow 22, 80, 443, 9394
   - Backups: Enable
   - Name: contest-hq-production

3. Note the IP address

### 2. Initial Server Setup

```bash
ssh root@<HETZNER_IP>

# Update system
apt-get update && apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# Install Docker Compose
apt-get install -y docker-compose-plugin

# Create deploy user
adduser --disabled-password --gecos "" deploy
usermod -aG docker deploy
mkdir -p /home/deploy/.ssh
cp ~/.ssh/authorized_keys /home/deploy/.ssh/
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys

# Set up firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 9394/tcp
ufw --force enable

# Create monitoring directory
mkdir -p /opt/monitoring
chown deploy:deploy /opt/monitoring
```

### 3. Update config/deploy.yml

Update the server IP in `config/deploy.yml`:
```yaml
servers:
  web:
    - <HETZNER_IP>
```

### 4. Backup Current Production

```bash
# On current server
kamal app exec -i 'bin/rails backup:run'
kamal app exec -i 'bin/rails backup:list'

# Download locally as safety
kamal app exec 'cat /rails/storage/production.sqlite3' > production-backup-$(date +%Y%m%d).sqlite3
```

### 5. Deploy to Hetzner

```bash
# From local machine
kamal setup

# Restore database
kamal app exec -i 'bin/rails backup:restore[TIMESTAMP]'
kamal app restart

# Verify
curl http://<HETZNER_IP>/up
curl http://<HETZNER_IP>:9394/metrics
```

### 6. Deploy Monitoring Stack

```bash
# Copy files to server
scp -r monitoring/ deploy@<HETZNER_IP>:/opt/monitoring/

# SSH to server
ssh deploy@<HETZNER_IP>
cd /opt/monitoring

# Update prometheus.yml with server IP
sed -i "s/<HETZNER_IP>/$(curl -s ifconfig.me)/g" prometheus.yml

# Create .env (get password from 1Password)
cat > .env <<EOF
GRAFANA_ADMIN_PASSWORD=K7mP9xR2vN8qL4wE6tY3sA1zF5hJ0uC9
EOF

# Deploy
chmod +x setup.sh
./setup.sh
```

### 7. Configure DNS

Update DNS records:
```
A     contesthq.app           → <HETZNER_IP>   (TTL: 300)
A     metrics.contesthq.app   → <HETZNER_IP>   (TTL: 300)
```

Wait 5-10 minutes for propagation.

### 8. Verify SSL

Kamal proxy will automatically request Let's Encrypt certificates.

```bash
curl -I https://contesthq.app
curl -I https://metrics.contesthq.app
```

### 9. Import Grafana Dashboards

1. Access https://metrics.contesthq.app
2. Login with admin credentials
3. Import dashboards:
   - ID 14133 (Rails)
   - ID 14134 (Puma)

## Monitoring Access

- **Grafana URL:** https://metrics.contesthq.app
- **Username:** admin
- **Password:** Stored in 1Password (monitoring stack is independent of Rails)

## Backup Strategy

- **Database:** Daily backups to Hetzner Object Storage (3am)
- **Server:** Hetzner automated backups (daily snapshots)
- **Retention:** 30 days

## Maintenance

### Update Application
```bash
git push
kamal deploy
```

### Restart Monitoring
```bash
ssh deploy@<HETZNER_IP>
cd /opt/monitoring
docker compose restart
```

### View Logs
```bash
# Application
kamal app logs -f

# Monitoring
ssh deploy@<HETZNER_IP>
cd /opt/monitoring
docker compose logs -f
```

## Rollback Plan

If issues occur:
1. Revert DNS to old server (161.35.122.13)
2. Wait 5 minutes (TTL=300)
3. Old server still has data
4. Debug Hetzner offline

## Post-Migration Cleanup

After 7 days of stable operation:
1. Verify all functionality
2. Confirm backups running
3. Destroy DigitalOcean droplet
4. Update documentation
