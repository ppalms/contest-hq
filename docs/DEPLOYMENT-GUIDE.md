# Hetzner Migration & Monitoring Deployment Guide

## Overview

This guide walks you through migrating Contest HQ from DigitalOcean to Hetzner and deploying the complete monitoring stack (Prometheus + Grafana).

**Estimated Time:** 3-4 hours  
**Target Server:** Hetzner CX32 (4 vCPU, 8GB RAM)  
**Cost:** €10.19/month (~$11)

---

## Pre-Deployment Checklist

Before starting, ensure you have:

- [ ] Hetzner Cloud account
- [ ] SSH key added to Hetzner
- [ ] DNS access for contesthq.app
- [ ] Rails production credentials master key
- [ ] Docker Hub credentials (ppalms account)
- [ ] 1Password for storing Grafana password

### Save Grafana Password in 1Password

The monitoring stack runs independently of Rails via Docker Compose. Store the Grafana password in 1Password as your master copy:

- **Title:** Contest HQ Grafana
- **URL:** https://metrics.contesthq.app
- **Username:** admin
- **Password:** Stored in 1Password (search for "Grafana Admin Password")

**Note:** The password is set via the `GRAFANA_ADMIN_PASSWORD` environment variable in Kamal's `.kamal/secrets` file. Never commit passwords to git.

---

## Part 1: Provision Hetzner Server (15 minutes)

### 1.1 Create Server

1. Go to https://console.hetzner.cloud
2. Select your project or create "Contest HQ Production"
3. Click "Add Server"
4. Configure:
   - **Location:** Falkenstein (fsn1)
   - **Image:** Ubuntu 24.04
   - **Type:** CX32 (4 vCPU, 8GB RAM, 80GB SSD)
   - **Networking:** IPv4 + IPv6
   - **SSH Keys:** Select your key
   - **Firewalls:** Create new firewall:
     ```
     Inbound Rules:
     - SSH (22) from anywhere
     - HTTP (80) from anywhere
     - HTTPS (443) from anywhere
     - Custom TCP (9394) from anywhere
     ```
   - **Backups:** Enable (€1.70/month)
   - **Name:** contest-hq-production

5. Click "Create & Buy Now"
6. **Note the IP address** - you'll use it throughout this guide

### 1.2 Initial Server Setup

SSH to the new server:
```bash
ssh root@<HETZNER_IP>
```

Run these commands:
```bash
# Update system
apt-get update && apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# Install Docker Compose plugin
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

# Test Docker
docker run hello-world
```

Verify installation:
```bash
docker --version
docker compose version
id deploy
```

Exit and test deploy user:
```bash
exit
ssh deploy@<HETZNER_IP>
docker ps
exit
```

---

## Part 2: Update Configuration (5 minutes)

### 2.1 Update Kamal Deploy Config

Edit `config/deploy.yml` and update line 10:
```yaml
servers:
  web:
    - <HETZNER_IP>  # Replace with your actual Hetzner IP
```

### 2.2 Commit Changes

```bash
git add .
git commit -m "Add monitoring stack and prepare for Hetzner migration

- Add Yabeda metrics (Rails, Puma, Prometheus)
- Add OpenTelemetry Collector for metrics aggregation
- Create Prometheus + Grafana monitoring stack
- Update deployment config for Hetzner server
- Add migration and monitoring documentation"

git push origin main
```

---

## Part 3: Backup Current Production (10 minutes)

### 3.1 Create Final Backup

```bash
# Run backup on current DigitalOcean server
kamal app exec -i 'bin/rails backup:run'

# Verify backup exists
kamal app exec -i 'bin/rails backup:list'
```

### 3.2 Download Safety Backup

```bash
# Download database locally
kamal app exec 'cat /rails/storage/production.sqlite3' > production-backup-$(date +%Y%m%d).sqlite3

# Verify file size
ls -lh production-backup-*.sqlite3
```

---

## Part 4: Deploy to Hetzner (30 minutes)

### 4.1 Initial Kamal Setup

```bash
# From local machine
kamal setup
```

This will:
- Install Kamal proxy (Traefik)
- Build and push Docker image
- Deploy Contest HQ
- Deploy OTel Collector accessory
- Run database migrations
- Start the application

**Watch for any errors during deployment.**

### 4.2 Restore Database

```bash
# List available backups
kamal app exec -i 'bin/rails backup:list'

# Restore latest backup (replace TIMESTAMP with actual value)
kamal app exec -i 'bin/rails backup:restore[TIMESTAMP]'
# Type RESTORE when prompted

# Restart application
kamal app restart
```

### 4.3 Verify Application

```bash
# Check health endpoint
curl http://<HETZNER_IP>/up
# Should return: 200 OK

# Check metrics endpoint
curl http://<HETZNER_IP>:9394/metrics | head -20
# Should show Prometheus metrics

# Check logs
kamal app logs --tail 50
```

---

## Part 5: Deploy Monitoring Stack (20 minutes)

### 5.1 Copy Files to Server

```bash
# From local machine
scp -r monitoring/ deploy@<HETZNER_IP>:/opt/monitoring/
```

### 5.2 Configure and Deploy

```bash
# SSH to server
ssh deploy@<HETZNER_IP>
cd /opt/monitoring

# Update prometheus.yml with actual IP
sed -i "s/<HETZNER_IP>/$(curl -s ifconfig.me)/g" prometheus.yml

# Create .env file
cat > .env <<EOF
GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
EOF

# Make setup script executable
chmod +x setup.sh

# Deploy monitoring stack
./setup.sh

# Verify containers are running
docker compose ps

# Check logs (Ctrl+C to exit)
docker compose logs -f
```

### 5.3 Verify Monitoring

```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
# Should show: "up"

# Exit SSH
exit
```

---

## Part 6: Configure DNS (15 minutes)

### 6.1 Update DNS Records

In your DNS provider (Cloudflare, Route53, etc.):

1. **Add metrics subdomain:**
   ```
   A     metrics.contesthq.app   → <HETZNER_IP>   (TTL: 300)
   ```

2. **Update main domain:**
   ```
   A     contesthq.app           → <HETZNER_IP>   (TTL: 300)
   ```

### 6.2 Verify DNS Propagation

```bash
# Check DNS resolution
dig contesthq.app +short
# Should show: <HETZNER_IP>

dig metrics.contesthq.app +short
# Should show: <HETZNER_IP>

# Test HTTPS (wait 2-3 minutes for SSL)
curl -I https://contesthq.app
# Should show: HTTP/2 200

curl -I https://metrics.contesthq.app
# Should show: HTTP/2 200 or redirect
```

---

## Part 7: Configure Grafana (15 minutes)

### 7.1 Access Grafana

Temporarily access via IP while SSL is being set up:
```
URL: http://<HETZNER_IP>:3001
Username: admin
Password: <stored in 1Password>
```

Or via subdomain (after DNS propagates):
```
URL: https://metrics.contesthq.app
```

### 7.2 Verify Prometheus Connection

1. Go to Configuration → Data Sources
2. Click "Prometheus"
3. Scroll down and click "Test"
4. Should show: "Data source is working"

### 7.3 Import Dashboards

**Rails Application Metrics:**
1. Click "+" → Import
2. Enter ID: `14133`
3. Click "Load"
4. Select "Prometheus" datasource
5. Click "Import"

**Puma Server Metrics:**
1. Click "+" → Import
2. Enter ID: `14134`
3. Click "Load"
4. Select "Prometheus" datasource
5. Click "Import"

### 7.4 Verify Data

1. Open each dashboard
2. Should see metrics populating
3. If no data, wait 1-2 minutes for first scrape

---

## Part 8: Final Testing (20 minutes)

### 8.1 Application Testing

- [ ] Visit https://contesthq.app
- [ ] Login works
- [ ] Create test account
- [ ] Navigate through app
- [ ] Check background jobs running
- [ ] Test email sending
- [ ] Check logs for errors: `kamal app logs -f`

### 8.2 Monitoring Testing

- [ ] Visit https://metrics.contesthq.app
- [ ] Dashboards showing data
- [ ] Metrics updating in real-time
- [ ] No errors in Prometheus targets: http://<HETZNER_IP>:9090/targets
- [ ] No errors in Grafana logs: `ssh deploy@<HETZNER_IP> "cd /opt/monitoring && docker compose logs grafana"`

### 8.3 Performance Testing

- [ ] Response times acceptable
- [ ] No memory leaks visible in Grafana
- [ ] CPU usage normal
- [ ] Metrics collection not impacting performance

---

## Part 9: Post-Migration (After 7 days)

### 9.1 Verify Stability

- [ ] All functionality working
- [ ] Backups running successfully: `kamal app exec -i 'bin/rails backup:list'`
- [ ] Monitoring collecting metrics
- [ ] No performance issues
- [ ] No errors in logs

### 9.2 Cleanup

- [ ] Destroy DigitalOcean droplet
- [ ] Update documentation with new IP
- [ ] Increase DNS TTL to 3600
- [ ] Remove old server from monitoring

---

## Rollback Plan

If issues occur during or after migration:

### Immediate Rollback (During Migration)

1. **Revert DNS to DigitalOcean:**
   ```
   A     contesthq.app           → 161.35.122.13
   ```

2. Wait 5 minutes for propagation (TTL=300)
3. Old server still running, no data loss
4. Debug Hetzner issues offline

### Rollback After Migration (Within 24 hours)

1. Create backup on Hetzner: `kamal app exec -i 'bin/rails backup:run'`
2. Revert DNS to DigitalOcean IP
3. Wait for propagation
4. Restore latest backup on DO server if needed
5. Investigate Hetzner issues

---

## Troubleshooting

### Application Not Accessible

```bash
# Check container status
kamal app logs

# Check Traefik proxy
kamal proxy logs

# Restart application
kamal app restart
```

### Metrics Not Showing

```bash
# Check OTel Collector
kamal accessory logs otel_collector

# Check metrics endpoint
curl http://<HETZNER_IP>:9394/metrics

# Restart OTel Collector
kamal accessory restart otel_collector
```

### Grafana Not Accessible

```bash
# SSH to server
ssh deploy@<HETZNER_IP>
cd /opt/monitoring

# Check container status
docker compose ps

# Check logs
docker compose logs grafana

# Restart
docker compose restart grafana
```

### SSL Not Working

```bash
# Check Traefik logs
kamal proxy logs

# Verify DNS is pointing to new server
dig contesthq.app +short

# Wait 2-3 minutes for Let's Encrypt
```

---

## Support

For issues or questions:
1. Check logs: `kamal app logs -f`
2. Review documentation in `docs/`
3. Check monitoring dashboards
4. Review Hetzner server status

---

## Summary

**What You've Deployed:**
- ✅ Contest HQ on Hetzner CX32
- ✅ Prometheus metrics collection
- ✅ Grafana dashboards
- ✅ Automated backups to Hetzner Object Storage
- ✅ SSL certificates via Let's Encrypt
- ✅ Full monitoring and observability

**Monthly Cost:**
- Hetzner CX32: €8.49
- Hetzner Backups: €1.70
- **Total: €10.19 (~$11/month)**

**Savings:** ~$1-13/month compared to DigitalOcean

**Next Steps:**
1. Monitor application for 7 days
2. Configure alerts (future)
3. Optimize dashboards
4. Scale to CX42 when first customer goes live
