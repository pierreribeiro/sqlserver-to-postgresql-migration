# PostgreSQL Programming Constitution v1.0

## Perseus Database Migration Project - Authoritative Programming Standards

**Document Type:** Constitution (Binding Law)  
**Target Audience:** Claude Code, DBAs, Developers  
**PostgreSQL Version:** 17+  
**Created:** 2026-01-13  
**Authors:** Pierre Ribeiro + Claude (Desktop Command Center)  
**Status:** ACTIVE - MANDATORY COMPLIANCE

---

## Preamble

This Constitution establishes the binding programming standards for all PostgreSQL code produced during the Perseus Database Migration project. These principles ensure code quality, performance, maintainability, and consistency across all database objects: tables, indexes, views, functions, procedures, triggers, sequences, and Foreign Data Wrapper configurations.

**Compliance is mandatory. No exceptions without documented justification and DBA approval.**

---

## Article I: Naming Conventions

### Section 1.1 - Universal Naming Rules

All database objects SHALL:

1. Use **lowercase `snake_case`** exclusively
2. Start with a letter (a-z)
3. Contain only letters, numbers, and underscores
4. Not exceed **63 characters** (PostgreSQL identifier limit)
5. Avoid SQL reserved words and PostgreSQL keywords
6. Never use the `pg_` prefix (reserved for system objects)
7. Never use dollar signs (`$`) or non-ASCII characters

### Section 1.2 - Object-Specific Prefixes and Suffixes

| Object Type | Convention | Example |
|-------------|------------|---------|
| Tables | Plural nouns | `customers`, `order_items` |
| Views | Prefix `v_` | `v_active_customers` |
| Materialized Views | Prefix `mv_` | `mv_monthly_sales` |
| Temporary Tables | Prefix `tmp_` | `tmp_processing_batch` |
| Sequences | Suffix `_seq` | `customer_id_seq` |
| Primary Key Index | Suffix `_pkey` | `customers_pkey` |
| Unique Index | Suffix `_key` | `customers_email_key` |
| Standard Index | Suffix `_idx` | `orders_customer_id_idx` |
| Exclusion Constraint | Suffix `_excl` | `reservations_room_excl` |
| Foreign Key | Suffix `_fkey` | `orders_customer_id_fkey` |
| Check Constraint | Suffix `_check` | `orders_amount_check` |
| Functions | Action verb prefix | `get_customer_by_id()` |
| Procedures | Action verb prefix | `process_order_batch()` |
| Triggers | Prefix `trg_` | `trg_audit_customer_changes` |
| Types | Suffix `_type` | `address_type` |
| Enums | Suffix `_enum` | `order_status_enum` |

### Section 1.3 - Function Naming Patterns

Functions MUST begin with action verbs indicating their operation:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `get_` | Read/SELECT operations | `get_customer_by_id()` |
| `select_` | Query returning resultset | `select_active_orders()` |
| `insert_` | Single insert operation | `insert_customer()` |
| `update_` | Update operation | `update_customer_status()` |
| `delete_` | Delete operation | `delete_inactive_customers()` |
| `upsert_` | Insert or update | `upsert_product()` |
| `process_` | Complex business logic | `process_monthly_billing()` |
| `validate_` | Validation logic | `validate_email_format()` |
| `calculate_` | Computation | `calculate_order_total()` |
| `sync_` | Synchronization | `sync_inventory_levels()` |

### Section 1.4 - Parameter and Variable Naming

1. **Parameters**: Use named notation, never positional
2. **Conflict Resolution**: Append underscore when parameter names conflict with column names
   ```sql
   -- CORRECT: Disambiguates parameter from column
   CREATE FUNCTION get_customer(customer_id_ BIGINT)
   ```
3. **Boolean Columns**: Use `is_` or `has_` prefix (`is_active`, `has_subscription`)
4. **Primary Keys**: Use `id` or `_id` suffix (`customer_id`, `order_id`)
5. **Temporal Columns**: Use `_at` suffix (`created_at`, `updated_at`, `deleted_at`)
6. **Foreign Keys**: Match referenced table singular + `_id` (`customer_id` references `customers`)

---

## Article II: Data Type Standards

### Section 2.1 - Primary Key Strategy

1. **Preferred Type**: `BIGINT` for all primary keys
2. **Generation**: Use `GENERATED ALWAYS AS IDENTITY` (not `SERIAL`)
3. **String PKs**: Maximum 64 bytes if absolutely necessary
4. **UUID**: Acceptable for distributed systems; use `gen_random_uuid()`

```sql
-- CORRECT: Identity column
CREATE TABLE customers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ...
);

-- AVOID: SERIAL (legacy, has sequence gap issues)
-- CREATE TABLE customers (id SERIAL PRIMARY KEY, ...);
```

### Section 2.2 - Numeric Types

| Type | Usage | Notes |
|------|-------|-------|
| `INTEGER` | General numeric fields | 4 bytes, -2B to +2B |
| `BIGINT` | IDs, large counts | 8 bytes, default when uncertain |
| `SMALLINT` | AVOID | Negligible savings, overflow risk |
| `NUMERIC(p,s)` | Financial/precise decimals | Specify precision and scale |
| `MONEY` | Currency values | Use with caution (locale-dependent) |
| `REAL` | Scientific, low-precision | NEVER use equality comparisons |
| `DOUBLE PRECISION` | Scientific, coordinates | NEVER use equality comparisons |

### Section 2.3 - String Types

| Type | Usage | Notes |
|------|-------|-------|
| `TEXT` | Unlimited text | Preferred for flexibility |
| `VARCHAR(n)` | Constrained text | Enforces data quality |
| `CHAR(n)` | AVOID | Pads with spaces, no benefits |

### Section 2.4 - Temporal Types

1. **MANDATORY**: Store all timestamps as `TIMESTAMPTZ` (timestamp with time zone)
2. **MANDATORY**: Store in UTC timezone
3. **Format**: Use ISO-8601 for input/output (`YYYY-MM-DD HH:MI:SS`)
4. **Date-only**: Use `DATE` type
5. **Time-only**: Use `TIME` or `TIMETZ`
6. **Intervals**: Use `INTERVAL` type for durations

```sql
-- CORRECT
created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

-- AVOID: TIMESTAMP without timezone
-- created_at TIMESTAMP NOT NULL
```

### Section 2.5 - Boolean Types

1. Use native `BOOLEAN` type
2. Column names MUST use `is_` or `has_` prefix
3. Default explicitly: `DEFAULT FALSE` or `DEFAULT TRUE`

### Section 2.6 - Enumerated Types

Use `ENUM` for columns with:
- Fixed, small value sets (< 12 values)
- Values that rarely change
- Values requiring validation

```sql
CREATE TYPE order_status_enum AS ENUM (
    'pending', 'confirmed', 'processing', 
    'shipped', 'delivered', 'cancelled'
);
```

### Section 2.7 - JSON Types

| Type | Usage | Notes |
|------|-------|-------|
| `JSONB` | Queryable JSON | Indexable, preferred |
| `JSON` | Preserved formatting | Rare use cases only |

**MANDATORY**: Use `JSONB` for any JSON that will be queried or indexed.

### Section 2.8 - NULL Handling Principles

1. **Semantic Equivalence**: If zero and NULL mean the same thing, enforce `NOT NULL`
2. **Comparison**: Use `IS NULL` for NULL checks, `=` for value checks
3. **Safe Comparison**: Use `IS DISTINCT FROM` for NULL-safe comparisons
4. **Aggregation**: Use `COALESCE()` to handle NULLs in aggregates
5. **Default Values**: Prefer explicit defaults over NULL where semantically appropriate

```sql
-- NULL-safe comparison
WHERE column_a IS DISTINCT FROM column_b

-- Aggregate with NULL handling
SELECT COALESCE(SUM(amount), 0) AS total
```

---

## Article III: SQL Statement Standards

### Section 3.1 - SELECT Statement Rules

**PROHIBITION**: Never use `SELECT *` in production code.

**MANDATORY**:
1. Enumerate all required columns explicitly
2. Qualify column names with table aliases in multi-table queries
3. Use meaningful table aliases (not single letters like `a`, `b`)

```sql
-- CORRECT
SELECT 
    c.id,
    c.name,
    c.email,
    o.order_date,
    o.total_amount
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.is_active = TRUE;

-- PROHIBITED
SELECT * FROM customers c JOIN orders o ON o.customer_id = c.id;
```

### Section 3.2 - Query Optimization Rules

1. **Index Coverage**: All online queries MUST have supporting indexes
   - Exception: Tables < 100 rows or < 100KB
   - Exception: Very low-frequency operations

2. **Avoid Full Table Scans**: Ensure WHERE clauses use indexed columns

3. **Negation Operators**: AVOID `!=` or `<>` as first filter condition
   ```sql
   -- AVOID: Causes full table scan
   WHERE status != 'deleted'
   
   -- PREFER: Use positive condition with index
   WHERE status IN ('active', 'pending', 'completed')
   ```

4. **EXISTS vs IN**: Use `EXISTS` for subqueries
   ```sql
   -- PREFER
   WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id)
   
   -- AVOID for large datasets
   WHERE customer_id IN (SELECT id FROM customers WHERE ...)
   ```

5. **Array Comparison**: Use `= ANY()` instead of `IN` for value lists
   ```sql
   -- PREFER
   WHERE status = ANY(ARRAY['active', 'pending'])
   
   -- ACCEPTABLE for small lists
   WHERE status IN ('active', 'pending')
   ```

6. **Fuzzy Search**: Left-wildcard patterns cannot use B-tree indexes
   ```sql
   -- CANNOT use index
   WHERE name LIKE '%smith'
   
   -- CAN use index (right-wildcard)
   WHERE name LIKE 'smith%'
   
   -- For left-wildcard, create reverse() functional index
   ```

7. **Existence Checks**: Use LIMIT 1, not COUNT(*)
   ```sql
   -- CORRECT
   SELECT EXISTS(SELECT 1 FROM orders WHERE customer_id = 123 LIMIT 1);
   
   -- INEFFICIENT
   SELECT COUNT(*) > 0 FROM orders WHERE customer_id = 123;
   ```

### Section 3.3 - RETURNING Clause Usage

Use `RETURNING` to retrieve data after DML operations:

```sql
INSERT INTO customers (name, email)
VALUES ('John Doe', 'john@example.com')
RETURNING id, created_at;

UPDATE orders 
SET status = 'shipped', shipped_at = CURRENT_TIMESTAMP
WHERE id = 123
RETURNING id, status, shipped_at;
```

### Section 3.4 - UPSERT Pattern

Use `INSERT ... ON CONFLICT` for upsert operations:

```sql
INSERT INTO products (sku, name, price)
VALUES ('ABC123', 'Widget', 29.99)
ON CONFLICT (sku) 
DO UPDATE SET 
    name = EXCLUDED.name,
    price = EXCLUDED.price,
    updated_at = CURRENT_TIMESTAMP
RETURNING id;
```

---

## Article IV: Common Table Expressions (CTEs)

### Section 4.1 - CTE vs Temporary Tables

**PREFER CTEs over temporary tables** for intermediate results:

| Feature | CTEs | Temp Tables |
|---------|------|-------------|
| Memory Usage | Lower (no table creation) | Higher |
| Readability | Better (inline) | Worse (separate) |
| Indexing | Not possible | Possible |
| Reuse in Query | Multiple references | Multiple references |
| Transaction Scope | Query-scoped | Session-scoped |

### Section 4.2 - CTE Best Practices

1. **Naming**: Use descriptive names reflecting the data subset
2. **Materialization**: PostgreSQL 12+ allows `MATERIALIZED` / `NOT MATERIALIZED` hints
3. **Recursive CTEs**: Always include termination conditions and depth limits

```sql
-- Example: Well-structured CTE
WITH active_customers AS (
    SELECT id, name, email
    FROM customers
    WHERE is_active = TRUE
      AND deleted_at IS NULL
),
recent_orders AS (
    SELECT 
        customer_id,
        COUNT(*) AS order_count,
        SUM(total_amount) AS total_spent
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY customer_id
)
SELECT 
    ac.id,
    ac.name,
    COALESCE(ro.order_count, 0) AS order_count,
    COALESCE(ro.total_spent, 0) AS total_spent
FROM active_customers ac
LEFT JOIN recent_orders ro ON ro.customer_id = ac.id
ORDER BY total_spent DESC;
```

### Section 4.3 - Recursive CTE Safety

**MANDATORY** for recursive CTEs:
1. Include termination condition
2. Consider `LIMIT` clause for safety
3. Use cycle detection for graph traversals

```sql
-- Safe recursive CTE with depth limit
WITH RECURSIVE hierarchy AS (
    -- Anchor member
    SELECT id, parent_id, name, 1 AS depth
    FROM categories
    WHERE parent_id IS NULL
    
    UNION ALL
    
    -- Recursive member with depth limit
    SELECT c.id, c.parent_id, c.name, h.depth + 1
    FROM categories c
    JOIN hierarchy h ON h.id = c.parent_id
    WHERE h.depth < 10  -- Safety limit
)
SELECT * FROM hierarchy;
```

---

## Article V: Functions and Procedures

### Section 5.1 - Functions vs Procedures Decision Matrix

| Characteristic | Function | Procedure |
|----------------|----------|-----------|
| Return Value | REQUIRED | Optional (OUT params) |
| Use in SQL | YES | NO (CALL only) |
| Transaction Control | NO | YES (COMMIT/ROLLBACK) |
| Best For | Calculations, queries | Multi-step operations |

### Section 5.2 - Function Volatility Classification

**MANDATORY**: Always specify volatility category:

| Category | Description | Use Case |
|----------|-------------|----------|
| `IMMUTABLE` | Same output for same input, always | Pure calculations, constants |
| `STABLE` | Same output within single query | Lookups, current_user |
| `VOLATILE` | Output may change anytime | Modifying data, random(), clock |

```sql
-- CORRECT: Explicit volatility
CREATE OR REPLACE FUNCTION calculate_tax(amount NUMERIC)
RETURNS NUMERIC
LANGUAGE SQL
IMMUTABLE
PARALLEL SAFE
AS $$
    SELECT amount * 0.08;
$$;
```

### Section 5.3 - Additional Function Attributes

Specify when applicable:

| Attribute | Usage |
|-----------|-------|
| `PARALLEL SAFE` | Can run in parallel query |
| `PARALLEL RESTRICTED` | Cannot run in parallel worker |
| `PARALLEL UNSAFE` | Prevents parallelization |
| `RETURNS NULL ON NULL INPUT` | Skip execution if any arg is NULL |
| `STRICT` | Synonym for RETURNS NULL ON NULL INPUT |
| `SECURITY DEFINER` | Execute as function owner |
| `SECURITY INVOKER` | Execute as calling user (default) |

### Section 5.4 - Function Design Principles

**Functions ARE appropriate for:**
- Encapsulating transactions
- Reducing network round trips
- Small amounts of custom logic
- Data validation
- Calculated columns

**Functions are NOT appropriate for:**
- Complex computations (use application layer)
- Frequent type conversions
- Heavy ETL processing
- Long-running operations

### Section 5.5 - Procedure Design Principles

Use procedures when you need:
- Transaction control (COMMIT/ROLLBACK within procedure)
- Multi-step operations with intermediate commits
- Batch processing with progress checkpoints

```sql
CREATE OR REPLACE PROCEDURE process_large_batch(
    batch_size_ INTEGER DEFAULT 1000
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_processed INTEGER := 0;
    v_row RECORD;
BEGIN
    FOR v_row IN 
        SELECT id FROM pending_items 
        WHERE processed_at IS NULL 
        LIMIT batch_size_
    LOOP
        -- Process item
        UPDATE pending_items 
        SET processed_at = CURRENT_TIMESTAMP 
        WHERE id = v_row.id;
        
        v_processed := v_processed + 1;
        
        -- Commit every 100 rows
        IF v_processed % 100 = 0 THEN
            COMMIT;
            RAISE NOTICE 'Processed % items', v_processed;
        END IF;
    END LOOP;
    
    COMMIT;
    RAISE NOTICE 'Completed: % items processed', v_processed;
END;
$$;
```

### Section 5.6 - Function Overloading

**AVOID function overloading**, especially with integer types:

```sql
-- PROHIBITED: Ambiguous overloading
CREATE FUNCTION get_item(id INTEGER) ...
CREATE FUNCTION get_item(id BIGINT) ...  -- Ambiguous!

-- CORRECT: Different names
CREATE FUNCTION get_item_by_id(id_ BIGINT) ...
CREATE FUNCTION get_item_by_sku(sku_ VARCHAR(50)) ...
```

---

## Article VI: Views and Materialized Views

### Section 6.1 - View Types and Use Cases

| Type | Characteristics | Use Cases |
|------|-----------------|-----------|
| Simple View | Single table, no aggregation | Column hiding, row filtering, security |
| Complex View | Joins, aggregations | Reporting, dashboards |
| Materialized View | Physically stored | Expensive aggregations, caching |
| Updatable View | Supports DML | Simplified interface to complex structure |

### Section 6.2 - View Design Guidelines

1. **Naming**: Prefix with `v_` for views, `mv_` for materialized views
2. **Documentation**: Add `COMMENT ON VIEW` explaining purpose
3. **Performance**: Ensure supporting indexes exist on base tables
4. **Security**: Use views to implement row-level security

### Section 6.3 - Materialized View Patterns

```sql
-- Create materialized view with appropriate indexes
CREATE MATERIALIZED VIEW mv_monthly_sales AS
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    product_category,
    SUM(quantity) AS total_quantity,
    SUM(amount) AS total_revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
GROUP BY 1, 2
WITH DATA;

-- Create index for common query patterns
CREATE INDEX mv_monthly_sales_month_idx 
ON mv_monthly_sales (month);

-- Refresh strategy
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_sales;
```

### Section 6.4 - Updatable Views

Use `WITH CHECK OPTION` for data integrity:

```sql
CREATE VIEW v_active_customers AS
SELECT id, name, email, phone, is_active
FROM customers
WHERE is_active = TRUE
  AND deleted_at IS NULL
WITH CHECK OPTION;

-- Prevents inserting/updating rows that don't match WHERE clause
```

---

## Article VII: Indexing Strategy

### Section 7.1 - Index Type Selection Matrix

| Index Type | Operators | Best For |
|------------|-----------|----------|
| B-tree (default) | `=`, `<`, `>`, `<=`, `>=`, `BETWEEN`, `IN`, `IS NULL` | Most queries |
| Hash | `=` only | Exact match lookups |
| GIN | `@>`, `<@`, `?`, `?|`, `?&`, `&&` | JSONB, arrays, full-text |
| GiST | Geometric, range, full-text | Spatial, proximity, exclusion |
| BRIN | `<`, `<=`, `=`, `>=`, `>` | Large sequential/time-series data |
| SP-GiST | Various | Hierarchical, clustered data |

### Section 7.2 - Indexing Best Practices

1. **Create indexes for all query WHERE clauses** used in online queries
2. **Composite indexes**: Order columns by selectivity (most selective first)
3. **Partial indexes**: Use for selective conditions
   ```sql
   CREATE INDEX orders_pending_idx ON orders (created_at)
   WHERE status = 'pending';
   ```
4. **Expression indexes**: Index computed values
   ```sql
   CREATE INDEX customers_lower_email_idx ON customers (LOWER(email));
   ```
5. **Covering indexes**: Include columns to enable index-only scans
   ```sql
   CREATE INDEX orders_covering_idx ON orders (customer_id) 
   INCLUDE (order_date, status);
   ```

### Section 7.3 - Index Anti-Patterns

**AVOID:**
1. Indexes on low-cardinality columns (boolean, status with few values)
2. Too many indexes on frequently-updated tables
3. Redundant indexes (subset of existing composite index)
4. Indexes without monitoring usage

### Section 7.4 - Index Maintenance

1. Monitor index usage with `pg_stat_user_indexes`
2. Identify and drop unused indexes
3. Rebuild bloated indexes with `REINDEX CONCURRENTLY`
4. Run `ANALYZE` after bulk operations

---

## Article VIII: Error Handling

### Section 8.1 - Exception Handling Structure

```sql
CREATE OR REPLACE FUNCTION safe_operation(param_ INTEGER)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_result BOOLEAN := FALSE;
BEGIN
    -- Main logic
    PERFORM some_operation(param_);
    v_result := TRUE;
    
    RETURN v_result;
    
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Duplicate entry for param %', param_;
        RETURN FALSE;
    WHEN foreign_key_violation THEN
        RAISE WARNING 'Referenced record not found for param %', param_;
        RETURN FALSE;
    WHEN OTHERS THEN
        RAISE WARNING 'Unexpected error: % - %', SQLSTATE, SQLERRM;
        RETURN FALSE;
END;
$$;
```

### Section 8.2 - Exception Handling Rules

1. **PREFER specific exceptions** over `WHEN OTHERS`
2. **Log errors** with appropriate severity (NOTICE, WARNING, EXCEPTION)
3. **Include context** in error messages (parameter values, state)
4. **Minimize exception blocks**: They create savepoints (performance cost)
5. **Never swallow errors silently**: Always log or re-raise

### Section 8.3 - RAISE Statement Levels

| Level | Purpose | Behavior |
|-------|---------|----------|
| `DEBUG` | Detailed debugging | Configurable visibility |
| `LOG` | Server-side logging | Configurable visibility |
| `INFO` | Informational | Always visible |
| `NOTICE` | Notable events | Always visible |
| `WARNING` | Potential issues | Always visible |
| `EXCEPTION` | Errors | Aborts transaction |

### Section 8.4 - Performance Consideration

**WARNING**: Exception blocks create implicit savepoints.

```sql
-- INEFFICIENT: Exception block in loop creates many savepoints
FOR i IN 1..1000 LOOP
    BEGIN
        INSERT INTO t VALUES (i);
    EXCEPTION WHEN unique_violation THEN
        NULL;  -- Each iteration creates savepoint!
    END;
END LOOP;

-- BETTER: Handle outside loop or use ON CONFLICT
INSERT INTO t 
SELECT generate_series(1, 1000)
ON CONFLICT DO NOTHING;
```

---

## Article IX: Foreign Data Wrappers (FDW)

### Section 9.1 - FDW Setup Pattern

```sql
-- 1. Enable extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- 2. Create foreign server
CREATE SERVER remote_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'remote-host.example.com',
    port '5432',
    dbname 'remote_database',
    fetch_size '10000',           -- Tune based on network latency
    use_remote_estimate 'true'    -- Use remote statistics
);

-- 3. Create user mapping
CREATE USER MAPPING FOR local_user
SERVER remote_server
OPTIONS (
    user 'remote_user',
    password 'secure_password'    -- Consider using .pgpass
);

-- 4. Import schema (preferred over manual creation)
IMPORT FOREIGN SCHEMA remote_schema
FROM SERVER remote_server
INTO local_schema;
```

### Section 9.2 - FDW Performance Optimization

| Parameter | Default | Recommendation | Purpose |
|-----------|---------|----------------|---------|
| `fetch_size` | 100 | 1000-10000 | Rows per network round trip |
| `use_remote_estimate` | false | true | Use remote server statistics |
| `extensions` | empty | list needed | Push down extension functions |

### Section 9.3 - FDW Query Optimization

1. **Push down WHERE clauses**: Ensure conditions use IMMUTABLE operators
2. **Use CTEs for filtering**: Pre-filter before joining with local tables
3. **Run ANALYZE on foreign tables**: Maintain local statistics
4. **Materialize for heavy use**: Cache frequently-accessed remote data

```sql
-- OPTIMIZED: Filter remote data in CTE before local join
WITH remote_filtered AS (
    SELECT id, data
    FROM remote_table
    WHERE created_at > CURRENT_DATE - INTERVAL '7 days'
)
SELECT l.*, r.data
FROM local_table l
JOIN remote_filtered r ON r.id = l.remote_id;
```

### Section 9.4 - FDW Caching Strategy

```sql
-- Materialized view for caching remote data
CREATE MATERIALIZED VIEW mv_remote_cache AS
SELECT * FROM remote_table
WHERE created_at > CURRENT_DATE - INTERVAL '30 days'
WITH DATA;

-- Create indexes on cached data
CREATE INDEX mv_remote_cache_id_idx ON mv_remote_cache (id);

-- Refresh strategy (schedule appropriately)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_remote_cache;
```

---

## Article X: Transaction Management

### Section 10.1 - Transaction Principles

1. **Keep transactions short**: Commit or rollback as soon as possible
2. **Avoid long-running transactions**: IDLE IN transactions > 10 min may be terminated
3. **Enable AutoCommit**: Prevent orphaned transactions
4. **Use connection pooling**: Access through pgbouncer (port 6432)

### Section 10.2 - Timeout Configuration

```sql
-- Set statement timeout (10ms for online, longer for batch)
SET statement_timeout = '10ms';        -- Online queries
SET statement_timeout = '5min';        -- Batch operations

-- Set lock timeout to avoid indefinite waits
SET lock_timeout = '3s';
```

### Section 10.3 - Advisory Locks for Hotspots

```sql
-- For high-concurrency access to same rows
SELECT pg_advisory_lock(hashtext('order_processing:' || order_id::text));
-- ... perform operations ...
SELECT pg_advisory_unlock(hashtext('order_processing:' || order_id::text));

-- Or use transaction-scoped locks (auto-release on commit/rollback)
SELECT pg_advisory_xact_lock(hashtext('order_processing:' || order_id::text));
```

---

## Article XI: Performance Optimization

### Section 11.1 - Query Analysis

**MANDATORY** for new code:
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT ... ;
```

Key metrics to verify:
- No unexpected sequential scans on large tables
- Index scans where expected
- Reasonable row estimates vs actual rows
- Acceptable buffer usage

### Section 11.2 - Bulk Load Optimization

```sql
-- For large data loads:
-- 1. Disable autovacuum temporarily
ALTER TABLE target_table SET (autovacuum_enabled = false);

-- 2. Increase work_mem for session
SET work_mem = '256MB';
SET maintenance_work_mem = '512MB';

-- 3. Use COPY instead of INSERT
COPY target_table FROM '/path/to/data.csv' WITH (FORMAT csv, HEADER);

-- 4. Create indexes after loading
CREATE INDEX ...;

-- 5. Analyze and re-enable autovacuum
ANALYZE target_table;
ALTER TABLE target_table SET (autovacuum_enabled = true);
```

### Section 11.3 - Partitioning Guidelines

Consider partitioning when:
- Single table exceeds 100 million rows
- Single table exceeds 10GB
- Time-series data with frequent range queries
- Need to efficiently archive old data

---

## Article XII: Code Organization and Documentation

### Section 12.1 - Object Comments

**MANDATORY**: All database objects must have comments:

```sql
COMMENT ON TABLE customers IS 'Customer master data with contact and billing information';
COMMENT ON COLUMN customers.is_active IS 'FALSE when customer churned or requested deletion';
COMMENT ON FUNCTION get_customer_by_id IS 'Retrieves customer by primary key, returns NULL if not found';
```

### Section 12.2 - Code Formatting Standards

1. **Keywords**: UPPERCASE (`SELECT`, `FROM`, `WHERE`, `JOIN`)
2. **Identifiers**: lowercase (`customers`, `order_date`)
3. **Indentation**: 4 spaces (no tabs)
4. **Line length**: Maximum 120 characters
5. **Column lists**: One column per line for readability
6. **Commas**: Leading comma style for easy line manipulation

```sql
SELECT 
    c.id
    , c.name
    , c.email
    , o.order_date
    , o.total_amount
FROM customers c
JOIN orders o 
    ON o.customer_id = c.id
WHERE c.is_active = TRUE
    AND o.order_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY o.order_date DESC;
```

### Section 12.3 - Change Management

1. **No DDL in application code**: Schema changes through migration scripts only
2. **CONCURRENTLY for production**: Use `CREATE INDEX CONCURRENTLY`, `REINDEX CONCURRENTLY`
3. **Rollback scripts**: Every schema change must have corresponding rollback
4. **Version control**: All database code in Git repository

---

## Article XIII: Security Standards

### Section 13.1 - Principle of Least Privilege

1. Application users get minimum required permissions
2. Use roles for permission grouping
3. Never use superuser in applications
4. Grant permissions on schemas, not databases

### Section 13.2 - SQL Injection Prevention

1. **ALWAYS use parameterized queries**
2. **NEVER concatenate user input into SQL strings**
3. Use `quote_ident()` for dynamic identifiers
4. Use `quote_literal()` for dynamic literals

```sql
-- SAFE: Parameterized
EXECUTE format('SELECT * FROM %I WHERE id = $1', table_name) USING user_id;

-- DANGEROUS: String concatenation
EXECUTE 'SELECT * FROM ' || table_name || ' WHERE id = ' || user_id;  -- PROHIBITED!
```

---

## Article XIV: Migration-Specific Standards (SQL Server → PostgreSQL)

### Section 14.1 - Temporary Table Patterns

SQL Server temporary tables must be converted to PostgreSQL patterns:

```sql
-- SQL Server: CREATE TABLE #temp ...
-- PostgreSQL: CREATE TEMPORARY TABLE tmp_ ...

CREATE TEMPORARY TABLE tmp_processing (
    id BIGINT,
    data TEXT
) ON COMMIT DROP;  -- or ON COMMIT DELETE ROWS
```

### Section 14.2 - Transaction Control Replacement

```sql
-- SQL Server: BEGIN TRANSACTION / COMMIT / ROLLBACK
-- PostgreSQL: BEGIN / COMMIT / ROLLBACK (or use procedures)

-- In procedures, you can use:
BEGIN;
    -- statements
COMMIT;  -- or ROLLBACK;
```

### Section 14.3 - IDENTITY Column Conversion

```sql
-- SQL Server: IDENTITY(1,1)
-- PostgreSQL: GENERATED ALWAYS AS IDENTITY

CREATE TABLE products (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ...
);
```

### Section 14.4 - String Function Mapping

| SQL Server | PostgreSQL |
|------------|------------|
| `ISNULL(a, b)` | `COALESCE(a, b)` |
| `LEN(s)` | `LENGTH(s)` |
| `GETDATE()` | `CURRENT_TIMESTAMP` |
| `DATEADD(...)` | `+ INTERVAL '...'` |
| `DATEDIFF(...)` | Arithmetic or `AGE()` |
| `CONVERT(type, val)` | `val::type` or `CAST()` |
| `TOP n` | `LIMIT n` |

### Section 14.5 - Linked Server to FDW Conversion

Replace SQL Server linked server (OPENQUERY) with postgres_fdw:

```sql
-- SQL Server:
-- SELECT * FROM OPENQUERY(LinkedServer, 'SELECT * FROM remote_table')

-- PostgreSQL:
SELECT * FROM fdw_schema.remote_table;
-- (after proper FDW setup as per Article IX)
```

---

## Article XV: Compliance and Enforcement

### Section 15.1 - Code Review Requirements

All database code changes require:
1. Self-review against this Constitution
2. Technical Lead review
3. DBA review for production deployment
4. EXPLAIN ANALYZE results for new queries

### Section 15.2 - Quality Score Dimensions

Code quality assessed across:
1. **Syntax Correctness** (0-10): Valid PostgreSQL syntax
2. **Logic Preservation** (0-10): Business logic integrity
3. **Performance** (0-10): Query efficiency, index usage
4. **Maintainability** (0-10): Readability, documentation
5. **Security** (0-10): Input validation, permissions

**Minimum passing score: 7.0/10 overall, no dimension below 6.0**

### Section 15.3 - Violation Handling

| Severity | Action Required |
|----------|-----------------|
| P0 - Critical | Block deployment, immediate fix |
| P1 - High | Fix before production |
| P2 - Medium | Fix in next sprint |
| P3 - Low | Track for future improvement |

---

## Appendix A: Quick Reference Card

```
NAMING:
- Tables: plural snake_case (customers)
- Views: v_name (v_active_customers)
- Mat Views: mv_name (mv_monthly_sales)
- Functions: verb_noun (get_customer_by_id)
- Indexes: table_column_suffix (_pkey, _key, _idx)

DATA TYPES:
- PKs: BIGINT GENERATED ALWAYS AS IDENTITY
- Strings: TEXT or VARCHAR(n)
- Timestamps: TIMESTAMPTZ (always UTC)
- JSON: JSONB (not JSON)

QUERIES:
- NO SELECT * in production
- EXISTS over IN for subqueries
- LIMIT 1 for existence checks
- CTEs over temp tables

FUNCTIONS:
- Always specify volatility (IMMUTABLE/STABLE/VOLATILE)
- No overloading with similar types
- Use RETURNING after DML
- Use ON CONFLICT for upserts

ERROR HANDLING:
- Specific exceptions over WHEN OTHERS
- Include context in error messages
- Minimize exception blocks (performance)

FDW:
- fetch_size: 1000-10000
- use_remote_estimate: true
- ANALYZE foreign tables regularly
- Use CTEs to pre-filter remote data
```

---

## Article XVI: Brownfield Migration Compatibility

### Section 16.1 - Context and Scope

The Perseus Database Migration is a **brownfield project** migrating from SQL Server to PostgreSQL. This article addresses naming convention transitions for existing objects.

**Key Findings from Application Team Analysis (2026-01):**

| Aspect | Finding | Implication |
|--------|---------|-------------|
| Procedure calls in application | None identified | Safe to rename |
| Database jobs | 6 jobs with SP references | Will be refactored |
| Migration scripts | Occasional SP calls | Communicate changes |
| Table/column naming | Already snake_case | No conversion needed |
| Case sensitivity | Not present in application | Safe to lowercase |
| ORM behavior | Handles column mapping | No ordinal position issues |

### Section 16.2 - Naming Convention Transition Strategy

**APPROVED APPROACH**: Convert all PascalCase names to snake_case.

The dual-layer compatibility approach is **NOT REQUIRED** because:
1. No stored procedure calls exist in the application codebase
2. Table and column names are already snake_case compliant
3. The application layer has no case-sensitive dependencies
4. Job references will be refactored as part of migration

### Section 16.3 - PascalCase to snake_case Conversion Rules

When converting SQL Server object names:

```
SQL Server (PascalCase)     →  PostgreSQL (snake_case)
─────────────────────────────────────────────────────
GetMaterialByRunProperties  →  get_material_by_run_properties
ReconcileMUpstream          →  reconcile_mupstream
sp_MoveNode                 →  move_node (drop sp_ prefix)
fn_CalculateTotal           →  calculate_total (drop fn_ prefix)
tbl_Customers               →  customers (drop tbl_ prefix)
vw_ActiveOrders             →  v_active_orders (standardize prefix)
```

**Conversion Algorithm:**
1. Remove Hungarian notation prefixes (`sp_`, `fn_`, `tbl_`, `vw_`)
2. Insert underscore before each uppercase letter
3. Convert entire string to lowercase
4. Apply standard PostgreSQL prefixes where applicable (`v_`, `mv_`, `tmp_`)

### Section 16.4 - Coordination Requirements

**MANDATORY** before deploying renamed objects:

| Stakeholder | Action Required | Timing |
|-------------|-----------------|--------|
| DBA Team | Document all name changes | Before deployment |
| Dev Team | Update 6 database jobs | Coordinated deployment |
| Migration Scripts | Update any SP references | Before next migration run |
| Documentation | Update schema documentation | Post-deployment |

**Communication Template:**
```
Subject: [Perseus] Stored Procedure Rename - [original_name]

Old Name: GetMaterialByRunProperties
New Name: get_material_by_run_properties
Schema: pgsql
Deployment Date: YYYY-MM-DD
Impact: Database jobs requiring update: [list]

Action Required: Update job references before/during deployment window.
```

### Section 16.5 - Objects Exempt from Renaming

The following objects MAY retain original names if renaming creates unacceptable risk:

1. **External system interfaces** - Objects called by systems outside Perseus control
2. **Third-party integrations** - APIs or connectors with hardcoded references
3. **Audit/compliance requirements** - Where name traceability is legally required

**Exemption requires**: Written approval from Project Lead and DBA with documented justification.

### Section 16.6 - Tracking and Documentation

**MANDATORY** for all renamed objects:

1. **Maintain mapping table** in project documentation:
   ```
   | SQL Server Name | PostgreSQL Name | Renamed Date | Notes |
   |-----------------|-----------------|--------------|-------|
   | GetMaterialByRunProperties | get_material_by_run_properties | 2026-01-15 | Sprint 9 |
   ```

2. **Git commit message format**:
   ```
   feat(procedure): convert GetMaterialByRunProperties to snake_case
   
   - Renamed: GetMaterialByRunProperties → get_material_by_run_properties
   - Follows PostgreSQL Programming Constitution Article XVI
   - Job impact: job_material_sync (to be updated by Dev team)
   ```

3. **Update AWS SCT analysis documents** with new names

### Section 16.7 - Validation Checklist

Before deploying any renamed object:

- [ ] New name follows snake_case convention (Article I)
- [ ] No SQL reserved words in new name
- [ ] Dev team notified of change
- [ ] Job references identified and update scheduled
- [ ] Migration scripts checked for references
- [ ] Documentation updated with name mapping
- [ ] Rollback script prepared (CREATE OR REPLACE with old name if needed)

---

## Article XVII: Migration-Specific Quality Gates

### Section 17.1 - Pre-Conversion Checklist

Before converting any SQL Server object:

- [ ] Original T-SQL source code obtained
- [ ] AWS SCT conversion output reviewed
- [ ] Dependencies identified (callers and callees)
- [ ] Test data/scenarios documented
- [ ] Expected behavior baseline established

### Section 17.2 - Conversion Quality Scoring

All converted objects are scored on 5 dimensions:

| Dimension | Weight | Criteria |
|-----------|--------|----------|
| Syntax Correctness | 20% | Valid PostgreSQL 17 syntax, no errors |
| Logic Preservation | 30% | Business logic identical to original |
| Performance | 20% | Within 20% of SQL Server baseline |
| Maintainability | 15% | Readable, documented, follows Constitution |
| Security | 15% | No injection risks, proper permissions |

**Scoring Scale:**
- 10: Exceptional - Exceeds requirements
- 8-9: Good - Meets all requirements
- 6-7: Acceptable - Minor issues, can deploy
- 4-5: Needs Work - Significant issues, fix before deploy
- 0-3: Critical - Major problems, block deployment

**Passing Threshold:**
- Overall score: ≥ 7.0
- No individual dimension: < 6.0

### Section 17.3 - Issue Classification

| Priority | Description | Action | SLA |
|----------|-------------|--------|-----|
| P0 - Critical | Blocks execution, data corruption risk | Immediate fix | Before any testing |
| P1 - High | Logic errors, performance degradation >50% | Fix before deployment | Within sprint |
| P2 - Medium | Non-critical improvements, minor performance | Fix in next sprint | Next sprint |
| P3 - Low | Style/convention suggestions | Track for future | Backlog |

### Section 17.4 - Common SQL Server → PostgreSQL Issues

**P0 Issues (Always check):**
| Issue | SQL Server | PostgreSQL Fix |
|-------|------------|----------------|
| Temp table initialization | `SELECT INTO #temp` | `CREATE TEMP TABLE` + `INSERT` |
| Transaction control | `BEGIN TRAN` | `BEGIN` (or use procedures) |
| Identity insert | `SET IDENTITY_INSERT ON` | `OVERRIDING SYSTEM VALUE` |
| String concatenation | `+` operator | `||` operator or `CONCAT()` |
| Null comparison | `= NULL` | `IS NULL` |
| Top N rows | `SELECT TOP n` | `LIMIT n` |
| Conditional logic | `IIF(cond, t, f)` | `CASE WHEN cond THEN t ELSE f END` |

**P1 Issues (Performance):**
| Issue | SQL Server | PostgreSQL Fix |
|-------|------------|----------------|
| NOLOCK hint | `WITH (NOLOCK)` | Remove (use appropriate isolation) |
| Index hints | `WITH (INDEX=...)` | Remove (trust planner) or use `pg_hint_plan` |
| Excessive LOWER() | AWS SCT adds unnecessarily | Remove if column already lowercase |
| Missing COALESCE | NULL handling | Add explicit NULL handling |

### Section 17.5 - Post-Conversion Validation

**MANDATORY** after conversion:

1. **Syntax validation**: Execute in PostgreSQL without errors
2. **Logic validation**: Compare output with SQL Server for same inputs
3. **Performance validation**: EXPLAIN ANALYZE, compare with baseline
4. **Edge case validation**: NULL handling, empty sets, boundary conditions

---

## Appendix B: SQL Server to PostgreSQL Quick Reference

### B.1 - Data Type Mapping

| SQL Server | PostgreSQL | Notes |
|------------|------------|-------|
| `INT` | `INTEGER` | |
| `BIGINT` | `BIGINT` | |
| `SMALLINT` | `SMALLINT` | |
| `TINYINT` | `SMALLINT` | No TINYINT in PG |
| `BIT` | `BOOLEAN` | |
| `DECIMAL(p,s)` | `NUMERIC(p,s)` | |
| `MONEY` | `NUMERIC(19,4)` or `MONEY` | |
| `FLOAT` | `DOUBLE PRECISION` | |
| `REAL` | `REAL` | |
| `DATETIME` | `TIMESTAMP` | |
| `DATETIME2` | `TIMESTAMP` | |
| `DATETIMEOFFSET` | `TIMESTAMPTZ` | |
| `DATE` | `DATE` | |
| `TIME` | `TIME` | |
| `CHAR(n)` | `CHAR(n)` | Avoid, use VARCHAR |
| `VARCHAR(n)` | `VARCHAR(n)` | |
| `VARCHAR(MAX)` | `TEXT` | |
| `NVARCHAR(n)` | `VARCHAR(n)` | PG is UTF-8 native |
| `NVARCHAR(MAX)` | `TEXT` | |
| `TEXT` | `TEXT` | |
| `BINARY(n)` | `BYTEA` | |
| `VARBINARY(n)` | `BYTEA` | |
| `IMAGE` | `BYTEA` | |
| `UNIQUEIDENTIFIER` | `UUID` | |
| `XML` | `XML` | |
| `SQL_VARIANT` | `JSONB` or specific type | Case-by-case |

### B.2 - Function Mapping

| SQL Server | PostgreSQL | Notes |
|------------|------------|-------|
| `GETDATE()` | `CURRENT_TIMESTAMP` | |
| `GETUTCDATE()` | `CURRENT_TIMESTAMP AT TIME ZONE 'UTC'` | |
| `SYSDATETIME()` | `CLOCK_TIMESTAMP()` | |
| `DATEADD(unit, n, date)` | `date + INTERVAL 'n unit'` | |
| `DATEDIFF(unit, start, end)` | `EXTRACT(unit FROM end - start)` or `AGE()` | |
| `DATEPART(unit, date)` | `EXTRACT(unit FROM date)` | |
| `DATENAME(unit, date)` | `TO_CHAR(date, format)` | |
| `CONVERT(type, val)` | `val::type` or `CAST(val AS type)` | |
| `CAST(val AS type)` | `CAST(val AS type)` | |
| `ISNULL(a, b)` | `COALESCE(a, b)` | |
| `NULLIF(a, b)` | `NULLIF(a, b)` | Same |
| `COALESCE(...)` | `COALESCE(...)` | Same |
| `IIF(cond, t, f)` | `CASE WHEN cond THEN t ELSE f END` | |
| `CHOOSE(idx, v1, v2, ...)` | `CASE idx WHEN 1 THEN v1 ... END` | |
| `LEN(s)` | `LENGTH(s)` | |
| `DATALENGTH(s)` | `OCTET_LENGTH(s)` | |
| `CHARINDEX(sub, str)` | `POSITION(sub IN str)` | |
| `PATINDEX(pat, str)` | `REGEXP_INSTR(str, pat)` (PG 15+) | |
| `SUBSTRING(s, start, len)` | `SUBSTRING(s FROM start FOR len)` | |
| `LEFT(s, n)` | `LEFT(s, n)` | Same |
| `RIGHT(s, n)` | `RIGHT(s, n)` | Same |
| `LTRIM(s)` | `LTRIM(s)` | Same |
| `RTRIM(s)` | `RTRIM(s)` | Same |
| `TRIM(s)` | `TRIM(s)` | Same |
| `UPPER(s)` | `UPPER(s)` | Same |
| `LOWER(s)` | `LOWER(s)` | Same |
| `REPLACE(s, old, new)` | `REPLACE(s, old, new)` | Same |
| `STUFF(s, start, len, new)` | `OVERLAY(s PLACING new FROM start FOR len)` | |
| `REPLICATE(s, n)` | `REPEAT(s, n)` | |
| `SPACE(n)` | `REPEAT(' ', n)` | |
| `REVERSE(s)` | `REVERSE(s)` | Same |
| `STRING_AGG(col, sep)` | `STRING_AGG(col, sep)` | Same (PG 9.0+) |
| `ABS(n)` | `ABS(n)` | Same |
| `CEILING(n)` | `CEILING(n)` | Same |
| `FLOOR(n)` | `FLOOR(n)` | Same |
| `ROUND(n, d)` | `ROUND(n, d)` | Same |
| `POWER(base, exp)` | `POWER(base, exp)` | Same |
| `SQRT(n)` | `SQRT(n)` | Same |
| `SIGN(n)` | `SIGN(n)` | Same |
| `RAND()` | `RANDOM()` | |
| `NEWID()` | `gen_random_uuid()` | |
| `ROW_NUMBER()` | `ROW_NUMBER()` | Same |
| `RANK()` | `RANK()` | Same |
| `DENSE_RANK()` | `DENSE_RANK()` | Same |
| `NTILE(n)` | `NTILE(n)` | Same |
| `LAG(col, n)` | `LAG(col, n)` | Same |
| `LEAD(col, n)` | `LEAD(col, n)` | Same |
| `FIRST_VALUE(col)` | `FIRST_VALUE(col)` | Same |
| `LAST_VALUE(col)` | `LAST_VALUE(col)` | Same |

### B.3 - Syntax Mapping

| SQL Server | PostgreSQL |
|------------|------------|
| `SELECT TOP n ...` | `SELECT ... LIMIT n` |
| `SELECT TOP n PERCENT ...` | Use window functions or subquery |
| `SELECT ... INTO #temp` | `CREATE TEMP TABLE ... AS SELECT ...` |
| `INSERT INTO ... SELECT ...` | Same |
| `UPDATE ... FROM ...` | Same (PostgreSQL extension) |
| `DELETE ... FROM ... JOIN ...` | `DELETE FROM ... USING ...` |
| `MERGE INTO ...` | `INSERT ... ON CONFLICT ...` or `MERGE` (PG 15+) |
| `BEGIN TRANSACTION` | `BEGIN` |
| `COMMIT TRANSACTION` | `COMMIT` |
| `ROLLBACK TRANSACTION` | `ROLLBACK` |
| `SAVE TRANSACTION name` | `SAVEPOINT name` |
| `ROLLBACK TO name` | `ROLLBACK TO SAVEPOINT name` |
| `@@ROWCOUNT` | Use `GET DIAGNOSTICS` or `FOUND` |
| `@@IDENTITY` | `LASTVAL()` or `RETURNING` |
| `SCOPE_IDENTITY()` | `CURRVAL(seq)` or `RETURNING` |
| `@@ERROR` | Use exception handling |
| `RAISERROR(...)` | `RAISE EXCEPTION ...` |
| `PRINT ...` | `RAISE NOTICE ...` |
| `SET NOCOUNT ON` | Not needed (no count messages by default) |
| `IF ... BEGIN ... END` | `IF ... THEN ... END IF` |
| `WHILE ... BEGIN ... END` | `WHILE ... LOOP ... END LOOP` |
| `BREAK` | `EXIT` |
| `CONTINUE` | `CONTINUE` |
| `RETURN` | `RETURN` |
| `TRY ... CATCH` | `BEGIN ... EXCEPTION ... END` |
| `EXEC sp_name` | `CALL proc_name()` or `SELECT func_name()` |

### B.4 - Linked Server to FDW Migration

| SQL Server | PostgreSQL |
|------------|------------|
| `sp_addlinkedserver` | `CREATE SERVER ... FOREIGN DATA WRAPPER postgres_fdw` |
| `sp_addlinkedsrvlogin` | `CREATE USER MAPPING FOR ...` |
| `OPENQUERY(server, 'query')` | Query foreign table directly |
| `server.database.schema.table` | `foreign_schema.table` |

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-13 | Pierre Ribeiro + Claude | Initial release |
| 1.1 | 2026-01-14 | Pierre Ribeiro + Claude | Added Article XVI (Brownfield Compatibility), Article XVII (Quality Gates), Appendix B (SQL Server mapping) based on dev team feedback |

**This Constitution is effective immediately and applies to all code produced for the Perseus Database Migration project.**

---

*End of Constitution*
