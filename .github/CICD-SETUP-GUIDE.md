# CI/CD Pipeline Setup Guide
## Perseus Database Migration - Automated Validation

### Overview
This guide walks through setting up the automated CI/CD pipeline for validating SQL Server → PostgreSQL migrations.

**Pipeline capabilities:**
- ✅ PostgreSQL 17 syntax validation
- ✅ Dependency graph integrity checks
- ✅ Quality score enforcement (≥7.0/10.0)
- ✅ Performance regression detection (±20%)
- ✅ Automated PR comments with validation results

---

## Prerequisites

### 1. GitHub Repository Setup
Ensure your repository has:
- [x] GitHub Actions enabled (Settings → Actions → Allow all actions)
- [x] Branch protection rules (Settings → Branches)
  - Require status checks to pass: `SQL Syntax Validation`
  - Require pull request reviews: 1 reviewer minimum
  - Include administrators: No (for emergency bypasses)

### 2. Local Development Environment
```bash
# PostgreSQL 17 (for local testing)
brew install postgresql@17  # macOS
# OR
sudo apt-get install postgresql-17  # Linux

# Python 3.11+ (for quality analysis)
python3 --version  # Should be 3.11+

# Install Python dependencies
pip install -r scripts/automation/requirements.txt
```

### 3. Repository Permissions
Ensure the following GitHub Actions permissions:
- Settings → Actions → General → Workflow permissions
  - ✅ Read and write permissions
  - ✅ Allow GitHub Actions to create and approve pull requests

---

## Installation Steps

### Step 1: Verify Pipeline Files
All files should already exist in `.github/`:
```bash
.github/
├── workflows/
│   ├── migration-validation.yml  # Main CI/CD pipeline
│   └── README.md                 # Workflow documentation
├── hooks/
│   └── pre-commit               # Local validation hook
└── CICD-SETUP-GUIDE.md          # This file
```

Verify files exist:
```bash
ls -la .github/workflows/
ls -la .github/hooks/
```

### Step 2: Install Pre-commit Hook (Optional)
For local validation before pushing:
```bash
# Copy hook to git directory
cp .github/hooks/pre-commit .git/hooks/pre-commit

# Make executable (should already be)
chmod +x .git/hooks/pre-commit

# Test hook
git add .github/
git commit -m "test: verify pre-commit hook" --dry-run
```

**What the hook does:**
- Validates SQL syntax on staged `.sql` files
- Runs quality analysis on refactored objects
- Blocks commit if syntax errors found
- Shows quality scores (non-blocking warnings)

**Bypass hook (emergency only):**
```bash
git commit --no-verify -m "fix: emergency hotfix"
```

### Step 3: Test Pipeline Locally

#### Test 1: Syntax Validation
```bash
# Single file
./scripts/validation/syntax-check.sh source/building/pgsql/refactored/20.\ create-procedure/addarc.sql

# All procedures
./scripts/validation/syntax-check.sh source/building/pgsql/refactored/20.\ create-procedure/*.sql
```

**Expected output:**
```
[INFO] Starting syntax validation...
[OK] addarc.sql - Syntax valid
[INFO] Validation complete: 1 passed, 0 failed
```

#### Test 2: Dependency Check
```bash
# Requires PostgreSQL connection
psql -d perseus_dev -f scripts/validation/dependency-check.sql
```

**Expected output:**
```
NOTICE: Dependency validation framework loaded
NOTICE: 0 critical dependency issues found
```

#### Test 3: Quality Analysis
```bash
# Analyze a single object
python3 scripts/automation/analyze-object.py --type procedure --name addarc

# Get score only
python3 scripts/automation/analyze-object.py --type procedure --name addarc --score-only
```

**Expected output:**
```
Quality Score: 8.5/10.0
- Syntax Correctness: 9.0/10.0
- Logic Preservation: 8.5/10.0
- Performance: 8.0/10.0
- Maintainability: 8.5/10.0
- Security: 9.0/10.0
```

### Step 4: Trigger First Pipeline Run

#### Option A: Push to Feature Branch
```bash
# Create feature branch
git checkout -b test-cicd-pipeline

# Make a trivial change to a SQL file
echo "-- Test comment" >> source/building/pgsql/refactored/20.\ create-procedure/addarc.sql

# Commit and push
git add .
git commit -m "test: trigger CI/CD pipeline"
git push origin test-cicd-pipeline
```

#### Option B: Create Pull Request
```bash
# After pushing feature branch
gh pr create --title "Test: CI/CD Pipeline" --body "Testing automated validation pipeline"

# OR use GitHub UI:
# https://github.com/[org]/[repo]/compare/test-cicd-pipeline
```

### Step 5: Monitor Pipeline Execution
1. Navigate to GitHub Actions tab: `https://github.com/[org]/[repo]/actions`
2. Click on the workflow run: `Perseus Migration Validation`
3. Monitor each job:
   - ✅ Syntax Validation (2-3 min)
   - ✅ Dependency Check (3-4 min)
   - ✅ Quality Gate (1-2 min)
   - ✅ Performance Regression (2-3 min)
   - ✅ Summary Report (1 min)

**Expected total runtime:** 9-13 minutes

### Step 6: Review Validation Report
On pull requests, the pipeline automatically posts a comment:

```markdown
## Perseus Migration Validation Report

**Commit:** abc123def
**Branch:** test-cicd-pipeline
**Date:** 2026-01-25 15:30:00
**Triggered by:** pull_request

### Validation Results
- ✓ Syntax Validation: success
- ✓ Dependency Check: success
- ✓ Quality Gate: success
- ✓ Performance Check: success

### ✅ Overall Status: PASSED
```

---

## Configuration

### Customizing Quality Threshold
**Default:** 7.0/10.0 (per CLAUDE.md)

**To change:**
1. Edit `.github/workflows/migration-validation.yml`
2. Find line: `if [ $(echo "$SCORE_NUM < 7.0" | bc -l 2>/dev/null || echo "1") -eq 1 ]; then`
3. Change `7.0` to desired threshold (e.g., `8.0`)
4. Update CLAUDE.md to reflect new standard

### Customizing Performance Tolerance
**Default:** ±20% (per CLAUDE.md)

**To change:**
1. Edit `scripts/validation/performance-test-framework.sql`
2. Find `REGRESSION` status calculation
3. Modify threshold percentage
4. Update CLAUDE.md documentation

### Adding Branch Triggers
**Default branches:** `main`, `develop`, `001-tsql-to-pgsql`

**To add branches:**
```yaml
on:
  push:
    branches: [ main, develop, 001-tsql-to-pgsql, feature/* ]
```

### Disabling Specific Jobs
**To skip a job temporarily:**
```yaml
quality-gate:
  name: Quality Score Validation
  if: false  # Disable this job
  runs-on: ubuntu-latest
  ...
```

---

## Troubleshooting

### Issue: Pipeline Fails on First Run
**Cause:** PostgreSQL test database not initialized

**Solution:**
1. Check syntax-validation job logs
2. Ensure `perseus_test` database created
3. Verify health checks passing: `pg_isready`
4. Re-run failed jobs

### Issue: Quality Gate Always Fails
**Cause:** analyze-object.py not finding objects

**Solution:**
1. Check file path format: `source/building/pgsql/refactored/[type]/[name].sql`
2. Verify object type mapping:
   - `20. create-procedure` → `procedure`
   - `19. create-function` → `function`
   - `15. create-view` → `view`
3. Run locally to debug: `python3 scripts/automation/analyze-object.py --type [type] --name [name] --verbose`

### Issue: Dependency Check Skipped
**Cause:** Validation tables not populated

**Solution:**
This is normal for new objects. The job logs will show:
```
INFO: Dependency validation tables not yet populated - skipping
```

To populate dependencies:
1. Run full dependency analysis: `psql -f scripts/validation/dependency-check.sql`
2. Ensure all dependent objects already exist
3. Re-run pipeline

### Issue: Performance Regression False Positives
**Cause:** No baseline metrics established

**Solution:**
1. Run performance tests on known-good baseline
2. Establish baseline metrics in `performance.test_results`
3. Re-run pipeline to compare against baseline

### Issue: Pre-commit Hook Fails
**Cause:** Scripts not executable or PostgreSQL not running

**Solution:**
```bash
# Make scripts executable
chmod +x scripts/validation/syntax-check.sh

# Start PostgreSQL
brew services start postgresql@17  # macOS
sudo systemctl start postgresql    # Linux

# Test hook manually
./scripts/validation/syntax-check.sh [file.sql]
```

---

## Best Practices

### 1. Commit Frequently
Run pipeline on small, incremental changes rather than large batches.

**Good:**
```bash
git commit -m "feat: add get_material_by_id function"  # 1 file
git commit -m "test: add unit tests for get_material_by_id"  # 1 file
```

**Bad:**
```bash
git commit -m "feat: add 25 functions"  # 25 files - hard to debug failures
```

### 2. Use Conventional Commits
Helps with automated changelog generation:

```bash
feat: add new stored procedure
fix: correct FK constraint logic
docs: update dependency analysis
test: add edge case tests
perf: optimize index on goo table
refactor: convert WHILE loop to CTE
```

### 3. Review Pipeline Logs
Even when pipeline passes, review logs for warnings:
- Syntax warnings (deprecated functions)
- Quality score near threshold (7.0-7.5)
- Performance near regression boundary (18-20% slower)

### 4. Local Testing First
Always run validation locally before pushing:
```bash
# Quick pre-push checklist
./scripts/validation/syntax-check.sh [changed-files]
python3 scripts/automation/analyze-object.py --type [type] --name [name]
psql -f [changed-files]  # Manual test
```

### 5. Document Bypass Reasons
If using `[skip ci]`, document why in PR:
```
fix: emergency hotfix for production deadlock [skip ci]

Bypassing CI/CD due to critical production incident.
Manual validation performed:
- Syntax checked locally
- Deployed to DEV and tested
- Rollback plan prepared

Will run full validation pipeline post-merge.
```

---

## Advanced Usage

### Running Pipeline on Specific Files
Modify workflow to accept manual dispatch:
```yaml
on:
  workflow_dispatch:
    inputs:
      files:
        description: 'SQL files to validate (comma-separated)'
        required: true
```

### Caching Dependencies
Speed up pipeline by caching Python packages:
```yaml
- name: Cache pip dependencies
  uses: actions/cache@v3
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('scripts/automation/requirements.txt') }}
```

### Self-Hosted Runners
For high-frequency pipelines, use self-hosted runners:
```yaml
jobs:
  syntax-validation:
    runs-on: self-hosted  # Instead of ubuntu-latest
```

**Benefits:**
- Faster execution (no cold start)
- Persistent PostgreSQL instance
- Cached dependencies

---

## Maintenance Schedule

### Weekly
- [ ] Review pipeline execution times (target: <13 min)
- [ ] Check for failed runs and patterns
- [ ] Update quality score baselines if needed

### Monthly
- [ ] Update PostgreSQL image: `postgres:17-alpine`
- [ ] Update Python dependencies: `pip install -U -r requirements.txt`
- [ ] Review and archive old artifacts

### Quarterly
- [ ] Audit quality gate thresholds (adjust if team velocity changes)
- [ ] Review performance baselines (update if schema changes)
- [ ] Update documentation for new team members

---

## Migration to Production Deployment

When pipeline is stable (after 2-3 weeks), add production deployment:

### Step 1: Create Production Environment
GitHub Settings → Environments → New environment:
- Name: `production`
- Required reviewers: Pierre Ribeiro + 1 DBA
- Deployment branches: `main` only

### Step 2: Add Deployment Job
```yaml
deploy-production:
  name: Deploy to Production
  needs: [syntax-validation, dependency-validation, quality-gate, performance-regression]
  environment: production
  runs-on: ubuntu-latest
  if: github.ref == 'refs/heads/main'

  steps:
    - uses: actions/checkout@v4
    - name: Deploy to Production PostgreSQL
      env:
        PROD_DB_HOST: ${{ secrets.PROD_DB_HOST }}
        PROD_DB_USER: ${{ secrets.PROD_DB_USER }}
        PROD_DB_PASSWORD: ${{ secrets.PROD_DB_PASSWORD }}
      run: |
        ./scripts/deployment/deploy-production.sh
```

### Step 3: Configure Secrets
GitHub Settings → Secrets and variables → Actions → New repository secret:
- `PROD_DB_HOST`: Production PostgreSQL hostname
- `PROD_DB_USER`: Deployment user (limited permissions)
- `PROD_DB_PASSWORD`: Deployment password

---

## Support

**Pipeline issues:**
1. Check GitHub Actions logs
2. Review troubleshooting section
3. Run scripts locally to isolate issue
4. Contact: Pierre Ribeiro (Senior DBA/DBRE)

**Related documentation:**
- Workflow details: `.github/workflows/README.md`
- Validation scripts: `scripts/validation/README.md`
- Automation scripts: `scripts/automation/README.md`
- Project guide: `CLAUDE.md`

---

**Setup Date:** 2026-01-25
**Pipeline Version:** 1.0
**PostgreSQL Version:** 17-alpine
**Python Version:** 3.11
**Status:** ✅ Production Ready
