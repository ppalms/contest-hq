# SQLite Migration Rollback Procedures

This document provides comprehensive rollback procedures for the PostgreSQL to SQLite migration.

## Critical Prerequisites

### 🚨 BEFORE STARTING MIGRATION
- [ ] **DO NOT destroy PostgreSQL database droplet until 48 hours post-migration**
- [ ] **Keep PostgreSQL backups for at least 7 days**
- [ ] **Maintain access to pre-migration codebase**

## Rollback Decision Matrix

| Issue Severity | Time Since Migration | Recommended Action |
|---------------|---------------------|-------------------|
| **Critical** (data loss, auth failure) | < 2 hours | **Emergency Rollback** |
| **High** (major functionality broken) | 2-24 hours | **Planned Rollback** |
| **Medium** (performance issues) | 24-48 hours | **Fix Forward or Rollback** |
| **Low** (minor issues) | > 48 hours | **Fix Forward** |

## Emergency Rollback (< 2 hours post-migration)

### Symptoms Requiring Emergency Rollback
- Users cannot authenticate
- Data appears missing or corrupted
- Critical application errors
- Complete site outage

### Emergency Rollback Steps

#### Step 1: Enable Maintenance Mode
```bash
# Immediately put site in maintenance mode
kamal app exec 'touch tmp/maintenance.txt'

# Verify maintenance mode
curl -I https://contesthq.app
# Should return 503
```

#### Step 2: Quick Deploy Previous Version
```bash
# Find the commit before SQLite migration
git log --oneline -10

# Checkout previous commit (before migration)
git checkout 913dbf1  # Replace with actual pre-migration commit

# Emergency release deployment
gh release create v$(date +%Y.%m.%d-%H%M)-emergency-rollback \
  --title "EMERGENCY ROLLBACK - SQLite Migration" \
  --notes "Emergency rollback from SQLite migration due to critical issues"

# Monitor deployment
kamal app logs -f
```

#### Step 3: Restore PostgreSQL Configuration
```bash
# Restore original deploy.yml if needed
git checkout main -- config/deploy.yml

# Restore PostgreSQL secrets in .kamal/secrets
# (Uncomment PostgreSQL variables)
```

#### Step 4: Verify PostgreSQL Database
```bash
# SSH to database droplet
ssh root@167.71.21.241

# Verify PostgreSQL is running
systemctl status postgresql
sudo -u postgres psql -c "SELECT version();"

# Test database connection
sudo -u postgres psql contest_hq_production -c "SELECT COUNT(*) FROM users;"
```

#### Step 5: Remove Maintenance Mode
```bash
# Once rollback deployment completes
kamal app exec 'rm -f tmp/maintenance.txt'

# Test application
curl -s https://contesthq.app/landing | grep "Contest HQ"
```

**Emergency Rollback Time: 10-15 minutes**

## Planned Rollback (2-24 hours post-migration)

Use this for non-critical issues that require more careful rollback.

### Step 1: Assessment
```bash
# Document current issues
# Take screenshots of errors
# Export current SQLite data as backup
kamal app exec --interactive --reuse 'bundle exec rails db:migrate:backup_sqlite RAILS_ENV=production'
```

### Step 2: Communication
- Notify users of planned maintenance window
- Schedule rollback during low-traffic hours

### Step 3: Rollback Execution
Follow Emergency Rollback steps but with more careful verification at each stage.

## Data Recovery Rollback (> 24 hours post-migration)

### Scenario A: PostgreSQL Droplet Still Exists

#### Data Verification
```bash
# Compare current SQLite data with PostgreSQL backup
ssh root@167.71.21.241

# Check PostgreSQL data currency
sudo -u postgres psql contest_hq_production -c "
  SELECT
    'users' as table_name,
    COUNT(*) as count,
    MAX(updated_at) as last_updated
  FROM users
  UNION ALL
  SELECT
    'contests' as table_name,
    COUNT(*) as count,
    MAX(updated_at) as last_updated
  FROM contests;
"
```

#### Data Loss Assessment
```bash
# If data created after migration needs to be preserved
# Export recent SQLite data
kamal console
# In Rails console:
recent_data = User.where('created_at > ?', Time.parse('2024-XX-XX XX:XX:XX UTC'))
File.write('/tmp/recent_users.json', recent_data.to_json)
# Similar for other tables with recent changes
```

### Scenario B: PostgreSQL Droplet Destroyed

#### Restore from Backup
```bash
# Create new PostgreSQL droplet
doctl compute droplet create postgresql-restore \
  --size s-1vcpu-1gb \
  --image ubuntu-24-04-x64 \
  --region nyc1

# Install PostgreSQL
ssh root@NEW_DROPLET_IP
apt update && apt install -y postgresql postgresql-client

# Restore from backup
createdb -U postgres contest_hq_production
psql -U postgres contest_hq_production < backup_TIMESTAMP.sql
```

## Rollback Verification Checklist

### Functional Testing
- [ ] User registration/login works
- [ ] Contest creation functions
- [ ] School management works
- [ ] Email notifications send
- [ ] Admin functions accessible
- [ ] Background jobs processing

### Data Integrity Checks
```bash
# Key data counts
kamal console
User.count
Contest.count
ContestEntry.count
School.count

# Recent activity
User.where('created_at > ?', 1.week.ago).count
Contest.where('created_at > ?', 1.month.ago).count
```

### Performance Verification
```bash
# Response time check
curl -w "%{time_total}" -s -o /dev/null https://contesthq.app

# Database query performance
kamal console
# Test complex queries
User.joins(:contest_entries).group(:user_id).count.keys.count
```

## Post-Rollback Actions

### Immediate (within 1 hour)
- [ ] Remove maintenance mode
- [ ] Test all critical user flows
- [ ] Monitor error logs for 30 minutes
- [ ] Communicate rollback completion to users

### Short-term (within 24 hours)
- [ ] Document rollback reasons
- [ ] Analyze what went wrong with migration
- [ ] Plan fixes for identified issues
- [ ] Schedule new migration attempt (if desired)

### Medium-term (within 1 week)
- [ ] Review rollback procedures effectiveness
- [ ] Update migration plan based on lessons learned
- [ ] Decide on next steps (retry migration or stay with PostgreSQL)

## Rollback Decision Points

### Stay with PostgreSQL if:
- Multiple migration attempts failed
- Data complexity makes migration risky
- PostgreSQL-specific features are needed
- Team comfort level with current setup

### Retry Migration if:
- Issues were deployment/configuration related
- Benefits still outweigh risks
- Lessons learned address previous failures
- Clear fixes identified for rollback causes

## Communication Templates

### Emergency Rollback Notice
```
🚨 Service Alert: Contest HQ Maintenance

We've identified an issue with our recent system update and are rolling back to ensure service stability.

Expected downtime: 10-15 minutes
Status updates: [status page or Twitter]

We apologize for any inconvenience.
```

### Planned Rollback Notice
```
📅 Scheduled Maintenance: Contest HQ

We're reverting a recent system update to address performance issues.

Maintenance Window: [DATE] [TIME] (15-20 minutes)
Impact: Brief service interruption
Alternative: [if any]

Thank you for your patience.
```

## Lessons Learned Template

### Post-Rollback Analysis
- **What went wrong**: [technical details]
- **Root cause**: [underlying issue]
- **Detection time**: [how quickly issue was found]
- **Rollback time**: [total time to rollback]
- **Data impact**: [any data loss or corruption]
- **User impact**: [service disruption details]

### Improvements for Next Attempt
- [ ] Better testing procedures
- [ ] Enhanced monitoring
- [ ] Improved rollback automation
- [ ] Additional safeguards
- [ ] Team preparation

## Emergency Contacts

- **Technical Issues**: Application logs, database logs
- **Infrastructure**: DigitalOcean dashboard, Kamal commands
- **DNS/SSL**: CloudFlare or DNS provider
- **User Communication**: Status page, social media accounts

---

**Remember: Better to rollback safely than risk extended downtime or data loss.**