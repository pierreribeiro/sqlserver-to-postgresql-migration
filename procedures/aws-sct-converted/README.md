# AWS SCT Converted Procedures

## 📁 Directory Purpose

This directory contains PostgreSQL procedures **automatically converted** by AWS Schema Conversion Tool (SCT) from the original SQL Server T-SQL procedures.

**Status:** BASELINE - Not production-ready without manual review

---

## ⚠️ CRITICAL: These Files Require Manual Review

AWS SCT provides approximately **70% conversion accuracy**. The remaining **30% requires manual intervention** before production deployment.

### Common SCT Issues

1. **Transaction Control**
   - Incorrect BEGIN/COMMIT/ROLLBACK placement
   - Missing EXCEPTION blocks
   
2. **Syntax Errors**
   - RAISE statements need conversion to RAISE NOTICE/EXCEPTION
   - Variable declarations may need adjustments
   
3. **Performance Concerns**
   - Unnecessary LOWER() functions
   - Inefficient temp table usage
   - Missing indexes

---

## 📋 Workflow

```
SQL Server Original
        ↓
    AWS SCT
        ↓
[THIS DIRECTORY] ← You are here
        ↓
Manual Review & Analysis
        ↓
Corrected Version
        ↓
Production
```

---

## 🔍 What To Expect Here

Each file in this directory:
- ✅ Has valid PostgreSQL syntax (mostly)
- ✅ Preserves original business logic
- ❌ NOT tested
- ❌ NOT performance-optimized
- ❌ NOT production-ready

**Next Step:** Each procedure must go through 4-phase workflow (Analysis → Correction → Validation → Deployment)

---

## 📁 File Naming Convention

Original (SQL Server):
```
ReconcileMUpstream.sql
```

AWS SCT Output (This Directory):
```
reconcilemupstream.sql
```

Notes:
- All lowercase
- Same name as original (case-insensitive match)
- .sql extension

---

## 🛠️ How To Use

1. **Extract from SQL Server:**
   ```bash
   # Use SSMS or sqlcmd to export procedure
   ```

2. **Run AWS SCT:**
   ```bash
   # Use AWS SCT GUI or CLI to convert
   ```

3. **Save Output Here:**
   ```bash
   cp converted-output.sql procedures/aws-sct-converted/procedurename.sql
   ```

4. **Create Analysis:**
   ```bash
   # Use analysis template in /templates/
   # Compare with original
   # Identify issues
   ```

5. **Track Progress:**
   ```bash
   # Update tracking/progress-tracker.md
   # Update priority-matrix.csv
   ```

---

## 🎯 Quality Expectations

AWS SCT output typically scores:
- **Syntax:** 8-9/10 (mostly valid PostgreSQL)
- **Logic:** 7-8/10 (business logic preserved)
- **Performance:** 5-7/10 (not optimized)
- **Production-Ready:** 3-5/10 (needs manual fixes)

**Average Quality Score:** 6-7/10

**Target After Manual Review:** 9-10/10

---

## 📊 Current Inventory - **16 FILES AVAILABLE** ✅

| # | Procedure | Converted Date | Status | Priority |
|---|-----------|----------------|--------|----------|
| 1 | addarc.sql | 2025-11-13 | ✅ Available | P1 |
| 2 | getmaterialbyrunproperties.sql | 2025-11-13 | ✅ Available | P1 |
| 3 | linkunlinkedmaterials.sql | 2025-11-13 | ✅ Available | P3 |
| 4 | materialtotransition.sql | 2025-11-13 | ✅ Available | P2 |
| 5 | movecontainer.sql | 2025-11-13 | ✅ Available | P3 |
| 6 | movegootype.sql | 2025-11-13 | ✅ Available | P3 |
| 7 | processdirtytrees.sql | 2025-11-13 | ✅ Available | P1 |
| 8 | processsomemupstream.sql | 2025-11-13 | ✅ Available | P1 |
| 9 | reconcilemupstream.sql | 2025-11-13 | ✅ Analyzed | P1 |
| 10 | removearc.sql | 2025-11-13 | ✅ Available | P1 |
| 11 | transitiontomaterial.sql | 2025-11-13 | ✅ Available | P2 |
| 12 | sp_move_node.sql | 2025-11-13 | ✅ Available | P2 |
| 13 | usp_updatecontainertypefromargus.sql | 2025-11-13 | ✅ Available | P3 |
| 14 | usp_updatemdownstream.sql | 2025-11-13 | ✅ Available | P1 |
| 15 | usp_updatemupstream.sql | 2025-11-13 | ✅ Available | P1 |
| 16 | README.md | 2025-11-13 | ✅ Documentation | - |

**Total:** 15 SQL procedures + 1 README = 16 files

**Conversion Date:** All converted on 2025-11-13 via AWS SCT batch operation

**Next Action:** Begin systematic analysis starting with P1 procedures

---

## 🚨 NEVER Deploy From This Directory

**CRITICAL RULE:** Files in this directory are **NEVER deployed directly** to any environment (DEV/QA/PROD).

All files must first:
1. Be analyzed (→ procedures/analysis/)
2. Be corrected (→ procedures/corrected/)
3. Pass validation tests
4. Get approval from DBA/DBRE

---

## 📚 Related Documentation

- Original T-SQL procedures: `../original/`
- Analysis reports: `../analysis/`
- Production-ready versions: `../corrected/`
- Project plan: `/docs/PROJECT-PLAN.md`
- Analysis template: `/templates/analysis-template.md`
- Priority matrix: `/tracking/priority-matrix.csv`

---

**Maintained by:** Pierre Ribeiro (DBA/DBRE)  
**Last Updated:** 2025-11-13  
**Version:** 1.1  
**Status:** 🟢 16 FILES AVAILABLE - READY FOR ANALYSIS
