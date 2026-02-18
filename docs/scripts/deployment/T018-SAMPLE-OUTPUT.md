# T018 Sample Output: deploy-object.sh

This document shows sample output from the deployment automation script for various scenarios.

---

## Scenario 1: Successful Procedure Deployment

```bash
$ ./deploy-object.sh procedure "../../source/building/pgsql/refactored/20. create-procedure/1. perseus.getmaterialbyrunproperties.sql"
```

**Output:**
```
=========================================================================
PERSEUS DATABASE MIGRATION - OBJECT DEPLOYMENT
=========================================================================
[INFO] Deployment log: scripts/deployment/deploy-20260125_143052.log
[INFO] Object Type:    procedure
[INFO] SQL File:       /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/20. create-procedure/1. perseus.getmaterialbyrunproperties.sql
[INFO] Environment:    dev
[INFO] Database:       perseus_dev

>>> Validating arguments
[✓ SUCCESS] Valid object type: procedure
[✓ SUCCESS] SQL file exists: /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/20. create-procedure/1. perseus.getmaterialbyrunproperties.sql
[✓ SUCCESS] Deployment environment: dev
[INFO] Execution mode: Docker container (perseus-postgres-dev)

>>> Checking database connection
[✓ SUCCESS] Database connection OK: perseus_dev

>>> Extracting object metadata from SQL file
[✓ SUCCESS] Detected object: perseus_dbo.getmaterialbyrunproperties (procedure)

=========================================================================
PRE-DEPLOYMENT VALIDATION
=========================================================================

>>> Running syntax validation
[INFO] Validating: /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/20. create-procedure/1. perseus.getmaterialbyrunproperties.sql
[✓ SUCCESS] 1. perseus.getmaterialbyrunproperties.sql - Syntax valid
[✓ SUCCESS] Syntax validation passed

>>> Running dependency validation
[INFO] Dependency check available but skipped (run manually if needed)
[INFO] Manual check: psql -d perseus_dev -f scripts/validation/dependency-check.sql

=========================================================================
BACKUP CREATION
=========================================================================

>>> Creating backup of existing object (if exists)
[INFO] Created backup directory: scripts/deployment/backups/2026-01-25
[✓ SUCCESS] Backup created: scripts/deployment/backups/2026-01-25/procedure_perseus_dbo_getmaterialbyrunproperties_20260125_143052.sql
[✓ SUCCESS] Old backups cleaned up

=========================================================================
DEPLOYMENT EXECUTION
=========================================================================

>>> Deploying object to database
[✓ SUCCESS] Object deployed successfully: perseus_dbo.getmaterialbyrunproperties

=========================================================================
POST-DEPLOYMENT VERIFICATION
=========================================================================

>>> Verifying deployment
[✓ SUCCESS] Verification passed: Object exists in database

>>> Updating migration log
[✓ SUCCESS] Migration log updated

=========================================================================
DEPLOYMENT SUMMARY
=========================================================================
[✓ SUCCESS] Deployment completed successfully!

[INFO] Object:         perseus_dbo.getmaterialbyrunproperties
[INFO] Type:           procedure
[INFO] Environment:    dev
[INFO] Backup:         scripts/deployment/backups/2026-01-25/procedure_perseus_dbo_getmaterialbyrunproperties_20260125_143052.sql
[INFO] Log:            scripts/deployment/deploy-20260125_143052.log
```

**Exit Code:** 0

---

## Scenario 2: Dry-run Mode (Validation Only)

```bash
$ ./deploy-object.sh --dry-run view "../../source/building/pgsql/refactored/15. create-view/translated.sql"
```

**Output:**
```
=========================================================================
PERSEUS DATABASE MIGRATION - OBJECT DEPLOYMENT
=========================================================================
[INFO] Deployment log: scripts/deployment/deploy-20260125_144215.log
[INFO] Object Type:    view
[INFO] SQL File:       /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/15. create-view/translated.sql
[INFO] Environment:    dev
[INFO] Database:       perseus_dev
[⚠ WARNING] DRY RUN MODE ENABLED - No changes will be made

>>> Validating arguments
[✓ SUCCESS] Valid object type: view
[✓ SUCCESS] SQL file exists: /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/15. create-view/translated.sql
[✓ SUCCESS] Deployment environment: dev
[INFO] Execution mode: Docker container (perseus-postgres-dev)

>>> Checking database connection
[✓ SUCCESS] Database connection OK: perseus_dev

>>> Extracting object metadata from SQL file
[✓ SUCCESS] Detected object: public.translated (view)

=========================================================================
PRE-DEPLOYMENT VALIDATION
=========================================================================

>>> Running syntax validation
[INFO] Validating: /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/15. create-view/translated.sql
[✓ SUCCESS] translated.sql - Syntax valid
[✓ SUCCESS] Syntax validation passed

>>> Running dependency validation
[INFO] Dependency check available but skipped (run manually if needed)
[INFO] Manual check: psql -d perseus_dev -f scripts/validation/dependency-check.sql

=========================================================================
BACKUP CREATION
=========================================================================

>>> Creating backup of existing object (if exists)
[⚠ WARNING] DRY RUN MODE - Backup skipped

=========================================================================
DEPLOYMENT EXECUTION
=========================================================================

>>> Deploying object to database
[⚠ WARNING] DRY RUN MODE - Deployment skipped

=========================================================================
POST-DEPLOYMENT VERIFICATION
=========================================================================

>>> Verifying deployment
[INFO] DRY RUN MODE - Verification skipped

>>> Updating migration log
[INFO] DRY RUN MODE - Migration log update skipped

=========================================================================
DEPLOYMENT SUMMARY
=========================================================================
[✓ SUCCESS] Deployment completed successfully!

[INFO] Object:         public.translated
[INFO] Type:           view
[INFO] Environment:    dev
[INFO] Log:            scripts/deployment/deploy-20260125_144215.log
```

**Exit Code:** 0

---

## Scenario 3: Syntax Validation Failure

```bash
$ ./deploy-object.sh procedure "../../source/building/pgsql/refactored/20. create-procedure/bad_syntax.sql"
```

**Output:**
```
=========================================================================
PERSEUS DATABASE MIGRATION - OBJECT DEPLOYMENT
=========================================================================
[INFO] Deployment log: scripts/deployment/deploy-20260125_145330.log
[INFO] Object Type:    procedure
[INFO] SQL File:       /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/20. create-procedure/bad_syntax.sql
[INFO] Environment:    dev
[INFO] Database:       perseus_dev

>>> Validating arguments
[✓ SUCCESS] Valid object type: procedure
[✓ SUCCESS] SQL file exists: /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/20. create-procedure/bad_syntax.sql
[✓ SUCCESS] Deployment environment: dev
[INFO] Execution mode: Docker container (perseus-postgres-dev)

>>> Checking database connection
[✓ SUCCESS] Database connection OK: perseus_dev

>>> Extracting object metadata from SQL file
[✓ SUCCESS] Detected object: perseus_dbo.bad_syntax_proc (procedure)

=========================================================================
PRE-DEPLOYMENT VALIDATION
=========================================================================

>>> Running syntax validation
[INFO] Validating: /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/20. create-procedure/bad_syntax.sql
[✗ FAIL] bad_syntax.sql - Syntax errors detected:

    ERROR:  syntax error at or near "SELCT"
    LINE 42:     SELCT * FROM perseus_dbo.material WHERE material_id = par_material_id;
                 ^

[✗ ERROR] Syntax validation failed
[INFO] Run manually: scripts/validation/syntax-check.sh /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/20. create-procedure/bad_syntax.sql

>>> Running dependency validation
[INFO] Dependency check available but skipped (run manually if needed)
[INFO] Manual check: psql -d perseus_dev -f scripts/validation/dependency-check.sql

[✗ ERROR] Validation failed. Use --force to deploy anyway (NOT RECOMMENDED)
```

**Exit Code:** 1

---

## Scenario 4: Force Deployment (Override Warnings)

```bash
$ ./deploy-object.sh --force function "../../source/building/pgsql/refactored/19. create-function/mcgetupstream.sql"
```

**Output:**
```
=========================================================================
PERSEUS DATABASE MIGRATION - OBJECT DEPLOYMENT
=========================================================================
[INFO] Deployment log: scripts/deployment/deploy-20260125_150445.log
[INFO] Object Type:    function
[INFO] SQL File:       /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/19. create-function/mcgetupstream.sql
[INFO] Environment:    dev
[INFO] Database:       perseus_dev

>>> Validating arguments
[✓ SUCCESS] Valid object type: function
[✓ SUCCESS] SQL file exists: /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/19. create-function/mcgetupstream.sql
[✓ SUCCESS] Deployment environment: dev
[INFO] Execution mode: Docker container (perseus-postgres-dev)

>>> Checking database connection
[✓ SUCCESS] Database connection OK: perseus_dev

>>> Extracting object metadata from SQL file
[✓ SUCCESS] Detected object: public.mcgetupstream (function)

=========================================================================
PRE-DEPLOYMENT VALIDATION
=========================================================================

>>> Running syntax validation
[INFO] Validating: /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/19. create-function/mcgetupstream.sql
[⚠ WARNING] Function references table not yet deployed: public.goo
[✓ SUCCESS] Syntax validation passed (with warnings)

>>> Running dependency validation
[INFO] Dependency check available but skipped (run manually if needed)
[INFO] Manual check: psql -d perseus_dev -f scripts/validation/dependency-check.sql

[⚠ WARNING] Validation failed but --force flag used, continuing deployment

=========================================================================
BACKUP CREATION
=========================================================================

>>> Creating backup of existing object (if exists)
[INFO] Object does not exist (new object, no backup needed)
[✓ SUCCESS] Old backups cleaned up

=========================================================================
DEPLOYMENT EXECUTION
=========================================================================

>>> Deploying object to database
[✓ SUCCESS] Object deployed successfully: public.mcgetupstream

=========================================================================
POST-DEPLOYMENT VERIFICATION
=========================================================================

>>> Verifying deployment
[✓ SUCCESS] Verification passed: Object exists in database

>>> Updating migration log
[✓ SUCCESS] Migration log updated

=========================================================================
DEPLOYMENT SUMMARY
=========================================================================
[✓ SUCCESS] Deployment completed successfully!

[INFO] Object:         public.mcgetupstream
[INFO] Type:           function
[INFO] Environment:    dev
[INFO] Log:            scripts/deployment/deploy-20260125_150445.log
```

**Exit Code:** 0

---

## Scenario 5: Deployment Failure (with Rollback)

```bash
$ ./deploy-object.sh procedure "../../source/building/pgsql/refactored/20. create-procedure/runtime_error.sql"
```

**Output:**
```
=========================================================================
PERSEUS DATABASE MIGRATION - OBJECT DEPLOYMENT
=========================================================================
[INFO] Deployment log: scripts/deployment/deploy-20260125_151620.log
[INFO] Object Type:    procedure
[INFO] SQL File:       /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/20. create-procedure/runtime_error.sql
[INFO] Environment:    dev
[INFO] Database:       perseus_dev

>>> Validating arguments
[✓ SUCCESS] Valid object type: procedure
[✓ SUCCESS] SQL file exists: /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/20. create-procedure/runtime_error.sql
[✓ SUCCESS] Deployment environment: dev
[INFO] Execution mode: Docker container (perseus-postgres-dev)

>>> Checking database connection
[✓ SUCCESS] Database connection OK: perseus_dev

>>> Extracting object metadata from SQL file
[✓ SUCCESS] Detected object: perseus_dbo.runtime_error_proc (procedure)

=========================================================================
PRE-DEPLOYMENT VALIDATION
=========================================================================

>>> Running syntax validation
[INFO] Validating: /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/20. create-procedure/runtime_error.sql
[✓ SUCCESS] runtime_error.sql - Syntax valid
[✓ SUCCESS] Syntax validation passed

>>> Running dependency validation
[INFO] Dependency check available but skipped (run manually if needed)
[INFO] Manual check: psql -d perseus_dev -f scripts/validation/dependency-check.sql

=========================================================================
BACKUP CREATION
=========================================================================

>>> Creating backup of existing object (if exists)
[INFO] Created backup directory: scripts/deployment/backups/2026-01-25
[✓ SUCCESS] Backup created: scripts/deployment/backups/2026-01-25/procedure_perseus_dbo_runtime_error_proc_20260125_151620.sql
[✓ SUCCESS] Old backups cleaned up

=========================================================================
DEPLOYMENT EXECUTION
=========================================================================

>>> Deploying object to database
[✗ ERROR] Deployment failed with errors:

    ERROR:  column "nonexistent_column" does not exist
    LINE 52:     SELECT nonexistent_column FROM perseus_dbo.material;
                        ^
    ROLLBACK

[⚠ WARNING] Backup available for rollback: scripts/deployment/backups/2026-01-25/procedure_perseus_dbo_runtime_error_proc_20260125_151620.sql
[INFO] To rollback: scripts/deployment/rollback-object.sh scripts/deployment/backups/2026-01-25/procedure_perseus_dbo_runtime_error_proc_20260125_151620.sql

[✗ ERROR] Deployment failed
```

**Exit Code:** 2

---

## Scenario 6: Staging Environment Deployment

```bash
$ ./deploy-object.sh --env staging view "../../source/building/pgsql/refactored/15. create-view/v_material_lineage.sql"
```

**Output:**
```
=========================================================================
PERSEUS DATABASE MIGRATION - OBJECT DEPLOYMENT
=========================================================================
[INFO] Deployment log: scripts/deployment/deploy-20260125_152735.log
[INFO] Object Type:    view
[INFO] SQL File:       /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/15. create-view/v_material_lineage.sql
[INFO] Environment:    staging
[INFO] Database:       perseus_dev

>>> Validating arguments
[✓ SUCCESS] Valid object type: view
[✓ SUCCESS] SQL file exists: /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/15. create-view/v_material_lineage.sql
[✓ SUCCESS] Deployment environment: staging
[INFO] Execution mode: Docker container (perseus-postgres-dev)

>>> Checking database connection
[✓ SUCCESS] Database connection OK: perseus_dev

>>> Extracting object metadata from SQL file
[✓ SUCCESS] Detected object: public.v_material_lineage (view)

=========================================================================
PRE-DEPLOYMENT VALIDATION
=========================================================================

>>> Running syntax validation
[INFO] Validating: /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/15. create-view/v_material_lineage.sql
[✓ SUCCESS] v_material_lineage.sql - Syntax valid
[✓ SUCCESS] Syntax validation passed

>>> Running dependency validation
[INFO] Dependency check available but skipped (run manually if needed)
[INFO] Manual check: psql -d perseus_dev -f scripts/validation/dependency-check.sql

=========================================================================
BACKUP CREATION
=========================================================================

>>> Creating backup of existing object (if exists)
[INFO] Created backup directory: scripts/deployment/backups/2026-01-25
[✓ SUCCESS] Backup created: scripts/deployment/backups/2026-01-25/view_public_v_material_lineage_20260125_152735.sql
[✓ SUCCESS] Old backups cleaned up

=========================================================================
DEPLOYMENT EXECUTION
=========================================================================

>>> Deploying object to database
[✓ SUCCESS] Object deployed successfully: public.v_material_lineage

=========================================================================
POST-DEPLOYMENT VERIFICATION
=========================================================================

>>> Verifying deployment
[✓ SUCCESS] Verification passed: Object exists in database

>>> Updating migration log
[✓ SUCCESS] Migration log updated

=========================================================================
DEPLOYMENT SUMMARY
=========================================================================
[✓ SUCCESS] Deployment completed successfully!

[INFO] Object:         public.v_material_lineage
[INFO] Type:           view
[INFO] Environment:    staging
[INFO] Backup:         scripts/deployment/backups/2026-01-25/view_public_v_material_lineage_20260125_152735.sql
[INFO] Log:            scripts/deployment/deploy-20260125_152735.log
```

**Exit Code:** 0

---

## Scenario 7: Invalid Arguments

```bash
$ ./deploy-object.sh invalid_type nonexistent.sql
```

**Output:**
```
=========================================================================
PERSEUS DATABASE MIGRATION - OBJECT DEPLOYMENT
=========================================================================
[INFO] Deployment log: scripts/deployment/deploy-20260125_153850.log
[INFO] Object Type:    invalid_type
[INFO] SQL File:       /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/nonexistent.sql
[INFO] Environment:    dev
[INFO] Database:       perseus_dev

>>> Validating arguments
[✗ ERROR] Invalid object type: invalid_type
[INFO] Valid types: procedure, function, view, table, index, constraint
```

**Exit Code:** 4

---

## Scenario 8: Help Output

```bash
$ ./deploy-object.sh --help
```

**Output:**
```
Perseus Database Migration - Object Deployment Script

Usage:
  ./deploy-object.sh <object_type> <sql_file_path> [options]

Arguments:
  object_type       Type of database object:
                    - procedure (stored procedures)
                    - function (table-valued or scalar functions)
                    - view (standard or materialized views)
                    - table (base tables)
                    - index (indexes)
                    - constraint (PK, FK, unique, check constraints)

  sql_file_path     Absolute or relative path to SQL file

Options:
  --env <env>       Deployment environment: dev|staging|prod (default: dev)
  --skip-backup     Skip backup creation (NOT RECOMMENDED for production)
  --skip-syntax     Skip syntax validation (NOT RECOMMENDED)
  --skip-deps       Skip dependency validation
  --force           Force deployment even if warnings detected
  --dry-run         Validate only, do not execute deployment
  --help, -h        Show this help message

Environment Variables:
  DB_USER           Database user (default: perseus_admin)
  DB_NAME           Database name (default: perseus_dev)
  DB_HOST           Database host (default: localhost)
  DB_PORT           Database port (default: 5432)
  PGPASSWORD_FILE   Path to password file
  DOCKER_CONTAINER  Docker container name (default: perseus-postgres-dev)

Exit Codes:
  0 - Deployment successful
  1 - Validation failed
  2 - Deployment failed (with rollback)
  3 - Rollback failed (CRITICAL)
  4 - Invalid arguments

Examples:
  # Deploy a procedure to development
  ./deploy-object.sh procedure source/building/pgsql/refactored/20.\ create-procedure/1.\ perseus.getmaterialbyrunproperties.sql

  # Deploy a view to staging with dry-run
  ./deploy-object.sh --env staging --dry-run view source/building/pgsql/refactored/15.\ create-view/translated.sql

  # Force deploy a function (skip warnings)
  ./deploy-object.sh --force function source/building/pgsql/refactored/19.\ create-function/mcgetupstream.sql

For more information, see: scripts/deployment/README.md
```

**Exit Code:** 0

---

## Log File Sample

**File:** `scripts/deployment/deploy-20260125_143052.log`

```
[2026-01-25 14:30:52] [SECTION] PERSEUS DATABASE MIGRATION - OBJECT DEPLOYMENT
[2026-01-25 14:30:52] [INFO] Deployment log: scripts/deployment/deploy-20260125_143052.log
[2026-01-25 14:30:52] [STEP] Validating arguments
[2026-01-25 14:30:52] [SUCCESS] Valid object type: procedure
[2026-01-25 14:30:52] [SUCCESS] SQL file exists: /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/20. create-procedure/1. perseus.getmaterialbyrunproperties.sql
[2026-01-25 14:30:52] [SUCCESS] Deployment environment: dev
[2026-01-25 14:30:52] [INFO] Execution mode: Docker container (perseus-postgres-dev)
[2026-01-25 14:30:53] [STEP] Checking database connection
[2026-01-25 14:30:53] [SUCCESS] Database connection OK: perseus_dev
[2026-01-25 14:30:53] [STEP] Extracting object metadata from SQL file
[2026-01-25 14:30:53] [SUCCESS] Detected object: perseus_dbo.getmaterialbyrunproperties (procedure)
[2026-01-25 14:30:53] [SECTION] PRE-DEPLOYMENT VALIDATION
[2026-01-25 14:30:53] [STEP] Running syntax validation
[2026-01-25 14:30:54] [SUCCESS] Syntax validation passed
[2026-01-25 14:30:54] [STEP] Running dependency validation
[2026-01-25 14:30:54] [INFO] Dependency check available but skipped (run manually if needed)
[2026-01-25 14:30:54] [SECTION] BACKUP CREATION
[2026-01-25 14:30:54] [STEP] Creating backup of existing object (if exists)
[2026-01-25 14:30:54] [INFO] Created backup directory: scripts/deployment/backups/2026-01-25
[2026-01-25 14:30:55] [SUCCESS] Backup created: scripts/deployment/backups/2026-01-25/procedure_perseus_dbo_getmaterialbyrunproperties_20260125_143052.sql
[2026-01-25 14:30:55] [SUCCESS] Old backups cleaned up
[2026-01-25 14:30:55] [SECTION] DEPLOYMENT EXECUTION
[2026-01-25 14:30:55] [STEP] Deploying object to database
[2026-01-25 14:30:56] [SUCCESS] Object deployed successfully: perseus_dbo.getmaterialbyrunproperties
[2026-01-25 14:30:56] [SECTION] POST-DEPLOYMENT VERIFICATION
[2026-01-25 14:30:56] [STEP] Verifying deployment
[2026-01-25 14:30:56] [SUCCESS] Verification passed: Object exists in database
[2026-01-25 14:30:56] [STEP] Updating migration log
[2026-01-25 14:30:56] [SUCCESS] Migration log updated
[2026-01-25 14:30:56] [SECTION] DEPLOYMENT SUMMARY
[2026-01-25 14:30:56] [SUCCESS] Deployment completed successfully!
[2026-01-25 14:30:56] [INFO] Object:         perseus_dbo.getmaterialbyrunproperties
[2026-01-25 14:30:56] [INFO] Type:           procedure
[2026-01-25 14:30:56] [INFO] Environment:    dev
[2026-01-25 14:30:56] [INFO] Backup:         scripts/deployment/backups/2026-01-25/procedure_perseus_dbo_getmaterialbyrunproperties_20260125_143052.sql
[2026-01-25 14:30:56] [INFO] Log:            scripts/deployment/deploy-20260125_143052.log
```

---

## Migration Log Sample

**Query:**
```sql
SELECT
    id,
    object_type,
    object_schema || '.' || object_name AS object_fqn,
    deployment_timestamp,
    deployment_environment,
    deployment_status
FROM perseus.migration_log
ORDER BY id DESC
LIMIT 5;
```

**Result:**
```
 id |  object_type  |                object_fqn                | deployment_timestamp |  environment  | status
----+---------------+------------------------------------------+----------------------+---------------+---------
  5 | procedure     | perseus_dbo.getmaterialbyrunproperties  | 2026-01-25 14:30:56  | dev           | SUCCESS
  4 | view          | public.translated                        | 2026-01-25 14:20:15  | dev           | SUCCESS
  3 | function      | public.mcgetupstream                     | 2026-01-25 13:45:30  | dev           | SUCCESS
  2 | procedure     | perseus_dbo.addarc                       | 2026-01-25 13:30:22  | dev           | SUCCESS
  1 | procedure     | perseus_dbo.move_node                    | 2026-01-25 13:15:10  | dev           | SUCCESS
(5 rows)
```

---

## Backup File Sample

**File:** `scripts/deployment/backups/2026-01-25/procedure_perseus_dbo_getmaterialbyrunproperties_20260125_143052.sql`

```sql
-- ============================================================================
-- BACKUP: perseus_dbo.getmaterialbyrunproperties (procedure)
-- ============================================================================
-- Backup Date: 2026-01-25 14:30:55
-- Environment: dev
-- Database: perseus_dev
-- Original File: /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/building/pgsql/refactored/20. create-procedure/1. perseus.getmaterialbyrunproperties.sql
--
-- This is an automatic backup created before deployment.
-- Retention: 7 days
-- ============================================================================

CREATE OR REPLACE PROCEDURE perseus_dbo.getmaterialbyrunproperties(
    IN par_runid VARCHAR,
    IN par_hourtimepoint NUMERIC,
    INOUT out_goo_identifier INTEGER DEFAULT 0
)
LANGUAGE plpgsql
AS $BODY$
-- [Original procedure definition here]
-- ...
$BODY$;
```

---

## Directory Structure After Deployment

```
scripts/deployment/
├── backups/
│   ├── 2026-01-25/
│   │   ├── procedure_perseus_dbo_getmaterialbyrunproperties_20260125_143052.sql
│   │   ├── view_public_translated_20260125_142015.sql
│   │   └── function_public_mcgetupstream_20260125_134530.sql
│   └── 2026-01-24/
│       └── [older backups...]
├── deploy-20260125_143052.log
├── deploy-20260125_142015.log
├── deploy-20260125_134530.log
├── deploy-object.sh
├── T018-COMPLETION-SUMMARY.md
├── T018-QUALITY-REPORT.md
└── T018-SAMPLE-OUTPUT.md (this file)
```

---

**Note:** All sample output is based on expected behavior. Actual output may vary depending on database state, file contents, and system configuration.
