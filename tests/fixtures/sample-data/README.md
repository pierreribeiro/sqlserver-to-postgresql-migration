# Test Fixtures - Sample Data

**Purpose:** Provide realistic test data for validating database object migrations.

## Directory Structure

```
tests/fixtures/sample-data/
├── README.md                    # This file
├── 01-core-tables.sql          # Core tables (goo, material, container)
├── 02-relationship-tables.sql  # m_upstream, m_downstream
├── 03-transition-tables.sql    # material_transition, transition_material
├── 04-metadata-tables.sql      # Supporting metadata
└── load-all-fixtures.sh        # Load all fixtures in order
```

## Fixture Sets

### 1. Core Tables (01-core-tables.sql)
- `perseus.goo` - 100 sample materials
- `perseus.material` - 50 materials with properties
- `perseus.container` - 20 containers

### 2. Relationship Tables (02-relationship-tables.sql)
- `perseus.m_upstream` - 50 upstream relationships
- `perseus.m_downstream` - 50 downstream relationships

### 3. Transition Tables (03-transition-tables.sql)
- `perseus.material_transition` - 30 transitions
- `perseus.transition_material` - 30 transition materials

### 4. Metadata Tables (04-metadata-tables.sql)
- Supporting lookup tables
- Configuration data

## Usage

### Load All Fixtures
```bash
cd tests/fixtures/sample-data
./load-all-fixtures.sh dev
```

### Load Individual Fixture
```bash
psql -d perseus_dev -f tests/fixtures/sample-data/01-core-tables.sql
```

### Verify Fixture Load
```sql
SELECT
    schemaname,
    tablename,
    n_live_tup as row_count
FROM pg_stat_user_tables
WHERE schemaname IN ('perseus', 'perseus_test', 'fixtures')
ORDER BY schemaname, tablename;
```

## Fixture Design Principles

1. **Realistic Data**: Based on actual production patterns
2. **Edge Cases**: Include NULL, empty, boundary values
3. **Referential Integrity**: All FKs satisfied
4. **Minimal Size**: Enough for testing, not overwhelming
5. **Idempotent**: Can be reloaded without errors
6. **Documented**: Comments explain data relationships

## Test Data Characteristics

### Goo Table Sample (100 rows)
- IDs: 1-100
- Types: DNA (40), Protein (30), RNA (20), Other (10)
- NULL values: ~10% for optional fields
- Parent relationships: 30 materials have parents

### Material Table Sample (50 rows)
- Properties: run_id, batch_id, quality_score
- Edge cases: Empty strings, max varchar, special characters
- NULL scenarios: Optional fields intentionally NULL

### Relationship Tables (50 each)
- Upstream/downstream chains up to 5 levels deep
- Circular references: None (validates acyclic constraints)
- Orphaned references: None (validates FK integrity)

## Fixture Management

### Cleanup Test Data
```sql
-- Clean all test schemas
CALL perseus_test.cleanup_test_data('perseus_test');
CALL perseus_test.cleanup_test_data('fixtures');
```

### Refresh Fixtures
```bash
# Drop and reload
psql -d perseus_dev -c "TRUNCATE TABLE fixtures.sample_materials CASCADE;"
./load-all-fixtures.sh dev
```

## Fixture Quality Standards

**Minimum Requirements:**
- ✅ All fixtures load without errors
- ✅ All foreign keys valid
- ✅ Row counts match expected
- ✅ Data types correct
- ✅ Constraints satisfied (PK, UK, CK)

**Quality Checks:**
```sql
-- Check constraint violations
SELECT * FROM perseus_test.test_execution_log
WHERE status = 'ERROR'
  AND error_message LIKE '%constraint%';

-- Verify row counts
SELECT COUNT(*) FROM fixtures.sample_materials; -- Expected: 3
```

## Integration with Tests

**Unit Tests:**
- Use `fixtures.load_fixture_data('fixture_name')`
- Cleanup with `perseus_test.cleanup_test_data()`

**Integration Tests:**
- Load full fixture suite with `load-all-fixtures.sh`
- Verify data integrity with validation queries

**Performance Tests:**
- Use large fixture sets (1000+ rows)
- Benchmark with `performance.run_performance_test()`

## Contributing New Fixtures

1. Create SQL file: `NN-description.sql`
2. Follow naming convention: `fixtures.fixture_name`
3. Add to `load-all-fixtures.sh` in dependency order
4. Update this README
5. Test idempotency: Run twice, verify no errors

## Troubleshooting

**Issue: FK constraint violations**
- Solution: Load fixtures in dependency order (parent tables first)

**Issue: Duplicate key errors**
- Solution: Use `ON CONFLICT DO NOTHING` or `TRUNCATE` before insert

**Issue: Data type mismatches**
- Solution: Verify data types match schema (use `::type` casting)

---

**Maintained by:** Perseus Migration Team
**Last Updated:** 2026-01-25
**Version:** 1.0
