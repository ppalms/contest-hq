# Monitoring Guide

Contest HQ uses Prometheus and Grafana for application monitoring and observability.

## Overview

**Monitoring Stack:**
- **Prometheus:** Metrics collection and storage
- **Grafana:** Visualization and dashboards
- **Yabeda:** Ruby metrics instrumentation

**Metrics Collected:**
- Request rate, duration, and status codes
- Database query performance
- Puma thread pool usage
- Background job queue depth
- Memory and GC statistics

## Accessing Grafana

**Production:** https://metrics.contesthq.app

**Credentials:** Stored in 1Password (search for "Grafana Admin Password")

## Available Dashboards

### 1. Yabeda Rails Application Metrics (ID: 14133)

Displays Rails-specific metrics:
- **Request Throughput:** Requests per second by endpoint
- **Response Times:** p50, p95, p99 latencies
- **Error Rates:** 4xx and 5xx responses
- **Database Performance:** Query count and duration
- **View Rendering:** Template rendering times
- **ActiveJob:** Queue depth and job duration

### 2. Yabeda Puma Server Metrics (ID: 14134)

Displays Puma web server metrics:
- **Thread Pool:** Active threads, capacity, backlog
- **Worker Memory:** Memory usage per worker
- **Request Queue:** Queued requests waiting for threads
- **Connections:** Active and idle connections

## Setting Up Grafana

### First-Time Setup

1. **Login to Grafana:**
   - Navigate to: https://metrics.contesthq.app
   - Username: `admin`
   - Password: From 1Password

2. **Verify Prometheus Connection:**
   - Go to: Connections → Data Sources
   - Click "Prometheus"
   - Click "Save & Test"
   - Should show: ✅ "Data source is working"

3. **Import Dashboards:**

   **Import Yabeda Rails Dashboard:**
   - Click "+" → "Import"
   - Enter dashboard ID: `14133`
   - Click "Load"
   - Select datasource: "Prometheus"
   - Click "Import"

   **Import Yabeda Puma Dashboard:**
   - Click "+" → "Import"
   - Enter dashboard ID: `14134`
   - Click "Load"
   - Select datasource: "Prometheus"
   - Click "Import"

4. **Verify Data:**
   - Open "Yabeda Rails" dashboard
   - Set time range to "Last 15 minutes"
   - Should see live metrics

## Understanding Metrics

### Request Metrics

```promql
# Request rate (requests per second)
rate(yabeda_rails_requests_total[5m])

# Response time (95th percentile)
histogram_quantile(0.95, rate(yabeda_rails_request_duration_seconds_bucket[5m]))

# Error rate
rate(yabeda_rails_requests_total{status=~"5.."}[5m])
```

### Database Metrics

```promql
# Database query rate
rate(yabeda_rails_db_query_total[5m])

# Database query duration (95th percentile)
histogram_quantile(0.95, rate(yabeda_rails_db_query_duration_seconds_bucket[5m]))
```

### Puma Metrics

```promql
# Thread pool usage
yabeda_puma_running / yabeda_puma_pool_capacity

# Request backlog
yabeda_puma_backlog

# Worker memory
yabeda_puma_worker_memory_bytes
```

## Creating Custom Dashboards

### 1. Create New Dashboard

- Click "+" → "Dashboard"
- Click "Add new panel"

### 2. Add Metrics

Example panels:

**Request Rate:**
```promql
rate(yabeda_rails_requests_total[5m])
```

**Response Time (p95):**
```promql
histogram_quantile(0.95, rate(yabeda_rails_request_duration_seconds_bucket[5m]))
```

**Database Queries:**
```promql
rate(yabeda_rails_db_query_total[5m])
```

**Error Rate:**
```promql
rate(yabeda_rails_requests_total{status=~"5.."}[5m]) / rate(yabeda_rails_requests_total[5m])
```

### 3. Configure Panel

- Set visualization type (Graph, Gauge, Stat, etc.)
- Configure axes and units
- Set thresholds and colors
- Add panel title and description

### 4. Save Dashboard

- Click "Save dashboard"
- Enter name and folder
- Click "Save"

## Setting Up Alerts

### 1. Create Alert Rule

- Open a dashboard panel
- Click "Edit"
- Go to "Alert" tab
- Click "Create alert rule from this panel"

### 2. Configure Alert Conditions

Example: High Error Rate
```
WHEN avg() OF query(A, 5m, now) IS ABOVE 0.05
```

Example: Slow Response Time
```
WHEN avg() OF query(A, 5m, now) IS ABOVE 1000
```

### 3. Configure Notifications

- Set alert name and severity
- Add notification channel (email, Slack, etc.)
- Set notification message

### 4. Test Alert

- Click "Test rule"
- Verify notification is received

## Troubleshooting

### No Data in Dashboards

**Check Prometheus is scraping:**
```bash
# SSH to server
ssh deploy@<SERVER_IP>

# Check Prometheus targets
curl -s 'http://localhost:9090/api/v1/targets' | grep -o '"health":"[^"]*"'

# Should show: "health":"up"
```

**Check Rails metrics endpoint:**
```bash
# From server
curl -s http://localhost:3000/metrics | head -20

# Should show Prometheus-format metrics
```

**Check Grafana datasource:**
- Go to: Connections → Data Sources → Prometheus
- Click "Save & Test"
- Should show: ✅ "Data source is working"

### Grafana Shows "Data source is working" but No Metrics

**Wait for data collection:**
- Prometheus scrapes every 15 seconds
- May take 1-2 minutes for data to appear
- Refresh dashboard

**Check time range:**
- Set to "Last 15 minutes" or "Last 1 hour"
- Metrics only exist from when Prometheus started

### High Memory Usage

**Check Prometheus retention:**
- Default: 30 days
- Adjust in deployment configuration if needed

**Check Grafana cache:**
- Clear browser cache
- Restart Grafana container

## Metrics Retention

**Prometheus:**
- Retention: 30 days
- Scrape interval: 15 seconds
- Storage: SQLite-backed

**Grafana:**
- Dashboards: Persistent (stored in SQLite)
- User sessions: 7 days
- Query cache: 1 hour

## Best Practices

1. **Set appropriate time ranges** - Use "Last 15 minutes" for real-time, "Last 24 hours" for trends

2. **Use percentiles for latency** - p95 and p99 are more useful than averages

3. **Create alerts for critical metrics:**
   - Error rate >5%
   - Response time p95 >1s
   - Memory usage >80%
   - Thread pool exhaustion

4. **Organize dashboards by purpose:**
   - Application health (requests, errors, latency)
   - Infrastructure (CPU, memory, disk)
   - Business metrics (users, contests, entries)

5. **Document custom dashboards** - Add descriptions to panels and variables

## Additional Resources

- [Prometheus Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Yabeda Gem](https://github.com/yabeda-rb/yabeda)

## Getting Help

- Check [Troubleshooting Guide](TROUBLESHOOTING.md)
- Review Grafana logs (see deployment docs in 1Password)
- Contact infrastructure team
