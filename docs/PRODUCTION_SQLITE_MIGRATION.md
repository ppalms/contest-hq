# Production SQLite Migration Guide

This guide walks through the complete process of migrating Contest HQ production from PostgreSQL to SQLite.

## Pre-Migration Checklist

### Infrastructure Status
- [ ] App Droplet: 161.35.122.13 (will be kept, contains SQLite)
- [ ] Database Droplet: 167.71.21.241 (will be destroyed after migration)
- [ ] Domain: contesthq.app (SSL via Let's Encrypt)
- [ ] Deployment: Kamal via GitHub Actions

### Prerequisites
- [ ] PR #200 merged to main branch
- [ ] GitHub secrets updated (PostgreSQL secrets removed)
- [ ] Staging deployment tested successfully
- [ ] Users notified of maintenance window
- [ ] Backup procedures verified

## Migration Timeline

**Total Estimated Time: 45-60 minutes**
- Preparation: 15-20 minutes
- Actual downtime: 10-15 minutes
- Verification: 15-20 minutes
- Monitoring: Ongoing

## Step-by-Step Migration Process

### Phase 1: Data Backup and Preparation (15-20 minutes)

#### 1.1 Create PostgreSQL Backup
```bash
# SSH to database droplet
ssh root@167.71.21.241

# Create comprehensive backup
timestamp=$(date +%Y%m%d_%H%M%S)
pg_dump -h localhost -U $POSTGRES_USER -d contest_hq_production > /tmp/backup_${timestamp}.sql
pg_dump -h localhost -U $POSTGRES_USER -d contest_hq_production_cache > /tmp/backup_cache_${timestamp}.sql
pg_dump -h localhost -U $POSTGRES_USER -d contest_hq_production_queue > /tmp/backup_queue_${timestamp}.sql
pg_dump -h localhost -U $POSTGRES_USER -d contest_hq_production_cable > /tmp/backup_cable_${timestamp}.sql

# Download backups to local machine
scp root@167.71.21.241:/tmp/backup_*${timestamp}.sql ./backups/

# Verify backup files
ls -la ./backups/backup_*${timestamp}.sql
```

#### 1.2 Set Up Migration Environment Variables
```bash
# On your local machine, create environment file
cat > .env.migration << EOF
OLD_DB_HOST=167.71.21.241
OLD_POSTGRES_PORT=5432
OLD_POSTGRES_DB=contest_hq_production
OLD_POSTGRES_USER=your_postgres_user
OLD_POSTGRES_PASSWORD=your_postgres_password
EOF
```

### Phase 2: Production Deployment (10-15 minutes downtime)

#### 2.1 Enable Maintenance Mode
```bash
# Put application in maintenance mode
kamal app exec 'touch tmp/maintenance.txt'

# Verify maintenance mode is active
curl -I https://contesthq.app
# Should return 503 Service Unavailable
```

#### 2.2 Deploy SQLite Version
```bash
# Create GitHub release to trigger deployment
gh release create v$(date +%Y.%m.%d-%H%M) \
  --title "Production SQLite Migration - $(date)" \
  --notes "Deploy SQLite version and migrate from PostgreSQL"

# Monitor deployment
kamal app logs -f
```

#### 2.3 Execute Data Migration
```bash
# Once deployment completes, run migration
kamal app exec --interactive --reuse 'bash -c "
  export OLD_DB_HOST=167.71.21.241
  export OLD_POSTGRES_USER=your_postgres_user
  export OLD_POSTGRES_PASSWORD=your_postgres_password
  bundle exec rails db:migrate:postgres_to_sqlite RAILS_ENV=production
"'
```

### Phase 3: Verification and Activation (15-20 minutes)

#### 3.1 Data Verification
```bash
# Access Rails console
kamal console

# In Rails console, verify critical data:
puts "Users: #{User.count}"
puts "Contests: #{Contest.count}"
puts "Contest Entries: #{ContestEntry.count}"
puts "Schools: #{School.count}"

# Test key functionality
user = User.first
contest = Contest.first
puts "Sample user: #{user.email}" if user
puts "Sample contest: #{contest.name}" if contest

# Verify authentication works
User.authenticate_by(email: "test@example.com", password: "your_test_password")

# Exit console
exit
```

#### 3.2 Application Health Check
```bash
# Disable maintenance mode
kamal app exec 'rm -f tmp/maintenance.txt'

# Test application endpoints
curl -I https://contesthq.app
curl -s https://contesthq.app/landing | grep "Contest HQ"

# Check application logs
kamal app logs --tail 50
```

#### 3.3 Monitor Application Performance
```bash
# Monitor for 15-20 minutes
watch -n 30 'curl -s -o /dev/null -w "%{http_code} %{time_total}s" https://contesthq.app'

# Check SQLite database file sizes
kamal app exec 'ls -lah storage/*.sqlite3'
```

### Phase 4: Post-Migration Cleanup (After 24-48 hours)

#### 4.1 Infrastructure Cleanup
```bash
# Only after confirming migration success for 24-48 hours
# Destroy database droplet (IRREVERSIBLE)
doctl compute droplet delete database-droplet-id

# Update DNS if needed (usually not required)
```

#### 4.2 Cost Verification
- Monitor DigitalOcean billing for droplet reduction
- Expected savings: $6-12/month

## Rollback Procedures

### Emergency Rollback (if issues discovered within 2 hours)

#### Option A: Revert Deployment
```bash
# Deploy previous version
git checkout previous-commit-hash
gh release create v$(date +%Y.%m.%d-%H%M)-rollback \
  --title "Emergency Rollback" \
  --notes "Rollback from SQLite migration"
```

#### Option B: Restore PostgreSQL Connection
```bash
# Temporarily restore PostgreSQL configuration
# This requires keeping the database droplet running
git revert HEAD~2  # Revert SQLite changes
# Update secrets to include PostgreSQL credentials again
# Deploy rollback version
```

### Full Rollback (if issues discovered after extended time)

1. **Restore from PostgreSQL backup**:
   ```bash
   # On database droplet (if still exists)
   psql -U $POSTGRES_USER -d contest_hq_production < backup_TIMESTAMP.sql
   ```

2. **Revert all configuration changes**
3. **Deploy previous version**

## Monitoring Checklist (24-48 hours post-migration)

- [ ] Application responds correctly to all requests
- [ ] User authentication works
- [ ] Contest creation/editing functions
- [ ] School management works
- [ ] Email notifications send properly
- [ ] Background jobs process (Solid Queue)
- [ ] No unusual error rates in logs
- [ ] Database file sizes are reasonable
- [ ] Performance metrics are acceptable

## Success Criteria

✅ **All functionality working**
✅ **No data loss detected**
✅ **Performance within acceptable ranges**
✅ **No critical errors in logs**
✅ **User-facing features operational**
✅ **Background job processing normal**

## Emergency Contacts

- **Production Issues**: Check application logs first
- **DNS/SSL Issues**: Let's Encrypt auto-renewal should continue
- **Database Issues**: SQLite files in persistent Docker volume
- **Rollback Decision**: Based on user impact assessment

## Post-Migration Benefits Verification

After successful migration, verify:
- [ ] Reduced monthly costs (database droplet eliminated)
- [ ] Simplified deployment process
- [ ] Faster CI/CD pipeline
- [ ] Easier local development setup
- [ ] Single-server architecture simplicity

## Notes

- SQLite databases are stored in Docker persistent volumes
- Multi-database configuration maintained (primary, cache, queue, cable)
- All Rails 8 Solid gems continue to work with SQLite
- Database backups now part of application container backup strategy