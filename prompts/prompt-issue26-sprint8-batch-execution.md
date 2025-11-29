# Sprint 8 BATCH Execution Prompt - Issue #26

**Environment:** Claude Code Web (Hands)  
**Issue:** #26 - Sprint 8 BATCH Processing (Final Sprint)  
**Priority:** P3 (Low Criticality, Low-Medium Complexity)  
**Estimated Total:** 12-15 hours (3-4 days)  
**Quality Target:** 8.0-8.5/10 each procedure  
**Project Completion:** 80% → 100% ✅

---

## 🎯 Mission Objective

Complete the FINAL THREE procedures to achieve **100% project completion** using BATCH processing strategy for maximum efficiency.

**Procedures in BATCH:**
1. **LinkUnlinkedMaterials** (4-5h) - Simple link operation
2. **MoveContainer** (4-5h) - Size bloat reduction challenge
3. **MoveGooType** (4-5h) - 80% pattern reuse from MoveContainer

**BATCH Strategy Benefits:**
- Process all 3 together for context efficiency
- Apply consistent patterns across all
- Batch testing for integration validation
- Single comprehensive commit

---

## 📊 Sprint 8 Context

### Current Project Status
- **Completed:** 12/15 procedures (80%)
- **Quality Average:** 8.61/10
- **Time Efficiency:** 36% budget used (64% savings)
- **Highest Quality:** 9.5/10 (TransitionToMaterial, MaterialToTransition)

### Sprint 8 Procedures Overview

| Procedure | LOC | AWS SCT | Warnings | Priority | Complexity | Main Challenge |
|-----------|-----|---------|----------|----------|------------|----------------|
| **LinkUnlinkedMaterials** | 19→43 | +126% | 3 | P3 | 1.5/5 | Simple link operation |
| **MoveContainer** | 48→127 | +165% | 3 | P3 | 2.0/5 | **SIZE BLOAT reduction** |
| **MoveGooType** | 47→125 | +166% | 3 | P3 | 2.0/5 | **80% PATTERN REUSE** |

**Common Patterns Expected:**
- AWS SCT size bloat (126-166% increase)
- Similar warning profiles (3 each)
- Low complexity (simple operations)
- Opportunities for pattern reuse

---

## 🚀 PHASE 0: Environment Setup & GitHub CLI Verification

**PRIMEIRA AÇÃO - Execute ANTES de qualquer análise:**

```bash
# Verify GitHub CLI authentication
gh auth status

# View Issue #26 details
gh issue view 26 --repo pierreribeiro/sqlserver-to-postgresql-migration

# Expected output: Sprint 8 BATCH issue with all 3 procedures
```

**If gh commands fail:**
- Stop immediately and request Pierre to authenticate GitHub CLI
- DO NOT proceed without GitHub CLI access

---

## 📖 PHASE 1: Research & Analysis (1-2 hours)

### Step 1.1: Read Issue #26 (10 min)

**CRITICAL FIRST STEP:**
```bash
gh issue view 26 --repo pierreribeiro/sqlserver-to-postgresql-migration
```

Read the complete issue description, workflow, and success criteria.

---

### Step 1.2: Read ALL 3 Analysis Reports (30 min)

**Read in ORDER (establishes pattern library):**

```bash
# 1. LinkUnlinkedMaterials (simplest - baseline)
cat procedures/analysis/linkunlinkedmaterials-analysis.md

# 2. MoveContainer (bloat challenge - PRIMARY reference)
cat procedures/analysis/movecontainer-analysis.md

# 3. MoveGooType (pattern reuse - SECONDARY reference)
cat procedures/analysis/movegooype-analysis.md
```

**Focus Areas:**
- **Common P0 issues** across all 3
- **Bloat patterns** in MoveContainer/MoveGooType
- **Reusable patterns** from MoveContainer → MoveGooType
- **Unique challenges** per procedure

**Expected Common Issues:**
1. Transaction control broken (all 3)
2. AWS SCT bloat with verbose comments (all 3)
3. Unnecessary LOWER() calls (likely all 3)
4. Missing error handling (all 3)
5. No logging/observability (all 3)

---

### Step 1.3: Review AWS SCT Outputs (20 min)

```bash
# Compare AWS SCT bloat
wc -l procedures/aws-sct-converted/linkunlinkedmaterials.sql
wc -l procedures/aws-sct-converted/movecontainer.sql
wc -l procedures/aws-sct-converted/movegooype.sql

# Review actual conversions
cat procedures/aws-sct-converted/linkunlinkedmaterials.sql
cat procedures/aws-sct-converted/movecontainer.sql
cat procedures/aws-sct-converted/movegooype.sql
```

**Identify:**
- **Bloat sources:** Warning comments, verbose syntax
- **Common patterns:** Repeated conversion mistakes
- **Reuse opportunities:** Identical code blocks

---

### Step 1.4: Review Original T-SQL (20 min)

```bash
# Original business logic
cat procedures/original/dbo.LinkUnlinkedMaterials.sql
cat procedures/original/dbo.MoveContainer.sql
cat procedures/original/dbo.MoveGooType.sql
```

**Understand:**
- **Business logic** of each procedure
- **Parameter patterns**
- **Expected behavior**
- **Similarities** between MoveContainer and MoveGooType

---

### Step 1.5: Load PostgreSQL Template (10 min)

```bash
cat templates/postgresql-procedure-template.sql
```

**Template includes:**
- Transaction control patterns
- Error handling with SQLSTATE
- Logging with RAISE NOTICE
- Performance best practices
- Security patterns

---

## 🔧 PHASE 2: Execute BATCH Corrections (8-10 hours)

### 📋 BATCH Processing Order

**Process in this order for maximum efficiency:**

1. **LinkUnlinkedMaterials** (FIRST - 3-4h)
   - Simplest procedure
   - Establishes baseline patterns
   - Quick win for momentum

2. **MoveContainer** (SECOND - 4-5h)
   - Bloat reduction challenge
   - Creates pattern library for MoveGooType
   - Most complex of the 3

3. **MoveGooType** (THIRD - 3-4h)
   - 80% pattern reuse from MoveContainer
   - Fastest due to reuse
   - Validates pattern library effectiveness

---

### 2.1: LinkUnlinkedMaterials Correction (3-4h)

**Output File:** `procedures/corrected/linkunlinkedmaterials.sql`

#### P0 Critical Fixes (LinkUnlinkedMaterials)

Based on analysis report, fix ALL P0 issues:

1. **Transaction Control**
   ```sql
   CREATE OR REPLACE PROCEDURE perseus_dbo.linkunlinkedmaterials(
       -- parameters here
   )
   LANGUAGE plpgsql
   AS $$
   DECLARE
       -- declarations
   BEGIN
       -- Business logic
   EXCEPTION
       WHEN OTHERS THEN
           RAISE NOTICE 'ERROR in linkunlinkedmaterials: % %', SQLERRM, SQLSTATE;
           RAISE;
   END;
   $$;
   ```

2. **Fix AWS SCT Warnings** (all 3 warnings from analysis)

3. **Preserve Business Logic**
   - Simple link operation (INSERT/UPDATE)
   - Match original T-SQL behavior exactly

4. **Syntax Validation**
   ```bash
   # Validate PostgreSQL syntax
   psql --set=singleline=true -f procedures/corrected/linkunlinkedmaterials.sql --dry-run
   ```

#### P1 High-Priority Fixes (LinkUnlinkedMaterials)

1. **Comprehensive Error Handling**
   - NULL parameter validation
   - Constraint violation handling
   - Foreign key error handling

2. **Observability**
   ```sql
   RAISE NOTICE 'LinkUnlinkedMaterials: Starting for material_uid=%', par_material_uid;
   -- ... business logic ...
   RAISE NOTICE 'LinkUnlinkedMaterials: Completed - linked % materials', v_row_count;
   ```

3. **Performance Optimization**
   - Remove unnecessary LOWER() calls
   - Optimize queries
   - Add appropriate indexes (document only)

#### P2 Minor Enhancements (LinkUnlinkedMaterials)

1. **Documentation**
   - Comprehensive header
   - Business logic explanation
   - Parameter documentation

2. **Code Quality**
   - Consistent naming (snake_case)
   - Clear variable names
   - Readable formatting

---

### 2.2: MoveContainer Correction (4-5h)

**Output File:** `procedures/corrected/movecontainer.sql`

**CRITICAL CHALLENGE:** Size bloat reduction (48→127 LOC = +165%)

#### Bloat Reduction Strategy

**Expected Bloat Sources:**
1. AWS SCT warning comments (verbose)
2. Unnecessary BEGIN/END nesting
3. Verbose error messages
4. Redundant variable declarations

**Reduction Tactics:**
```sql
-- ❌ BLOAT (AWS SCT style)
/* ********** WARNING **********
   AWS SCT could not convert this...
   [50 lines of explanation]
   ****************************** */

-- ✅ CONCISE (production style)
-- Note: Original OPENQUERY replaced with direct query
```

**Target:** Reduce 127 LOC → ~60-70 LOC (similar to original 48)

#### P0 Critical Fixes (MoveContainer)

Based on analysis report:

1. **Transaction Control** (same pattern as LinkUnlinkedMaterials)

2. **Fix ALL AWS SCT Warnings** (3 warnings)

3. **Eliminate Bloat**
   - Remove verbose AWS comments
   - Simplify control structures
   - Consolidate error handling

4. **Preserve Business Logic**
   - Container movement operation
   - Parameter validation
   - State updates

#### P1 High-Priority Fixes (MoveContainer)

1. **Error Handling** (same pattern as LinkUnlinkedMaterials)

2. **Logging**
   ```sql
   RAISE NOTICE 'MoveContainer: Moving container % to %', par_container_id, par_target_location;
   ```

3. **Performance**
   - Remove LOWER() calls
   - Optimize container lookup queries

#### P2 Enhancements (MoveContainer)

1. **Documentation** (focus on bloat reduction achieved)
2. **Pattern Library** for MoveGooType reuse
3. **Code Quality**

---

### 2.3: MoveGooType Correction (3-4h)

**Output File:** `procedures/corrected/movegooype.sql`

**KEY STRATEGY:** 80% pattern reuse from MoveContainer

#### Pattern Reuse Analysis

**Similarities between MoveContainer and MoveGooType:**
- Same LOC size (48→127 vs 47→125)
- Same warning count (3 each)
- Same complexity score (2.0/5)
- Similar business logic (move operation)
- Similar AWS SCT bloat patterns

**Reuse Plan:**
1. **Copy MoveContainer structure** (transaction, error handling, logging)
2. **Replace business logic** (container → goo_type)
3. **Adjust parameters** (different entity IDs)
4. **Validate independently**

#### P0 Critical Fixes (MoveGooType)

**COPY from MoveContainer:**
1. Transaction control structure
2. Error handling patterns
3. Bloat reduction tactics

**ADJUST for MoveGooType:**
1. Entity-specific business logic
2. Table/column names
3. Parameter names

**Expected Time Savings:** 40-50% due to pattern reuse

#### P1 High-Priority Fixes (MoveGooType)

**COPY from MoveContainer:**
1. Error handling comprehensiveness
2. Logging patterns
3. Performance optimizations

**VALIDATE:**
1. GooType-specific constraints
2. State transition rules
3. Referential integrity

#### P2 Enhancements (MoveGooType)

1. **Documentation** (emphasize pattern reuse)
2. **Twin Relationship** (document similarity to MoveContainer)
3. **Code Quality**

---

## 🧪 PHASE 3: Create BATCH Tests (2-3 hours)

### 3.1: Individual Unit Tests (1.5h - 30 min each)

**Create 3 separate test files:**

```bash
# LinkUnlinkedMaterials tests
tests/unit/test_linkunlinkedmaterials.sql

# MoveContainer tests
tests/unit/test_movecontainer.sql

# MoveGooType tests
tests/unit/test_movegooype.sql
```

**Each test file includes (8+ test cases):**

1. **Happy Path**
   ```sql
   -- Test successful operation
   ```

2. **Validation Tests**
   ```sql
   -- Test NULL parameter handling
   -- Test invalid ID handling
   ```

3. **Constraint Tests**
   ```sql
   -- Test foreign key violations
   -- Test unique constraint violations
   ```

4. **Edge Cases**
   ```sql
   -- Test empty result sets
   -- Test duplicate operations (idempotency)
   ```

5. **Performance Test**
   ```sql
   -- Test with larger dataset
   ```

6. **Cleanup Verification**
   ```sql
   -- Verify no orphaned data
   ```

---

### 3.2: Integration Tests (1h)

**File:** `tests/integration/test_sprint8_batch.sql`

**Integration Scenarios:**

1. **Sequential Operations**
   ```sql
   -- Link materials
   CALL linkunlinkedmaterials(...);
   
   -- Move container
   CALL movecontainer(...);
   
   -- Move goo type
   CALL movegooype(...);
   
   -- Validate end state
   ```

2. **Concurrent Compatibility**
   ```sql
   -- Verify procedures don't conflict
   -- Test parallel execution safety
   ```

3. **Data Consistency**
   ```sql
   -- Verify referential integrity
   -- Test cascade behaviors
   ```

4. **Rollback Scenarios**
   ```sql
   -- Test transaction rollback
   -- Verify cleanup on error
   ```

---

### 3.3: Performance Benchmarking (30 min)

**File:** `tests/performance/test_sprint8_performance.sql`

**Benchmarks:**

1. **Individual Performance**
   ```sql
   -- Measure LinkUnlinkedMaterials execution time
   -- Measure MoveContainer execution time
   -- Measure MoveGooType execution time
   ```

2. **Batch Performance**
   ```sql
   -- Measure total batch execution time
   -- Compare to individual sum
   ```

3. **Optimization Validation**
   ```sql
   -- Verify LOWER() removal impact
   -- Verify query optimization impact
   ```

**Performance Targets:**
- LinkUnlinkedMaterials: <100ms
- MoveContainer: <200ms
- MoveGooType: <200ms

---

## 📝 PHASE 4: Documentation & Commit (1 hour)

### 4.1: Update Documentation (30 min)

**Files to update:**

1. **procedures/corrected/[procedure].sql headers**
   - Comprehensive documentation
   - Business logic explanation
   - Parameter descriptions
   - Example usage

2. **tests/README.md** (if needed)
   - Sprint 8 test documentation
   - BATCH testing approach

3. **CHANGELOG.md** (optional)
   - Sprint 8 achievements
   - Bloat reduction metrics
   - Pattern reuse success

---

### 4.2: Git Commit (30 min)

**Commit Strategy: SINGLE COMPREHENSIVE COMMIT**

```bash
# Stage all 3 corrected procedures
git add procedures/corrected/linkunlinkedmaterials.sql
git add procedures/corrected/movecontainer.sql
git add procedures/corrected/movegooype.sql

# Stage all tests
git add tests/unit/test_linkunlinkedmaterials.sql
git add tests/unit/test_movecontainer.sql
git add tests/unit/test_movegooype.sql
git add tests/integration/test_sprint8_batch.sql
git add tests/performance/test_sprint8_performance.sql

# Comprehensive commit message
git commit -m "feat: Sprint 8 BATCH - Final 3 procedures (Issue #26)

Sprint 8 COMPLETE: 3 P3 procedures corrected

Procedures:
- LinkUnlinkedMaterials (Quality: X.X/10, Time: Xh)
- MoveContainer (Quality: X.X/10, Time: Xh, Bloat: -XX%)
- MoveGooType (Quality: X.X/10, Time: Xh, Pattern Reuse: 80%)

Quality Achievements:
- All procedures: 8.0-8.5/10 target achieved
- MoveContainer: XX% bloat reduction (127→XX LOC)
- MoveGooType: 80% pattern reuse from MoveContainer
- Comprehensive test coverage (XX+ test cases)

Project Status:
- Procedures corrected: 15/15 (100%) ✅
- PROJECT COMPLETE - Phase 2 finished
- Ready for Integration Testing (Sprint 9)

P0 Fixes Applied (All 3 Procedures):
- Transaction control with error handling
- AWS SCT warnings resolved (9 total)
- Business logic preserved
- Syntax validated

P1 Fixes Applied:
- Comprehensive error handling
- Observability with RAISE NOTICE
- Performance optimizations (LOWER() removal)
- Security best practices

Testing:
- Unit tests: 3 files (24+ test cases)
- Integration tests: Batch compatibility validated
- Performance tests: All within targets

Time Tracking:
- LinkUnlinkedMaterials: Xh (estimated 4-5h)
- MoveContainer: Xh (estimated 4-5h)
- MoveGooType: Xh (estimated 4-5h)
- Total: XXh (estimated 12-15h)
- Efficiency: XX% of budget

Closes #26"

# Push to GitHub
git push origin main
```

---

## ✅ Quality Checklist - ALL 3 PROCEDURES

### LinkUnlinkedMaterials Checklist

**P0 Critical:**
- [ ] Transaction control implemented
- [ ] All 3 AWS SCT warnings resolved
- [ ] Business logic preserved (link operation)
- [ ] Syntax validates in PostgreSQL

**P1 High Priority:**
- [ ] Comprehensive error handling
- [ ] Logging with RAISE NOTICE
- [ ] Performance optimized (LOWER() removed)
- [ ] NULL parameter validation

**P2 Minor:**
- [ ] Documentation complete
- [ ] Code quality standards met
- [ ] Naming conventions (snake_case)

**Testing:**
- [ ] 8+ unit test cases created
- [ ] All tests pass
- [ ] Performance within target (<100ms)
- [ ] Integration tested

**Quality Target:** 8.0-8.5/10

---

### MoveContainer Checklist

**P0 Critical:**
- [ ] Transaction control implemented
- [ ] All 3 AWS SCT warnings resolved
- [ ] **BLOAT REDUCED:** 127 LOC → ~60-70 LOC
- [ ] Business logic preserved (move operation)
- [ ] Syntax validates in PostgreSQL

**P1 High Priority:**
- [ ] Comprehensive error handling
- [ ] Logging with RAISE NOTICE
- [ ] Performance optimized
- [ ] State validation

**P2 Minor:**
- [ ] Documentation emphasizes bloat reduction
- [ ] Pattern library created for MoveGooType
- [ ] Code quality excellent

**Testing:**
- [ ] 8+ unit test cases created
- [ ] All tests pass
- [ ] Performance within target (<200ms)
- [ ] Integration tested

**Quality Target:** 8.0-8.5/10
**Bloat Reduction Target:** -40% to -50%

---

### MoveGooType Checklist

**P0 Critical:**
- [ ] Transaction control (COPIED from MoveContainer)
- [ ] All 3 AWS SCT warnings resolved
- [ ] **80% PATTERN REUSE** from MoveContainer validated
- [ ] Business logic preserved (goo type move)
- [ ] Syntax validates in PostgreSQL

**P1 High Priority:**
- [ ] Error handling (COPIED from MoveContainer)
- [ ] Logging (COPIED from MoveContainer)
- [ ] Performance (COPIED from MoveContainer)
- [ ] Entity-specific validation

**P2 Minor:**
- [ ] Documentation emphasizes pattern reuse
- [ ] Twin relationship with MoveContainer documented
- [ ] Code quality matches MoveContainer

**Testing:**
- [ ] 8+ unit test cases created
- [ ] All tests pass
- [ ] Performance within target (<200ms)
- [ ] Integration tested
- [ ] Twin compatibility validated

**Quality Target:** 8.0-8.5/10
**Pattern Reuse Target:** 80% from MoveContainer

---

## 📊 Sprint 8 Success Metrics

### Overall Quality Gates

- [ ] **All 3 procedures:** Quality score 8.0-8.5/10
- [ ] **Project completion:** 100% (15/15 procedures)
- [ ] **Bloat reduction:** MoveContainer -40% or better
- [ ] **Pattern reuse:** MoveGooType 80% from MoveContainer
- [ ] **Time efficiency:** Within 12-15h estimate

### Individual Procedure Success

**LinkUnlinkedMaterials:**
- [ ] Quality: 8.0-8.5/10
- [ ] Time: 3-5h
- [ ] Tests: 8+ cases passing
- [ ] Establishes baseline patterns

**MoveContainer:**
- [ ] Quality: 8.0-8.5/10
- [ ] Time: 4-5h
- [ ] Bloat: 127 LOC → 60-70 LOC (-40%)
- [ ] Tests: 8+ cases passing
- [ ] Creates pattern library

**MoveGooType:**
- [ ] Quality: 8.0-8.5/10
- [ ] Time: 3-4h (fastest due to reuse)
- [ ] Pattern reuse: 80% from MoveContainer
- [ ] Tests: 8+ cases passing
- [ ] Validates pattern library

### BATCH Processing Success

- [ ] All 3 procedures integrated seamlessly
- [ ] Consistent patterns across all
- [ ] Single comprehensive commit
- [ ] Integration tests validate compatibility
- [ ] Total time: 12-15h

---

## 🎯 Final Deliverables

### Code Artifacts

1. ✅ **procedures/corrected/linkunlinkedmaterials.sql**
2. ✅ **procedures/corrected/movecontainer.sql**
3. ✅ **procedures/corrected/movegooype.sql**

### Test Artifacts

4. ✅ **tests/unit/test_linkunlinkedmaterials.sql**
5. ✅ **tests/unit/test_movecontainer.sql**
6. ✅ **tests/unit/test_movegooype.sql**
7. ✅ **tests/integration/test_sprint8_batch.sql**
8. ✅ **tests/performance/test_sprint8_performance.sql**

### Documentation

9. ✅ **Comprehensive procedure headers** (all 3)
10. ✅ **Git commit** (single comprehensive commit)
11. ✅ **Issue #26 closure comment** (automated by commit)

---

## 🚀 Post-Sprint 8: Next Steps

After Sprint 8 completion (100% procedures corrected):

### Sprint 9: Integration & Staging
1. **Integration Testing** - All 15 procedures together
2. **Performance Benchmarking** - vs SQL Server baseline
3. **Staging Deployment** - Deploy to staging environment
4. **User Acceptance Testing** - Validate with stakeholders

### Sprint 10: Production Deployment
1. **Production Deployment Plan**
2. **Rollback Strategy**
3. **Monitoring Setup**
4. **Production Deployment**
5. **Project Retrospective**

---

## 📝 Special Notes - Sprint 8

### Why BATCH Processing?

1. **Context Efficiency** - Load all 3 analyses once
2. **Pattern Reuse** - MoveContainer → MoveGooType (80%)
3. **Consistent Quality** - Apply same standards across all
4. **Single Commit** - Cleaner git history
5. **Momentum** - Complete final sprint in one push

### Critical Success Factors

1. **Read all 3 analyses FIRST** - Don't start coding blind
2. **Process in ORDER** - LinkUnlinked → Move → MoveGoo
3. **Apply bloat reduction** - MoveContainer is test case
4. **Maximize pattern reuse** - MoveGooType should be fast
5. **Comprehensive testing** - All 3 + integration

### Watch Out For

1. **Bloat temptation** - Easy to accept AWS SCT verbosity
2. **Pattern divergence** - Keep MoveGooType similar to MoveContainer
3. **Individual optimization** - Don't sacrifice quality for speed
4. **Test coverage** - Don't skip edge cases
5. **Documentation** - Record bloat reduction and pattern reuse

---

## 🎖️ Final Sprint - Mission Completion

**Sprint 8 represents:**
- ✅ **100% project completion** (Phase 2 finished)
- ✅ **All 15 procedures corrected**
- ✅ **Quality target exceeded** (8.0+ average)
- ✅ **Time efficiency maintained** (under budget)
- ✅ **Pattern library validated** (reuse successful)

**After Sprint 8:**
- Project enters Integration phase (Sprint 9)
- Production deployment planning (Sprint 10)
- Migration project COMPLETE

---

**Execute with excellence! This is the final sprint to 100% completion! 🚀**

**Personas Required:** @Database expert@ @Review code@  
**Expected Duration:** 12-15 hours (3-4 days)  
**Complexity:** LOW-MEDIUM (P3 procedures)  
**Pattern Reuse:** 80% MoveContainer → MoveGooType  
**BATCH Processing:** Maximum efficiency  

---

*Created: 2025-11-29*  
*Sprint: 8 (Final Sprint)*  
*Issue: #26*  
*Goal: 80% → 100% Project Completion*  

**Over and out! 📡**