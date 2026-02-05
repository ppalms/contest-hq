# Complete Disaster Recovery Guide

**Last Updated:** February 5, 2026  
**Server Configuration:** Hetzner CX33 (4 vCPU, 8GB RAM, 160GB SSD)  
**Estimated Recovery Time:** 45-60 minutes

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Phase 1: Provision New Hetzner Server](#phase-1-provision-new-hetzner-server)
3. [Phase 2: Configure Server & Install Docker](#phase-2-configure-server--install-docker)
4. [Phase 3: Deploy Application with Kamal](#phase-3-deploy-application-with-kamal)
5. [Phase 4: Restore Database from Backup](#phase-4-restore-database-from-backup)
6. [Phase 5: Deploy Monitoring Stack](#phase-5-deploy-monitoring-stack)
7. [Phase 6: Verify Infrastructure Health](#phase-6-verify-infrastructure-health)
8. [Phase 7: Update DNS (When Ready)](#phase-7-update-dns-when-ready)
9. [Troubleshooting](#troubleshooting)
10. [Rollback Procedures](#rollback-procedures)

---

## Prerequisites

### Required Access & Credentials

- [ ] **Hetzner Cloud Console Access**
  - URL: https://console.hetzner.cloud/
  - Account with billing permissions

- [ ] **Local Development Environment**
  - Git repository cloned: `/path/to/contest-hq`
  - Docker installed and running
  - SSH key pair available (`~/.ssh/id_rsa` or custom key)

- [ ] **Required Credentials** (from 1Password or secure storage)
  - `RAILS_MASTER_KEY` (from `config/master.key`)
  - `KAMAL_REGISTRY_PASSWORD` (Docker Hub access token)
  - Hetzner API token (optional, for automation)

- [ ] **DNS Access**
  - Access to DNS provider (Cloudflare, Route53, etc.)
  - Ability to update A records for `contesthq.app`

### Verify Prerequisites

```bash
# 1. Verify you're in the correct directory
cd /path/to/contest-hq
git status

# 2. Verify required files exist
ls -la config/master.key
ls -la config/deploy.yml
ls -la ~/.ssh/id_rsa.pub

# 3. Verify Docker is running
docker ps

# 4. Verify Kamal is installed
kamal version
# If not installed: gem install kamal
```

---

## Phase 1: Provision New Hetzner Server

**Estimated Time:** 5 minutes

### Step 1.1: Create New Server

1. **Login to Hetzner Cloud Console**
   - Go to: https://console.hetzner.cloud/
   - Select your project (or create new one)

2. **Click "Add Server"**

3. **Configure Server Settings:**

   **Location:**
   - Select: `Falkenstein, Germany` (or preferred region)
   - Note: Choose same region as your Object Storage for faster backups

   **Image:**
   - Select: `Ubuntu 24.04`

   **Type:**
   - Select: `CX33` (Shared vCPU)
     - 4 vCPU
     - 8 GB RAM
     - 160 GB SSD
     - Cost: ~€11.90/month

   **Networking:**
   - [x] Public IPv4
   - [ ] Public IPv6 (optional)

   **SSH Keys:**
   - Click "Add SSH Key"
   - Paste your public key: `cat ~/.ssh/id_rsa.pub`
   - Name it: `contest-hq-key`
   - Click "Add SSH Key"

   **Firewalls:**
   - Click "Create Firewall" (if not exists)
   - Name: `contest-hq-firewall`
   - **Inbound Rules:**
     ```
     SSH:    Port 22    Source: 0.0.0.0/0, ::/0
     HTTP:   Port 80    Source: 0.0.0.0/0, ::/0
     HTTPS:  Port 443   Source: 0.0.0.0/0, ::/0
     Note: Grafana is now accessible via HTTPS on port 443 (metrics.contesthq.app)
     Note: Prometheus is internal-only (no external port needed)
     ```
   - **Outbound Rules:**
     ```
     All traffic: Allow all
     ```
   - Click "Create Firewall"
   - Select the firewall for your server

   **Volumes:**
   - Skip (we use Docker volumes)

   **Additional Features:**
   - [ ] Backups (optional - we have our own backup system)
   - [ ] User data (skip)

   **Name:**
   - Enter: `contest-hq-production`

4. **Click "Create & Buy Now"**

5. **Wait for server to provision** (~30 seconds)

6. **Copy the server IP address**
   - Example: `157.180.79.212`
   - Save this - you'll need it throughout the recovery

### Step 1.2: Verify Server Access

```bash
# Test SSH access (replace with your server IP)
ssh root@157.180.79.212

# You should see Ubuntu welcome message
# Type 'exit' to disconnect
```

**If SSH fails:**
- Verify firewall allows port 22
- Verify SSH key was added correctly
- Try: `ssh -i ~/.ssh/id_rsa root@157.180.79.212`

---

## Phase 2: Configure Server & Install Docker

**Estimated Time:** 10 minutes

### Step 2.1: Create Deploy User

```bash
# SSH into the server
ssh root@157.180.79.212

# Create deploy user
adduser deploy
# Set password when prompted (save to 1Password)

# Add deploy user to sudo group
usermod -aG sudo deploy

# Setup SSH for deploy user
mkdir -p /home/deploy/.ssh
cp /root/.ssh/authorized_keys /home/deploy/.ssh/
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys

# Test deploy user access (from another terminal)
ssh deploy@157.180.79.212
# Should work without password

# Exit root session
exit
```

### Step 2.2: Install Docker

```bash
# SSH as deploy user
ssh deploy@157.180.79.212

# Update system packages
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker prerequisites
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add deploy user to docker group
sudo usermod -aG docker deploy

# Enable Docker to start on boot
sudo systemctl enable docker
sudo systemctl start docker

# IMPORTANT: Log out and back in for group changes to take effect
exit
ssh deploy@157.180.79.212

# Verify Docker installation
docker --version
docker ps
# Should show empty list (no permission errors)
```

### Step 2.3: Configure Server Settings

```bash
# Still SSH'd as deploy user

# Set hostname
sudo hostnamectl set-hostname contest-hq-production

# Configure timezone (optional)
sudo timedatectl set-timezone America/New_York
# Or use: sudo dpkg-reconfigure tzdata

# Install useful utilities
sudo apt-get install -y \
    htop \
    vim \
    curl \
    wget \
    git \
    python3-pip

# Exit SSH session
exit
```

---

## Phase 3: Deploy Application with Kamal

**Estimated Time:** 15 minutes

### Step 3.1: Update Kamal Configuration

```bash
# On your LOCAL machine
cd /path/to/contest-hq

# Checkout disaster-recovery branch (or main)
git checkout disaster-recovery
git pull origin disaster-recovery

# Update deploy.yml with new server IP
vim config/deploy.yml
```

**Update the following in `config/deploy.yml`:**

```yaml
servers:
  web:
    - 157.180.79.212  # <-- Update this with your new server IP

ssh:
  user: deploy        # <-- Ensure this is 'deploy' not 'root'
  keys: ["~/.ssh/id_rsa"]  # <-- Update if using different key
```

**Save and verify:**

```bash
# Verify the change
grep -A 2 "servers:" config/deploy.yml

# Should show:
# servers:
#   web:
#     - 157.180.79.212
```

### Step 3.2: Set Required Environment Variables

```bash
# Export required environment variables
export RAILS_MASTER_KEY=$(cat config/master.key)
export KAMAL_REGISTRY_PASSWORD="your_docker_hub_token_here"

# Verify they're set
echo $RAILS_MASTER_KEY
echo $KAMAL_REGISTRY_PASSWORD

# IMPORTANT: Add these to your ~/.bashrc for persistence
echo "export RAILS_MASTER_KEY=$(cat config/master.key)" >> ~/.bashrc
echo "export KAMAL_REGISTRY_PASSWORD=\"your_docker_hub_token_here\"" >> ~/.bashrc
```

### Step 3.3: Run Kamal Setup

```bash
# This will:
# - Install kamal-proxy (Traefik)
# - Build and push Docker image
# - Deploy application container
# - Deploy OTel collector accessory
# - Obtain SSL certificate from Let's Encrypt

kamal setup

# This will take 5-10 minutes
# Watch for any errors
```

**Expected Output:**

```
Acquiring the deploy lock...
Building Docker image...
Pushing image to registry...
Booting kamal-proxy...
Deploying web container...
Deploying accessories...
Releasing the deploy lock...
```

**If setup fails:**
- Check error messages carefully
- Verify environment variables are set
- Verify SSH access to server
- See [Troubleshooting](#troubleshooting) section

### Step 3.4: Verify Application Deployment

```bash
# Check application status
kamal app logs

# Should see:
# - Puma starting
# - Solid Queue supervisor starting
# - No errors about missing databases (they'll be empty but initialized)

# Check container is running
ssh deploy@157.180.79.212 "docker ps"

# Should show:
# - kamal-proxy
# - contest_hq-web-latest
# - contest_hq-otel_collector

# Test health endpoint (will fail until database is restored)
curl -I https://contesthq.app/up
# Or use server IP:
ssh deploy@157.180.79.212 "curl -I http://localhost:3000/up"
```

---

## Phase 4: Restore Database from Backup

**Estimated Time:** 10 minutes

### Step 4.1: List Available Backups

```bash
# From your LOCAL machine
kamal app exec -i 'bin/rails backup:list'
```

**Expected Output:**

```
Available backups in contest-hq-backups:

20260205_030000 - 45.67 MB - 2026-02-05 03:00:15 UTC
20260204_030000 - 45.23 MB - 2026-02-04 03:00:12 UTC
20260203_030000 - 44.87 MB - 2026-02-03 03:00:09 UTC

Total: 3 backups
```

**If no backups are listed:**
- Verify Hetzner Object Storage credentials in Rails credentials
- Check that backup bucket exists
- See [Troubleshooting](#troubleshooting) section

### Step 4.2: Verify Backup Integrity

```bash
# Verify the most recent backup
kamal app exec -i 'bin/rails backup:verify[20260205_030000]'
```

**Expected Output:**

```
Verifying backup: 20260205_030000
Downloading primary database...
✓ primary: 45.67 MB - Valid SQLite database
Downloading cache database...
✓ cache: 2.34 MB - Valid SQLite database
Downloading queue database...
✓ queue: 1.23 MB - Valid SQLite database
Downloading cable database...
✓ cable: 0.45 MB - Valid SQLite database

✓ All databases verified successfully
```

### Step 4.3: Restore Database

```bash
# Restore from the most recent backup
kamal app exec -i 'bin/rails backup:restore[20260205_030000]'
```

**You will be prompted:**

```
WARNING: This will replace your current databases!
Databases to restore:
  - primary: storage/production.sqlite3
  - cache: storage/production_cache.sqlite3
  - queue: storage/production_queue.sqlite3
  - cable: storage/production_cable.sqlite3

Backup timestamp: 20260205_030000

Type 'RESTORE' to confirm:
```

**Type:** `RESTORE` (all caps) and press Enter

**Expected Output:**

```
Restoring primary database...
Downloading backups/20260205_030000/primary.sqlite3...
Downloaded 45.67 MB
No existing primary database found (initial setup)
Replacing primary database...
✓ primary database restored

Restoring cache database...
Downloading backups/20260205_030000/cache.sqlite3...
Downloaded 2.34 MB
No existing cache database found (initial setup)
Replacing cache database...
✓ cache database restored

Restoring queue database...
Downloading backups/20260205_030000/queue.sqlite3...
Downloaded 1.23 MB
No existing queue database found (initial setup)
Replacing queue database...
✓ queue database restored

Restoring cable database...
Downloading backups/20260205_030000/cable.sqlite3...
Downloaded 0.45 MB
No existing cable database found (initial setup)
Replacing cable database...
✓ cable database restored

============================================================
✓ Restore completed successfully
============================================================

Restored databases:
  ✓ primary
  ✓ cache
  ✓ queue
  ✓ cable

NEXT STEPS:
1. Restart the application: kamal app restart
2. Verify application is working
3. Check logs for any errors
```

### Step 4.4: Restart Application

```bash
# Restart the application to pick up restored databases
kamal app restart

# Wait 30 seconds for restart
sleep 30

# Check logs
kamal app logs --tail 50
```

**Look for:**
- ✅ Puma started successfully
- ✅ Solid Queue supervisor started
- ✅ No database errors
- ✅ No missing table errors

### Step 4.5: Verify Database Restoration

```bash
# Check database record counts
kamal app exec -i 'bin/rails runner "
  puts \"Users: #{User.count}\"
  puts \"Accounts: #{Account.count}\"
  puts \"Contests: #{Contest.count}\"
"'
```

**Expected Output (example):**

```
Users: 74
Accounts: 2
Contests: 4
```

**If counts are 0:**
- Database restore may have failed
- Check logs: `kamal app logs --grep error`
- Try restoring again from a different backup

---

## Phase 5: Deploy Monitoring Stack

**Estimated Time:** 5 minutes

**Note:** Monitoring is now managed as Kamal accessories (Prometheus + Grafana), not Docker Compose.

### Step 5.1: Set Grafana Password

```bash
# On your LOCAL machine
cd /path/to/contest-hq

# Generate a secure password for Grafana
export GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

# Display the password (SAVE THIS TO 1PASSWORD!)
echo "Grafana Admin Password: $GRAFANA_ADMIN_PASSWORD"

# Verify the password is set
echo $GRAFANA_ADMIN_PASSWORD
```

### Step 5.2: Deploy Monitoring Accessories

```bash
# Ensure required environment variables are set
export RAILS_MASTER_KEY=$(cat config/master.key)
export KAMAL_REGISTRY_PASSWORD="<your-docker-hub-token>"
# GRAFANA_ADMIN_PASSWORD already set above

# Deploy Prometheus (internal metrics collection)
kamal accessory boot prometheus

# Deploy Grafana (public dashboard with SSL)
kamal accessory boot grafana

# Verify both containers are running
ssh deploy@157.180.79.212 "docker ps | grep -E '(prometheus|grafana)'"

# Expected output:
# contest_hq-prometheus   Up X minutes   9090/tcp
# contest_hq-grafana      Up X minutes   0.0.0.0:3000->3000/tcp
```

### Step 5.3: Verify Prometheus is Scraping Metrics

```bash
# Wait 30 seconds for Prometheus to start scraping
sleep 30

# Check Prometheus targets
ssh deploy@157.180.79.212 "curl -s 'http://localhost:9090/api/v1/targets' | grep -o '\"health\":\"[^\"]*\"'"

# Expected output:
# "health":"up"
# "health":"up"

# Query for Rails metrics
ssh deploy@157.180.79.212 "curl -s 'http://localhost:9090/api/v1/query?query=up{job=\"contest-hq\"}' | grep -o '\"value\":\[.*\]'"

# Expected: "value":[<timestamp>,"1"]
```

### Step 5.4: Access Grafana

**Grafana is now accessible at:** https://metrics.contesthq.app

```bash
# Test HTTPS access
curl -I https://metrics.contesthq.app

# Expected: HTTP/2 200 (with Let's Encrypt SSL certificate)

# Login credentials:
# Username: admin
# Password: <the password you generated in Step 5.1>
```

### Step 5.5: Import Grafana Dashboards

1. **Login to Grafana:**
   - Navigate to: https://metrics.contesthq.app
   - Username: `admin`
   - Password: `<from Step 5.1>`

2. **Verify Prometheus Connection:**
   - Go to: Connections → Data Sources
   - Click "Prometheus"
   - Click "Save & Test"
   - Should show: ✅ "Data source is working"

3. **Import Yabeda Rails Dashboard:**
   - Click "+" → "Import"
   - Enter dashboard ID: `14133`
   - Click "Load"
   - Select datasource: "Prometheus"
   - Click "Import"

4. **Import Yabeda Puma Dashboard:**
   - Click "+" → "Import"
   - Enter dashboard ID: `14134`
   - Click "Load"
   - Select datasource: "Prometheus"
   - Click "Import"

5. **Verify Data:**
   - Open "Yabeda Rails" dashboard
   - Set time range to "Last 15 minutes"
   - Should see live metrics (request rate, response time, etc.)

### Step 5.6: Verify Metrics Collection

```bash
# From your LOCAL machine

# Check available metrics
ssh deploy@157.180.79.212 "curl -s 'http://localhost:9090/api/v1/label/__name__/values' | grep -E '(yabeda|puma|rails)' | head -10"

# Expected output (sample):
# yabeda_puma_backlog
# yabeda_puma_running
# yabeda_puma_pool_capacity
# yabeda_rails_requests_total
# yabeda_rails_request_duration_seconds_bucket
# ...

# If no metrics appear, check Rails app logs:
kamal app logs --tail 50 | grep -i yabeda
```

---

## Phase 6: Verify Infrastructure Health

**Estimated Time:** 10 minutes

### Step 6.1: Application Health Checks

```bash
# From your LOCAL machine

# 1. Check health endpoint
curl -I https://contesthq.app/up
# Expected: HTTP/2 200

# Or via server IP:
ssh deploy@157.180.79.212 "curl -I http://localhost:3000/up"
# Expected: HTTP/1.1 200 OK

# 2. Check application logs
kamal app logs --tail 100

# Look for:
# ✅ No errors
# ✅ Puma serving requests
# ✅ Solid Queue processing jobs

# 3. Check container status
ssh deploy@157.180.79.212 "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# Expected:
# NAME                        STATUS          PORTS
# contest_hq-web-<hash>       Up X minutes    80/tcp
# contest_hq-prometheus       Up X minutes    9090/tcp
# contest_hq-grafana          Up X minutes    0.0.0.0:3000->3000/tcp
# kamal-proxy                 Up X minutes    0.0.0.0:80-443->80-443/tcp
```

### Step 6.2: Database Verification

```bash
# Verify database is accessible and has data
kamal app exec -i 'bin/rails runner "
  puts \"=== Database Health Check ===\"
  puts \"Users: #{User.count}\"
  puts \"Accounts: #{Account.count}\"
  puts \"Contests: #{Contest.count}\"
  puts \"Entries: #{Entry.count}\" rescue puts \"Entries: N/A\"
  puts \"\"
  puts \"Latest User: #{User.last&.email}\"
  puts \"Latest Contest: #{Contest.last&.name}\"
"'
```

**Expected Output:**

```
=== Database Health Check ===
Users: 74
Accounts: 2
Contests: 4
Entries: 156

Latest User: user@example.com
Latest Contest: Spring 2026 Competition
```

### Step 6.3: Background Jobs Verification

```bash
# Check Solid Queue is running
kamal app exec -i 'bin/rails runner "
  puts \"=== Solid Queue Status ===\"
  puts \"Processes: #{SolidQueue::Process.count}\"
  puts \"Ready Jobs: #{SolidQueue::ReadyExecution.count}\"
  puts \"Scheduled Jobs: #{SolidQueue::ScheduledExecution.count}\"
  puts \"Failed Jobs: #{SolidQueue::FailedExecution.count}\"
"'
```

**Expected Output:**

```
=== Solid Queue Status ===
Processes: 4
Ready Jobs: 0
Scheduled Jobs: 2
Failed Jobs: 0
```

### Step 6.4: Monitoring Stack Verification

**Access Monitoring:**

1. **Grafana (Public with SSL):**
   - URL: https://metrics.contesthq.app
   - Login: `admin` / `<password from Step 5.1>`
   - Dashboards should show live metrics

2. **Prometheus (Internal - SSH tunnel if needed):**
   ```bash
   # Create SSH tunnel to access Prometheus directly
   ssh -L 9090:localhost:9090 deploy@157.180.79.212
   
   # In browser: http://localhost:9090
   # Go to Status → Targets
   # Verify targets are "UP":
   #   - prometheus (localhost:9090)
   #   - contest-hq (Docker service discovery)
   ```

3. **Import Dashboards:**
   - Click "+" → Import
   - Enter dashboard ID: `14133` (Yabeda Rails)
   - Select Prometheus datasource
   - Click Import
   - Repeat for dashboard ID: `14134` (Yabeda Puma)

4. **Verify Metrics:**
   - Open Yabeda Rails dashboard
   - Set time range: "Last 15 minutes"
   - Should see live metrics (request rates, response times, etc.)

### Step 6.5: SSL Certificate Verification

```bash
# Check SSL certificate
echo | openssl s_client -servername contesthq.app -connect 157.180.79.212:443 2>/dev/null | openssl x509 -noout -dates

# Expected output:
# notBefore=Feb  5 04:27:32 2026 GMT
# notAfter=May  6 04:27:31 2026 GMT

# Verify certificate is from Let's Encrypt
echo | openssl s_client -servername contesthq.app -connect 157.180.79.212:443 2>/dev/null | openssl x509 -noout -issuer

# Expected:
# issuer=C = US, O = Let's Encrypt, CN = R3
```

### Step 6.6: Functional Testing

**Manual Testing Checklist:**

- [ ] **Homepage loads:** https://contesthq.app (via IP or DNS)
- [ ] **Login works:** Test with known user credentials
- [ ] **Dashboard displays:** User can see their contests/data
- [ ] **Navigation works:** Click through major sections
- [ ] **No JavaScript errors:** Check browser console (F12)
- [ ] **No 500 errors:** Check application logs

```bash
# Monitor logs during testing
kamal app logs -f

# In another terminal, test endpoints
curl -I https://contesthq.app/
curl -I https://contesthq.app/login
curl -I https://contesthq.app/up
```

---

## Phase 7: Update DNS (When Ready)

**Estimated Time:** 5 minutes (+ propagation time)

### Step 7.1: Pre-DNS Update Checklist

Before updating DNS, verify:

- [ ] Application is fully functional on new server
- [ ] Database is restored and verified
- [ ] SSL certificate is valid
- [ ] Monitoring is working
- [ ] All health checks pass
- [ ] Functional testing complete
- [ ] Old server is still running (for rollback)

### Step 7.2: Update DNS Records

**Example for Cloudflare:**

1. Login to Cloudflare dashboard
2. Select your domain: `contesthq.app`
3. Go to DNS → Records
4. Find the A record for `contesthq.app`
5. Click "Edit"
6. Update:
   - **Type:** A
   - **Name:** @ (or contesthq.app)
   - **IPv4 address:** `157.180.79.212` (your new server IP)
   - **TTL:** 300 (5 minutes) - for faster propagation
   - **Proxy status:** DNS only (gray cloud) - recommended for initial testing
7. Click "Save"

**Optional: Add monitoring subdomain**

1. Click "Add record"
2. Configure:
   - **Type:** A
   - **Name:** metrics
   - **IPv4 address:** `157.180.79.212`
   - **TTL:** 300
   - **Proxy status:** DNS only
3. Click "Save"

### Step 7.3: Verify DNS Propagation

```bash
# Check DNS resolution
dig contesthq.app +short

# Should show: 157.180.79.212

# Check from multiple DNS servers
dig @8.8.8.8 contesthq.app +short
dig @1.1.1.1 contesthq.app +short

# Test HTTPS access
curl -I https://contesthq.app/up

# Should return: HTTP/2 200
```

**DNS Propagation Time:**
- Local cache: 5-10 minutes (with TTL 300)
- Global propagation: 1-24 hours (typically < 1 hour)

### Step 7.4: Monitor Traffic Switch

```bash
# Watch application logs for incoming requests
kamal app logs -f

# You should start seeing requests coming in
# Look for GET requests from real users (not just health checks)

# Monitor Grafana for traffic
# Open: http://localhost:3001 (via SSH tunnel)
# Dashboard: Yabeda Rails
# Watch for: Request rate increasing
```

### Step 7.5: Verify Old Server Traffic Drops

```bash
# SSH to OLD server (if still running)
ssh deploy@OLD_SERVER_IP

# Check logs
docker logs contest-hq-web-1 --tail 100

# Should see: Decreasing traffic as DNS propagates
```

---

## Phase 8: Post-Recovery Tasks

### Step 8.1: Update Documentation

```bash
# Update config/deploy.yml if not already committed
git add config/deploy.yml
git commit -m "Update production server IP to Hetzner CX33"

# Update monitoring configuration
git add monitoring/prometheus.yml
git commit -m "Update Prometheus config for new server"

# Push changes
git push origin disaster-recovery
```

### Step 8.2: Update Credentials Storage

- [ ] Update 1Password with new server IP
- [ ] Update 1Password with Grafana password
- [ ] Update 1Password with deploy user password
- [ ] Document new server details (hostname, IP, specs)

### Step 8.3: Configure Automated Backups

```bash
# Verify backup job is scheduled
kamal app exec -i 'bin/rails runner "
  puts \"=== Backup Schedule ===\"
  SolidQueue::RecurringTask.all.each do |task|
    puts \"#{task.key}: #{task.schedule}\"
  end
"'
```

**Expected Output:**

```
=== Backup Schedule ===
daily_backup: every day at 3am
weekly_backup_cleanup: every sunday at 4am
```

**Test backup manually:**

```bash
# Run a manual backup
kamal app exec -i 'bin/rails backup:run'

# Verify backup was created
kamal app exec -i 'bin/rails backup:list'

# Should show new backup with today's timestamp
```

### Step 8.4: Set Up Monitoring Alerts (Optional)

**Configure Grafana Alerts:**

1. Open Grafana: http://localhost:3001
2. Go to Alerting → Alert rules
3. Create alerts for:
   - High error rate (> 5% of requests)
   - Slow response time (p95 > 1s)
   - High queue backlog (> 100 jobs)
   - Low disk space (< 10% free)

### Step 8.5: Schedule Quarterly Restore Test

Add to calendar:
- **Frequency:** Quarterly (first Sunday of Jan, Apr, Jul, Oct)
- **Task:** Spin up test server and restore from backup
- **Purpose:** Verify disaster recovery procedures work

---

## Troubleshooting

### Issue: Kamal Setup Fails with "Permission Denied"

**Symptoms:**
```
ERROR: permission denied while trying to connect to the Docker daemon socket
```

**Solution:**
```bash
# SSH to server
ssh deploy@157.180.79.212

# Add deploy user to docker group
sudo usermod -aG docker deploy

# Log out and back in
exit
ssh deploy@157.180.79.212

# Verify docker access
docker ps
```

### Issue: Database Restore Fails with "Backup Not Found"

**Symptoms:**
```
ERROR: The specified key does not exist
```

**Solution:**
```bash
# Verify S3 credentials are correct
kamal app exec -i 'bin/rails runner "
  config = Rails.application.config.backup
  puts \"Bucket: #{config.s3_bucket}\"
  puts \"Endpoint: #{config.s3_client.config.endpoint}\"
"'

# List backups directly from S3
kamal app exec -i 'bin/rails runner "
  s3 = Rails.application.config.backup.s3_client
  bucket = Rails.application.config.backup.s3_bucket
  resp = s3.list_objects_v2(bucket: bucket, prefix: \"backups/\")
  resp.contents.each { |obj| puts obj.key }
"'
```

### Issue: SSL Certificate Not Obtained

**Symptoms:**
```
curl: (60) SSL certificate problem: unable to get local issuer certificate
```

**Solution:**
```bash
# Check kamal-proxy logs
ssh deploy@157.180.79.212 "docker logs kamal-proxy"

# Look for Let's Encrypt errors
# Common issues:
# - DNS not pointing to server yet
# - Port 80/443 blocked by firewall
# - Rate limit hit (5 certs per domain per week)

# Reboot proxy to retry
kamal proxy reboot
```

### Issue: Prometheus Not Scraping Metrics

**Symptoms:**
- Grafana shows "No data"
- Prometheus targets show "down"

**Solution:**
```bash
# SSH to server
ssh deploy@157.180.79.212

# Verify Prometheus is on kamal network
docker network inspect kamal | grep prometheus

# If not found, connect it
docker network connect kamal prometheus
docker compose -f /opt/monitoring/docker-compose.yml restart prometheus

# Verify Rails app is exposing metrics
docker exec $(docker ps --filter 'label=role=web' --format '{{.Names}}') curl -s http://localhost:9394/metrics | head -20

# Should show Puma/Rails metrics
```

### Issue: Application Shows 500 Errors

**Symptoms:**
- Homepage returns 500 error
- Logs show database errors

**Solution:**
```bash
# Check logs for specific error
kamal app logs --grep error

# Common issues:
# 1. Database not restored
kamal app exec -i 'bin/rails runner "puts User.count"'

# 2. Missing migrations
kamal app exec -i 'bin/rails db:migrate:status'

# 3. Credentials issue
kamal app exec -i 'bin/rails runner "puts Rails.application.credentials.secret_key_base"'

# Restart application
kamal app restart
```

### Issue: Solid Queue Not Processing Jobs

**Symptoms:**
- Jobs stuck in "ready" state
- No worker processes

**Solution:**
```bash
# Check Solid Queue processes
kamal app exec -i 'bin/rails runner "
  puts \"Processes: #{SolidQueue::Process.count}\"
  SolidQueue::Process.all.each do |p|
    puts \"  #{p.kind}: #{p.hostname} (last_heartbeat: #{p.last_heartbeat_at})\"
  end
"'

# If no processes, restart app
kamal app restart

# Check logs for Solid Queue startup
kamal app logs --grep "Solid Queue"
```

---

## Rollback Procedures

### Scenario: New Server Has Critical Issues

**If you need to rollback to the old server:**

1. **Verify old server is still running**
   ```bash
   ssh deploy@OLD_SERVER_IP
   docker ps
   # Verify contest-hq container is running
   ```

2. **Update DNS back to old server**
   - Change A record for `contesthq.app` back to old IP
   - Wait for DNS propagation (5-10 minutes)

3. **Verify old server is receiving traffic**
   ```bash
   ssh deploy@OLD_SERVER_IP
   docker logs contest-hq-web-1 -f
   # Should see incoming requests
   ```

4. **Create backup from old server**
   ```bash
   # SSH to old server
   ssh deploy@OLD_SERVER_IP
   
   # Run manual backup
   kamal app exec -i 'bin/rails backup:run'
   ```

5. **Document issues with new server**
   - Save logs from new server
   - Document what went wrong
   - Plan fixes before next attempt

### Scenario: Database Restore Corrupted Data

**If restored database has issues:**

1. **Stop application**
   ```bash
   kamal app stop
   ```

2. **Restore from different backup**
   ```bash
   # List backups
   kamal app exec -i 'bin/rails backup:list'
   
   # Restore from earlier backup
   kamal app exec -i 'bin/rails backup:restore[EARLIER_TIMESTAMP]'
   ```

3. **Restart and verify**
   ```bash
   kamal app restart
   kamal app exec -i 'bin/rails runner "puts User.count"'
   ```

---

## Recovery Time Breakdown

| Phase | Task | Estimated Time |
|-------|------|----------------|
| 1 | Provision Hetzner server | 5 minutes |
| 2 | Configure server & install Docker | 10 minutes |
| 3 | Deploy application with Kamal | 15 minutes |
| 4 | Restore database from backup | 10 minutes |
| 5 | Deploy monitoring stack | 10 minutes |
| 6 | Verify infrastructure health | 10 minutes |
| 7 | Update DNS | 5 minutes |
| **Total** | | **65 minutes** |

**Note:** DNS propagation adds 5-60 minutes but doesn't block other work.

---

## Appendix: Quick Reference Commands

### Server Access
```bash
# SSH to production server
ssh deploy@157.180.79.212

# SSH with tunnel for monitoring
ssh -L 3001:localhost:3001 -L 9090:localhost:9090 deploy@157.180.79.212
```

### Kamal Commands
```bash
# Deploy application
kamal setup

# View logs
kamal app logs -f

# Restart application
kamal app restart

# Run Rails console
kamal app exec -i 'bin/rails console'

# Run Rails command
kamal app exec -i 'bin/rails runner "puts User.count"'
```

### Backup Commands
```bash
# List backups
kamal app exec -i 'bin/rails backup:list'

# Verify backup
kamal app exec -i 'bin/rails backup:verify[TIMESTAMP]'

# Restore backup
kamal app exec -i 'bin/rails backup:restore[TIMESTAMP]'

# Run manual backup
kamal app exec -i 'bin/rails backup:run'
```

### Monitoring Commands
```bash
# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | grep health

# Query metrics
curl -s 'http://localhost:9090/api/v1/query?query=puma_running'

# Restart monitoring stack
cd /opt/monitoring && docker compose restart
```

### Health Checks
```bash
# Application health
curl -I https://contesthq.app/up

# Container status
docker ps

# Database check
kamal app exec -i 'bin/rails runner "puts User.count"'

# Solid Queue check
kamal app exec -i 'bin/rails runner "puts SolidQueue::Process.count"'
```

---

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-02-05 | Initial | Created complete disaster recovery guide for Hetzner CX33 |

---

**End of Disaster Recovery Guide**
