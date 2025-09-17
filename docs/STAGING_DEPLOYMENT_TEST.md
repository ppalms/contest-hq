# Staging Deployment Test Guide

This guide provides comprehensive testing procedures for the SQLite migration before production deployment.

## Test Environment Setup

### Option A: Local Testing with Production Data
```bash
# 1. Export production PostgreSQL data
ssh root@167.71.21.241
pg_dump -h localhost -U $POSTGRES_USER contest_hq_production > /tmp/prod_export.sql
scp root@167.71.21.241:/tmp/prod_export.sql ./test_data/

# 2. Setup local PostgreSQL for testing
docker run -d --name postgres-test -e POSTGRES_USER=test -e POSTGRES_PASSWORD=test -p 5433:5432 postgres:17
createdb -h localhost -p 5433 -U test contest_hq_test
psql -h localhost -p 5433 -U test contest_hq_test < ./test_data/prod_export.sql

# 3. Test migration locally
export OLD_DB_HOST=localhost
export OLD_POSTGRES_PORT=5433
export OLD_POSTGRES_USER=test
export OLD_POSTGRES_PASSWORD=test
export OLD_POSTGRES_DB=contest_hq_test

RAILS_ENV=production bundle exec rails db:migrate:postgres_to_sqlite
```

### Option B: DigitalOcean Test Droplet
```bash
# Create temporary test droplet
doctl compute droplet create contest-hq-test \
  --size s-1vcpu-1gb \
  --image ubuntu-24-04-x64 \
  --region nyc1

# Configure test deployment in deploy.yml
# (Temporarily modify for test server)
```

## Pre-Deployment Tests

### 1. Code Quality Verification
```bash
# Ensure all tests pass locally
bin/rails test test:system
bin/rubocop
bin/brakeman --no-pager
bin/importmap audit

# Expected results:
# Tests: 143 runs, 0 failures, 0 errors
# Rubocop: No offenses detected
# Brakeman: No warnings found
# Importmap: No vulnerabilities found
```

### 2. Database Schema Verification
```bash
# Check SQLite schema matches PostgreSQL
bin/rails db:schema:dump
# Compare with original PostgreSQL schema

# Verify multi-database configuration
bin/rails runner "
  puts 'Primary DB: ' + ActiveRecord::Base.connection.adapter_name
  puts 'Cache DB: ' + ActiveRecord::SolidCache::Entry.connection.adapter_name
  puts 'Queue DB: ' + ActiveRecord::SolidQueue::Job.connection.adapter_name
  puts 'Cable DB: ' + ActionCable::SubscriptionAdapter::PostgreSQL.connection.adapter_name rescue 'Cable: SQLite (expected)'
"
```

### 3. Migration Script Testing
```bash
# Test migration script dry-run
RAILS_ENV=production bundle exec rails runner "
  # Simulate migration without committing
  puts 'Testing migration script...'
  # Add validation logic here
"
```

## Deployment Testing

### 1. Deploy to Test Environment
```bash
# Deploy to staging/test server
kamal deploy -d staging  # If staging config available

# OR manually deploy to test droplet
git push staging sqlite-migration
```

### 2. Post-Deployment Verification

#### Application Health
```bash
# Basic connectivity
curl -I https://test-server-url
# Expected: HTTP 200 OK

# Application loads
curl -s https://test-server-url/landing | grep "Contest HQ"
# Expected: Should find "Contest HQ" in response

# Assets loading
curl -I https://test-server-url/assets/application.css
# Expected: HTTP 200 OK
```

#### Database Functionality
```bash
# Connect to test Rails console
kamal console -d staging  # or ssh to test server + rails console

# Basic data queries
User.count
Contest.count
School.count

# Test relationships
User.first.contest_entries.count
School.first.users.count

# Test search functionality (LIKE queries)
School.where("name LIKE ?", "%test%").count
User.where("email LIKE ?", "%@example.com%").count
```

#### Authentication Testing
```bash
# In Rails console
user = User.first
puts "User: #{user.email}"

# Test password authentication
User.authenticate_by(email: user.email, password: "test_password")
# Should return user object or nil
```

#### Background Jobs Testing
```bash
# Test Solid Queue functionality
SolidQueue::Job.count

# Create test job
class TestJob < ApplicationJob
  def perform
    Rails.logger.info "Test job executed successfully at #{Time.current}"
  end
end

TestJob.perform_later
sleep 5
# Check if job was processed
```

## Functional Testing Checklist

### User Management
- [ ] User registration works
- [ ] User login/logout works
- [ ] Password reset functions
- [ ] User profile updates
- [ ] Role assignment works

### Contest Management
- [ ] Contest creation
- [ ] Contest editing
- [ ] Contest deletion
- [ ] Contest search/filter
- [ ] Contest entries management

### School Management
- [ ] School creation
- [ ] School editing
- [ ] School search (LIKE queries)
- [ ] School-user relationships

### System Features
- [ ] Email notifications send
- [ ] File uploads work (if any)
- [ ] Background jobs process
- [ ] Multi-tenant functionality
- [ ] Time zone handling

## Performance Testing

### Database Performance
```bash
# Time critical queries
time_start = Time.current
User.includes(:contest_entries).limit(100).to_a
puts "Query time: #{Time.current - time_start}s"

# Should be under 1-2 seconds for reasonable data sizes
```

### Memory Usage
```bash
# Check SQLite database sizes
ls -lah storage/*.sqlite3

# Expected sizes depend on data volume
# Should be reasonable (< 1GB for typical usage)
```

### Response Time Testing
```bash
# Test response times
for endpoint in "/" "/landing" "/users" "/contests" "/organizations/schools"; do
  echo "Testing $endpoint"
  curl -s -w "Time: %{time_total}s\n" -o /dev/null https://test-server-url$endpoint
done

# Expected: All under 2-3 seconds
```

## Data Integrity Testing

### Record Counts Verification
```bash
# Compare counts between PostgreSQL and SQLite
# (This requires access to both databases during testing)

# PostgreSQL counts
psql -h 167.71.21.241 -U $POSTGRES_USER contest_hq_production -c "
SELECT
  'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT
  'contests' as table_name, COUNT(*) as count FROM contests
UNION ALL
SELECT
  'schools' as table_name, COUNT(*) as count FROM schools
UNION ALL
SELECT
  'contest_entries' as table_name, COUNT(*) as count FROM contest_entries;
"

# SQLite counts (in Rails console)
puts "Users: #{User.count}"
puts "Contests: #{Contest.count}"
puts "Schools: #{School.count}"
puts "Contest Entries: #{ContestEntry.count}"

# Counts should match exactly
```

### Data Sampling
```bash
# Sample data verification
# Check that specific important records exist correctly

# In Rails console:
# Test user
user = User.find_by(email: 'known_production_email@example.com')
puts "User found: #{user.present?}"
puts "User roles: #{user.roles.pluck(:name)}" if user

# Test contest
contest = Contest.find_by(name: 'Known Contest Name')
puts "Contest found: #{contest.present?}"
puts "Contest entries: #{contest.contest_entries.count}" if contest
```

## Error Testing

### Handle Error Conditions
```bash
# Test database errors gracefully
# In Rails console:
begin
  # Try invalid query
  ActiveRecord::Base.connection.execute("SELECT * FROM nonexistent_table")
rescue => e
  puts "Error handled: #{e.class}"
end

# Test connection limits
# Create many simultaneous connections
```

### Log Analysis
```bash
# Check for errors in logs
kamal app logs --tail 100 | grep -i error
kamal app logs --tail 100 | grep -i exception

# Expected: No critical errors during normal operation
```

## Staging Test Results Template

### Test Summary
- **Environment**: [staging server details]
- **Test Date**: [date and time]
- **Database Migration**: [success/failure]
- **Data Records Migrated**: [counts]
- **Test Duration**: [total test time]

### Functional Tests
| Feature | Status | Notes |
|---------|--------|-------|
| User Authentication | ✅/❌ | [details] |
| Contest Management | ✅/❌ | [details] |
| School Management | ✅/❌ | [details] |
| Search Functionality | ✅/❌ | [details] |
| Background Jobs | ✅/❌ | [details] |
| Email Notifications | ✅/❌ | [details] |

### Performance Results
| Metric | Value | Acceptable? |
|--------|-------|-------------|
| Database Migration Time | [minutes] | < 15 min |
| Average Response Time | [seconds] | < 2 sec |
| Database Size | [MB/GB] | Reasonable |
| Memory Usage | [MB] | < 512 MB |

### Issues Found
- [ ] Issue 1: [description and severity]
- [ ] Issue 2: [description and severity]
- [ ] Issue 3: [description and severity]

### Go/No-Go Decision
- [ ] **GO** - All critical tests pass, ready for production
- [ ] **NO-GO** - Critical issues found, need fixes before production

### Next Steps
- [ ] Fix identified issues
- [ ] Re-test problem areas
- [ ] Schedule production migration
- [ ] OR investigate alternative approaches

## Test Cleanup

### After Testing
```bash
# Remove test data
rm -rf test_data/

# Stop test containers
docker stop postgres-test
docker rm postgres-test

# Clean up test droplet (if used)
doctl compute droplet delete contest-hq-test

# Reset any temporary configuration changes
git checkout -- config/deploy.yml  # if modified for testing
```

---

**Only proceed to production migration if ALL critical tests pass in staging!**