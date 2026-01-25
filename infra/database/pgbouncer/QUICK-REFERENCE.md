# PgBouncer Quick Reference Guide

**Version:** 1.0
**Last Updated:** 2026-01-25

---

## Quick Start

```bash
# Deploy PgBouncer
cd /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database/pgbouncer
./deploy-pgbouncer.sh

# Test installation
./test-pgbouncer.sh

# Monitor in real-time
./monitor-pgbouncer.sh 5
```

---

## Connection Strings

### Via PgBouncer (Pooled - RECOMMENDED)
```bash
psql -h localhost -p 6432 -U perseus_admin -d perseus_dev
```

### Direct to PostgreSQL (Admin Only)
```bash
psql -h localhost -p 5432 -U perseus_admin -d perseus_dev
```

### PgBouncer Admin Console
```bash
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer
```

---

## Common Commands

### View Pool Status
```sql
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW POOLS;"
```

### View Statistics
```sql
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW STATS;"
```

### View Active Connections
```sql
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW CLIENTS;"
```

### View Server Connections
```sql
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW SERVERS;"
```

### View Configuration
```sql
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW CONFIG;"
```

---

## Pool Management

### Pause All Connections (Maintenance Mode)
```sql
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "PAUSE;"
```

### Resume Connections
```sql
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "RESUME;"
```

### Reload Configuration (No Downtime)
```sql
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "RELOAD;"
```

### Graceful Shutdown
```sql
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHUTDOWN;"
```

---

## Container Management

### Start PgBouncer
```bash
cd /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database
docker-compose up -d pgbouncer
```

### Stop PgBouncer
```bash
docker-compose stop pgbouncer
```

### Restart PgBouncer
```bash
docker-compose restart pgbouncer
```

### View Logs
```bash
docker-compose logs -f pgbouncer
```

### Check Container Status
```bash
docker ps | grep pgbouncer
```

---

## Monitoring Queries

### Check for Waiting Clients
```sql
SELECT database, cl_waiting
FROM pgbouncer.pools
WHERE cl_waiting > 0;
```

### Pool Utilization
```sql
SELECT
    database,
    sv_active,
    pool_size,
    ROUND(100.0 * sv_active / NULLIF(pool_size, 0), 2) AS utilization_pct
FROM pgbouncer.pools
WHERE database != 'pgbouncer';
```

### Transaction Throughput
```sql
SELECT
    database,
    total_xact_count AS transactions,
    total_query_count AS queries,
    ROUND(avg_xact_time / 1000, 2) AS avg_xact_ms,
    ROUND(avg_query_time / 1000, 2) AS avg_query_ms
FROM pgbouncer.stats
WHERE database = 'perseus_dev';
```

---

## Troubleshooting

### Connection Failed

**Check container status:**
```bash
docker ps | grep pgbouncer
```

**Check logs:**
```bash
docker-compose logs pgbouncer | tail -50
```

**Verify PostgreSQL is running:**
```bash
psql -h localhost -p 5432 -U perseus_admin -d perseus_dev -c "SELECT 1;"
```

### Clients Waiting

**Check pool status:**
```sql
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW POOLS;"
```

**Increase pool size temporarily:**
```sql
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SET default_pool_size = 50; RELOAD;"
```

**Increase pool size permanently:**
```bash
# Edit pgbouncer.ini
vim /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database/pgbouncer/pgbouncer.ini

# Change: default_pool_size = 50
# Restart: docker-compose restart pgbouncer
```

### Authentication Failed

**Regenerate userlist.txt:**
```bash
cd /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database/pgbouncer
./generate-userlist.sh
docker-compose restart pgbouncer
```

---

## Maintenance Tasks

### Daily Health Check
```bash
# Quick status
docker ps | grep perseus

# Pool status
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW POOLS;"
```

### Weekly Review
```bash
# Check logs for errors
docker-compose logs --since 7d pgbouncer | grep -i error

# Review statistics
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW STATS;"
```

### Monthly Password Rotation
```bash
# 1. Change PostgreSQL password
psql -h localhost -p 5432 -U postgres -d postgres -c \
  "ALTER USER perseus_admin WITH PASSWORD 'new_password';"

# 2. Regenerate userlist
cd /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database/pgbouncer
./generate-userlist.sh

# 3. Reload PgBouncer (no downtime)
docker-compose exec pgbouncer kill -HUP 1
```

---

## Configuration Reference

### Key Settings (CN-073 Compliant)

| Setting | Value | Purpose |
|---------|-------|---------|
| `pool_size` | 10 | Connections per database (CN-073) |
| `server_lifetime` | 1800s | Max connection age (30 min) |
| `server_idle_timeout` | 300s | Max idle time (5 min) |
| `pool_mode` | transaction | Optimal for web apps |
| `max_client_conn` | 1000 | Max concurrent clients |
| `auth_type` | scram-sha-256 | Secure authentication |

---

## Alert Thresholds

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| `cl_waiting` | > 5 | > 20 | Increase pool_size |
| `maxwait` | > 5s | > 10s | Investigate slow queries |
| `avg_xact_time` | > 2s | > 5s | Optimize queries |
| Pool utilization | > 80% | > 95% | Increase pool_size |

---

## Emergency Procedures

### Rollback to Direct PostgreSQL

```bash
# 1. Update application connection strings
export PGPORT=5432  # Change from 6432

# 2. Stop PgBouncer
docker-compose stop pgbouncer

# 3. Increase PostgreSQL max_connections
docker-compose exec postgres psql -U perseus_admin -d postgres -c \
  "ALTER SYSTEM SET max_connections = 500;"
docker-compose restart postgres
```

### Complete Restart

```bash
cd /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database

# Stop all
docker-compose down

# Start PostgreSQL first
docker-compose up -d postgres

# Wait for PostgreSQL health check
sleep 10

# Start PgBouncer
docker-compose up -d pgbouncer

# Verify
docker ps | grep perseus
```

---

## File Locations

```
Configuration:
  pgbouncer.ini      /infra/database/pgbouncer/pgbouncer.ini
  userlist.txt       /infra/database/pgbouncer/userlist.txt

Scripts:
  Deploy             /infra/database/pgbouncer/deploy-pgbouncer.sh
  Test               /infra/database/pgbouncer/test-pgbouncer.sh
  Monitor            /infra/database/pgbouncer/monitor-pgbouncer.sh
  Generate users     /infra/database/pgbouncer/generate-userlist.sh

Documentation:
  README             /infra/database/pgbouncer/README.md
  Quick Reference    /infra/database/pgbouncer/QUICK-REFERENCE.md (this file)
  Completion Summary /infra/database/pgbouncer/T027-COMPLETION-SUMMARY.md

Logs:
  PgBouncer logs     docker-compose logs pgbouncer
  PostgreSQL logs    docker-compose logs postgres
```

---

## Performance Expectations

### Connection Overhead

- **Direct PostgreSQL:** 10-50ms per connection
- **Via PgBouncer:** <1ms per transaction (99% faster)

### Memory Footprint

- **Direct:** ~10MB per backend process
- **Pooled:** ~2MB per client connection

### Scalability

- **Without pooling:** Limited to `max_connections=100`
- **With PgBouncer:** Support 1000+ clients → 10-25 backends

---

## Support

**For detailed information, see:**
- README.md - Comprehensive documentation (26KB)
- T027-COMPLETION-SUMMARY.md - Task completion details

**Contact:**
- Pierre Ribeiro (Senior DBA/DBRE)

---

**Last Updated:** 2026-01-25
**Version:** 1.0
