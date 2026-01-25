# CI/CD Pipeline Documentation

## Overview
Automated validation pipeline for Perseus database migration (SQL Server → PostgreSQL 17). Ensures zero-defect quality standards across 769 database objects.

## Workflows

### migration-validation.yml
**Purpose:** Comprehensive validation gate enforcing constitution compliance and quality standards.

**Validation Gates:**
1. SQL syntax correctness (PostgreSQL 17 compatibility)
2. Dependency resolution (no missing/circular dependencies)
3. Quality score thresholds (≥7.0/10.0 per CLAUDE.md)
4. Performance regressions (±20% tolerance)

### Triggers
- **Push events:**
  - Branches: `main`, `develop`, `001-tsql-to-pgsql`
  - Paths: `source/building/pgsql/refactored/**/*.sql`, `scripts/**/*`

- **Pull request events:**
  - Target branches: `main`, `develop`
  - Paths: SQL files in refactored directory and scripts

- **Optimization:** Only runs when SQL/script files change

## Jobs Architecture

### 1. Syntax Validation (2-3 min)
**Purpose:** Verify PostgreSQL 17 syntax compliance

**Steps:**
- Spins up PostgreSQL 17 Alpine container
- Installs PostgreSQL client tools
- Runs `syntax-check.sh` on changed files
- Uploads validation logs as artifacts

**Exit criteria:**
- ❌ FAIL: Any syntax error detected
- ✅ PASS: All files parse successfully

**Environment:**
```yaml
PostgreSQL: 17-alpine
Database: perseus_test
Health checks: 10s intervals
Port: 5432
```

### 2. Dependency Check (3-4 min)
**Purpose:** Validate object dependency graph integrity

**Prerequisites:** Syntax validation must pass

**Steps:**
- Creates validation schema
- Loads dependency-check.sql framework
- Queries for CRITICAL severity issues
- Reports missing/circular dependencies

**Exit criteria:**
- ❌ FAIL: Any CRITICAL dependency issues
- ✅ PASS: Zero critical issues
- ⚠️ SKIP: Validation tables not populated (new objects)

**Database setup:**
```sql
CREATE SCHEMA perseus;
CREATE SCHEMA validation;
-- Loads dependency tracking tables
```

### 3. Quality Gate (1-2 min)
**Purpose:** Enforce 7-principle constitution compliance (CLAUDE.md)

**Prerequisites:** Syntax validation must pass

**Steps:**
- Installs Python 3.11 + dependencies
- Runs `analyze-object.py` on changed files
- Calculates 5-dimension quality score
- Enforces ≥7.0/10.0 threshold

**Quality dimensions:**
1. Syntax Correctness (20%)
2. Logic Preservation (30%)
3. Performance (20%)
4. Maintainability (15%)
5. Security (15%)

**Exit criteria:**
- ❌ FAIL: Any file scores <7.0/10.0 (currently warning only)
- ✅ PASS: All files ≥7.0/10.0
- ⚠️ SKIP: No refactored SQL files changed

**Example output:**
```
source/building/pgsql/refactored/20. create-procedure/addarc.sql: Quality Score = 8.5/10.0
source/building/pgsql/refactored/20. create-procedure/mcgetupstream.sql: Quality Score = 9.2/10.0
```

### 4. Performance Regression (2-3 min)
**Purpose:** Detect >20% performance degradation vs baseline

**Prerequisites:** Syntax validation must pass

**Steps:**
- Loads performance-test-framework.sql
- Runs benchmark queries
- Compares against baselines
- Flags regressions >20% slower

**Exit criteria:**
- ❌ FAIL: Any regression >20% (currently warning only)
- ✅ PASS: All tests within ±20% tolerance
- ⚠️ SKIP: Performance tables not populated

**Regression detection:**
```sql
SELECT COUNT(*) FROM performance.test_results
WHERE status = 'REGRESSION'
  AND executed_at > NOW() - INTERVAL '1 hour';
```

### 5. Summary Report (1 min)
**Purpose:** Aggregate validation results and notify stakeholders

**Always runs:** Even if previous jobs fail

**Steps:**
- Generates markdown report with all job statuses
- Posts comment on PR (if triggered by pull request)
- Uploads report artifact for audit trail

**Report format:**
```markdown
## Perseus Migration Validation Report

**Commit:** abc123def
**Branch:** 001-tsql-to-pgsql
**Date:** 2026-01-25 15:00:00
**Triggered by:** pull_request

### Validation Results
- ✓ Syntax Validation: success
- ✓ Dependency Check: success
- ✓ Quality Gate: success
- ✓ Performance Check: success

### ✅ Overall Status: PASSED
```

## Local Testing

**Test pipeline locally before pushing:**

```bash
# 1. Syntax validation (individual file)
./scripts/validation/syntax-check.sh source/building/pgsql/refactored/20.\ create-procedure/addarc.sql

# 2. Syntax validation (all procedures)
./scripts/validation/syntax-check.sh source/building/pgsql/refactored/20.\ create-procedure/*.sql

# 3. Dependency check (requires PostgreSQL)
psql -d perseus_dev -f scripts/validation/dependency-check.sql

# 4. Quality analysis (requires Python)
python3 scripts/automation/analyze-object.py --type procedure --name addarc

# 5. Performance test (requires PostgreSQL + test data)
psql -d perseus_dev -f scripts/validation/performance-test-framework.sql
```

## Environment Setup

**PostgreSQL container:**
```yaml
image: postgres:17-alpine
env:
  POSTGRES_DB: perseus_test
  POSTGRES_USER: test_user
  POSTGRES_PASSWORD: test_pass
health-cmd: pg_isready
```

**Python dependencies:**
```bash
pip install -r scripts/automation/requirements.txt
```

## Bypassing Checks

**Emergency bypass** (requires admin approval):
```bash
git commit -m "fix: emergency hotfix [skip ci]"
```

**When to bypass:**
- Critical production incident
- Infrastructure maintenance
- Documentation-only changes

**Process:**
1. Create PR with `[skip ci]` in commit message
2. Request admin approval in PR comments
3. Document bypass reason in PR description
4. Run manual validation post-merge

## Workflow Maintenance

### Updating PostgreSQL Version
```yaml
services:
  postgres:
    image: postgres:17-alpine  # Change version here
```

**After version change:**
1. Test locally with new version
2. Update documentation
3. Verify all scripts compatible
4. Monitor first CI run closely

### Adding New Validation Jobs

**Pattern:**
```yaml
new-validation:
  name: New Validation Check
  runs-on: ubuntu-latest
  needs: syntax-validation  # Always depend on syntax first

  steps:
    - uses: actions/checkout@v4
    - name: Run Validation
      run: ./scripts/validation/new-check.sh
```

**Integration checklist:**
- Add to `summary-report` needs list
- Update README.md documentation
- Add local testing instructions
- Test on feature branch first

### Modifying Quality Thresholds

**Current threshold:** 7.0/10.0 (CLAUDE.md)

**To change:**
1. Update `analyze-object.py` scoring logic
2. Update quality-gate job comparison: `"$SCORE_NUM < 7.0"`
3. Update CLAUDE.md documentation
4. Announce to team (breaking change)

## Troubleshooting

### Job: syntax-validation fails
**Symptoms:** PostgreSQL syntax errors in logs

**Common causes:**
- T-SQL → PostgreSQL transformation incomplete
- Missing schema qualification
- Implicit casting issues
- Reserved keyword conflicts

**Fix:**
1. Check syntax-check-*.log artifact
2. Run locally: `./scripts/validation/syntax-check.sh <file>`
3. Apply constitution transformations (CLAUDE.md)
4. Re-test and push

### Job: dependency-validation fails
**Symptoms:** CRITICAL dependency issues found

**Common causes:**
- Object created before dependencies
- Circular dependencies
- Typos in object names
- Missing schema prefixes

**Fix:**
1. Review dependency-check.sql output
2. Check dependency-analysis-consolidated.md for correct order
3. Ensure objects deployed in lote order (0-21)
4. Verify schema-qualified references

### Job: quality-gate fails
**Symptoms:** Quality score <7.0/10.0

**Common causes:**
- Missing error handling
- WHILE loops instead of CTEs
- No schema qualification
- Weak documentation

**Fix:**
1. Run `analyze-object.py` locally for detailed breakdown
2. Review 7 core principles (CLAUDE.md)
3. Apply constitution patterns
4. Target weakest dimension first

### Job: performance-regression fails
**Symptoms:** Queries >20% slower than baseline

**Common causes:**
- Missing indexes
- Poor query plan
- Inefficient joins
- Table scans instead of seeks

**Fix:**
1. Run EXPLAIN ANALYZE on regressed query
2. Check index usage: `pg_stat_user_indexes`
3. Review query plan vs SQL Server
4. Add/modify indexes as needed

### GitHub Actions quota limits
**Symptoms:** Workflows queued or failing with quota errors

**Solutions:**
- Use self-hosted runners (for high-frequency projects)
- Reduce workflow frequency (e.g., only on PRs)
- Optimize job parallelization
- Cache dependencies (poetry cache, pip cache)

## Performance Benchmarks

**Typical execution times:**
- Syntax validation: 2-3 min
- Dependency check: 3-4 min
- Quality gate: 1-2 min
- Performance tests: 2-3 min
- Summary report: 1 min
- **Total pipeline:** 9-13 min

**Optimization opportunities:**
- Parallel job execution (already implemented)
- Cached Python dependencies
- Incremental validation (only changed files)
- Self-hosted runners for large projects

## Security Considerations

**Secrets management:**
- PostgreSQL credentials: Test credentials only (not production)
- GitHub token: Automatically provided by Actions
- No sensitive data in logs or artifacts

**Best practices:**
- Never commit production credentials
- Use GitHub Secrets for any sensitive config
- Review artifact contents before public repos
- Rotate test credentials periodically

## Migration to Production

**When pipeline is stable:**

1. **Add PROD deployment job** (manual approval required):
```yaml
deploy-production:
  needs: [syntax-validation, dependency-validation, quality-gate, performance-regression]
  environment: production  # Requires manual approval
  runs-on: ubuntu-latest
  steps:
    - name: Deploy to Production
      run: ./scripts/deployment/deploy-production.sh
```

2. **Configure GitHub Environment:**
   - Settings → Environments → New environment → `production`
   - Required reviewers: Pierre Ribeiro + 1 DBA
   - Deployment branches: `main` only

3. **Add rollback automation:**
```yaml
rollback-production:
  if: failure()
  steps:
    - name: Rollback Deployment
      run: ./scripts/deployment/rollback-production.sh
```

## Related Documentation

- **Project specification:** `docs/PROJECT-SPECIFICATION.md`
- **Constitution:** `docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md`
- **Validation scripts:** `scripts/validation/README.md`
- **Automation scripts:** `scripts/automation/README.md`
- **Main project guide:** `CLAUDE.md`

## Support

**Issues with CI/CD pipeline:**
1. Check workflow logs in GitHub Actions tab
2. Review troubleshooting section above
3. Run validation scripts locally to isolate issue
4. Contact project lead: Pierre Ribeiro (Senior DBA/DBRE)

---
**Last Updated:** 2026-01-25
**Pipeline Version:** 1.0
**PostgreSQL Version:** 17-alpine
**Python Version:** 3.11
