# PgBouncer Connection Pooling - Perseus PostgreSQL Migration

**Version:** 1.0
**Last Updated:** 2026-01-25
**Environment:** Development
**Reference:** specs/001-tsql-to-pgsql/spec.md CN-073

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Configuration](#configuration)
4. [Deployment](#deployment)
5. [Connection Strings](#connection-strings)
6. [Monitoring](#monitoring)
7. [Troubleshooting](#troubleshooting)
8. [Performance Tuning](#performance-tuning)
9. [Security](#security)
10. [Disaster Recovery](#disaster-recovery)

---

## Overview

PgBouncer is a lightweight connection pooler for PostgreSQL that significantly reduces connection overhead and improves application performance. This setup provides production-ready connection pooling for the Perseus database migration project.

### Why Connection Pooling?

**Without pooling:**
- Each client connection creates a new PostgreSQL backend process (~10MB memory)
- Connection establishment overhead: 10-50ms per connection
- Limited to `max_connections=100` in PostgreSQL (hard limit)
- High memory usage with many connections

**With PgBouncer:**
- 1000+ client connections → 10-25 actual PostgreSQL connections
- Connection reuse: <1ms overhead (99% faster)
- Memory footprint: ~2MB per client connection
- Automatic connection management and lifecycle

### Key Features

- **Transaction pooling**: Optimal for web applications (default mode)
- **Connection limits**: 1000 clients → 100 max database connections
- **Automatic timeout**: 30-minute server lifetime, 5-minute idle timeout (per CN-073)
- **Health checks**: Built-in monitoring and statistics
- **Zero downtime**: Graceful shutdown and RELOAD support

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Applications                            │
│  (Web, APIs, CLI tools, SymmetricDS replication)                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Port 6432 (PgBouncer)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         PgBouncer                               │
│                   (Connection Pooler)                           │
│                                                                 │
│  Client Connections: 1000 max                                   │
│  Pool Size: 10-25 connections per database                      │
│  Pool Mode: Transaction (server per transaction)                │
│                                                                 │
│  Databases:                                                     │
│    - perseus_dev (pool_size=10)                                 │
│    - perseus_test (pool_size=5)                                 │
│    - perseus_staging (pool_size=15, when ready)                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Port 5432 (PostgreSQL)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      PostgreSQL 17.7                            │
│                   (perseus-postgres-dev)                        │
│                                                                 │
│  max_connections: 100                                           │
│  Actual usage: 10-25 connections (pooled via PgBouncer)         │
│  Reserved: 75+ connections for direct admin access              │
└─────────────────────────────────────────────────────────────────┘
```

### Connection Flow

1. **Application connects** to PgBouncer (port 6432)
2. **PgBouncer authenticates** using userlist.txt
3. **Transaction starts** → PgBouncer assigns a backend connection from the pool
4. **Transaction completes** → Connection returned to pool (runs `DISCARD ALL`)
5. **Connection reused** for next transaction from any client

### Pool Modes Explained

| Mode | Description | Use Case | Connection Reuse |
|------|-------------|----------|------------------|
| **Transaction** | Server assigned per transaction | Web apps, APIs | High (default) |
| Session | Server assigned for entire session | Long-lived connections | Low |
| Statement | Server assigned per statement | Extremely short operations | Very High |

**Perseus uses transaction mode** for optimal balance between compatibility and performance.

---

## Configuration

### File Structure

```
pgbouncer/
├── Dockerfile              # PgBouncer container image
├── pgbouncer.ini           # Main configuration file
├── userlist.txt            # User authentication (passwords/hashes)
├── generate-userlist.sh    # Script to extract hashes from PostgreSQL
└── README.md               # This file
```

### pgbouncer.ini - Key Settings

```ini
[databases]
perseus_dev = host=postgres port=5432 dbname=perseus_dev pool_size=10

[pgbouncer]
listen_port = 6432
auth_type = md5
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25
min_pool_size = 10
server_lifetime = 1800       # 30 minutes (CN-073)
server_idle_timeout = 300    # 5 minutes (CN-073)
```

### Pool Sizing Guidelines (CN-073)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `pool_size` | 10 per database | FDW specification (CN-073) |
| `server_lifetime` | 1800s (30 min) | Prevent long-lived connection issues |
| `server_idle_timeout` | 300s (5 min) | Release idle connections quickly |
| `max_client_conn` | 1000 | Support high concurrency |
| `default_pool_size` | 25 | General workloads (can override per DB) |

### Authentication Setup

PgBouncer supports multiple authentication methods:

1. **MD5** (current): Compatible with PostgreSQL default
2. **SCRAM-SHA-256**: More secure, recommended for production
3. **Trust**: No authentication (development only, insecure)
4. **PAM**: External authentication (advanced)

**Current configuration uses MD5** for compatibility. Switch to SCRAM-SHA-256 for production:

```ini
auth_type = scram-sha-256
```

---

## Deployment

### Prerequisites

- Docker and Docker Compose installed
- PostgreSQL container running (`perseus-postgres-dev`)
- `perseus_admin` user exists in PostgreSQL

### Step 1: Generate User Authentication File

```bash
cd /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database/pgbouncer

# Make script executable
chmod +x generate-userlist.sh

# Generate userlist.txt from PostgreSQL
./generate-userlist.sh
```

**Output:**
```
PgBouncer Userlist Generator
============================================

Checking PostgreSQL connectivity... OK

Extracting password hashes from PostgreSQL...
  - perseus_admin... OK

Success! Userlist generated at: userlist.txt
File permissions: -rw------- perseus_admin users
```

### Step 2: Build and Start PgBouncer

```bash
cd /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database

# Build PgBouncer image
docker-compose build pgbouncer

# Start PgBouncer (PostgreSQL must be running)
docker-compose up -d pgbouncer

# Check logs
docker-compose logs -f pgbouncer
```

### Step 3: Verify PgBouncer is Running

```bash
# Check container status
docker ps | grep pgbouncer

# Test connection via PgBouncer
psql -h localhost -p 6432 -U perseus_admin -d perseus_dev -c "SELECT version();"

# Check pool status
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW POOLS;"
```

**Expected output:**
```
 database    | user          | cl_active | cl_waiting | sv_active | sv_idle | sv_used
-------------+---------------+-----------+------------+-----------+---------+---------
 perseus_dev | perseus_admin |         0 |          0 |         0 |       0 |       0
 pgbouncer   | pgbouncer     |         1 |          0 |         0 |       0 |       0
```

### Step 4: Update Application Connection Strings

**Before (direct PostgreSQL):**
```
postgresql://perseus_admin:password@localhost:5432/perseus_dev
```

**After (via PgBouncer):**
```
postgresql://perseus_admin:password@localhost:6432/perseus_dev
```

**Environment variables:**
```bash
export PGHOST=localhost
export PGPORT=6432
export PGUSER=perseus_admin
export PGDATABASE=perseus_dev
export PGPASSWORD=<from .secrets/postgres_password.txt>
```

---

## Connection Strings

### Development Environment

| Use Case | Connection String | Notes |
|----------|-------------------|-------|
| **Pooled (default)** | `postgresql://perseus_admin@localhost:6432/perseus_dev` | Use for applications |
| **Direct (admin)** | `postgresql://perseus_admin@localhost:5432/perseus_dev` | Use for DDL, maintenance |
| **PgBouncer admin** | `postgresql://perseus_admin@localhost:6432/pgbouncer` | Statistics and control |

### When to Use Direct vs Pooled

**Use PgBouncer (port 6432):**
- ✅ Web applications
- ✅ API services
- ✅ Short-lived scripts
- ✅ SymmetricDS replication
- ✅ Read-heavy workloads

**Use Direct PostgreSQL (port 5432):**
- ✅ Schema migrations (DDL)
- ✅ Long-running analytics queries
- ✅ VACUUM, ANALYZE maintenance
- ✅ Database backups
- ✅ Replication setup

### psql Connection Examples

```bash
# Via PgBouncer (pooled)
psql -h localhost -p 6432 -U perseus_admin -d perseus_dev

# Direct to PostgreSQL (bypass pool)
psql -h localhost -p 5432 -U perseus_admin -d perseus_dev

# PgBouncer admin console
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer
```

---

## Monitoring

### PgBouncer Admin Console

Connect to the special `pgbouncer` database for statistics:

```bash
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer
```

### Key Monitoring Commands

#### 1. Pool Status (`SHOW POOLS`)

```sql
SHOW POOLS;
```

**Columns:**
- `database`: Database name
- `user`: Username
- `cl_active`: Active client connections
- `cl_waiting`: Clients waiting for connection
- `sv_active`: Active server connections
- `sv_idle`: Idle server connections in pool
- `sv_used`: Recently used connections
- `maxwait`: Max time client waited (seconds)

**Red flags:**
- `cl_waiting > 0`: Clients waiting (pool exhausted)
- `maxwait > 10`: Clients waiting too long (increase pool_size)

#### 2. Database Statistics (`SHOW STATS`)

```sql
SHOW STATS;
```

**Columns:**
- `total_xact_count`: Total transactions processed
- `total_query_count`: Total queries processed
- `total_received`: Bytes received from clients
- `total_sent`: Bytes sent to clients
- `avg_xact_time`: Average transaction duration (microseconds)
- `avg_query_time`: Average query duration (microseconds)

**Performance indicators:**
- `avg_xact_time < 1000000` (1s): Good
- `avg_xact_time > 5000000` (5s): Investigate slow queries

#### 3. Active Connections (`SHOW CLIENTS`)

```sql
SHOW CLIENTS;
```

Shows all client connections with IP addresses, connection time, and state.

#### 4. Server Connections (`SHOW SERVERS`)

```sql
SHOW SERVERS;
```

Shows actual PostgreSQL backend connections (pool members).

#### 5. Configuration (`SHOW CONFIG`)

```sql
SHOW CONFIG;
```

Displays all PgBouncer configuration parameters.

### Monitoring Queries for Automation

Save these queries in a monitoring script:

```sql
-- Pool health check
SELECT
    database,
    cl_active,
    cl_waiting,
    sv_active,
    sv_idle,
    CASE
        WHEN cl_waiting > 0 THEN 'WARNING: Clients waiting'
        WHEN sv_active >= sv_idle * 2 THEN 'WARNING: Pool saturation'
        ELSE 'OK'
    END AS status
FROM pgbouncer.pools;

-- Transaction throughput
SELECT
    database,
    total_xact_count,
    total_query_count,
    avg_xact_time / 1000 AS avg_xact_ms,
    avg_query_time / 1000 AS avg_query_ms
FROM pgbouncer.stats;

-- Connection distribution
SELECT
    database,
    user,
    COUNT(*) AS connection_count
FROM pgbouncer.clients
GROUP BY database, user;
```

### Alert Thresholds

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| `cl_waiting` | > 5 | > 20 | Increase pool_size |
| `maxwait` | > 5s | > 10s | Increase pool_size or investigate slow queries |
| `avg_xact_time` | > 2s | > 5s | Optimize queries |
| `sv_active / pool_size` | > 0.8 | > 0.95 | Increase pool_size |

### Grafana Dashboard (Recommended)

**Metrics to track:**
1. Client connections (active, waiting)
2. Server connections (active, idle)
3. Transaction rate (per second)
4. Average transaction time
5. Pool utilization (%)

**Example Prometheus query:**
```promql
rate(pgbouncer_stats_total_xact_count[5m])
```

---

## Troubleshooting

### Problem: "FATAL: no such database: perseus_dev"

**Cause:** Database not defined in `pgbouncer.ini [databases]` section.

**Solution:**
```bash
# Edit pgbouncer.ini
vim /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database/pgbouncer/pgbouncer.ini

# Add database entry
[databases]
perseus_dev = host=postgres port=5432 dbname=perseus_dev pool_size=10

# Reload PgBouncer
docker-compose exec pgbouncer psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "RELOAD;"
```

### Problem: "FATAL: password authentication failed"

**Cause:** User password hash mismatch between `userlist.txt` and PostgreSQL.

**Solution:**
```bash
# Regenerate userlist.txt
cd /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database/pgbouncer
./generate-userlist.sh

# Reload PgBouncer configuration
docker-compose restart pgbouncer
```

### Problem: Clients Waiting (`cl_waiting > 0`)

**Cause:** Pool exhausted, all connections in use.

**Solution 1: Increase pool size (temporary)**
```bash
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SET default_pool_size = 50; RELOAD;"
```

**Solution 2: Increase pool size (permanent)**
```bash
# Edit pgbouncer.ini
vim /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database/pgbouncer/pgbouncer.ini

# Change:
default_pool_size = 50

# Restart PgBouncer
docker-compose restart pgbouncer
```

### Problem: "connection limit exceeded for non-superusers"

**Cause:** PostgreSQL `max_connections` exceeded.

**Solution:**
```bash
# Check current connections
docker-compose exec postgres psql -U perseus_admin -d postgres -c \
  "SELECT count(*) FROM pg_stat_activity;"

# Increase max_connections (requires PostgreSQL restart)
# Edit compose.yaml, add:
# - "-c"
# - "max_connections=200"

docker-compose restart postgres
```

### Problem: PgBouncer Not Responding

**Diagnostics:**
```bash
# Check container status
docker ps | grep pgbouncer

# Check logs
docker-compose logs pgbouncer

# Verify port listening
docker exec perseus-pgbouncer-dev netstat -tuln | grep 6432

# Test PostgreSQL connectivity from PgBouncer
docker exec perseus-pgbouncer-dev psql -h postgres -p 5432 -U perseus_admin -d perseus_dev -c "SELECT 1;"
```

### Problem: Performance Degradation

**Investigation steps:**
```bash
# 1. Check pool saturation
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW POOLS;"

# 2. Check slow queries
docker-compose exec postgres psql -U perseus_admin -d perseus_dev -c \
  "SELECT query, mean_exec_time FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"

# 3. Check PostgreSQL connections
docker-compose exec postgres psql -U perseus_admin -d postgres -c \
  "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"
```

---

## Performance Tuning

### Optimal Pool Sizing

**Formula:**
```
pool_size = (number_of_cores * 2) + effective_spindle_count
```

**For Perseus development (4-core laptop):**
```
pool_size = (4 * 2) + 1 = 9 ≈ 10 ✓
```

**Production (8-core server, SSD):**
```
pool_size = (8 * 2) + 4 = 20
```

### Connection Lifecycle Tuning

| Parameter | Development | Staging | Production |
|-----------|-------------|---------|------------|
| `server_lifetime` | 1800s (30 min) | 3600s (1 hr) | 3600s (1 hr) |
| `server_idle_timeout` | 300s (5 min) | 600s (10 min) | 600s (10 min) |
| `query_wait_timeout` | 120s | 60s | 30s |
| `client_idle_timeout` | 0 (disabled) | 600s | 300s |

### Pool Mode Selection

**Transaction mode (current):**
- ✅ Best for web applications
- ✅ High connection reuse
- ⚠️ Cannot use prepared statements
- ⚠️ Cannot use session-level temp tables

**Session mode:**
- ✅ Full PostgreSQL compatibility
- ✅ Supports prepared statements
- ❌ Low connection reuse
- ❌ Higher memory usage

**Statement mode:**
- ✅ Maximum connection reuse
- ❌ Limited feature support
- ❌ Only for simple queries

### Load Testing

**Test with pgbench:**
```bash
# Initialize test database
pgbench -h localhost -p 6432 -U perseus_admin -d perseus_dev -i -s 50

# Run 10-minute load test (100 clients)
pgbench -h localhost -p 6432 -U perseus_admin -d perseus_dev \
  -c 100 -j 4 -T 600 -P 10

# Compare with direct PostgreSQL
pgbench -h localhost -p 5432 -U perseus_admin -d perseus_dev \
  -c 100 -j 4 -T 600 -P 10
```

**Expected results:**
- PgBouncer should handle 100+ clients with <10 active server connections
- Transaction rate should be within 5% of direct PostgreSQL
- Connection overhead reduced by 90%+

---

## Security

### Authentication Best Practices

**1. Use SCRAM-SHA-256 (production)**

```bash
# In PostgreSQL, set password encryption
ALTER SYSTEM SET password_encryption = 'scram-sha-256';
SELECT pg_reload_conf();

# Change user password to regenerate hash
ALTER USER perseus_admin WITH PASSWORD 'new_secure_password';

# Update pgbouncer.ini
auth_type = scram-sha-256

# Regenerate userlist.txt
./generate-userlist.sh
```

**2. Rotate passwords regularly**

```bash
# Quarterly password rotation
ALTER USER perseus_admin WITH PASSWORD 'Q1-2026-secure-password';
./generate-userlist.sh
docker-compose restart pgbouncer
```

**3. Restrict admin access**

```ini
# In pgbouncer.ini
admin_users = perseus_admin
stats_users = monitoring_user, prometheus_exporter
```

### File Permissions

```bash
# Verify secure permissions
ls -la /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database/pgbouncer/

# Expected:
# -rw------- userlist.txt (600)
# -rw-r--r-- pgbouncer.ini (644)

# Fix if needed
chmod 600 userlist.txt
chmod 644 pgbouncer.ini
```

### Network Security

**Development (current):**
```yaml
# Listen on all interfaces (Docker networking)
listen_addr = 0.0.0.0
```

**Production (recommended):**
```yaml
# Listen only on private network
listen_addr = 10.0.0.0/8

# Or use Unix socket
unix_socket_dir = /var/run/postgresql
```

### TLS Encryption

**Enable TLS for production:**

```ini
# In pgbouncer.ini
client_tls_sslmode = require
client_tls_ca_file = /etc/pgbouncer/ca.crt
client_tls_cert_file = /etc/pgbouncer/server.crt
client_tls_key_file = /etc/pgbouncer/server.key

server_tls_sslmode = require
```

**Generate certificates:**
```bash
# Self-signed certificate (development)
openssl req -new -x509 -days 365 -nodes -text \
  -out server.crt -keyout server.key \
  -subj "/CN=pgbouncer.perseus.local"

# Copy to container
cp server.crt server.key /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database/pgbouncer/
docker-compose restart pgbouncer
```

### Audit Logging

**Enable detailed logging:**
```ini
# In pgbouncer.ini
log_connections = 1
log_disconnections = 1
log_pooler_errors = 1
verbose = 1  # 0=quiet, 1=normal, 2=verbose
```

**Log rotation:**
```bash
# Create logrotate configuration
cat > /etc/logrotate.d/pgbouncer << EOF
/var/log/pgbouncer/pgbouncer.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 pgbouncer pgbouncer
    postrotate
        docker exec perseus-pgbouncer-dev kill -HUP 1
    endscript
}
EOF
```

---

## Disaster Recovery

### Backup and Restore

**Configuration backup:**
```bash
# Backup PgBouncer configuration
tar -czf pgbouncer-config-$(date +%Y%m%d).tar.gz \
  /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database/pgbouncer/

# Restore configuration
tar -xzf pgbouncer-config-20260125.tar.gz -C /tmp
cp /tmp/pgbouncer/* /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/infra/database/pgbouncer/
docker-compose restart pgbouncer
```

### Graceful Shutdown

**PAUSE connections (maintenance mode):**
```bash
# Pause all databases (finish active transactions, reject new ones)
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "PAUSE;"

# Perform maintenance
# ...

# Resume connections
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "RESUME;"
```

**Graceful shutdown:**
```bash
# Wait for all clients to disconnect
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHUTDOWN;"

# Force shutdown (kill active connections)
docker-compose stop pgbouncer
```

### Failover Scenarios

**Scenario 1: PgBouncer fails, PostgreSQL healthy**

**Detection:**
- Application cannot connect to port 6432
- PostgreSQL port 5432 still accessible

**Recovery:**
```bash
# 1. Check container status
docker ps -a | grep pgbouncer

# 2. View logs
docker-compose logs pgbouncer

# 3. Restart PgBouncer
docker-compose restart pgbouncer

# 4. Verify recovery
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW POOLS;"
```

**Scenario 2: PostgreSQL fails, PgBouncer healthy**

**Detection:**
- Clients see "cannot connect to server" errors
- PgBouncer logs show connection failures

**Recovery:**
```bash
# 1. Restart PostgreSQL
docker-compose restart postgres

# 2. Wait for PostgreSQL health check
docker-compose ps postgres

# 3. PgBouncer auto-reconnects (no action needed)

# 4. Verify connections
psql -h localhost -p 6432 -U perseus_admin -d perseus_dev -c "SELECT 1;"
```

**Scenario 3: Network partition**

**Detection:**
- PgBouncer cannot reach PostgreSQL
- Clients receive "database connection timed out"

**Recovery:**
```bash
# 1. Verify network connectivity
docker exec perseus-pgbouncer-dev ping postgres

# 2. Check Docker network
docker network inspect perseus-dev-network

# 3. Recreate network if needed
docker-compose down
docker-compose up -d
```

### Rollback Procedures

**Rollback to direct PostgreSQL (emergency):**

```bash
# 1. Update application connection strings
export PGPORT=5432  # Change from 6432 to 5432

# 2. Stop PgBouncer
docker-compose stop pgbouncer

# 3. Increase PostgreSQL max_connections temporarily
docker-compose exec postgres psql -U perseus_admin -d postgres -c \
  "ALTER SYSTEM SET max_connections = 500;"
docker-compose restart postgres

# 4. Monitor PostgreSQL load
watch "docker-compose exec postgres psql -U perseus_admin -d postgres -c \
  'SELECT count(*) FROM pg_stat_activity;'"
```

**Rollback from configuration change:**

```bash
# 1. Restore previous configuration
git checkout HEAD~1 -- pgbouncer/pgbouncer.ini

# 2. Reload PgBouncer
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "RELOAD;"

# 3. Verify configuration
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW CONFIG;"
```

### Health Check Scripts

**automated-health-check.sh:**

```bash
#!/usr/bin/env bash
# PgBouncer health check for monitoring systems

PGBOUNCER_HOST="localhost"
PGBOUNCER_PORT="6432"
PGBOUNCER_USER="perseus_admin"

# Check 1: PgBouncer responding
if ! psql -h ${PGBOUNCER_HOST} -p ${PGBOUNCER_PORT} -U ${PGBOUNCER_USER} \
  -d pgbouncer -c "SHOW POOLS;" > /dev/null 2>&1; then
    echo "CRITICAL: PgBouncer not responding"
    exit 2
fi

# Check 2: No clients waiting
CL_WAITING=$(psql -h ${PGBOUNCER_HOST} -p ${PGBOUNCER_PORT} -U ${PGBOUNCER_USER} \
  -d pgbouncer -tAc "SELECT SUM(cl_waiting) FROM pools;")

if [ "${CL_WAITING}" -gt 10 ]; then
    echo "WARNING: ${CL_WAITING} clients waiting for connections"
    exit 1
fi

# Check 3: PostgreSQL connectivity
if ! psql -h ${PGBOUNCER_HOST} -p ${PGBOUNCER_PORT} -U ${PGBOUNCER_USER} \
  -d perseus_dev -c "SELECT 1;" > /dev/null 2>&1; then
    echo "CRITICAL: Cannot connect to PostgreSQL via PgBouncer"
    exit 2
fi

echo "OK: PgBouncer healthy"
exit 0
```

---

## Operations Runbook

### Daily Operations

**Morning health check:**
```bash
# 1. Verify PgBouncer is running
docker ps | grep pgbouncer

# 2. Check pool status
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW POOLS;"

# 3. Review overnight statistics
psql -h localhost -p 6432 -U perseus_admin -d pgbouncer -c "SHOW STATS;"
```

### Weekly Maintenance

```bash
# 1. Review logs for errors
docker-compose logs --since 7d pgbouncer | grep -i error

# 2. Check pool utilization trends
# (Integrate with monitoring dashboard)

# 3. Validate configuration
docker-compose exec pgbouncer cat /etc/pgbouncer/pgbouncer.ini | grep -E "pool_size|server_lifetime"
```

### Monthly Maintenance

```bash
# 1. Rotate passwords
ALTER USER perseus_admin WITH PASSWORD 'monthly-rotated-password';
./generate-userlist.sh
docker-compose restart pgbouncer

# 2. Update PgBouncer image
docker-compose pull pgbouncer
docker-compose up -d pgbouncer

# 3. Backup configuration
tar -czf pgbouncer-config-$(date +%Y%m).tar.gz pgbouncer/
```

---

## References

- **PgBouncer Documentation**: https://www.pgbouncer.org/
- **Perseus Spec CN-073**: specs/001-tsql-to-pgsql/spec.md (connection pooling settings)
- **PostgreSQL Max Connections**: https://www.postgresql.org/docs/17/runtime-config-connection.html
- **Docker Compose**: https://docs.docker.com/compose/

---

## Support

For issues or questions:

1. **Check troubleshooting section** above
2. **Review PgBouncer logs**: `docker-compose logs pgbouncer`
3. **Consult PostgreSQL logs**: `docker-compose logs postgres`
4. **Contact DBA team**: Pierre Ribeiro (Senior DBA/DBRE)

---

**Last Updated:** 2026-01-25
**Version:** 1.0
**Maintainer:** Pierre Ribeiro
