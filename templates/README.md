# Templates

## 📁 Directory Purpose

This directory contains **reusable templates** for creating consistent documentation, procedures, and tests across the migration project.

**Goal:** Standardize formats and reduce manual work

---

## 📋 Available Templates

### 1. analysis-template.md
**Purpose:** Template for procedure analysis documents

**Usage:**
```bash
# Copy template
cp templates/analysis-template.md procedures/analysis/procedure_name-analysis.md

# Fill in sections
# - Quality scorecard
# - Issue breakdown (P0/P1/P2/P3)
# - Corrected code
# - Recommendations
```

**Sections:**
- Executive Summary
- Quality Scorecard (0-10 scale)
- Original Code (T-SQL)
- AWS SCT Output (PL/pgSQL)
- Issue Analysis
  - P0 Critical Issues
  - P1 High Priority Issues
  - P2 Medium Priority Issues
  - P3 Low Priority Issues
- Corrected Code (Production-Ready)
- Performance Considerations
- Testing Recommendations
- Deployment Checklist
- Change Log

---

### 2. procedure-template.sql
**Purpose:** PostgreSQL procedure skeleton with best practices

**Usage:**
```bash
# Copy template
cp templates/procedure-template.sql procedures/corrected/procedure_name.sql

# Customize
# - Replace placeholders
# - Add business logic
# - Update documentation
```

**Structure:**
```sql
-- =============================================================================
-- Procedure: schema.procedure_name
-- Description: [Brief description]
-- 
-- Author: Pierre Ribeiro (DBA/DBRE)
-- Created: YYYY-MM-DD
-- Modified: YYYY-MM-DD
-- 
-- Quality Score: [X.X/10]
-- Original: SQL Server T-SQL
-- Converted: AWS SCT + Manual Review
-- 
-- Dependencies:
--   - Tables: [list]
--   - Other procedures: [list]
--   - Functions: [list]
-- 
-- Parameters:
--   IN p_param1 TYPE - Description
--   OUT p_result TYPE - Description
-- 
-- Returns: [Description]
-- 
-- Example Usage:
--   SELECT * FROM schema.procedure_name(param1, param2);
-- 
-- Change Log:
--   YYYY-MM-DD - Initial PostgreSQL version
-- =============================================================================

CREATE OR REPLACE FUNCTION schema.procedure_name(
    p_param1 INT,
    p_param2 VARCHAR(100)
)
RETURNS TABLE(
    result_id INT,
    result_name VARCHAR(100)
)
LANGUAGE plpgsql
SECURITY DEFINER  -- or INVOKER
AS $$
DECLARE
    -- Variable declarations
    v_count INT;
    v_status VARCHAR(50);
BEGIN
    -- Logging (optional)
    RAISE NOTICE 'procedure_name: Starting execution';
    
    -- Input validation
    IF p_param1 IS NULL THEN
        RAISE EXCEPTION 'Parameter p_param1 cannot be NULL'
            USING ERRCODE = 'P0001',
                  HINT = 'Provide a valid value for p_param1';
    END IF;
    
    -- Main logic
    RETURN QUERY
    SELECT 
        id,
        name
    FROM target_table
    WHERE condition = p_param1;
    
    -- Logging (optional)
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'procedure_name: Returned % rows', v_count;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Error handling
        RAISE EXCEPTION 'procedure_name failed: %', SQLERRM
            USING ERRCODE = SQLSTATE,
                  HINT = 'Check input parameters and database state';
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION schema.procedure_name(INT, VARCHAR) TO appropriate_role;

-- Add comment
COMMENT ON FUNCTION schema.procedure_name(INT, VARCHAR) IS 
'[Brief description for system catalog]';

-- =============================================================================
-- Usage Examples:
-- =============================================================================

-- Example 1: Basic usage
-- SELECT * FROM schema.procedure_name(123, 'Active');

-- Example 2: Error handling
-- DO $$
-- BEGIN
--     PERFORM schema.procedure_name(NULL, 'Active');
-- EXCEPTION
--     WHEN OTHERS THEN
--         RAISE NOTICE 'Caught error: %', SQLERRM;
-- END $$;
```

---

### 3. test-unit-template.sql
**Purpose:** pgTAP unit test template

**Usage:**
```bash
# Copy template
cp templates/test-unit-template.sql tests/unit/test_procedure_name.sql

# Customize test cases
```

**Structure:**
```sql
-- =============================================================================
-- Unit Test: schema.procedure_name
-- Author: Pierre Ribeiro
-- Created: YYYY-MM-DD
-- Framework: pgTAP
-- =============================================================================

BEGIN;

SELECT plan(10);

-- TEST SETUP
CREATE SCHEMA IF NOT EXISTS test;
SET search_path TO test, public;

-- Create mock tables
-- ...

-- TEST 1: Happy Path
SELECT lives_ok(
    'SELECT * FROM schema.procedure_name(1, ''test'')',
    'Procedure executes without error'
);

-- TEST 2: NULL handling
SELECT throws_ok(
    'SELECT * FROM schema.procedure_name(NULL, ''test'')',
    'P0001',
    'Parameter cannot be NULL'
);

-- More tests...

SELECT * FROM finish();

ROLLBACK;
```

---

### 4. test-integration-template.sql
**Purpose:** Integration test workflow template

**Usage:**
```bash
# Copy template
cp templates/test-integration-template.sql tests/integration/test_workflow_name.sql

# Define workflow steps
```

**Structure:**
```sql
-- =============================================================================
-- Integration Test: [Workflow Name]
-- Author: Pierre Ribeiro
-- Created: YYYY-MM-DD
-- =============================================================================

BEGIN;

SELECT plan(20);

-- SETUP
SET search_path TO perseus, public;

-- Clean test data
-- ...

-- Insert test dataset
-- ...

-- WORKFLOW STEP 1
SELECT lives_ok(
    'SELECT * FROM procedure_1(...)',
    'Step 1: procedure_1 executes'
);

-- Verify step 1 results
-- ...

-- WORKFLOW STEP 2
SELECT lives_ok(
    'SELECT * FROM procedure_2(...)',
    'Step 2: procedure_2 executes'
);

-- VALIDATION
-- ...

-- CLEANUP
-- ...

SELECT * FROM finish();

ROLLBACK;
```

---

## 🛠️ Using Templates

### Manual Approach
```bash
# 1. Copy template
cp templates/analysis-template.md procedures/analysis/myproc-analysis.md

# 2. Open in editor
code procedures/analysis/myproc-analysis.md

# 3. Search and replace placeholders
# - [PROCEDURE_NAME] → myproc
# - [DATE] → 2025-11-13
# - [AUTHOR] → Pierre Ribeiro

# 4. Fill in content
```

### Automated Approach
```bash
# Use script to generate from template
python scripts/automation/generate-from-template.py \
  --template templates/analysis-template.md \
  --output procedures/analysis/myproc-analysis.md \
  --replace "PROCEDURE_NAME=myproc" \
  --replace "DATE=$(date +%Y-%m-%d)" \
  --replace "AUTHOR=Pierre Ribeiro"
```

---

## 📝 Template Placeholders

### Common Placeholders
- `[PROCEDURE_NAME]` - Name of the procedure
- `[DATE]` - Current date (YYYY-MM-DD)
- `[AUTHOR]` - Author name
- `[SCHEMA]` - Database schema
- `[DESCRIPTION]` - Brief description
- `[QUALITY_SCORE]` - Quality score (0-10)
- `[SQL_SERVER_BASELINE]` - Performance baseline
- `[PARAMETERS]` - Parameter list
- `[DEPENDENCIES]` - Dependency list

### Example Replacement
```bash
# Before
CREATE OR REPLACE FUNCTION [SCHEMA].[PROCEDURE_NAME]

# After
CREATE OR REPLACE FUNCTION perseus.reconcilemupstream
```

---

## 🎯 Template Best Practices

### 1. Keep Templates Updated
```bash
# Review templates quarterly
# Add improvements from real procedures
# Remove sections that are never used
# Add new sections as patterns emerge
```

### 2. Version Control
```bash
# Track template changes
git log templates/procedure-template.sql

# Compare versions
git diff HEAD~1 templates/procedure-template.sql
```

### 3. Validate Templates
```bash
# Ensure templates are syntactically valid
psql -f templates/procedure-template.sql --dry-run

# Test template-generated code
psql -f generated_from_template.sql
```

---

## 📚 Adding New Templates

### Template Creation Guide

**Step 1: Identify Pattern**
- Notice repetitive work
- Extract common structure
- Identify variable parts

**Step 2: Create Template**
```bash
# Create new template file
touch templates/new-template.sql

# Add standard header
# Add placeholder sections
# Document usage
```

**Step 3: Document Template**
```markdown
# Add to this README.md

### X. new-template.sql
**Purpose:** [Description]
**Usage:** [How to use]
**Structure:** [What it contains]
```

**Step 4: Test Template**
```bash
# Generate file from template
# Verify it works
# Collect feedback
# Iterate
```

---

## 🔗 Template Automation

### generate-from-template.py
```python
#!/usr/bin/env python3
"""
Generate file from template with variable substitution
"""

import argparse
import sys
from pathlib import Path

def generate_from_template(template_path, output_path, replacements):
    # Read template
    with open(template_path, 'r') as f:
        content = f.read()
    
    # Apply replacements
    for old, new in replacements.items():
        content = content.replace(f'[{old}]', new)
    
    # Write output
    with open(output_path, 'w') as f:
        f.write(content)
    
    print(f"✅ Generated: {output_path}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--template', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--replace', action='append', required=True)
    
    args = parser.parse_args()
    
    # Parse replacements (KEY=VALUE format)
    replacements = {}
    for item in args.replace:
        key, value = item.split('=', 1)
        replacements[key] = value
    
    generate_from_template(
        args.template,
        args.output,
        replacements
    )
```

**Usage:**
```bash
python scripts/automation/generate-from-template.py \
  --template templates/procedure-template.sql \
  --output procedures/corrected/myproc.sql \
  --replace "PROCEDURE_NAME=myproc" \
  --replace "SCHEMA=perseus" \
  --replace "DATE=$(date +%Y-%m-%d)"
```

---

## 📊 Template Usage Tracking

### Track Which Templates Are Used
```bash
# Count files generated from each template
echo "analysis-template.md: $(ls procedures/analysis/*-analysis.md | wc -l)"
echo "procedure-template.sql: $(ls procedures/corrected/*.sql | wc -l)"
echo "test-unit-template.sql: $(ls tests/unit/test_*.sql | wc -l)"
```

### Template Effectiveness
- **Time Saved:** ~30 minutes per document (no template → with template)
- **Consistency:** 100% (all docs follow same structure)
- **Error Rate:** <5% (fewer missing sections)

---

## 🚨 Common Issues

### Template Not Found
```bash
# Verify template exists
ls -la templates/

# Check path
pwd
```

### Placeholder Not Replaced
```bash
# Check for typos in placeholder names
grep -r '\[.*\]' generated_file.sql

# Verify replacement syntax
--replace "KEY=VALUE"  # Correct
--replace KEY=VALUE    # Incorrect (missing quotes)
```

### Template Outdated
```bash
# Update template with latest best practices
git diff templates/procedure-template.sql

# Review recent procedures for patterns
ls -t procedures/corrected/*.sql | head -5
```

---

## 📈 Future Template Ideas

Potential new templates:
- [ ] Deployment checklist template
- [ ] Runbook template
- [ ] Performance tuning report template
- [ ] Migration status report template
- [ ] Risk assessment template
- [ ] Change request template

---

**Maintained by:** Pierre Ribeiro (DBA/DBRE)  
**Last Updated:** 2025-11-13  
**Version:** 1.0
