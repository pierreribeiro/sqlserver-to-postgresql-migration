# Execution Guide: Optimized Data Extraction

**Date**: 2026-02-04
**Status**: ✅ READY FOR EXECUTION
**Optimization**: Large table timeout fix applied

---

## Pre-Flight Checklist

### 1. Verify Optimization Changes ✅
```bash
cd /Users/pierre.ribeiro/.claude-worktrees/US3-table-structures/scripts/data-migration
./verify-optimization.sh
```

**Expected Output**: All 7 tests PASS

### 2. Check Environment
```bash
# Verify sqlcmd (SQL Server command-line tool)
sqlcmd -?

# Verify bcp (Bulk Copy Program)
bcp -v

# Verify connection to SQL Server
sqlcmd -S <server> -d perseus -Q "SELECT @@VERSION"

# Check available disk space (requires ~15GB)
df -h /tmp
```

### 3. Clean Previous Failed Runs
```bash
# Remove old CSV files
rm -rf /tmp/perseus-data-export/*.csv

# Remove old marker files
rm -f .export-ready-*

# Check logs directory
ls -lh logs/
```

---

## Execution Steps

### Step 1: Start Extraction (Main Terminal)
```bash
cd /Users/pierre.ribeiro/.claude-worktrees/US3-table-structures/scripts/data-migration

# Run extraction with optimized settings
./extract-data.sh
```

**Expected Timeline**:
- Start: T+0min
- SQL extraction (Tiers 0-4): T+10min
- CSV export start: T+10min
- m_upstream export complete: T+100min (1h40min)
- All exports complete: T+140min (2h20min)
- Total time: ~2h20min (within 4h30min keepalive)

### Step 2: Monitor Progress (Terminal 2)
```bash
# Watch log file in real-time
tail -f logs/extract-data-$(date +%Y%m%d)*.log
```

**Key Log Messages to Watch For**:
```
[TIMESTAMP] Started exporting m_upstream
[TIMESTAMP] Completed m_upstream
[TIMESTAMP] All tiers (0-4) CSV export completed
```

### Step 3: Monitor CSV Creation (Terminal 3)
```bash
# Watch CSV files being created
watch -n 30 'ls -lh /tmp/perseus-data-export/*.csv | tail -15'
```

**Expected CSV Sizes**:
- m_upstream: ~5-6GB (reduced from 16GB)
- Scraper: ~10MB (reduced from 11.7GB)
- m_downstream: ~448MB
- Others: Various small sizes

### Step 4: Track m_upstream Specifically (Terminal 4)
```bash
# Monitor m_upstream export progress
watch -n 60 'ls -lh /tmp/perseus-data-export/*m_upstream.csv 2>/dev/null || echo "Not started yet"'
```

---

## Success Criteria

### During Execution
- ✅ No Python exceptions in log
- ✅ No SQL timeout errors
- ✅ CSV files steadily appearing in /tmp/perseus-data-export/
- ✅ m_upstream export completes within 100 minutes

### After Completion
```bash
# 1. Check exit code
echo $?
# Expected: 0

# 2. Count CSV files
ls -1 /tmp/perseus-data-export/*.csv | wc -l
# Expected: 76 files

# 3. Verify m_upstream size
ls -lh /tmp/perseus-data-export/*m_upstream.csv
# Expected: ~5-6GB

# 4. Verify Scraper size
ls -lh /tmp/perseus-data-export/*Scraper.csv
# Expected: ~10MB

# 5. Check total export size
du -sh /tmp/perseus-data-export/
# Expected: ~10-15GB

# 6. Verify m_upstream row count
wc -l /tmp/perseus-data-export/##perseus_tier_0_m_upstream.csv
# Expected: ~34 million rows

# 7. Verify Scraper row count
wc -l /tmp/perseus-data-export/##perseus_tier_0_Scraper.csv
# Expected: ~9,000 rows

# 8. Check final log message
tail -5 logs/extract-data-$(date +%Y%m%d)*.log
# Expected: "All tiers (0-4) CSV export completed"
```

---

## Troubleshooting

### Issue 1: Still Timing Out
**Symptom**: m_upstream export exceeds 100 minutes

**Action**: Further reduce sample rate to 3%
```sql
-- Edit extract-tier-0.sql line 338
TABLESAMPLE(3 PERCENT) REPEATABLE(42);  -- 20M rows, ~3GB, ~54min
```

**Re-run**:
```bash
rm -rf /tmp/perseus-data-export/*.csv
./extract-data.sh
```

### Issue 2: SQL Connection Lost
**Symptom**: Log shows "Connection reset" or "Named pipe" errors

**Action**: Check SQL Server connectivity
```bash
sqlcmd -S <server> -d perseus -Q "SELECT @@SPID"
```

**If needed**: Increase keepalive timeout in .env
```bash
# Edit .env
MSSQL_KEEPALIVE_TIMEOUT=300  # 5 hours
```

### Issue 3: Disk Space Full
**Symptom**: "No space left on device" error

**Action**: Clean temporary files
```bash
# Check space
df -h /tmp

# Clean old exports
rm -rf /tmp/perseus-data-export-old/
rm -rf /tmp/*.csv

# Or use different export directory
export EXPORT_DIR=/data/perseus-export
./extract-data.sh
```

### Issue 4: Scraper Export Fails
**Symptom**: Scraper CSV not created or error in log

**Action**: Verify File column is NULL
```bash
# Check extract-tier-0.sql
grep -A 5 "CAST(NULL AS varbinary" extract-tier-0.sql
# Should show: CAST(NULL AS varbinary(max)) AS File
```

### Issue 5: BCP Export Hangs
**Symptom**: No progress after SQL extraction complete

**Action**: Check bcp process and SQL session
```bash
# Check running bcp processes
ps aux | grep bcp

# Check SQL session still alive
sqlcmd -S <server> -d tempdb -Q "SELECT * FROM sys.dm_exec_sessions WHERE session_id = <SPID>"

# If hung, check temp tables still exist
sqlcmd -S <server> -d tempdb -Q "SELECT name FROM sys.tables WHERE name LIKE '##perseus_tier_%'"

# If BCP hung, kill and check SQL session
pkill -f "bcp.*perseus"
```

---

## Post-Execution Validation

### 1. Data Quality Checks
```bash
# Verify CSV integrity (no truncated files)
for csv in /tmp/perseus-data-export/*.csv; do
    if ! tail -1 "$csv" | grep -q '[[:print:]]'; then
        echo "WARNING: $csv may be truncated"
    fi
done

# Check for empty CSV files
find /tmp/perseus-data-export/ -name "*.csv" -size 0
# Expected: No output (no empty files)

# Validate CSV format (spot check)
head -5 /tmp/perseus-data-export/##perseus_tier_0_m_upstream.csv
```

### 2. Performance Metrics
```bash
# Extract timing from log
grep -E "(Started exporting|Completed)" logs/extract-data-*.log | grep m_upstream
# Calculate: Completed time - Started time = Export time

# Compare to projections
# Expected: ~90 minutes (vs 4h20min before)
```

### 3. Document Results
```bash
# Create completion report
cat > EXTRACTION-COMPLETION-REPORT.md <<EOF
# Data Extraction Completion Report

**Date**: $(date +%Y-%m-%d)
**Total Time**: <INSERT_ACTUAL_TIME>
**Status**: ✅ SUCCESS / ❌ FAILED

## Statistics
- CSV Files Created: $(ls -1 /tmp/perseus-data-export/*.csv | wc -l)
- Total Export Size: $(du -sh /tmp/perseus-data-export/ | cut -f1)
- m_upstream Size: $(ls -lh /tmp/perseus-data-export/*m_upstream.csv | awk '{print $5}')
- m_upstream Rows: $(wc -l /tmp/perseus-data-export/*m_upstream.csv | awk '{print $1}')
- Scraper Size: $(ls -lh /tmp/perseus-data-export/*Scraper.csv | awk '{print $5}')
- Scraper Rows: $(wc -l /tmp/perseus-data-export/*Scraper.csv | awk '{print $1}')

## Performance vs. Projections
- m_upstream export: <ACTUAL> vs 90min projected
- Total time: <ACTUAL> vs 140min projected
- Optimization impact: <CALCULATE_%_IMPROVEMENT>

## Issues Encountered
<NONE / LIST_ISSUES>

## Next Steps
- [ ] Copy CSV files to PostgreSQL server
- [ ] Update progress tracker
- [ ] Proceed to PostgreSQL data load phase
EOF
```

---

## Next Phase: PostgreSQL Data Load

Once extraction is successful:

### 1. Copy CSV Files to PostgreSQL Server
```bash
# Option A: Direct copy (if on same network)
scp /tmp/perseus-data-export/*.csv postgres-server:/data/perseus-import/

# Option B: Compress and transfer
cd /tmp/perseus-data-export
tar -czf perseus-data-export.tar.gz *.csv
scp perseus-data-export.tar.gz postgres-server:/data/
# On postgres-server:
# tar -xzf perseus-data-export.tar.gz -C /data/perseus-import/
```

### 2. Verify CSV Files on PostgreSQL Server
```bash
# On PostgreSQL server
ls -lh /data/perseus-import/*.csv | wc -l
# Expected: 76 files

du -sh /data/perseus-import/
# Expected: ~10-15GB
```

### 3. Prepare PostgreSQL Schema
```bash
# Create schema and tables first
psql -d perseus_dev -f source/building/pgsql/refactored/14.\ create-table/*.sql
```

### 4. Load Data with COPY
```bash
# Create load script
cat > load-data.sh <<'EOF'
#!/bin/bash
for csv in /data/perseus-import/*.csv; do
    table_name=$(basename "$csv" .csv | sed 's/##perseus_tier_[0-9]_//')
    echo "Loading: $table_name from $csv"
    psql -d perseus_dev -c "\\COPY $table_name FROM '$csv' WITH CSV HEADER"
done
EOF

chmod +x load-data.sh
./load-data.sh
```

---

## Emergency Procedures

### If Extraction Fails Completely
1. Check logs for specific error: `tail -100 logs/extract-data-*.log`
2. Verify SQL Server connection: `sqlcmd -S <server> -d perseus -Q "SELECT 1"`
3. Check extract-tier-0.sql syntax: `sqlcmd -S <server> -d perseus -i extract-tier-0.sql`
4. Verify .env configuration: `cat .env`
5. Review Python dependencies: `pip3 list | grep mssql`

### If Need to Restart Mid-Extraction
1. Identify last completed tier from log
2. Comment out completed tiers in extract-data.sh
3. Remove incomplete CSV files: `rm -f /tmp/perseus-data-export/*tier_X*.csv`
4. Re-run: `./extract-data.sh`

### If Need to Cancel Extraction
```bash
# Find process ID
ps aux | grep extract-data

# Kill gracefully
pkill -TERM -f extract-data.sh

# Force kill if needed
pkill -KILL -f extract-data.sh

# Clean up
rm -f .export-ready-*
```

---

## Contact & Support

**Issues**: Check logs first: `logs/extract-data-*.log`

**Tools Required**:
- `sqlcmd` - SQL Server command-line tool (execute SQL scripts, query database)
- `bcp` - Bulk Copy Program (export temp tables to CSV files)
- Both tools are part of: SQL Server Command Line Tools (mssql-tools)

**Questions**: Review documentation:
- LARGE-TABLE-OPTIMIZATION-IMPLEMENTATION.md
- PRODUCTION-SAFE-MIGRATION-SUMMARY.md
- README.md

**Success**: Update progress tracker and proceed to PostgreSQL load phase

---

**Prepared by**: Claude Code (Sonnet 4.5)
**Date**: 2026-02-04
**Version**: 1.0
**Status**: READY FOR EXECUTION
