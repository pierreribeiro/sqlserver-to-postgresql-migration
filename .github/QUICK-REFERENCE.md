# CI/CD Pipeline Quick Reference
## Perseus Database Migration - Cheat Sheet

### Pipeline Status Badges
Add to README.md:
```markdown
[![Perseus Migration Validation](https://github.com/[org]/[repo]/actions/workflows/migration-validation.yml/badge.svg)](https://github.com/[org]/[repo]/actions/workflows/migration-validation.yml)
```

---

## Common Commands

### Local Validation (Before Commit)
```bash
# Syntax check single file
./scripts/validation/syntax-check.sh path/to/file.sql

# Syntax check all procedures
./scripts/validation/syntax-check.sh source/building/pgsql/refactored/20.\ create-procedure/*.sql

# Quality analysis
python3 scripts/automation/analyze-object.py --type procedure --name addarc

# Quick quality score
python3 scripts/automation/analyze-object.py --type procedure --name addarc --score-only
```

### Pipeline Triggers
```bash
# Push to trigger pipeline
git push origin feature-branch

# Create PR (triggers pipeline)
gh pr create --title "feat: add new function" --body "Description"

# Re-run failed jobs (GitHub UI)
# Actions tab → Click run → Re-run failed jobs
```

### Bypass Checks (Emergency Only)
```bash
# Skip CI/CD pipeline
git commit -m "fix: emergency hotfix [skip ci]"

# Skip pre-commit hook
git commit --no-verify -m "fix: emergency hotfix"
```

---

## Quality Gates Summary

| Gate | Threshold | Fails Build | Check Time |
|------|-----------|-------------|------------|
| Syntax Validation | Valid PostgreSQL 17 | ✅ Yes | 2-3 min |
| Dependency Check | Zero CRITICAL issues | ✅ Yes | 3-4 min |
| Quality Score | ≥7.0/10.0 | ⚠️ Warning only | 1-2 min |
| Performance Regression | ±20% tolerance | ⚠️ Warning only | 2-3 min |

**Total pipeline time:** 9-13 minutes

---

## Pipeline Jobs Flow

```
┌─────────────────────┐
│ Push / PR Created   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Syntax Validation   │ ← Runs first (parallel jobs depend on this)
└──────────┬──────────┘
           │
           ├────────────────┬─────────────────┬──────────────────┐
           ▼                ▼                 ▼                  ▼
┌──────────────────┐ ┌─────────────┐ ┌──────────────┐ ┌─────────────┐
│ Dependency Check │ │ Quality Gate│ │ Performance  │ │ (Parallel)  │
└──────────────────┘ └─────────────┘ └──────────────┘ └─────────────┘
           │                │                 │                  │
           └────────────────┴─────────────────┴──────────────────┘
                                      │
                                      ▼
                           ┌──────────────────┐
                           │ Summary Report   │
                           └──────────────────┘
                                      │
                                      ▼
                           ┌──────────────────┐
                           │ PR Comment Posted│
                           └──────────────────┘
```

---

## Interpreting Results

### ✅ All Checks Passed
```
### ✅ Overall Status: PASSED
- ✓ Syntax Validation: success
- ✓ Dependency Check: success
- ✓ Quality Gate: success
- ✓ Performance Check: success
```
**Action:** Ready to merge (after code review)

### ❌ Syntax Validation Failed
```
[ERROR] Syntax error at line 45: missing semicolon
```
**Action:**
1. Download artifact: `syntax-check-*.log`
2. Fix syntax error locally
3. Run `./scripts/validation/syntax-check.sh file.sql`
4. Push fix

### ❌ Dependency Check Failed
```
ERROR: 3 critical dependency issues found
- Missing table: perseus.goo
- Circular dependency: view_a → view_b → view_a
```
**Action:**
1. Check dependency order: `docs/code-analysis/dependency-analysis-consolidated.md`
2. Ensure objects deployed in lote order (0-21)
3. Fix missing dependencies
4. Push fix

### ⚠️ Quality Score Warning
```
Quality Score: 6.5/10.0 (below 7.0 threshold)
- Syntax Correctness: 8.0/10.0
- Logic Preservation: 7.0/10.0
- Performance: 5.0/10.0 ← Low
- Maintainability: 7.0/10.0
- Security: 6.5/10.0
```
**Action:**
1. Focus on lowest dimension (Performance: 5.0)
2. Review 7 core principles: `CLAUDE.md`
3. Apply constitution patterns
4. Re-analyze locally

### ⚠️ Performance Regression Warning
```
WARNING: 2 performance regressions detected
- get_material_by_id: 450ms (was 300ms) - 50% slower
```
**Action:**
1. Run `EXPLAIN ANALYZE` on regressed query
2. Check index usage
3. Compare query plan with SQL Server baseline
4. Optimize and re-test

---

## File Paths Reference

### Pipeline Configuration
```
.github/
├── workflows/
│   ├── migration-validation.yml  ← Main pipeline
│   └── README.md                 ← Detailed docs
├── hooks/
│   └── pre-commit               ← Local validation
├── CICD-SETUP-GUIDE.md          ← Setup instructions
└── QUICK-REFERENCE.md           ← This file
```

### Validation Scripts
```
scripts/validation/
├── syntax-check.sh              ← PostgreSQL syntax validator
├── dependency-check.sql         ← Dependency graph checker
├── performance-test-framework.sql ← Performance baseline tests
└── README.md                     ← Script documentation
```

### Automation Scripts
```
scripts/automation/
├── analyze-object.py            ← Quality score calculator
├── requirements.txt             ← Python dependencies
└── README.md                     ← Script documentation
```

---

## Object Type Mapping

| Directory | Object Type | analyze-object.py Flag |
|-----------|-------------|----------------------|
| `20. create-procedure/` | Stored Procedure | `--type procedure` |
| `19. create-function/` | Function | `--type function` |
| `15. create-view/` | View | `--type view` |
| `14. create-table/` | Table | `--type table` |
| `16. create-index/` | Index | `--type index` |

**Example:**
```bash
# File: source/building/pgsql/refactored/20. create-procedure/addarc.sql
python3 scripts/automation/analyze-object.py --type procedure --name addarc
```

---

## Quality Score Dimensions

| Dimension | Weight | What It Measures |
|-----------|--------|------------------|
| Syntax Correctness | 20% | Valid PostgreSQL 17 syntax |
| Logic Preservation | 30% | Business logic matches SQL Server |
| Performance | 20% | Within ±20% of baseline |
| Maintainability | 15% | Readable, documented, follows constitution |
| Security | 15% | No SQL injection, proper permissions |

**Minimum scores:**
- Overall: ≥7.0/10.0
- No dimension: <6.0/10.0

---

## Constitution Compliance Checklist

When quality score is low, verify compliance with 7 core principles:

- [ ] **ANSI-SQL Primacy** - Standard SQL over vendor extensions
- [ ] **Strict Typing** - Explicit `CAST()` or `::`, no implicit casting
- [ ] **Set-Based Execution** - No WHILE loops, use CTEs/window functions
- [ ] **Atomic Transactions** - Explicit BEGIN/COMMIT/ROLLBACK
- [ ] **Idiomatic Naming** - `snake_case`, schema-qualified references
- [ ] **Error Resilience** - Specific exception types, include context
- [ ] **Modular Logic** - Schema-qualify to prevent search_path vulnerabilities

**Reference:** `docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md`

---

## Troubleshooting Quick Fixes

### "PostgreSQL client not found"
```bash
# macOS
brew install postgresql@17

# Linux
sudo apt-get install postgresql-client-17
```

### "Python module not found"
```bash
pip install -r scripts/automation/requirements.txt
```

### "syntax-check.sh permission denied"
```bash
chmod +x scripts/validation/syntax-check.sh
```

### "analyze-object.py returns 0 score"
```bash
# Check file exists in correct location
ls -la source/building/pgsql/refactored/[type]/[name].sql

# Run with verbose flag
python3 scripts/automation/analyze-object.py --type [type] --name [name] --verbose
```

### "Pre-commit hook not running"
```bash
# Reinstall hook
cp .github/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Test manually
.git/hooks/pre-commit
```

---

## Emergency Procedures

### Production Hotfix (Bypass CI/CD)
```bash
# 1. Create hotfix branch
git checkout -b hotfix-prod-issue main

# 2. Make minimal fix
vim source/building/pgsql/refactored/20.\ create-procedure/critical_proc.sql

# 3. Test locally
./scripts/validation/syntax-check.sh source/building/pgsql/refactored/20.\ create-procedure/critical_proc.sql
psql -d perseus_dev -f source/building/pgsql/refactored/20.\ create-procedure/critical_proc.sql

# 4. Commit with skip ci
git commit -m "fix: critical production deadlock [skip ci]

Bypassing CI/CD due to critical production incident.
Manual validation: syntax checked, deployed to DEV, tested.
Will run full validation post-merge."

# 5. Push and create PR
git push origin hotfix-prod-issue
gh pr create --title "HOTFIX: Critical production issue" --body "Emergency fix - manual validation performed"

# 6. Request emergency review
# Tag reviewers in PR
# Merge immediately after approval

# 7. Post-merge validation
# Re-run full pipeline on main branch
# Document incident in tracking/activity-log-*.md
```

---

## Useful GitHub CLI Commands

```bash
# View pipeline status
gh run list --workflow=migration-validation.yml

# View specific run details
gh run view [run-id]

# Re-run failed jobs
gh run rerun [run-id] --failed

# View PR checks
gh pr checks

# Merge PR after checks pass
gh pr merge --squash --delete-branch
```

---

## Performance Benchmarks

**Expected execution times:**
- Syntax validation: 2-3 min
- Dependency check: 3-4 min
- Quality gate: 1-2 min
- Performance tests: 2-3 min
- Summary report: 1 min
- **Total:** 9-13 min

**If pipeline exceeds 15 min:**
1. Check for network issues (Docker image pull)
2. Verify PostgreSQL container health
3. Review logs for hung jobs
4. Consider self-hosted runners

---

## Contact & Support

**Pipeline issues:** Pierre Ribeiro (Senior DBA/DBRE)

**Related documentation:**
- Full setup guide: `.github/CICD-SETUP-GUIDE.md`
- Workflow details: `.github/workflows/README.md`
- Project guide: `CLAUDE.md`

**Report bugs:**
```bash
gh issue create --title "CI/CD: [Issue]" --body "Description" --label "cicd"
```

---

**Version:** 1.0
**Last Updated:** 2026-01-25
**Status:** ✅ Production Ready
