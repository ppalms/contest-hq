# Disaster Recovery Quick Start

**For detailed instructions, see:** [DISASTER-RECOVERY-COMPLETE.md](./DISASTER-RECOVERY-COMPLETE.md)

## Prerequisites Checklist

- [ ] Hetzner Cloud Console access
- [ ] `RAILS_MASTER_KEY` from `config/master.key`
- [ ] `KAMAL_REGISTRY_PASSWORD` (Docker Hub token)
- [ ] SSH key pair (`~/.ssh/id_rsa`)
- [ ] DNS provider access

## Recovery Steps (45-60 minutes)

### 1. Provision Hetzner CX33 Server (5 min)
```bash
# Via Hetzner Cloud Console:
# - Location: Falkenstein, Germany
# - Image: Ubuntu 24.04
# - Type: CX33 (4 vCPU, 8GB RAM, 160GB SSD)
# - Add SSH key
# - Configure firewall (ports 22, 80, 443, 3001, 9090)
# - Name: contest-hq-production

# Save the server IP: 157.180.79.212
```

### 2. Configure Server (10 min)
```bash
# SSH to server
ssh root@NEW_SERVER_IP

# Create deploy user
adduser deploy
usermod -aG sudo deploy
mkdir -p /home/deploy/.ssh
cp /root/.ssh/authorized_keys /home/deploy/.ssh/
chown -R deploy:deploy /home/deploy/.ssh

# Install Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker deploy

# Log out and back in as deploy user
exit
ssh deploy@NEW_SERVER_IP
```

### 3. Deploy Application (15 min)
```bash
# On LOCAL machine
cd /path/to/contest-hq

# Update config/deploy.yml with new server IP
vim config/deploy.yml
# Change: servers.web[0] to NEW_SERVER_IP

# Export credentials
export RAILS_MASTER_KEY=$(cat config/master.key)
export KAMAL_REGISTRY_PASSWORD="your_docker_token"

# Deploy
kamal setup
```

### 4. Restore Database (10 min)
```bash
# List backups
kamal app exec -i 'bin/rails backup:list'

# Restore latest
kamal app exec -i 'bin/rails backup:restore[TIMESTAMP]'
# Type: RESTORE

# Restart
kamal app restart

# Verify
kamal app exec -i 'bin/rails runner "puts User.count"'
```

### 5. Deploy Monitoring (10 min)
```bash
# SSH to server
ssh deploy@NEW_SERVER_IP
sudo mkdir -p /opt/monitoring
sudo chown deploy:deploy /opt/monitoring
exit

# Copy files
scp monitoring/* deploy@NEW_SERVER_IP:/opt/monitoring/

# SSH back
ssh deploy@NEW_SERVER_IP
cd /opt/monitoring

# Create .env with Grafana password
echo "GF_SECURITY_ADMIN_PASSWORD=$(openssl rand -base64 32)" > .env

# Start monitoring
docker compose up -d

# Connect to kamal network
docker network connect kamal prometheus
docker compose restart prometheus
```

### 6. Verify Health (10 min)
```bash
# Application
curl -I https://contesthq.app/up

# Database
kamal app exec -i 'bin/rails runner "puts User.count"'

# Monitoring
ssh -L 3001:localhost:3001 deploy@NEW_SERVER_IP
# Open: http://localhost:3001
```

### 7. Update DNS (5 min)
```bash
# Update A record for contesthq.app
# Point to: NEW_SERVER_IP
# TTL: 300 (5 minutes)

# Verify
dig contesthq.app +short
```

## Quick Reference

### Environment Variables
```bash
export RAILS_MASTER_KEY=$(cat config/master.key)
export KAMAL_REGISTRY_PASSWORD="dckr_pat_..."
```

### Common Commands
```bash
# Logs
kamal app logs -f

# Console
kamal app exec -i 'bin/rails console'

# Restart
kamal app restart

# Backups
kamal app exec -i 'bin/rails backup:list'
kamal app exec -i 'bin/rails backup:restore[TIMESTAMP]'
```

### Troubleshooting
```bash
# Check containers
docker ps

# Check logs
kamal app logs --grep error

# Verify database
kamal app exec -i 'bin/rails runner "puts User.count"'

# Restart everything
kamal app restart
```

## Emergency Contacts

- **Hetzner Support:** https://console.hetzner.cloud/support
- **Documentation:** docs/DISASTER-RECOVERY-COMPLETE.md

## Server Specs

- **Provider:** Hetzner Cloud
- **Type:** CX33
- **CPU:** 4 vCPU (shared)
- **RAM:** 8 GB
- **Disk:** 160 GB SSD
- **Cost:** ~€11.90/month
- **Location:** Falkenstein, Germany

---

**For detailed step-by-step instructions with troubleshooting, see:**  
[DISASTER-RECOVERY-COMPLETE.md](./DISASTER-RECOVERY-COMPLETE.md)
