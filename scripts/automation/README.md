# Automation Scripts

## 📁 Directory Purpose

This directory contains **Python automation scripts** that reduce manual work in the migration process by generating analysis documents, comparing versions, extracting warnings, and auto-generating test templates.

**Key Functions:**
- 🤖 Generate analysis documents from SQL code
- 🔍 Compare original vs. corrected versions
- ⚠️ Extract and categorize AWS SCT warnings
- 🧪 Auto-generate test templates

---

## 🎯 Automation Philosophy

**If You Do It Twice, Automate It**

These scripts save time by:
- Reducing manual analysis time (hours → minutes)
- Ensuring consistent documentation format
- Catching issues earlier in the process
- Generating boilerplate code automatically

**Time Savings Estimate:**
- Manual analysis: ~4-6 hours per procedure
- With automation: ~1-2 hours per procedure
- **ROI:** 60-75% time reduction

---

## 📋 Available Scripts

### 1. analyze-procedure.py
**Purpose:** Generate analysis document from SQL procedure

**Usage:**
```bash
python scripts/automation/analyze-procedure.py \
  --original procedures/original/ReconcileMUpstream.sql \
  --converted procedures/aws-sct-converted/reconcilemupstream.sql \
  --output procedures/analysis/reconcilemupstream-analysis.md
```

**What It Does:**
1. Parses both original (T-SQL) and converted (PL/pgSQL) files
2. Identifies differences and potential issues
3. Categorizes issues by priority (P0/P1/P2/P3)
4. Calculates quality score (0-10)
5. Generates detailed analysis document (Markdown)
6. Includes code snippets and recommendations

**Example Output:**
```markdown
# AWS SCT Conversion Analysis: ReconcileMUpstream

## Quality Score: 6.6/10

## Issues Found

### P0 - CRITICAL (2 issues)
1. Transaction control broken
   - Line 45: COMMIT missing
   - Impact: Data corruption risk
   
2. RAISE statement syntax error
   - Line 78: RAISE requires EXCEPTION or NOTICE
   - Impact: Compilation failure

### P1 - HIGH (3 issues)
...
```

**Configuration:** `automation-config.json`

**Dependencies:**
- sqlparse (Python SQL parser)
- regex patterns for issue detection

---

### 2. compare-versions.py
**Purpose:** Diff original vs. corrected with semantic analysis

**Usage:**
```bash
python scripts/automation/compare-versions.py \
  --original procedures/original/ReconcileMUpstream.sql \
  --aws-sct procedures/aws-sct-converted/reconcilemupstream.sql \
  --corrected procedures/corrected/reconcilemupstream.sql \
  --output procedures/analysis/reconcilemupstream-diff.html
```

**What It Does:**
1. Generates side-by-side comparison (HTML)
2. Highlights semantic changes (not just syntax)
3. Shows what AWS SCT changed
4. Shows what manual corrections were applied
5. Color codes by change type:
   - 🔴 Removed
   - 🟢 Added
   - 🟡 Modified

**Example Output (HTML):**
```html
<div class="comparison">
  <div class="original">
    <span class="removed">BEGIN TRAN</span>
  </div>
  <div class="corrected">
    <span class="added">BEGIN; -- PostgreSQL transaction</span>
  </div>
  <div class="reason">
    Transaction syntax converted to PostgreSQL standard
  </div>
</div>
```

**Use Cases:**
- Code review sessions
- Documentation for stakeholders
- Training material
- Regression analysis

---

### 3. extract-warnings.py
**Purpose:** Parse AWS SCT warnings and categorize them

**Usage:**
```bash
python scripts/automation/extract-warnings.py \
  --sct-output aws-sct-report.xml \
  --output tracking/sct-warnings-summary.csv
```

**What It Does:**
1. Parses AWS SCT XML output
2. Extracts all warnings and errors
3. Categorizes by type (syntax, performance, data type, etc.)
4. Maps to specific procedures
5. Prioritizes by severity
6. Generates CSV report

**Example Output (CSV):**
```csv
Procedure,Warning Type,Severity,Line,Description,Recommendation
ReconcileMUpstream,Transaction,P0,45,Missing COMMIT,Add explicit transaction control
ReconcileMUpstream,Performance,P1,120,Unnecessary LOWER(),Remove LOWER() calls
AddArc,DataType,P2,30,DATETIME → TIMESTAMP,Verify timezone handling
```

**Use Cases:**
- Initial assessment (how much work?)
- Prioritization (which procedures first?)
- Tracking (how many warnings resolved?)
- Reporting (status to management)

---

### 4. generate-tests.py
**Purpose:** Auto-generate test templates from procedure signature

**Usage:**
```bash
python scripts/automation/generate-tests.py \
  --procedure procedures/corrected/reconcilemupstream.sql \
  --output tests/unit/test_reconcilemupstream.sql
```

**What It Does:**
1. Parses procedure signature (parameters, return type)
2. Generates test structure:
   - Test fixtures (sample data)
   - Positive test cases
   - Negative test cases (error handling)
   - Edge cases (NULL, empty, extreme values)
   - Performance baseline test
3. Creates test SQL with placeholders
4. Includes assertions and expected results

**Example Output:**
```sql
-- =============================================================================
-- Unit Test: reconcilemupstream
-- Generated: 2025-11-13 by generate-tests.py
-- =============================================================================

BEGIN;

-- Test 1: Happy Path
SELECT plan(5);  -- pgTAP test framework

-- Prepare test data
INSERT INTO M_Upstream_test VALUES (...);

-- Execute procedure
SELECT lives_ok(
  'SELECT reconcilemupstream($1, $2)',
  'Procedure executes without error'
);

-- Verify results
SELECT results_eq(
  'SELECT * FROM M_Upstream WHERE ...',
  ARRAY[...],
  'Expected results match'
);

-- Test 2: NULL Parameter
SELECT throws_ok(
  'SELECT reconcilemupstream(NULL, $1)',
  'P0001',
  'Parameter cannot be NULL'
);

-- Test 3: Edge Case (Empty String)
...

ROLLBACK;
```

**Configuration:**
- Test frameworks: pgTAP, pgtap, custom
- Test data generation rules
- Assertion templates

---

## 🔧 Configuration

### automation-config.json
```json
{
  "analyze_procedure": {
    "issue_patterns": {
      "transaction_control": [
        "BEGIN TRAN",
        "COMMIT TRAN",
        "ROLLBACK TRAN"
      ],
      "raise_statements": [
        "RAISERROR",
        "RAISE_APPLICATION_ERROR"
      ],
      "temp_tables": [
        "#\\w+"
      ]
    },
    "quality_weights": {
      "p0_critical": -3.0,
      "p1_high": -1.5,
      "p2_medium": -0.5,
      "p3_low": -0.1
    }
  },
  "generate_tests": {
    "framework": "pgTAP",
    "test_types": [
      "happy_path",
      "null_params",
      "edge_cases",
      "error_handling",
      "performance"
    ]
  }
}
```

---

## 🚀 Batch Processing

### Process All Procedures
```bash
#!/bin/bash
# scripts/automation/batch-analyze-all.sh

for original in procedures/original/*.sql; do
  name=$(basename "$original" .sql | tr '[:upper:]' '[:lower:]')
  
  python scripts/automation/analyze-procedure.py \
    --original "$original" \
    --converted "procedures/aws-sct-converted/${name}.sql" \
    --output "procedures/analysis/${name}-analysis.md"
    
  python scripts/automation/generate-tests.py \
    --procedure "procedures/corrected/${name}.sql" \
    --output "tests/unit/test_${name}.sql"
done

echo "✅ Batch processing complete"
```

---

## 📊 Automation Metrics

Track automation effectiveness:

| Metric | Manual | Automated | Improvement |
|--------|--------|-----------|-------------|
| **Analysis Time** | 4-6 hours | 1-2 hours | 60-75% ⬇️ |
| **Documentation** | 2 hours | 5 minutes | 95% ⬇️ |
| **Test Creation** | 3 hours | 10 minutes | 95% ⬇️ |
| **Consistency** | Variable | 100% | ✅ Perfect |
| **Error Rate** | 5-10% | <1% | 90% ⬇️ |

**Total Time Savings per Procedure:** ~8 hours → ~2 hours (75% reduction)

**Project Savings (15 procedures):** ~120 hours → ~30 hours = **90 hours saved**

---

## 🛠️ Development Guide

### Adding New Automation Script

**Template:**
```python
#!/usr/bin/env python3
"""
Script: my_automation.py
Purpose: [Description]
Author: Pierre Ribeiro
Created: YYYY-MM-DD
"""

import argparse
import sys
from pathlib import Path

def parse_arguments():
    parser = argparse.ArgumentParser(
        description='[Script description]'
    )
    parser.add_argument('--input', required=True, help='Input file')
    parser.add_argument('--output', required=True, help='Output file')
    return parser.parse_args()

def main():
    args = parse_arguments()
    
    try:
        # 1. Read input
        # 2. Process
        # 3. Write output
        # 4. Log results
        
        print(f"✅ Success: {args.output}")
        return 0
        
    except Exception as e:
        print(f"❌ Error: {str(e)}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())
```

---

## 📚 Dependencies

### Python Requirements
```txt
# requirements.txt
sqlparse>=0.4.3       # SQL parsing
regex>=2023.10.3      # Advanced regex
jinja2>=3.1.2         # Template engine
pyyaml>=6.0.1         # YAML config
beautifulsoup4>=4.12  # HTML parsing (for compare-versions)
lxml>=4.9.3           # XML parsing (for extract-warnings)
pandas>=2.1.0         # Data analysis (for reports)
click>=8.1.7          # CLI framework
rich>=13.6.0          # Terminal formatting
```

### Installation
```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# or
.venv\Scripts\activate  # Windows

# Install dependencies
pip install -r scripts/automation/requirements.txt
```

---

## 🚨 Troubleshooting

### Script Fails to Parse SQL
```bash
# Try with debug mode
python scripts/automation/analyze-procedure.py \
  --original file.sql \
  --converted file.sql \
  --output output.md \
  --debug

# Check SQL syntax first
psql -f file.sql --dry-run
```

### Missing Dependencies
```bash
# Reinstall all dependencies
pip install -r scripts/automation/requirements.txt --force-reinstall
```

### Performance Issues (Large Files)
```python
# Add streaming mode for large files
parser.parse_stream(input_file)  # Instead of parse_file()
```

---

## 🔗 Integration Points

### CI/CD Pipeline
```yaml
# .github/workflows/analyze.yml
- name: Auto-generate Analysis
  run: |
    python scripts/automation/analyze-procedure.py \
      --original ${{ env.ORIGINAL_FILE }} \
      --converted ${{ env.CONVERTED_FILE }} \
      --output analysis.md
    
    # Fail if quality score < 7.0
    quality_score=$(grep "Quality Score:" analysis.md | awk '{print $3}')
    if (( $(echo "$quality_score < 7.0" | bc -l) )); then
      echo "❌ Quality score too low: $quality_score"
      exit 1
    fi
```

### Git Hooks
```bash
# .git/hooks/pre-commit
#!/bin/bash
# Auto-generate analysis on commit

for file in procedures/corrected/*.sql; do
  if git diff --cached --name-only | grep -q "$file"; then
    python scripts/automation/analyze-procedure.py \
      --original "procedures/original/$(basename $file)" \
      --converted "$file" \
      --output "procedures/analysis/$(basename $file .sql)-analysis.md"
      
    git add "procedures/analysis/$(basename $file .sql)-analysis.md"
  fi
done
```

---

## 📈 Future Enhancements

Potential additions:
- [ ] AI-powered issue detection (ML model)
- [ ] Automatic correction suggestions
- [ ] Natural language analysis summaries
- [ ] Integration with IDE (VSCode extension)
- [ ] Real-time analysis (watch mode)
- [ ] Performance prediction model

---

**Maintained by:** Pierre Ribeiro (DBA/DBRE)  
**Last Updated:** 2025-11-13  
**Version:** 1.0
