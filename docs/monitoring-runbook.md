# Monitoring Operations Runbook

## Daily Operations

### Check System Health

```bash
# Application health
curl https://contesthq.app/up

# Metrics endpoint
curl http://<SERVER_IP>:9394/metrics | head -20

# Prometheus targets
curl http://<SERVER_IP>:9090/api/v1/targets | jq '.data.activeTargets[].health'
```

### View Dashboards

1. Open https://metrics.contesthq.app
2. Login with admin credentials
3. Check dashboards:
   - Rails Application Metrics
   - Puma Server Metrics

## Common Tasks

### Restart Monitoring Stack

```bash
ssh deploy@<SERVER_IP>
cd /opt/monitoring
docker compose restart
```

### View Prometheus Metrics

```bash
# SSH to server
ssh deploy@<SERVER_IP>

# Query Prometheus
curl 'http://localhost:9090/api/v1/query?query=rails_requests_total'
```

### Import New Dashboard

1. Go to Grafana → Dashboards → Import
2. Enter dashboard ID or paste JSON
3. Select Prometheus datasource
4. Click Import

### Backup Grafana Dashboards

```bash
ssh deploy@<SERVER_IP>
cd /opt/monitoring
docker compose exec grafana grafana-cli admin export-dashboard > backup.json
```

## Troubleshooting

### Metrics Not Showing in Grafana

1. Check Prometheus is scraping:
   ```bash
   curl http://<SERVER_IP>:9090/targets
   ```

2. Check OTel Collector is running:
   ```bash
   kamal accessory logs otel_collector
   ```

3. Check app is exposing metrics:
   ```bash
   curl http://<SERVER_IP>:9394/metrics
   ```

### Grafana Not Accessible

1. Check container is running:
   ```bash
   ssh deploy@<SERVER_IP>
   cd /opt/monitoring
   docker compose ps
   ```

2. Check logs:
   ```bash
   docker compose logs grafana
   ```

3. Restart if needed:
   ```bash
   docker compose restart grafana
   ```

### High Memory Usage

1. Check Prometheus retention:
   ```bash
   # Current setting: 30 days
   # Reduce if needed in prometheus.yml
   ```

2. Check Grafana query performance:
   - Reduce dashboard refresh rates
   - Optimize queries

### OTel Collector Not Scraping

1. Check container is running:
   ```bash
   kamal accessory logs otel_collector
   ```

2. Verify Docker socket access:
   ```bash
   kamal accessory exec otel_collector ls -la /var/run/docker.sock
   ```

3. Restart if needed:
   ```bash
   kamal accessory restart otel_collector
   ```

## Key Metrics to Monitor

### Application Health
- **Request Rate:** `rate(rails_requests_total[5m])`
- **Error Rate:** `rate(rails_requests_total{status=~"5.."}[5m])`
- **Response Time (p95):** `histogram_quantile(0.95, rails_request_duration_seconds)`

### Server Health
- **Puma Workers:** `puma_workers`
- **Thread Pool Usage:** `puma_pool_capacity`
- **Memory Usage:** Check via Grafana system metrics

### Background Jobs
- **Queue Depth:** Monitor Solid Queue metrics
- **Job Failures:** Check application logs

## Alerts (Future)

To be configured:
- High error rate (>1%)
- Slow response time (p95 >1s)
- Worker saturation (>80%)
- Disk space (>80%)
- Job queue backlog (>100)

## Useful Queries

### Top 10 Slowest Endpoints
```promql
topk(10, histogram_quantile(0.95, 
  rate(rails_request_duration_seconds_bucket[5m])
))
```

### Error Rate by Controller
```promql
sum by (controller) (
  rate(rails_requests_total{status=~"5.."}[5m])
)
```

### Request Rate Over Time
```promql
sum(rate(rails_requests_total[5m]))
```

## Maintenance Schedule

- **Daily:** Check dashboards for anomalies
- **Weekly:** Review slow queries and errors
- **Monthly:** Verify backup integrity
- **Quarterly:** Test disaster recovery
