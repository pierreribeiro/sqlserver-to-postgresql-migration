# Original T-SQL Procedures

This directory contains the **original stored procedures** extracted from SQL Server Enterprise 2014.

## 📋 Purpose

These files serve as the **source of truth** for the conversion process. They are read-only reference files.

## 📁 Expected Contents

Place all extracted T-SQL procedures here with `.sql` extension:

- ReconcileMUpstream.sql
- AddArc.sql
- GetMaterialByRunProperties.sql  
- [... other procedures]

## 🔧 Extraction Method

### Option 1: SQL Server Management Studio (SSMS)

```
1. Connect to SQL Server
2. Navigate to: Databases → perseus → Programmability → Stored Procedures
3. Right-click procedure → Script As → CREATE To → File
4. Save to this directory
5. Repeat for all procedures
```

### Option 2: Automated Script

```sql
-- Generate all procedures at once
SELECT OBJECT_DEFINITION(object_id) 
FROM sys.procedures 
WHERE schema_id = SCHEMA_ID('dbo');
```

## ⚠️ Important Rules

- **DO NOT** modify files in this directory
- **DO NOT** commit credentials or sensitive data
- **DO** preserve original formatting and comments
- **DO** name files consistently (lowercase, underscores)

## 📊 Current Status

**Total Procedures:** 15  
**Extracted:** 1 (ReconcileMUpstream)  
**Pending:** 14

| Procedure | Status | Date Extracted |
|-----------|--------|----------------|
| ReconcileMUpstream | ✅ Extracted | 2025-11-12 |
| AddArc | ⏳ Pending | - |
| GetMaterialByRunProperties | ⏳ Pending | - |
| [others] | ⏳ Pending | - |

---

**Last Updated:** 2025-11-12  
**Maintained By:** Pierre Ribeiro