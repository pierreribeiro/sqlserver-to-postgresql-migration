# Performance Tests

## 📁 Directory Purpose

This directory contains **performance benchmark tests** to validate that PostgreSQL procedures perform within acceptable thresholds compared to SQL Server baseline.

**Test Goal:** PostgreSQL execution ≤120% of SQL Server baseline

**Test Framework:** EXPLAIN ANALYZE + Custom benchmarking scripts

---

## 🎯 Performance Testing Philosophy

**Measure, Don't Guess**

Performance tests should:
- ✅ Establish SQL Server baseline first
- ✅ Use realistic dataset sizes
- ✅ Test under representative load
- ✅ Measure multiple metrics (time, I/O, memory, locks)
- ✅ Run multiple iterations (avoid noise)
- ✅ Compare apples-to-apples (same data, same queries)

**Acceptance Criteria:** PostgreSQL ≤120% (1.2x) of SQL Server

---

## 📋 Performance Test Structure

### Benchmark Test Template

```sql
-- =============================================================================
-- Performance Benchmark: schema.procedure_name
-- Author: Pierre Ribeiro
-- Created: YYYY-MM-DD
-- Baseline: SQL Server execution time
-- =============================================================================

\timing on

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

-- Test dataset size
\set test_dataset_size 10000

-- Number of iterations (for averaging)
\set iterations 5

-- SQL Server baseline (from production measurements)
\set sqlserver_baseline_ms 980

-- Acceptable delta (20% slower is acceptable)
\set max_delta_percent 20

-- =============================================================================
-- SETUP: Prepare Test Data
-- =============================================================================

-- Clean test data
DELETE FROM M_Upstream WHERE MaterialID BETWEEN 90000 AND 99999;

-- Insert test dataset (realistic size)
INSERT INTO M_Upstream (MaterialID, ParentID, Quantity, Status)
SELECT 
    90000 + generate_series,
    1000 + (generate_series % 100),
    (random() * 1000)::INT,
    CASE (random() * 3)::INT
        WHEN 0 THEN 'Active'
        WHEN 1 THEN 'Pending'
        ELSE 'Inactive'
    END
FROM generate_series(1, :test_dataset_size);

-- Analyze tables (update statistics)
ANALYZE M_Upstream;
ANALYZE Materials;

-- =============================================================================
-- WARMUP: Populate Cache
-- =============================================================================

-- Run once to warm up buffer cache (not counted)
SELECT * FROM reconcilemupstream(90001, 'Active');

-- =============================================================================
-- BENCHMARK: Measure Performance
-- =============================================================================

\echo '=========================================='
\echo 'Performance Benchmark: reconcilemupstream'
\echo '=========================================='
\echo 'Dataset Size: ' :test_dataset_size
\echo 'Iterations: ' :iterations
\echo 'SQL Server Baseline: ' :sqlserver_baseline_ms 'ms'
\echo '=========================================='

-- Create temporary table to store results
CREATE TEMP TABLE benchmark_results (
    iteration INT,
    execution_time_ms NUMERIC,
    rows_processed INT,
    buffer_hits BIGINT,
    buffer_reads BIGINT,
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Run benchmark iterations
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time_ms NUMERIC;
    i INT;
BEGIN
    FOR i IN 1..:iterations LOOP
        -- Reset statistics
        SELECT pg_stat_reset();
        
        -- Measure execution time
        start_time := clock_timestamp();
        
        PERFORM * FROM reconcilemupstream(90001 + i, 'Active');
        
        end_time := clock_timestamp();
        execution_time_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
        
        -- Capture statistics
        INSERT INTO benchmark_results (
            iteration,
            execution_time_ms,
            rows_processed,
            buffer_hits,
            buffer_reads
        )
        SELECT 
            i,
            execution_time_ms,
            (SELECT COUNT(*) FROM M_Upstream WHERE MaterialID = 90001 + i),
            sum(blks_hit),
            sum(blks_read)
        FROM pg_stat_database
        WHERE datname = current_database();
        
    END LOOP;
END $$;

-- =============================================================================
-- ANALYSIS: Calculate Statistics
-- =============================================================================

\echo ''
\echo 'Results:'
\echo '=========================================='

SELECT 
    'Avg Execution Time' AS metric,
    ROUND(AVG(execution_time_ms), 2)::TEXT || ' ms' AS value
FROM benchmark_results
UNION ALL
SELECT 
    'Min Execution Time',
    ROUND(MIN(execution_time_ms), 2)::TEXT || ' ms'
FROM benchmark_results
UNION ALL
SELECT 
    'Max Execution Time',
    ROUND(MAX(execution_time_ms), 2)::TEXT || ' ms'
FROM benchmark_results
UNION ALL
SELECT 
    'Std Deviation',
    ROUND(STDDEV(execution_time_ms), 2)::TEXT || ' ms'
FROM benchmark_results
UNION ALL
SELECT 
    'Buffer Hit Ratio',
    ROUND(100.0 * AVG(buffer_hits::NUMERIC / NULLIF(buffer_hits + buffer_reads, 0)), 2)::TEXT || ' %'
FROM benchmark_results
UNION ALL
SELECT 
    'Rows/Second',
    ROUND(AVG(rows_processed / NULLIF(execution_time_ms / 1000.0, 0)), 0)::TEXT
FROM benchmark_results;

\echo '=========================================='

-- =============================================================================
-- COMPARISON: PostgreSQL vs SQL Server
-- =============================================================================

DO $$
DECLARE
    avg_pg_time NUMERIC;
    delta_ms NUMERIC;
    delta_percent NUMERIC;
    verdict TEXT;
BEGIN
    -- Calculate average PostgreSQL time
    SELECT AVG(execution_time_ms) INTO avg_pg_time
    FROM benchmark_results;
    
    -- Calculate delta
    delta_ms := avg_pg_time - :sqlserver_baseline_ms;
    delta_percent := (delta_ms / :sqlserver_baseline_ms) * 100;
    
    -- Determine verdict
    IF delta_percent <= :max_delta_percent THEN
        verdict := '✅ PASS - Within acceptable threshold';
    ELSE
        verdict := '❌ FAIL - Exceeds acceptable threshold';
    END IF;
    
    -- Display comparison
    RAISE NOTICE '';
    RAISE NOTICE 'Comparison to SQL Server:';
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'SQL Server Baseline:    % ms', :sqlserver_baseline_ms;
    RAISE NOTICE 'PostgreSQL Average:     % ms', ROUND(avg_pg_time, 2);
    RAISE NOTICE 'Delta:                  % ms (% %%)', ROUND(delta_ms, 2), ROUND(delta_percent, 2);
    RAISE NOTICE 'Threshold:              % %%', :max_delta_percent;
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Verdict: %', verdict;
    RAISE NOTICE '==========================================';
    
    -- Fail test if exceeds threshold
    IF delta_percent > :max_delta_percent THEN
        RAISE EXCEPTION 'Performance test failed: exceeded threshold';
    END IF;
END $$;

-- =============================================================================
-- EXPLAIN ANALYZE: Detailed Execution Plan
-- =============================================================================

\echo ''
\echo 'Execution Plan:'
\echo '=========================================='

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT TEXT)
SELECT * FROM reconcilemupstream(90001, 'Active');

-- =============================================================================
-- CLEANUP
-- =============================================================================

DELETE FROM M_Upstream WHERE MaterialID BETWEEN 90000 AND 99999;
DROP TABLE benchmark_results;

\timing off
```

---

## 🔍 Performance Metrics

### Key Metrics to Measure

1. **Execution Time**
   - Wall-clock time (total runtime)
   - Planning time (query optimization)
   - Execution time (actual work)

2. **I/O Metrics**
   - Buffer hits (data found in cache)
   - Buffer reads (data read from disk)
   - Buffer hit ratio (should be >90%)

3. **Resource Usage**
   - Memory usage (work_mem, shared_buffers)
   - CPU usage (% utilization)
   - Temp file usage (if queries spill to disk)

4. **Throughput**
   - Rows processed per second
   - Queries per second (QPS)

5. **Lock Contention**
   - Lock wait time
   - Deadlock count

---

## 📊 Benchmark Scenarios

### Scenario 1: Small Dataset (< 1K rows)
**File:** `benchmark_reconcilemupstream_small.sql`

**Dataset:** 1,000 rows  
**SQL Server Baseline:** 45 ms  
**PostgreSQL Target:** ≤54 ms (120%)  
**Focus:** Query optimization, index usage

---

### Scenario 2: Medium Dataset (10K rows)
**File:** `benchmark_reconcilemupstream_medium.sql`

**Dataset:** 10,000 rows  
**SQL Server Baseline:** 980 ms  
**PostgreSQL Target:** ≤1,176 ms (120%)  
**Focus:** Batch processing, memory usage

---

### Scenario 3: Large Dataset (100K rows)
**File:** `benchmark_reconcilemupstream_large.sql`

**Dataset:** 100,000 rows  
**SQL Server Baseline:** 8,500 ms  
**PostgreSQL Target:** ≤10,200 ms (120%)  
**Focus:** Scalability, temp table usage

---

### Scenario 4: Concurrent Load
**File:** `benchmark_reconcilemupstream_concurrent.sql`

**Load:** 10 concurrent sessions  
**SQL Server Baseline:** 1,200 ms (avg)  
**PostgreSQL Target:** ≤1,440 ms (120%)  
**Focus:** Lock contention, connection pooling

---

## 🛠️ Running Performance Tests

### Single Benchmark
```bash
# Run one benchmark
psql -h localhost -d perseus_test \
  -f tests/performance/benchmark_reconcilemupstream.sql

# Save results to file
psql -h localhost -d perseus_test \
  -f tests/performance/benchmark_reconcilemupstream.sql \
  > results/reconcilemupstream_$(date +%Y%m%d).txt
```

### All Benchmarks
```bash
# Run all performance tests
for benchmark in tests/performance/benchmark_*.sql; do
  echo "Running $(basename $benchmark)..."
  psql -h localhost -d perseus_test -f "$benchmark" \
    > "results/$(basename $benchmark .sql)_$(date +%Y%m%d).txt"
done

# Generate summary report
python scripts/automation/generate-performance-report.py results/
```

### Compare Before/After
```bash
# Before optimization
psql -f tests/performance/benchmark_procedure.sql > before.txt

# Apply optimization (index, query rewrite, etc.)
psql -c "CREATE INDEX idx_material_parent ON M_Upstream(MaterialID, ParentID);"

# After optimization
psql -f tests/performance/benchmark_procedure.sql > after.txt

# Compare
diff before.txt after.txt
```

---

## 📈 Performance Analysis Tools

### EXPLAIN ANALYZE
```sql
-- Detailed execution plan
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, TIMING)
SELECT * FROM reconcilemupstream(1, 'Active');

-- Key metrics to look for:
-- - Seq Scan vs Index Scan
-- - Nested Loop vs Hash Join
-- - Sort methods (quicksort, external merge)
-- - Buffers (hit, read, temp)
```

### pg_stat_statements
```sql
-- Enable pg_stat_statements
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- View query statistics
SELECT 
    query,
    calls,
    mean_exec_time,
    stddev_exec_time,
    rows
FROM pg_stat_statements
WHERE query LIKE '%reconcilemupstream%'
ORDER BY mean_exec_time DESC;
```

### pg_stat_activity
```sql
-- Monitor running queries
SELECT 
    pid,
    usename,
    application_name,
    state,
    query_start,
    state_change,
    query
FROM pg_stat_activity
WHERE state = 'active'
AND query NOT LIKE '%pg_stat_activity%';
```

---

## 🎯 Performance Tuning Checklist

### Query Optimization
- [ ] Add indexes on frequently filtered columns
- [ ] Use covering indexes to avoid table lookups
- [ ] Rewrite correlated subqueries as JOINs
- [ ] Use CTEs or temp tables for complex logic
- [ ] Avoid unnecessary DISTINCT or ORDER BY

### Configuration Tuning
- [ ] Adjust `work_mem` for sorting/hashing operations
- [ ] Increase `shared_buffers` for larger datasets
- [ ] Configure `effective_cache_size` accurately
- [ ] Set `random_page_cost` appropriately (SSD vs HDD)
- [ ] Enable parallel query execution

### Schema Optimization
- [ ] Add appropriate indexes (B-tree, GiST, GIN)
- [ ] Partition large tables
- [ ] Use table inheritance for polymorphic data
- [ ] Materialize expensive views
- [ ] Denormalize for read-heavy workloads

### Procedural Optimization
- [ ] Batch inserts/updates (avoid row-by-row)
- [ ] Use bulk operations (COPY, INSERT...SELECT)
- [ ] Minimize function calls in tight loops
- [ ] Cache frequently accessed data
- [ ] Use prepared statements

---

## 🚨 Performance Red Flags

### Watch For These Issues

❌ **Sequential Scans on Large Tables**
```sql
-- Problem
Seq Scan on m_upstream  (cost=0.00..180000.00 rows=1000000)

-- Solution: Add index
CREATE INDEX idx_m_upstream_materialid ON M_Upstream(MaterialID);
```

❌ **Nested Loop with Large Inner Side**
```sql
-- Problem
Nested Loop  (cost=0.43..500000.00 rows=100000)

-- Solution: Force hash join
SET enable_nestloop = off;  -- Temporary
```

❌ **External Sort (Disk Spill)**
```sql
-- Problem
Sort Method: external merge  Disk: 25600kB

-- Solution: Increase work_mem
SET work_mem = '64MB';
```

❌ **Low Buffer Hit Ratio (<90%)**
```sql
-- Problem
Buffer Hits: 1000, Buffer Reads: 9000  (10% hit ratio)

-- Solution: Increase shared_buffers, add indexes
```

---

## 📚 Related Documentation

- Unit tests: `/tests/unit/`
- Integration tests: `/tests/integration/`
- Validation scripts: `/scripts/validation/`
- Performance tuning guide: `/docs/performance-tuning.md`

---

## 🔗 CI/CD Integration

```yaml
# .github/workflows/performance-test.yml
name: Performance Tests

on:
  push:
    branches: [main]
  schedule:
    - cron: '0 2 * * 0'  # Weekly on Sunday 2 AM

jobs:
  benchmark:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup PostgreSQL
        uses: ikalnytskyi/action-setup-postgres@v4
        
      - name: Run Performance Tests
        run: |
          for test in tests/performance/benchmark_*.sql; do
            psql -f "$test" > "results/$(basename $test).txt"
          done
      
      - name: Analyze Results
        run: |
          python scripts/automation/analyze-performance.py results/
      
      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: performance-results
          path: results/
```

---

**Maintained by:** Pierre Ribeiro (DBA/DBRE)  
**Last Updated:** 2025-11-13  
**Version:** 1.0
