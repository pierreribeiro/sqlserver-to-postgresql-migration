# Tests Directory

## Purpose

Comprehensive test suite for validating migrated PostgreSQL objects against SQL Server baseline. Ensures zero defects through unit tests, integration tests, and performance benchmarks.

## Structure

```
tests/
├── unit/           # ✅ Per-procedure unit tests (15 files complete)
├── integration/    # ✅ Cross-object workflow tests (2 files)
└── performance/    # ✅ Performance benchmarks vs SQL Server (1 file)
```

## Contents

### Unit Tests (✅ 15 Procedures Complete)

**[unit/](unit/)** - Individual procedure validation with comprehensive test cases

15 test files covering all migrated procedures:
1. `test_addarc.sql` - Add arc to material transition graph
2. `test_getmaterialbyrunproperties.sql` - Retrieve materials by run properties
3. `test_linkunlinkedmaterials.sql` - Link unlinked materials
4. `test_materialtotransition.sql` - Convert material to transition
5. `test_movecontainer.sql` - Move container between locations
6. `test_movegootype.sql` - Update goo type assignments
7. `test_processdirtytrees.sql` - Process dirty tree structures
8. `test_processsomemupstream.sql` - Process upstream relationships
9. `test_reconcilemupstream.sql` - Reconcile upstream material data
10. `test_removearc.sql` - Remove arc from material transition graph
11. `test_sp_move_node.sql` - Move node in hierarchy
12. `test_transitiontomaterial.sql` - Convert transition to material
13. `test_usp_updatecontainertypefromargus.sql` - Update container type
14. `test_usp_updatemdownstream.sql` - Update downstream relationships
15. `test_usp_updatemupstream.sql` - Update upstream relationships

**Test Coverage Per Procedure:**
- ✅ Happy path (valid inputs, expected results)
- ✅ Null handling (NULL parameters)
- ✅ Edge cases (empty strings, zero values, boundaries)
- ✅ Error scenarios (FK violations, unique constraints, rollbacks)
- ✅ Data integrity (row counts, checksums)

**Run all unit tests:**
```bash
for test in tests/unit/test_*.sql; do
  echo "Running $test..."
  psql -d perseus_dev -f "$test"
done
```

### Integration Tests (✅ 2 Files Available)

**[integration/](integration/)** - Cross-procedure workflow validation

- `test_sprint8_batch.sql` - Batch processing workflow tests
- `test_twin_procedures.sql` - Paired procedure interaction tests (e.g., AddArc + RemoveArc)

**Integration test scenarios:**
- Multi-procedure workflows (add → process → reconcile)
- Transaction boundaries across procedures
- Data consistency after complex operations
- Cascade effects and dependency validation

**Run integration tests:**
```bash
psql -d perseus_dev -f tests/integration/test_sprint8_batch.sql
psql -d perseus_dev -f tests/integration/test_twin_procedures.sql
```

### Performance Tests (✅ 1 File Available)

**[performance/](performance/)** - Performance benchmarks vs SQL Server baseline

- `test_sprint8_performance.sql` - Execution time benchmarks for migrated procedures

**Performance criteria:**
- ✅ Within ±20% of SQL Server baseline (MINIMUM)
- 🎯 Target: +50-100% improvement (achieved in Sprint 3: +63% to +97%)

**Benchmark categories:**
- Small dataset (10-100 rows)
- Medium dataset (1K-10K rows)
- Large dataset (100K+ rows)
- Complex queries (joins, aggregations, CTEs)

**Run performance tests:**
```bash
psql -d perseus_dev -f tests/performance/test_sprint8_performance.sql
```

## Test Standards

### Test File Structure

Each unit test file MUST include:

```sql
-- =============================================================================
-- Test: procedure_name
-- Description: [Test description]
-- Procedure: schema.procedure_name
-- Created: YYYY-MM-DD
-- =============================================================================

BEGIN;

-- Setup: Create test data
-- Test 1: Happy path
-- Test 2: Null handling
-- Test 3: Edge cases
-- Test 4: Error scenarios
-- Cleanup: Remove test data

ROLLBACK; -- Always rollback test data
```

### Test Execution Requirements

**All tests MUST:**
- ✅ Run in transaction (BEGIN...ROLLBACK)
- ✅ Clean up test data (no side effects)
- ✅ Use ASSERT statements or explicit validation
- ✅ Print clear pass/fail messages
- ✅ Test both success and failure paths

**Example test pattern:**
```sql
-- Test: Happy path
DO $$
DECLARE
    v_result INTEGER;
BEGIN
    SELECT * INTO v_result FROM perseus.procedure_name(param1, param2);

    ASSERT v_result = expected_value, 'Test failed: expected value mismatch';
    RAISE NOTICE 'PASS: Happy path test';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'FAIL: %', SQLERRM;
END $$;
```

## Test Execution Workflow

### Development (DEV Environment)

```bash
# Run specific unit test
psql -d perseus_dev -f tests/unit/test_<procedure>.sql

# Run all unit tests
for test in tests/unit/test_*.sql; do psql -d perseus_dev -f "$test"; done

# Run integration tests
psql -d perseus_dev -f tests/integration/test_sprint8_batch.sql

# Run performance benchmarks
psql -d perseus_dev -f tests/performance/test_sprint8_performance.sql
```

### Quality Gate Validation (STAGING)

**Before deploying to STAGING, ALL tests must PASS:**
```bash
# Comprehensive test run
./scripts/validation/run-all-tests.sh  # (planned script)
```

**STAGING deployment criteria:**
- ✅ Zero unit test failures
- ✅ Zero integration test failures
- ✅ Performance within ±20% of baseline
- ✅ Zero P0/P1 issues
- ✅ Quality score ≥7.0/10

### Production Validation (PROD)

**Post-deployment smoke tests:**
```bash
# Smoke test suite (subset of unit tests)
./scripts/deployment/smoke-test.sh <procedure_name> prod  # (planned)
```

## Test Coverage Status

| Test Type | Complete | Pending | Coverage |
|-----------|----------|---------|----------|
| **Unit Tests** | 15 ✅ | 754 | 2% (procedures only) |
| **Integration Tests** | 2 ✅ | TBD | Batch + twin procedures |
| **Performance Tests** | 1 ✅ | TBD | Sprint 3 procedures |

**Next priority:** Create unit tests for P0 critical path objects (views, functions, tables)

## Test Development Guidelines

**When creating new tests:**
1. Copy template from existing test file
2. Include all 5 test categories (happy path, null, edge, error, integrity)
3. Use meaningful test data (realistic scenarios)
4. Document expected results inline
5. Test both return values AND side effects
6. Always use transactions (BEGIN...ROLLBACK)
7. Add to appropriate subdirectory (unit/integration/performance)

**Test naming conventions:**
- Unit tests: `test_<procedure_name>.sql`
- Integration tests: `test_<workflow_name>.sql`
- Performance tests: `test_<sprint_name>_performance.sql`

## Navigation

- See [unit/README.md](unit/README.md) for unit test details
- See [integration/README.md](integration/README.md) for integration test details
- See [performance/README.md](performance/README.md) for performance benchmark details
- Up: [../README.md](../README.md)

---

**Last Updated:** 2026-01-22 | **Status:** 15 unit tests complete (procedures), integration + performance tests available
