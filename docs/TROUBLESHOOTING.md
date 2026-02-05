# Troubleshooting Guide

Common issues and solutions for Contest HQ.

## Table of Contents

- [Application Issues](#application-issues)
- [Database Issues](#database-issues)
- [Deployment Issues](#deployment-issues)
- [Monitoring Issues](#monitoring-issues)
- [Performance Issues](#performance-issues)

---

## Application Issues

### Application Won't Start

**Symptoms:**
- Server fails to start
- Error messages in logs

**Solutions:**

1. **Check database connectivity:**
   ```bash
   bin/rails db:version
   ```

2. **Check for pending migrations:**
   ```bash
   bin/rails db:migrate:status
   ```

3. **Check logs:**
   ```bash
   tail -f log/development.log
   ```

4. **Verify dependencies:**
   ```bash
   bundle install
   yarn install
   ```

### 500 Internal Server Error

**Symptoms:**
- Application returns 500 errors
- Error pages shown to users

**Solutions:**

1. **Check application logs:**
   ```bash
   tail -f log/production.log
   ```

2. **Check for exceptions:**
   - Look for stack traces in logs
   - Check error tracking service (if configured)

3. **Verify database:**
   ```bash
   bin/rails dbconsole
   # Run: SELECT 1;
   ```

### Slow Response Times

**Symptoms:**
- Pages load slowly
- Timeouts

**Solutions:**

1. **Check database queries:**
   - Look for N+1 queries in logs
   - Use `includes()` to eager load associations

2. **Check background jobs:**
   ```bash
   bin/rails solid_queue:status
   ```

3. **Monitor metrics:**
   - Check Grafana for slow endpoints
   - Identify bottlenecks

---

## Database Issues

### Database Locked

**Symptoms:**
- `SQLite3::BusyException: database is locked`

**Solutions:**

1. **Check for long-running queries:**
   ```bash
   # In Rails console
   ActiveRecord::Base.connection.execute("PRAGMA busy_timeout = 5000")
   ```

2. **Restart application:**
   ```bash
   # Development
   bin/dev

   # Production (see deployment docs)
   ```

### Migration Fails

**Symptoms:**
- Migration errors
- Schema mismatch

**Solutions:**

1. **Rollback and retry:**
   ```bash
   bin/rails db:rollback
   bin/rails db:migrate
   ```

2. **Check migration file:**
   - Verify syntax
   - Check for conflicts

3. **Reset database (development only):**
   ```bash
   bin/rails db:reset
   ```

### Data Corruption

**Symptoms:**
- Unexpected data values
- Constraint violations

**Solutions:**

1. **Restore from backup:**
   - See disaster recovery docs in 1Password

2. **Run data integrity checks:**
   ```ruby
   # In Rails console
   User.find_each { |u| u.valid? || puts("Invalid: #{u.id}") }
   ```

---

## Deployment Issues

### Deployment Fails

**Symptoms:**
- Kamal deployment errors
- Application not accessible

**Solutions:**

1. **Check Kamal logs:**
   ```bash
   kamal app logs --tail 100
   ```

2. **Verify environment variables:**
   ```bash
   # Check .kamal/secrets
   cat .kamal/secrets
   ```

3. **Check server connectivity:**
   ```bash
   ssh deploy@<SERVER_IP>
   docker ps
   ```

### Container Won't Start

**Symptoms:**
- Container exits immediately
- Health checks fail

**Solutions:**

1. **Check container logs:**
   ```bash
   kamal app logs
   ```

2. **Verify image:**
   ```bash
   kamal app images
   ```

3. **Check health endpoint:**
   ```bash
   curl http://localhost:3000/up
   ```

---

## Monitoring Issues

### Grafana Shows "No Data"

**Symptoms:**
- Dashboards empty
- No metrics visible

**Solutions:**

1. **Check Prometheus connection:**
   - Go to: Connections → Data Sources → Prometheus
   - Click "Save & Test"

2. **Verify metrics endpoint:**
   ```bash
   curl http://localhost:3000/metrics
   ```

3. **Check time range:**
   - Set to "Last 15 minutes"
   - Metrics only exist from when Prometheus started

4. **Wait for data collection:**
   - Prometheus scrapes every 15 seconds
   - May take 1-2 minutes for data to appear

### Prometheus Not Scraping

**Symptoms:**
- Targets show as "DOWN"
- No metrics collected

**Solutions:**

1. **Check Prometheus targets:**
   ```bash
   curl http://localhost:9090/api/v1/targets
   ```

2. **Verify network connectivity:**
   - Ensure containers are on same network
   - Check firewall rules

3. **Restart Prometheus:**
   ```bash
   kamal accessory restart prometheus
   ```

---

## Performance Issues

### High Memory Usage

**Symptoms:**
- Application using excessive memory
- Out of memory errors

**Solutions:**

1. **Check memory usage:**
   ```bash
   docker stats
   ```

2. **Analyze memory leaks:**
   - Use memory profiler gem
   - Check for unbounded collections

3. **Increase memory limit:**
   - Update deployment configuration
   - Scale server if needed

### High CPU Usage

**Symptoms:**
- CPU at 100%
- Slow response times

**Solutions:**

1. **Check CPU usage:**
   ```bash
   docker stats
   ```

2. **Identify hot spots:**
   - Check Grafana for slow endpoints
   - Profile with rack-mini-profiler

3. **Optimize code:**
   - Add database indexes
   - Cache expensive operations
   - Move work to background jobs

### Background Jobs Backing Up

**Symptoms:**
- Jobs not processing
- Queue depth increasing

**Solutions:**

1. **Check Solid Queue:**
   ```bash
   bin/rails solid_queue:status
   ```

2. **Check for failed jobs:**
   ```ruby
   # In Rails console
   SolidQueue::Job.failed.count
   ```

3. **Increase workers:**
   - Update Solid Queue configuration
   - Scale if needed

---

## Getting More Help

### Logs to Check

**Application Logs:**
```bash
# Development
tail -f log/development.log

# Production
kamal app logs --tail 100
```

**Container Logs:**
```bash
# All containers
docker ps
docker logs <container_id>

# Specific accessory
kamal accessory logs prometheus
kamal accessory logs grafana
```

### Diagnostic Commands

**Check application health:**
```bash
curl http://localhost:3000/up
```

**Check database:**
```bash
bin/rails dbconsole
```

**Check background jobs:**
```bash
bin/rails solid_queue:status
```

**Check metrics:**
```bash
curl http://localhost:3000/metrics
```

### When to Escalate

Contact infrastructure team if:
- Data loss or corruption
- Security incident
- Complete service outage
- Database restore needed

Refer to disaster recovery documentation in 1Password for emergency procedures.

---

## Additional Resources

- [Development Guide](DEVELOPMENT.md)
- [Monitoring Guide](MONITORING.md)
- [Quick Reference](QUICK-REFERENCE.md)
- Disaster Recovery Docs (1Password)
