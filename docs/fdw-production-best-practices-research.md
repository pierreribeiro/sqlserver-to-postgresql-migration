# PostgreSQL Foreign Data Wrapper (postgres_fdw) Production Best Practices
## Research Report for Perseus Migration Project

**Document Type:** Architecture Decision Research
**Created:** 2026-01-19
**Author:** Pierre Ribeiro (Senior DBA/DBRE)
**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Context:** Replacing SQL Server linked servers with FDW for hermes, sqlapps, deimeter
**Version:** 1.0
**Status:** APPROVED

---

## Executive Summary

This research report provides comprehensive best practices for implementing PostgreSQL Foreign Data Wrapper (postgres_fdw) in production to replace SQL Server linked servers. The Perseus database accesses 17 tables across 3 external databases (hermes, sqlapps, deimeter) via cross-database queries.

### Quick Reference Decision Matrix

| Configuration Aspect | Recommended Setting | Rationale |
|---------------------|-------------------|-----------|
| **Connection Pooling** | Application-level + PgBouncer transaction mode | FDW maintains session-lifetime connections |
| **Connection Timeout** | connect_timeout='5' | Balance detection vs network latency |
| **TCP Keepalives** | keepalives='1', keepalives_idle='30', keepalives_interval='10', keepalives_count='3' | Detect dead connections within ~60s |
| **fetch_size** | 5000-10000 for analytical, 100-500 for OLTP | Reduce network round trips |
| **batch_size (PG14+)** | 2000-5000 for bulk inserts | Optimize bulk operations |
| **use_remote_estimate** | TRUE for complex joins | Improve query planning accuracy |
| **async_capable (PG14+)** | TRUE (default) | Enable parallel foreign table scans |
| **Authentication** | SCRAM-SHA-256 with password option | Avoid plaintext passwords |
| **Transaction Mode** | Read-only where possible, understand distributed transaction limitations | No 2PC support |

---

## 1. Connection Management & Pooling

### 1.1 Connection Lifecycle Behavior

**Key Finding:** postgres_fdw maintains connections for the entire lifetime of a database session, which creates challenges when using connection poolers.

**Impact for Perseus:**
- Application connections via PgBouncer will keep FDW connections open
- Each local session = 1 connection per foreign server
- Maximum potential connections: `max_connections × number_of_foreign_servers`

### 1.2 Recommended Connection Strategy

#### Decision: Layered Connection Management

```
Application Layer (100 connections)
    ↓
PgBouncer (Transaction Mode)
    ↓ (20 pooled connections)
PostgreSQL Main DB
    ↓ (FDW maintains persistent connections)
Foreign Servers (hermes, sqlapps, deimeter)
```

**Configuration:**

```sql
-- Foreign Server Configuration (hermes example)
CREATE SERVER hermes_fdw
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (
    host 'hermes.production.local',
    port '5432',
    dbname 'hermes',
    -- Connection timeout settings
    connect_timeout '5',              -- 5 seconds connection attempt timeout
    -- TCP keepalive settings (detect dead connections)
    keepalives '1',                   -- Enable TCP keepalives
    keepalives_idle '30',             -- Start probing after 30s idle
    keepalives_interval '10',         -- Probe every 10s
    keepalives_count '3',             -- Fail after 3 missed probes (total ~60s)
    -- Performance settings
    fetch_size '5000',                -- Batch size for SELECT queries
    use_remote_estimate 'true',       -- Get accurate costs from remote
    async_capable 'true',             -- Enable asynchronous execution (PG14+)
    extensions 'pg_stat_statements'   -- Shared extensions (if applicable)
  );

-- User Mapping with SCRAM authentication
CREATE USER MAPPING FOR perseus_app
  SERVER hermes_fdw
  OPTIONS (
    user 'perseus_readonly',
    password 'SCRAM-SHA-256$...'  -- Use SCRAM-hashed password
  );
```

**Rationale:**
1. **PgBouncer in transaction mode** prevents session-level state accumulation
2. **Limited pooled connections** (e.g., 20) to main DB controls FDW connection count
3. **TCP keepalives** detect and close dead connections within 60 seconds
4. **Connection timeout** prevents hanging on unreachable foreign servers

### 1.3 Connection Limits Calculation

For Perseus with 3 foreign databases:

```
Maximum FDW connections = pooled_connections × foreign_servers
Example: 20 pooled connections × 3 servers = 60 concurrent FDW connections

Foreign server must accommodate:
- Perseus FDW connections: 60
- Application direct connections: varies by server
- Other systems: varies
```

**Implementation Note:**
```sql
-- Set appropriate limits on foreign servers
ALTER ROLE perseus_readonly CONNECTION LIMIT 100;

-- Monitor connection usage
SELECT
    usename,
    application_name,
    COUNT(*) as connection_count
FROM pg_stat_activity
WHERE usename = 'perseus_readonly'
GROUP BY usename, application_name;
```

---

## 2. Connection Failure Handling & Retry Logic

### 2.1 Automatic Connection Retry (PostgreSQL 14+)

**Key Finding:** PostgreSQL 14+ includes automatic connection retry logic for postgres_fdw. When a cached connection fails, postgres_fdw automatically attempts reconnection at the beginning of a new remote transaction.

**Behavior:**
- Connection failures detected at transaction start trigger automatic retry
- Retry message logged at DEBUG3 level: "postgres_fdw connection retry is successful"
- Transparent to application for recoverable failures
- Only applies at beginning of remote transaction (not mid-transaction)

### 2.2 Error Scenarios & Handling

| Scenario | FDW Behavior | Application Impact | Mitigation |
|----------|--------------|-------------------|------------|
| **Foreign server down at query start** | Immediate error | Query fails with connection error | Implement application retry with exponential backoff |
| **Connection dropped during idle** | Auto-retry on next use (PG14+) | Transparent recovery | Enable TCP keepalives to detect faster |
| **Network partition mid-query** | Query fails, connection marked bad | Transaction rollback required | Monitor query duration, set statement_timeout |
| **Foreign server failover** | Connection to old server fails | Next query auto-retries to new endpoint (if DNS updated) | Use DNS-based failover, short TTL |

### 2.3 Recommended Error Handling Pattern

```sql
-- Application-level retry wrapper (pseudo-code)
CREATE OR REPLACE FUNCTION perseus_fdw_query_with_retry(
    p_query TEXT,
    p_max_retries INTEGER DEFAULT 3
)
RETURNS SETOF RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_retry_count INTEGER := 0;
    v_backoff_ms INTEGER := 100;
BEGIN
    LOOP
        BEGIN
            -- Execute the FDW query
            RETURN QUERY EXECUTE p_query;
            EXIT;  -- Success, exit loop
        EXCEPTION
            WHEN sqlstate '08000' THEN  -- Connection exceptions
                v_retry_count := v_retry_count + 1;

                IF v_retry_count >= p_max_retries THEN
                    RAISE EXCEPTION
                        'FDW query failed after % retries: %',
                        p_max_retries, SQLERRM
                    USING HINT = 'Check foreign server availability';
                END IF;

                -- Exponential backoff
                PERFORM pg_sleep(v_backoff_ms / 1000.0);
                v_backoff_ms := v_backoff_ms * 2;

                RAISE NOTICE 'FDW connection failed, retry % of %',
                    v_retry_count, p_max_retries;
        END;
    END LOOP;
END;
$$;
```

### 2.4 Statement Timeout Configuration

Protect against hanging queries on foreign servers:

```sql
-- Set statement timeout for FDW queries
ALTER SERVER hermes_fdw OPTIONS (ADD statement_timeout '30000');  -- 30 seconds

-- Or per-user mapping
ALTER USER MAPPING FOR perseus_app SERVER hermes_fdw
  OPTIONS (ADD statement_timeout '30000');

-- Application-level override for long-running queries
SET LOCAL statement_timeout = '300000';  -- 5 minutes for specific query
SELECT * FROM foreign_large_table;
RESET statement_timeout;
```

---

## 3. Performance Optimization Techniques

### 3.1 Predicate Pushdown

**Key Finding:** postgres_fdw automatically pushes down WHERE clauses, but only for built-in operators and functions. Custom functions, non-immutable functions, or complex expressions may cause local filtering.

**Verification Method:**

```sql
-- ALWAYS verify predicate pushdown with EXPLAIN
EXPLAIN (VERBOSE, COSTS OFF)
SELECT *
FROM hermes_runs_fdw
WHERE experiment_id = 12345
  AND run_status = 'completed';

-- Good output (pushdown working):
-- Foreign Scan on hermes_runs_fdw
--   Remote SQL: SELECT ... FROM runs WHERE experiment_id = 12345 AND run_status = 'completed'

-- Bad output (no pushdown):
-- Foreign Scan on hermes_runs_fdw
--   Remote SQL: SELECT * FROM runs
--   Filter: (experiment_id = 12345) AND (run_status = 'completed')
```

**Common Pushdown Failures:**

| Expression Type | Pushes Down? | Example | Solution |
|----------------|-------------|---------|----------|
| Built-in operators | ✅ Yes | `col = 5`, `col > 10` | Use as-is |
| Built-in functions (immutable) | ✅ Yes | `LOWER(col) = 'test'` | Use as-is |
| Custom functions | ❌ No | `my_custom_func(col)` | Recreate function on foreign server with `extensions` option |
| CASE expressions | ✅ Yes (PG10+) | `CASE WHEN ... END` | Use as-is |
| Aggregates | ✅ Yes (PG10+) | `COUNT(*)`, `SUM(col)` | Use as-is |
| Non-immutable functions | ❌ No | `NOW()`, `RANDOM()` | Evaluate locally before passing |

### 3.2 fetch_size Tuning

**Key Finding:** Default fetch_size is 100 rows, which is suboptimal for most use cases.

**Tuning Guidelines:**

```sql
-- Analytical/Reporting Queries (large result sets)
ALTER FOREIGN TABLE hermes_runs OPTIONS (SET fetch_size '10000');

-- OLTP Queries (small result sets, fast response)
ALTER FOREIGN TABLE hermes_conditions OPTIONS (SET fetch_size '500');

-- Server-level default (applies to all tables)
ALTER SERVER hermes_fdw OPTIONS (SET fetch_size '5000');
```

**Performance Impact Example:**
- Query returning 100,000 rows
- fetch_size=100: 1,000 network round trips
- fetch_size=10000: 10 network round trips (100× reduction)

**Trade-offs:**
- **Larger fetch_size:** Fewer round trips, higher memory usage, longer TTFB (time to first byte)
- **Smaller fetch_size:** More round trips, lower memory, faster TTFB

**Recommendation for Perseus:**
- Hermes runs table (large scans): fetch_size=10000
- Common lookup tables (small scans): fetch_size=500
- Default server setting: fetch_size=5000

### 3.3 use_remote_estimate for Query Planning

**Key Finding:** Local statistics on foreign tables are often stale or inaccurate. `use_remote_estimate=true` fetches real-time cost estimates from the remote server.

**Configuration:**

```sql
-- Enable remote estimates for accurate join planning
ALTER FOREIGN TABLE hermes_runs OPTIONS (ADD use_remote_estimate 'true');

-- Or server-wide
ALTER SERVER hermes_fdw OPTIONS (ADD use_remote_estimate 'true');
```

**Impact:**
- Executes `EXPLAIN` on remote server for each query plan
- Adds ~10-50ms planning overhead
- Dramatically improves join order and strategy selection

**When to Use:**
- ✅ Complex joins involving foreign and local tables
- ✅ Large foreign tables with selective WHERE clauses
- ✅ Production workloads where plan quality > planning time
- ❌ Simple single-table queries (overhead not worth it)
- ❌ Ad-hoc queries (planning overhead adds up)

### 3.4 Aggregate Pushdown (PostgreSQL 10+)

**Key Finding:** PostgreSQL 10+ pushes aggregate functions (COUNT, SUM, AVG, MIN, MAX) to foreign servers, dramatically reducing data transfer.

**Example:**

```sql
-- Query: Count runs per experiment
SELECT experiment_id, COUNT(*)
FROM hermes_runs_fdw
GROUP BY experiment_id;

-- Remote SQL (aggregate pushdown working):
-- SELECT experiment_id, COUNT(*) FROM runs GROUP BY experiment_id

-- Without pushdown (bad):
-- SELECT * FROM runs  (transfers all rows, aggregates locally)
```

**Verification:**
```sql
EXPLAIN (VERBOSE, COSTS OFF)
SELECT experiment_id, COUNT(*), AVG(duration_seconds)
FROM hermes_runs_fdw
GROUP BY experiment_id;

-- Look for aggregate functions in Remote SQL
```

**Support Matrix:**
- COUNT(*), COUNT(col): ✅ Pushed down
- SUM, AVG, MIN, MAX: ✅ Pushed down
- STDDEV, VARIANCE: ✅ Pushed down (if on remote)
- Custom aggregates: ❌ Not pushed down

### 3.5 Cross-Server Join Optimization

**Key Finding:** Joins between foreign tables on different servers are highly inefficient (nested loop fetching all data).

**Problem:**

```sql
-- BAD: Cross-server join (hermes_fdw × sqlapps_fdw)
SELECT hr.experiment_id, lu.description
FROM hermes_runs_fdw hr
JOIN sqlapps_lookups_fdw lu ON hr.status_code = lu.code;

-- Execution: Fetches ALL rows from both servers, joins locally
```

**Solution 1: CTE Materialization**

```sql
-- BETTER: Materialize foreign data first
WITH hermes_data AS (
    SELECT experiment_id, status_code
    FROM hermes_runs_fdw
    WHERE experiment_id = 12345  -- Reduce rows early
),
sqlapps_data AS (
    SELECT code, description
    FROM sqlapps_lookups_fdw
    WHERE code IN (SELECT DISTINCT status_code FROM hermes_data)  -- Correlated
)
SELECT hd.experiment_id, sd.description
FROM hermes_data hd
JOIN sqlapps_data sd ON hd.status_code = sd.code;
```

**Solution 2: Local Caching for Lookup Tables**

```sql
-- BEST: Replicate small lookup tables locally
CREATE TABLE sqlapps_lookups_cached AS
SELECT * FROM sqlapps_lookups_fdw;

-- Refresh periodically (e.g., daily via cron job)
REFRESH TABLE sqlapps_lookups_cached;

-- Query uses local copy
SELECT hr.experiment_id, lu.description
FROM hermes_runs_fdw hr
JOIN sqlapps_lookups_cached lu ON hr.status_code = lu.code;
```

**Recommendation for Perseus:**
- **Lookup tables** (sqlapps.common): Replicate locally, refresh daily
- **Large transactional tables** (hermes.runs): Use FDW with selective WHERE clauses
- **Reporting queries**: Use CTEs to minimize data transfer

### 3.6 batch_size for Bulk Operations (PostgreSQL 14+)

**Key Finding:** PostgreSQL 14+ supports bulk inserts via FDW with `batch_size` option.

**Configuration:**

```sql
-- Enable batch inserts for foreign table
ALTER FOREIGN TABLE hermes_staging OPTIONS (ADD batch_size '5000');

-- Insert 100,000 rows
INSERT INTO hermes_staging SELECT * FROM local_data;

-- Without batch_size=1: 100,000 individual INSERT statements
-- With batch_size=5000: 20 batched INSERT statements (20× faster)
```

**Constraints:**
- Maximum parameters in libpq: 65,535
- Actual batch_size adjusted automatically: `min(batch_size, 65535 / column_count)`
- Example: 20 columns × 5000 rows = 100,000 parameters (exceeds limit, auto-adjusted to ~3276)

**Recommendation for Perseus:**
- If bulk loading to foreign tables: batch_size=2000 (safe for most schemas)
- Monitor and adjust based on column count

---

## 4. Security Considerations

### 4.1 Authentication Best Practices

**Key Finding:** Non-superusers MUST use password authentication. PostgreSQL 13+ introduced SCRAM pass-through to avoid plaintext passwords.

#### Decision: SCRAM-SHA-256 with User Mappings

**Configuration:**

```sql
-- 1. Create dedicated FDW role on foreign server
-- Execute on hermes database:
CREATE ROLE perseus_fdw_reader WITH LOGIN PASSWORD 'secure_password_here';
GRANT CONNECT ON DATABASE hermes TO perseus_fdw_reader;
GRANT USAGE ON SCHEMA public TO perseus_fdw_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO perseus_fdw_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO perseus_fdw_reader;

-- 2. Create user mapping on local server (perseus)
-- Execute on perseus database:
CREATE USER MAPPING FOR perseus_app
  SERVER hermes_fdw
  OPTIONS (
    user 'perseus_fdw_reader',
    password 'secure_password_here'  -- Stored encrypted in pg_user_mapping
  );

-- 3. Use SCRAM-SHA-256 (PostgreSQL 13+)
-- Foreign server (hermes) postgresql.conf:
-- password_encryption = 'scram-sha-256'

-- Create role with SCRAM:
CREATE ROLE perseus_fdw_reader WITH LOGIN PASSWORD 'secure_password_here';
-- Password automatically hashed with SCRAM-SHA-256

-- User mapping (perseus):
CREATE USER MAPPING FOR perseus_app
  SERVER hermes_fdw
  OPTIONS (
    user 'perseus_fdw_reader',
    password 'SCRAM-SHA-256$4096:...'  -- SCRAM hash instead of plaintext
  );
```

**Security Benefits:**
- Passwords stored encrypted in `pg_user_mapping` (encrypted with database master key)
- SCRAM pass-through avoids transmitting plaintext over network
- Per-user mapping enables audit trail (who accessed what)

### 4.2 Least Privilege Access

**Principle:** Grant only necessary permissions on foreign servers.

```sql
-- Foreign server role (hermes)
CREATE ROLE perseus_fdw_reader WITH LOGIN;

-- Read-only access
GRANT CONNECT ON DATABASE hermes TO perseus_fdw_reader;
GRANT USAGE ON SCHEMA public TO perseus_fdw_reader;

-- Grant SELECT only on required tables (17 tables for Perseus)
GRANT SELECT ON hermes.runs TO perseus_fdw_reader;
GRANT SELECT ON hermes.experiments TO perseus_fdw_reader;
GRANT SELECT ON hermes.run_conditions TO perseus_fdw_reader;
-- ... (repeat for all 6 hermes tables)

-- Explicitly REVOKE write permissions
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM perseus_fdw_reader;

-- Apply to future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE INSERT, UPDATE, DELETE ON TABLES FROM perseus_fdw_reader;
```

**Rationale:**
- Prevents accidental writes to foreign databases
- Limits blast radius of compromised credentials
- Enables better audit trail (read-only role cannot modify data)

### 4.3 SSL/TLS Encryption

**Configuration:**

```sql
-- Require SSL for all FDW connections
ALTER SERVER hermes_fdw OPTIONS (ADD sslmode 'require');

-- Or stronger: verify certificate
ALTER SERVER hermes_fdw OPTIONS (
    ADD sslmode 'verify-full',
    ADD sslcert '/path/to/client-cert.pem',
    ADD sslkey '/path/to/client-key.pem',
    ADD sslrootcert '/path/to/ca-cert.pem'
);
```

**SSL Mode Options:**

| Mode | Encryption | Server Verification | Use Case |
|------|------------|-------------------|----------|
| `disable` | ❌ No | ❌ No | Development only |
| `require` | ✅ Yes | ❌ No | Basic encryption (prevents eavesdropping) |
| `verify-ca` | ✅ Yes | ✅ CA verification | Prevents MITM with valid CA |
| `verify-full` | ✅ Yes | ✅ Full verification | Production (hostname + CA verification) |

**Recommendation for Perseus:**
- Production: `sslmode='verify-full'` with certificates
- Development: `sslmode='require'` (minimum)

### 4.4 Password Management

**Avoiding Plaintext Passwords:**

```bash
# Option 1: Use .pgpass file
# ~/.pgpass format: hostname:port:database:username:password
hermes.production.local:5432:hermes:perseus_fdw_reader:secure_password

# Permissions
chmod 0600 ~/.pgpass

# User mapping (no password in SQL)
CREATE USER MAPPING FOR perseus_app
  SERVER hermes_fdw
  OPTIONS (user 'perseus_fdw_reader');  -- Password from .pgpass
```

```sql
-- Option 2: Use environment variables (limited support)
-- Not recommended for production (less secure than .pgpass)

-- Option 3: Vault integration (most secure, requires extension)
-- Use HashiCorp Vault or AWS Secrets Manager via custom extension
```

**Recommendation for Perseus:**
- **Production:** SCRAM-SHA-256 with passwords in user mappings (encrypted in pg_user_mapping)
- **CI/CD:** Use .pgpass file with restricted permissions
- **Future:** Integrate with enterprise secret management (Vault, AWS Secrets Manager)

---

## 5. Monitoring & Observability

### 5.1 Key Metrics to Monitor

#### 5.1.1 Connection Metrics

```sql
-- View active FDW connections from local server
SELECT
    usename,
    application_name,
    client_addr,
    state,
    query_start,
    state_change,
    wait_event_type,
    wait_event,
    query
FROM pg_stat_activity
WHERE application_name LIKE '%fdw%'
ORDER BY query_start DESC;

-- Count connections per foreign server
-- (Run on each foreign server)
SELECT
    usename,
    COUNT(*) as connection_count,
    COUNT(*) FILTER (WHERE state = 'active') as active_count,
    COUNT(*) FILTER (WHERE state = 'idle') as idle_count
FROM pg_stat_activity
WHERE usename IN ('perseus_fdw_reader', 'perseus_app')
GROUP BY usename;
```

**Alerts:**
- Connection count exceeds 80% of limit
- Long-running FDW queries (>30 seconds)
- Idle FDW connections accumulating

#### 5.1.2 Query Performance Metrics

```sql
-- Create extension on local server
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Track FDW query performance
SELECT
    queryid,
    LEFT(query, 100) as query_preview,
    calls,
    total_exec_time::NUMERIC(10,2) as total_ms,
    mean_exec_time::NUMERIC(10,2) as avg_ms,
    max_exec_time::NUMERIC(10,2) as max_ms,
    stddev_exec_time::NUMERIC(10,2) as stddev_ms,
    rows
FROM pg_stat_statements
WHERE query LIKE '%foreign%'
   OR query LIKE '%_fdw%'
ORDER BY total_exec_time DESC
LIMIT 20;

-- Reset stats periodically (e.g., daily)
SELECT pg_stat_statements_reset();
```

**Alerts:**
- Query latency spikes (p99 > 5× baseline)
- Query failures (connection errors)
- Slow queries (>10s for OLTP, >60s for analytics)

#### 5.1.3 Data Transfer Metrics

```sql
-- Monitor data transfer volume (requires custom instrumentation)
-- Log FDW query results in application layer:
CREATE TABLE fdw_query_log (
    query_id BIGSERIAL PRIMARY KEY,
    server_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    executed_at TIMESTAMPTZ DEFAULT NOW(),
    execution_time_ms NUMERIC,
    rows_returned BIGINT,
    estimated_bytes_transferred BIGINT,  -- rows × avg_row_size
    error_message TEXT
);

-- Aggregate metrics
SELECT
    server_name,
    table_name,
    DATE(executed_at) as query_date,
    COUNT(*) as query_count,
    SUM(rows_returned) as total_rows,
    SUM(estimated_bytes_transferred) / 1024 / 1024 as mb_transferred,
    AVG(execution_time_ms) as avg_latency_ms,
    MAX(execution_time_ms) as max_latency_ms,
    COUNT(*) FILTER (WHERE error_message IS NOT NULL) as error_count
FROM fdw_query_log
WHERE executed_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY server_name, table_name, DATE(executed_at)
ORDER BY mb_transferred DESC;
```

**Alerts:**
- Data transfer spikes (>10× baseline)
- Error rate increases (>1% of queries)

### 5.2 FDW-Specific Statistics (PostgreSQL 15+)

**Key Finding:** PostgreSQL does not expose built-in FDW statistics views, but you can query internal catalogs.

```sql
-- List all foreign servers and their options
SELECT
    fs.srvname as server_name,
    fs.srvowner::regrole as owner,
    fdw.fdwname as wrapper_name,
    array_agg(fso.option_name || '=' || fso.option_value) as server_options
FROM pg_foreign_server fs
JOIN pg_foreign_data_wrapper fdw ON fs.srvfdw = fdw.oid
LEFT JOIN LATERAL (
    SELECT
        (unnest(fs.srvoptions))::text as opt,
        split_part((unnest(fs.srvoptions))::text, '=', 1) as option_name,
        split_part((unnest(fs.srvoptions))::text, '=', 2) as option_value
) fso ON true
GROUP BY fs.srvname, fs.srvowner, fdw.fdwname;

-- List all foreign tables and their options
SELECT
    ft.ftrelid::regclass as foreign_table,
    fs.srvname as server_name,
    array_agg(fto.option_name || '=' || fto.option_value) as table_options
FROM pg_foreign_table ft
JOIN pg_foreign_server fs ON ft.ftserver = fs.oid
LEFT JOIN LATERAL (
    SELECT
        split_part((unnest(ft.ftoptions))::text, '=', 1) as option_name,
        split_part((unnest(ft.ftoptions))::text, '=', 2) as option_value
) fto ON true
GROUP BY ft.ftrelid, fs.srvname;

-- List user mappings (without passwords)
SELECT
    um.umuser::regrole as local_user,
    fs.srvname as server_name,
    CASE
        WHEN um.umoptions IS NOT NULL THEN 'Password configured'
        ELSE 'No password (uses .pgpass)'
    END as auth_status
FROM pg_user_mapping um
JOIN pg_foreign_server fs ON um.umserver = fs.oid;
```

### 5.3 Monitoring Stack Recommendation

**Recommended Tools:**

1. **PostgreSQL Monitoring:**
   - **pgDash:** Comprehensive dashboard with FDW connection tracking
   - **pgMonitor (Crunchy Data):** Open-source Prometheus + Grafana stack
   - **Datadog PostgreSQL Integration:** Cloud-based monitoring

2. **Custom Monitoring:**
   - Export `pg_stat_activity` metrics to Prometheus
   - Track FDW query latency via pg_stat_statements
   - Log FDW errors to centralized logging (ELK, Splunk)

**Implementation Example (Prometheus + Grafana):**

```yaml
# prometheus-postgres-exporter.yml
datasources:
  - name: perseus_fdw_metrics
    connection_string: "postgresql://monitor:password@localhost:5432/perseus"
    queries:
      - name: fdw_connections
        query: |
          SELECT
            usename as user,
            application_name,
            COUNT(*) as connection_count
          FROM pg_stat_activity
          WHERE application_name LIKE '%fdw%'
          GROUP BY usename, application_name
        metrics:
          - connection_count:
              usage: GAUGE
              description: "Number of FDW connections"

      - name: fdw_query_performance
        query: |
          SELECT
            queryid,
            calls,
            mean_exec_time as avg_ms,
            max_exec_time as max_ms
          FROM pg_stat_statements
          WHERE query LIKE '%_fdw%'
        metrics:
          - avg_ms:
              usage: GAUGE
              description: "Average FDW query latency"
          - max_ms:
              usage: GAUGE
              description: "Max FDW query latency"
```

### 5.4 Health Check Queries

```sql
-- Test connectivity to all foreign servers
CREATE OR REPLACE FUNCTION check_fdw_health()
RETURNS TABLE(
    server_name TEXT,
    status TEXT,
    latency_ms NUMERIC,
    error_message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    start_time TIMESTAMPTZ;
    end_time TIMESTAMPTZ;
BEGIN
    FOR rec IN
        SELECT fs.srvname, ft.ftrelid::regclass as sample_table
        FROM pg_foreign_server fs
        JOIN pg_foreign_table ft ON ft.ftserver = fs.oid
        LIMIT 1  -- One table per server for testing
    LOOP
        BEGIN
            start_time := clock_timestamp();
            EXECUTE 'SELECT 1 FROM ' || rec.sample_table || ' LIMIT 1';
            end_time := clock_timestamp();

            RETURN QUERY SELECT
                rec.srvname,
                'OK'::TEXT,
                EXTRACT(MILLISECONDS FROM (end_time - start_time)),
                NULL::TEXT;
        EXCEPTION WHEN OTHERS THEN
            RETURN QUERY SELECT
                rec.srvname,
                'ERROR'::TEXT,
                NULL::NUMERIC,
                SQLERRM;
        END;
    END LOOP;
END;
$$;

-- Run health check
SELECT * FROM check_fdw_health();

-- Schedule via pg_cron (if installed)
CREATE EXTENSION IF NOT EXISTS pg_cron;
SELECT cron.schedule('fdw-health-check', '*/5 * * * *', $$
    INSERT INTO fdw_health_log
    SELECT NOW(), * FROM check_fdw_health();
$$);
```

---

## 6. Transaction Coordination & Limitations

### 6.1 Distributed Transaction Limitations

**Critical Finding:** postgres_fdw does NOT support two-phase commit (2PC). This creates ACID challenges for distributed transactions.

#### 6.1.1 What Works

```sql
-- Scenario 1: Read-only transactions (SAFE)
BEGIN;
SELECT * FROM hermes_runs_fdw WHERE experiment_id = 12345;
SELECT * FROM sqlapps_lookups_fdw WHERE code = 'COMPLETED';
COMMIT;
-- ✅ No data modification, no consistency risk

-- Scenario 2: Single foreign server writes (SAFE)
BEGIN;
INSERT INTO local_table VALUES (...);
UPDATE hermes_staging_fdw SET processed = true WHERE id = 123;
COMMIT;
-- ✅ Both commit, or both rollback (FDW follows local transaction)
```

#### 6.1.2 What Fails

```sql
-- Scenario 3: Multi-server writes (UNSAFE - NO 2PC)
BEGIN;
INSERT INTO hermes_staging_fdw VALUES (...);  -- Commits on hermes
INSERT INTO sqlapps_log_fdw VALUES (...);     -- Commits on sqlapps
-- If local commit fails here, foreign commits already persisted!
COMMIT;  -- Local fails, but foreign servers already committed
-- ❌ RESULT: Inconsistent state (orphaned records on foreign servers)
```

**Problem Explanation:**
1. Local transaction starts
2. FDW executes INSERT on hermes (commits on hermes)
3. FDW executes INSERT on sqlapps (commits on sqlapps)
4. Local COMMIT fails (e.g., constraint violation on local table)
5. **Foreign commits cannot be rolled back** (already committed on remote servers)
6. Result: Data inconsistency

### 6.2 Workarounds for Distributed Transactions

#### Option 1: Avoid Cross-Server Writes (RECOMMENDED)

**Decision:** Limit FDW writes to single foreign server per transaction.

```sql
-- Pattern: Write to ONE foreign server per transaction
BEGIN;
INSERT INTO local_table VALUES (...);
UPDATE hermes_staging_fdw SET processed = true WHERE id = 123;
COMMIT;

-- Separate transaction for second foreign server
BEGIN;
INSERT INTO sqlapps_log_fdw VALUES (...);
COMMIT;
```

**Implementation for Perseus:**
- **Read-only FDW connections** for hermes, sqlapps, deimeter (most common use case)
- **Write operations** remain local to perseus database
- **Staging pattern:** Copy foreign data to local staging tables, process locally

#### Option 2: Compensating Transactions (SAGA Pattern)

**For unavoidable multi-server writes:**

```sql
-- Pseudo-code
BEGIN;
    INSERT INTO hermes_staging_fdw VALUES (...) RETURNING id INTO v_hermes_id;

    BEGIN  -- Nested block
        INSERT INTO sqlapps_log_fdw VALUES (...);
    EXCEPTION WHEN OTHERS THEN
        -- Compensate: Delete from hermes
        DELETE FROM hermes_staging_fdw WHERE id = v_hermes_id;
        RAISE;
    END;
COMMIT;
```

**Limitations:**
- Compensation not atomic (can fail too)
- Race conditions if other transactions access interim state
- Complex error handling

#### Option 3: Application-Level 2PC (CUSTOM)

**Implement 2PC in application layer:**

```python
# Python example (pseudo-code)
def distributed_transaction():
    conn_local = connect('perseus')
    conn_hermes = connect('hermes')
    conn_sqlapps = connect('sqlapps')

    try:
        # Phase 1: Prepare
        conn_local.execute("BEGIN")
        conn_hermes.execute("BEGIN")
        conn_sqlapps.execute("BEGIN")

        conn_local.execute("INSERT INTO local_table ...")
        conn_hermes.execute("INSERT INTO staging ...")
        conn_sqlapps.execute("INSERT INTO log ...")

        # Phase 2: Commit
        conn_local.commit()
        conn_hermes.commit()
        conn_sqlapps.commit()

    except Exception as e:
        # Rollback all
        conn_local.rollback()
        conn_hermes.rollback()
        conn_sqlapps.rollback()
        raise
```

**Limitations:**
- Not truly atomic (network partition can cause split-brain)
- Requires distributed transaction coordinator
- Complex failure recovery

### 6.3 Recommendation for Perseus

**Decision: Read-Only FDW + Local Processing**

```
┌─────────────────────────────────────────────────┐
│           Foreign Databases (READ-ONLY)         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ hermes   │  │ sqlapps  │  │ deimeter │     │
│  │  (FDW)   │  │  (FDW)   │  │  (FDW)   │     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘     │
└───────┼────────────┼────────────┼─────────────┘
        │            │            │
        │ SELECT     │ SELECT     │ SELECT
        ▼            ▼            ▼
┌─────────────────────────────────────────────────┐
│         Local Database (perseus)                │
│  ┌────────────────────────────────────────┐    │
│  │      Staging Tables (local)            │    │
│  │  • hermes_runs_staging                 │    │
│  │  • sqlapps_lookups_cached              │    │
│  ├────────────────────────────────────────┤    │
│  │      Processing (local transactions)   │    │
│  │  • All writes to local tables          │    │
│  │  • Full ACID guarantees                │    │
│  └────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘
```

**Implementation:**

```sql
-- Step 1: Create read-only FDW connections
CREATE SERVER hermes_fdw ... OPTIONS (...);
CREATE USER MAPPING FOR perseus_app SERVER hermes_fdw
  OPTIONS (user 'perseus_readonly', ...);  -- READ-ONLY role

-- Step 2: Create local staging/cache tables
CREATE TABLE hermes_runs_staging (LIKE hermes_runs_fdw INCLUDING ALL);
CREATE TABLE sqlapps_lookups_cached (LIKE sqlapps_lookups_fdw INCLUDING ALL);

-- Step 3: Periodic refresh (pg_cron)
SELECT cron.schedule('refresh-hermes-staging', '*/15 * * * *', $$
    TRUNCATE hermes_runs_staging;
    INSERT INTO hermes_runs_staging
    SELECT * FROM hermes_runs_fdw
    WHERE created_at >= NOW() - INTERVAL '1 day';
$$);

-- Step 4: Application queries use local copies
SELECT hr.*, sl.description
FROM hermes_runs_staging hr
JOIN sqlapps_lookups_cached sl ON hr.status_code = sl.code
WHERE hr.experiment_id = 12345;
-- ✅ Fully local query, no FDW latency, full ACID guarantees
```

**Benefits:**
- No distributed transaction complexity
- Full ACID guarantees (local transactions only)
- Better performance (no network latency for writes)
- Simpler error handling

**Trade-offs:**
- Data slightly stale (acceptable for Perseus use cases)
- Requires storage for staging tables
- Refresh overhead (mitigated by scheduling)

---

## 7. Implementation Roadmap for Perseus

### 7.1 Phase 1: Infrastructure Setup

**Tasks:**

1. **Install postgres_fdw extension**
   ```sql
   CREATE EXTENSION IF NOT EXISTS postgres_fdw;
   ```

2. **Create foreign servers**
   ```sql
   -- See Section 1.2 for full configuration
   CREATE SERVER hermes_fdw FOREIGN DATA WRAPPER postgres_fdw OPTIONS (...);
   CREATE SERVER sqlapps_fdw FOREIGN DATA WRAPPER postgres_fdw OPTIONS (...);
   CREATE SERVER deimeter_fdw FOREIGN DATA WRAPPER postgres_fdw OPTIONS (...);
   ```

3. **Create read-only roles on foreign servers**
   ```sql
   -- Execute on each foreign database
   CREATE ROLE perseus_fdw_reader WITH LOGIN PASSWORD '...';
   GRANT SELECT ON required_tables TO perseus_fdw_reader;
   ```

4. **Create user mappings**
   ```sql
   -- Execute on perseus database
   CREATE USER MAPPING FOR perseus_app SERVER hermes_fdw
     OPTIONS (user 'perseus_fdw_reader', password '...');
   -- Repeat for sqlapps, deimeter
   ```

5. **Create foreign tables**
   ```sql
   -- Import all tables from foreign schema
   IMPORT FOREIGN SCHEMA public
     LIMIT TO (runs, experiments, run_conditions, ...)
     FROM SERVER hermes_fdw
     INTO public;

   -- Or create manually with options
   CREATE FOREIGN TABLE hermes_runs (
       id BIGINT,
       experiment_id BIGINT,
       ...
   ) SERVER hermes_fdw
   OPTIONS (
       schema_name 'public',
       table_name 'runs',
       fetch_size '10000',
       use_remote_estimate 'true'
   );
   ```

### 7.2 Phase 2: Migration from Linked Servers

**SQL Server Linked Server Syntax:**

```sql
-- SQL Server (old)
SELECT *
FROM [HERMES].[dbo].[runs]
WHERE experiment_id = 12345;
```

**PostgreSQL FDW Syntax:**

```sql
-- PostgreSQL (new)
SELECT *
FROM hermes_runs_fdw
WHERE experiment_id = 12345;
```

**Migration Tasks:**

1. **Inventory linked server queries**
   ```bash
   # Search codebase for linked server references
   grep -r "\[HERMES\]" source/
   grep -r "\[SQLAPPS\]" source/
   grep -r "\[DEIMETER\]" source/
   ```

2. **Update SQL syntax**
   - Replace `[SERVER].[schema].[table]` with `table_fdw`
   - Add explicit schema qualification if needed: `public.table_fdw`

3. **Test query equivalence**
   ```sql
   -- Compare results (SQL Server vs PostgreSQL)
   -- Validate row counts, checksums, edge cases
   ```

### 7.3 Phase 3: Performance Optimization

**Tasks:**

1. **Run EXPLAIN ANALYZE on critical queries**
   ```sql
   EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
   SELECT * FROM hermes_runs_fdw WHERE experiment_id = 12345;
   ```

2. **Verify predicate pushdown**
   - Check for "Remote SQL: ..." in EXPLAIN output
   - Ensure WHERE clauses appear in Remote SQL

3. **Tune fetch_size per table**
   - Large tables: 10000
   - Small tables: 500

4. **Run ANALYZE on foreign tables**
   ```sql
   ANALYZE hermes_runs_fdw;
   ```

5. **Consider local caching for lookup tables**
   ```sql
   CREATE TABLE sqlapps_lookups_cached AS
   SELECT * FROM sqlapps_lookups_fdw;

   CREATE INDEX ON sqlapps_lookups_cached (code);
   ```

### 7.4 Phase 4: Monitoring Setup

**Tasks:**

1. **Deploy monitoring queries** (Section 5.1)
   - Connection counts
   - Query performance
   - Error rates

2. **Configure alerts**
   - Connection limit warnings
   - Query latency spikes
   - FDW connection failures

3. **Set up health checks**
   ```sql
   SELECT * FROM check_fdw_health();  -- See Section 5.4
   ```

4. **Integrate with existing monitoring stack**
   - Export metrics to Prometheus/Datadog
   - Create Grafana dashboards

### 7.5 Phase 5: Testing & Validation

**Test Scenarios:**

1. **Functional Testing**
   - [ ] Query returns correct results (compare to SQL Server)
   - [ ] Row counts match
   - [ ] Aggregates match
   - [ ] Joins produce correct output

2. **Performance Testing**
   - [ ] Query latency within 20% of baseline
   - [ ] Network latency impact measured
   - [ ] Predicate pushdown verified

3. **Failure Testing**
   - [ ] Foreign server down (graceful error handling)
   - [ ] Network partition (timeout handling)
   - [ ] Connection exhaustion (connection limit enforcement)

4. **Load Testing**
   - [ ] Concurrent queries (100+ connections)
   - [ ] Connection pool behavior
   - [ ] Foreign server impact

---

## 8. Alternatives Considered

### 8.1 Alternative 1: Logical Replication (SymmetricDS)

**Description:** Replicate foreign tables to local database via SymmetricDS.

**Pros:**
- No FDW complexity
- Local queries (fast, full ACID)
- No foreign server dependency

**Cons:**
- Data latency (replication lag)
- Storage overhead (duplicate data)
- Replication setup and maintenance
- Already using SymmetricDS for sqlwarehouse2 (additional complexity)

**Verdict:** ❌ Rejected (too much replication complexity, Perseus needs near-real-time data)

### 8.2 Alternative 2: dblink Extension

**Description:** Use legacy `dblink` extension for cross-database queries.

**Pros:**
- Mature, widely used
- Flexible (supports arbitrary SQL)

**Cons:**
- No predicate pushdown
- No aggregate pushdown
- Manual connection management
- Less secure (connection string in queries)
- No query planning integration

**Verdict:** ❌ Rejected (postgres_fdw is superior in all aspects)

### 8.3 Alternative 3: Application-Level Federation

**Description:** Application fetches from multiple databases, joins in memory.

**Pros:**
- No database-level dependencies
- Full control over query execution
- Can optimize for application access patterns

**Cons:**
- Network latency (multiple round trips)
- Memory overhead (joins in application)
- Complex application logic
- No SQL-level optimizations

**Verdict:** ❌ Rejected (performance overhead, Perseus has complex SQL)

### 8.4 Alternative 4: Materialized Views over FDW

**Description:** Create materialized views on top of FDW tables, refresh periodically.

**Pros:**
- Fast local queries
- Snapshot consistency
- Simple refresh logic

**Cons:**
- Data staleness (refresh interval)
- Storage overhead
- Refresh performance impact

**Verdict:** ✅ **Recommended as complement to FDW** (not replacement)

**Implementation:**

```sql
-- Create materialized view over FDW
CREATE MATERIALIZED VIEW hermes_runs_recent AS
SELECT * FROM hermes_runs_fdw
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days';

-- Refresh periodically
REFRESH MATERIALIZED VIEW CONCURRENTLY hermes_runs_recent;

-- Schedule refresh (pg_cron)
SELECT cron.schedule('refresh-hermes-recent', '0 * * * *', $$
    REFRESH MATERIALIZED VIEW CONCURRENTLY hermes_runs_recent;
$$);
```

---

## 9. Decision Summary

### 9.1 Approved Architecture

**Foreign Data Wrapper Configuration for Perseus:**

```
┌────────────────────────────────────────────────────────┐
│                   Application Layer                     │
│                    (Pegasus / API)                      │
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────┐
│              Connection Pool (PgBouncer)                │
│              Transaction Mode, 20 connections           │
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────┐
│          PostgreSQL 17 - perseus Database               │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Foreign Data Wrappers (READ-ONLY)        │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐      │  │
│  │  │ hermes   │  │ sqlapps  │  │ deimeter │      │  │
│  │  │ 6 tables │  │ 9 tables │  │ 2 tables │      │  │
│  │  └──────────┘  └──────────┘  └──────────┘      │  │
│  │  • fetch_size=5000-10000                        │  │
│  │  • use_remote_estimate=true                     │  │
│  │  • TCP keepalives enabled                       │  │
│  │  • SCRAM-SHA-256 auth                           │  │
│  │  • SSL required (verify-full)                   │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │      Local Staging/Cache Tables (optional)       │  │
│  │  • sqlapps_lookups_cached (small lookups)       │  │
│  │  • Refreshed daily via pg_cron                  │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

### 9.2 Configuration Template

**Complete configuration for one foreign server (hermes):**

```sql
-- 1. Create foreign server
CREATE SERVER hermes_fdw
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (
    host 'hermes.production.internal',
    port '5432',
    dbname 'hermes',
    -- Connection management
    connect_timeout '5',
    keepalives '1',
    keepalives_idle '30',
    keepalives_interval '10',
    keepalives_count '3',
    -- Performance
    fetch_size '5000',
    use_remote_estimate 'true',
    async_capable 'true',
    -- Security
    sslmode 'verify-full',
    sslcert '/etc/ssl/certs/perseus-client.pem',
    sslkey '/etc/ssl/private/perseus-client.key',
    sslrootcert '/etc/ssl/certs/ca-bundle.pem'
  );

-- 2. Create user mapping (SCRAM authentication)
CREATE USER MAPPING FOR perseus_app
  SERVER hermes_fdw
  OPTIONS (
    user 'perseus_fdw_reader',
    password 'SCRAM-SHA-256$4096:...'  -- Use actual SCRAM hash
  );

-- 3. Import foreign tables
IMPORT FOREIGN SCHEMA public
  LIMIT TO (
    runs,
    experiments,
    run_conditions,
    run_condition_options,
    run_condition_values,
    run_master_conditions
  )
  FROM SERVER hermes_fdw
  INTO public;

-- 4. Rename tables with _fdw suffix
ALTER FOREIGN TABLE runs RENAME TO hermes_runs_fdw;
ALTER FOREIGN TABLE experiments RENAME TO hermes_experiments_fdw;
-- ... repeat for all tables

-- 5. Set table-specific options
ALTER FOREIGN TABLE hermes_runs_fdw OPTIONS (
  SET fetch_size '10000',  -- Large table, high scan volume
  SET use_remote_estimate 'true'
);

ALTER FOREIGN TABLE hermes_run_conditions_fdw OPTIONS (
  SET fetch_size '1000'  -- Smaller table, selective queries
);

-- 6. Run ANALYZE to populate local statistics
ANALYZE hermes_runs_fdw;
ANALYZE hermes_experiments_fdw;

-- 7. Create local cache for small lookup tables (optional)
CREATE TABLE hermes_master_conditions_cached AS
SELECT * FROM hermes_run_master_conditions_fdw;

CREATE INDEX ON hermes_master_conditions_cached (id);

-- 8. Schedule cache refresh (pg_cron)
SELECT cron.schedule(
  'refresh-hermes-lookups',
  '0 2 * * *',  -- Daily at 2 AM
  $$
    TRUNCATE hermes_master_conditions_cached;
    INSERT INTO hermes_master_conditions_cached
    SELECT * FROM hermes_run_master_conditions_fdw;
  $$
);
```

### 9.3 Operational Runbook

**Pre-Deployment Checklist:**

- [ ] Foreign server roles created with appropriate permissions
- [ ] SSL certificates deployed and tested
- [ ] Network connectivity verified (no firewall blocks)
- [ ] PgBouncer configured with appropriate pool size
- [ ] Monitoring dashboards deployed
- [ ] Health check queries scheduled
- [ ] Alert thresholds configured

**Post-Deployment Validation:**

- [ ] Run `SELECT * FROM check_fdw_health()` - all servers OK
- [ ] Verify predicate pushdown with EXPLAIN ANALYZE
- [ ] Compare query results to SQL Server baseline (checksums)
- [ ] Load test: 100 concurrent queries
- [ ] Failure test: Disconnect foreign server, verify graceful error handling
- [ ] Performance test: Query latency within 20% of baseline

**Ongoing Maintenance:**

- **Daily:** Review FDW error logs
- **Weekly:** Review query performance metrics (pg_stat_statements)
- **Monthly:** Review connection usage, adjust pool sizes if needed
- **Quarterly:** Re-run ANALYZE on foreign tables

---

## 10. References & Sources

### 10.1 Official Documentation

- [PostgreSQL Documentation: postgres_fdw](https://www.postgresql.org/docs/current/postgres-fdw.html)
- [PostgreSQL Documentation: Connections and Authentication](https://www.postgresql.org/docs/9.5/runtime-config-connection.html)

### 10.2 Performance & Best Practices

- [Performance Tips for Postgres FDW - Crunchy Data Blog](https://www.crunchydata.com/blog/performance-tips-for-postgres-fdw)
- [Mastering Postgres_FDW: Setup, optimize performance and avoid Common Pitfalls - Microsoft Community Hub](https://techcommunity.microsoft.com/blog/adforpostgresql/mastering-postgres-fdw-setup-optimize-performance-and-avoid-common-pitfalls/4463564)
- [Foreign data wrapper for PostgreSQL: Performance Tuning - Cybertec](https://www.cybertec-postgresql.com/en/foreign-data-wrapper-for-postgresql-performance-tuning/)
- [Why Postgres FDW Made My Queries Slow (and How I Fixed It) - Svix Blog](https://www.svix.com/blog/fdw-pitfalls/)
- [PostgreSQL: Aggregate Push-down in postgres_fdw - EDB](https://www.enterprisedb.com/blog/postgresql-aggregate-push-down-postgresfdw)
- [Boost query performance using Foreign Data Wrapper with minimal changes - OnGres](https://ongres.com/blog/boost-query-performance-using-fdw-with-minimal-changes/)

### 10.3 Connection Pooling & Management

- [Connection pooling best practices - Azure Database for PostgreSQL - Microsoft Learn](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-connection-pooling-best-practices)
- [Why you should use Connection Pooling when setting Max_connections in Postgres - EDB](https://www.enterprisedb.com/postgres-tutorials/why-you-should-use-connection-pooling-when-setting-maxconnections-postgres)
- [Performance best practices for using Azure Database for PostgreSQL – Connection Pooling - Microsoft Azure Blog](https://azure.microsoft.com/en-us/blog/performance-best-practices-for-using-azure-database-for-postgresql-connection-pooling/)
- [PostgreSQL Connection Pooling: Part 1 - Pros & Cons - ScaleGrid](https://scalegrid.io/blog/postgresql-connection-pooling-part-1-pros-and-cons/)

### 10.4 Connection Failure & Retry Logic

- [PostgreSQL: pgsql: postgres_fdw: Restructure connection retry logic](https://www.postgresql.org/message-id/E1kTHqd-0006zm-PU@gemulon.postgresql.org)
- [Thread: Retry Cached Remote Connections for postgres_fdw - Postgres Professional](https://postgrespro.com/list/thread-id/2500122)
- [Dead connection handling in PostgreSQL - Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.DeadConnectionHandling.html)
- [TCP keepalive for a better PostgreSQL experience - CYBERTEC](https://www.cybertec-postgresql.com/en/tcp-keepalive-for-a-better-postgresql-experience/)

### 10.5 Security & Authentication

- [Postgresql_fdw Authentication Changes in PostgreSQL 13 - Percona](https://www.percona.com/blog/postgresql_fdw-authentication-changes-in-postgresql-13/)
- [How to Secure PostgreSQL: Security Hardening Best Practices and Tips - EDB](https://www.enterprisedb.com/blog/how-to-secure-postgresql-security-hardening-best-practices-checklist-tips-encryption-authentication-vulnerabilities)

### 10.6 Monitoring & Observability

- [Monitoring Key Metrics: Postgres Health - EDB](https://www.enterprisedb.com/blog/monitoring-key-metrics-to-keep-your-postgres-db-healthy)
- [FDW Statistics - Postgres Wrappers](http://fdw.dev/guides/usage-statistics/)
- [Key metrics for PostgreSQL monitoring - Datadog](https://www.datadoghq.com/blog/postgresql-monitoring/)
- [Introducing prometheus_fdw: Seamless Monitoring in Postgres - Tembo](https://tembo.io/blog/monitoring-with-prometheus-fdw)

### 10.7 Distributed Transactions

- [Atomic Commit of Distributed Transactions - PostgreSQL wiki](https://wiki.postgresql.org/wiki/Atomic_Commit_of_Distributed_Transactions)
- [Thread: Transactions involving multiple postgres foreign servers - Postgres Professional](https://postgrespro.com/list/thread-id/1859279)
- [Parallel Commits for Transactions Using postgres_fdw on PostgreSQL 15 - Percona](https://www.percona.com/blog/parallel-commits-for-transactions-using-postgres_fdw-on-postgresql-15/)
- [Distributed Database With PostgreSQL – Atomic Commit Problems - Highgo Software](https://www.highgo.ca/2022/03/18/distributed-database-with-postgresql-atomic-commit-problems/)

### 10.8 PostgreSQL 14/15 Enhancements

- [postgres_fdw Enhancement in PostgreSQL 14 - Percona](https://www.percona.com/blog/postgres_fdw-enhancement-in-postgresql-14/)
- [PostgreSQL: Documentation: 14: F.35. postgres_fdw](https://www.postgresql.org/docs/14/postgres-fdw.html)

---

## Appendix A: Quick Start Checklist

**For DevOps/DBAs implementing FDW:**

### Step 1: Foreign Server Setup (5 min per server)

```bash
# On foreign server (hermes):
psql -U postgres -d hermes -c "
CREATE ROLE perseus_fdw_reader WITH LOGIN PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE hermes TO perseus_fdw_reader;
GRANT USAGE ON SCHEMA public TO perseus_fdw_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO perseus_fdw_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO perseus_fdw_reader;
"
```

### Step 2: Local Server Setup (10 min)

```bash
# On local server (perseus):
psql -U postgres -d perseus -c "
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

CREATE SERVER hermes_fdw
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (
    host 'hermes.prod.local',
    port '5432',
    dbname 'hermes',
    connect_timeout '5',
    keepalives '1',
    keepalives_idle '30',
    keepalives_interval '10',
    keepalives_count '3',
    fetch_size '5000',
    use_remote_estimate 'true',
    sslmode 'require'
  );

CREATE USER MAPPING FOR perseus_app
  SERVER hermes_fdw
  OPTIONS (user 'perseus_fdw_reader', password 'secure_password');

IMPORT FOREIGN SCHEMA public
  FROM SERVER hermes_fdw
  INTO public;
"
```

### Step 3: Validation (5 min)

```bash
# Test connectivity
psql -U perseus_app -d perseus -c "
SELECT * FROM check_fdw_health();
SELECT COUNT(*) FROM hermes_runs_fdw;
"

# Verify predicate pushdown
psql -U perseus_app -d perseus -c "
EXPLAIN (VERBOSE, COSTS OFF)
SELECT * FROM hermes_runs_fdw WHERE experiment_id = 12345;
"
```

---

## Document Metadata

**Revision History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-19 | Pierre Ribeiro | Initial research report |

**Approval:**

- [ ] Technical Review: _______________________
- [ ] Security Review: _______________________
- [ ] DBA Sign-off: _______________________

**Next Steps:**

1. Review this document with stakeholders
2. Approve configuration settings
3. Create Jira tickets for implementation phases
4. Schedule Phase 1 (Infrastructure Setup) for Sprint 10

---

**END OF DOCUMENT**
