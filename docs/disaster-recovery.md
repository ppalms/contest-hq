# Disaster Recovery Plan

## Overview

This document outlines the disaster recovery procedures for Contest HQ production environment.

**Recovery Objectives:**
- **RTO (Recovery Time Objective):** < 1 hour
- **RPO (Recovery Point Objective):** Up to 24 hours (daily backups at 3am)

## Backup Strategy

### What Gets Backed Up

| Component | Frequency | Retention | Location |
|-----------|-----------|-----------|----------|
| Primary SQLite database | Daily at 3am | 30 days | Hetzner Object Storage |
| Old backups cleanup | Weekly (Sundays at 4am) | N/A | Automated |

**Note:** Cache, queue, and cable databases are NOT backed up as they contain transient data.

### Backup Storage

- **Provider:** Hetzner Object Storage (S3-compatible)
- **Bucket:** Configured in Rails credentials
- **Endpoint:** `fsn1.your-objectstorage.com` (or configured region)
- **Path format:** `backups/YYYYMMDD_HHMMSS/production.sqlite3`

## Automated Backups

Backups run automatically via Solid Queue recurring jobs:

```yaml
# config/recurring.yml
production:
  daily_backup:
    class: BackupJob
    schedule: every day at 3am
  
  weekly_backup_cleanup:
    class: BackupCleanupJob
    schedule: every sunday at 4am
```

### Monitoring Backups

Check backup status in production logs:

```bash
# SSH into production server
ssh root@161.35.122.13

# View recent backup logs
docker logs contest-hq-web-1 | grep -i backup

# Or use kamal
kamal app logs --grep backup
```

## Manual Backup Operations

### Run Backup Manually

```bash
# From production server
kamal app exec -i 'bin/rails backup:run'
```

### List Available Backups

```bash
kamal app exec -i 'bin/rails backup:list'
```

Example output:
```
Available backups in contest-hq-backups:

20260203_030000 - 45.23 MB - 2026-02-03 03:00:15 UTC
20260202_030000 - 44.87 MB - 2026-02-02 03:00:12 UTC
20260201_030000 - 44.56 MB - 2026-02-01 03:00:09 UTC

Total: 3 backups
```

### Verify Backup Integrity

```bash
kamal app exec -i 'bin/rails backup:verify[20260203_030000]'
```

## Disaster Recovery Procedures

### Scenario 1: Database Corruption

**Symptoms:** Application errors, data inconsistencies, SQLite errors in logs

**Recovery Steps:**

1. **Identify the issue**
   ```bash
   kamal app logs --grep error
   ```

2. **List available backups**
   ```bash
   kamal app exec -i 'bin/rails backup:list'
   ```

3. **Verify the backup you want to restore**
   ```bash
   kamal app exec -i 'bin/rails backup:verify[TIMESTAMP]'
   ```

4. **Restore from backup** (DESTRUCTIVE)
   ```bash
   kamal app exec -i 'bin/rails backup:restore[TIMESTAMP]'
   ```
   
   This will:
   - Download the backup from Hetzner
   - Create a backup of the current database (`.before_restore`)
   - Replace the database file
   - Prompt for confirmation (type `RESTORE`)

5. **Restart the application**
   ```bash
   kamal app restart
   ```

6. **Verify application is working**
   - Visit https://contest-hq.com/up (should return 200)
   - Test login and basic functionality
   - Check logs for errors

### Scenario 2: Complete Server Failure

**Symptoms:** Server unreachable, hardware failure, hosting provider outage

**Recovery Steps:**

1. **Provision new server**
   - Create new DigitalOcean droplet (or Hetzner server)
   - Update DNS if IP changes
   - Install Docker

2. **Update deployment configuration**
   ```bash
   # On local machine
   # Edit config/deploy.yml with new server IP
   vim config/deploy.yml
   ```

3. **Deploy application**
   ```bash
   kamal setup
   ```

4. **Restore database from backup**
   ```bash
   # List backups
   kamal app exec -i 'bin/rails backup:list'
   
   # Restore latest backup
   kamal app exec -i 'bin/rails backup:restore[TIMESTAMP]'
   ```

5. **Restart and verify**
   ```bash
   kamal app restart
   ```

### Scenario 3: Accidental Data Deletion

**Symptoms:** User reports missing data, records deleted by mistake

**Recovery Steps:**

1. **Assess the damage**
   - Determine what data was deleted
   - Identify when it was deleted
   - Find the most recent backup before deletion

2. **Download backup for inspection**
   ```bash
   # On production server
   kamal app exec -i 'bin/rails runner "
     s3 = Rails.application.config.backup.s3_client
     bucket = Rails.application.config.backup.s3_bucket
     s3.get_object(
       bucket: bucket,
       key: \"backups/TIMESTAMP/production.sqlite3\",
       response_target: \"/tmp/inspect.sqlite3\"
     )
   "'
   ```

3. **Extract specific data** (if full restore not needed)
   ```bash
   # Copy backup locally
   kamal app exec 'cat /tmp/inspect.sqlite3' > inspect.sqlite3
   
   # Open with SQLite
   sqlite3 inspect.sqlite3
   
   # Export specific records
   .mode csv
   .output recovered_data.csv
   SELECT * FROM table_name WHERE ...;
   ```

4. **Import recovered data** or **restore full backup** (see Scenario 1)

## Testing & Verification

### Quarterly Restore Test

**Schedule:** First Sunday of each quarter

**Procedure:**

1. Spin up test server
2. Deploy application
3. Restore from latest backup
4. Verify data integrity
5. Document any issues
6. Destroy test server

### Backup Verification Checklist

Run monthly:

- [ ] Verify backups are running (check logs)
- [ ] Confirm backups exist in Hetzner (run `backup:list`)
- [ ] Verify backup size is reasonable (should grow with data)
- [ ] Test backup download (run `backup:verify`)
- [ ] Confirm old backups are being cleaned up (30-day retention)

## Emergency Contacts

**Primary:** [Your Name/Email]
**Secondary:** [Backup Contact]
**Hetzner Support:** https://console.hetzner.com/support

## Credentials & Access

**Required Access:**
- Production server SSH access
- Rails production credentials master key
- Hetzner Console access (for Object Storage)

**Credentials Location:**
- Master key: `config/master.key` (keep secure backup)
- S3 credentials: Encrypted in `config/credentials/production.yml.enc`

## Post-Recovery Checklist

After any recovery operation:

- [ ] Verify application is accessible
- [ ] Test user login
- [ ] Verify recent data is present
- [ ] Check background jobs are running
- [ ] Monitor error logs for 24 hours
- [ ] Document incident and recovery time
- [ ] Update this runbook if procedures changed

## Known Limitations

1. **RPO is 24 hours** - Data created/modified after last backup will be lost
2. **No point-in-time recovery** - Can only restore to backup timestamps
3. **Manual restore process** - Requires SSH access and manual commands
4. **Single region** - Backups stored in same region as primary (Hetzner EU)

## Future Improvements

Consider implementing:

- [ ] Continuous replication with Litestream
- [ ] Multi-region backup redundancy
- [ ] Automated restore testing
- [ ] Backup monitoring/alerting
- [ ] Shorter backup intervals (hourly)
- [ ] Application-level audit log for data recovery

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-02-03 | Initial | Created disaster recovery plan |
