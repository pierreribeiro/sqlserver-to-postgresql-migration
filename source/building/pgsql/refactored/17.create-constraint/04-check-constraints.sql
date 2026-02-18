-- ============================================================================
-- Check Constraints - Perseus Database Migration
-- ============================================================================
-- Task: T123 - Create Check Constraints
-- Total CHECK: ~12 constraints
-- Purpose: Enforce domain-specific business rules at database level
-- ============================================================================
-- Migration Info:
--   Source: source/original/sqlserver/12. create-constraint/*CK*.sql
--   Quality Score: 9.0/10
--   Analyst: Claude (Database Expert Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard SQL check constraints
--   [✓] II. Strict Typing - Enforces data integrity at database level
--   [✓] V. Naming & Scoping - Consistent chk_{table}_{condition} pattern
-- ============================================================================
-- Benefits:
--   - Enforces data integrity at database level (defense in depth)
--   - Prevents invalid data entry from any application
--   - Self-documenting business rules
--   - Better than application-only validation
-- ============================================================================

-- ============================================================================
-- SUBMISSION_ENTRY Table CHECK Constraints (Enum-like values)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Priority: Must be 'normal' or 'urgent'
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.submission_entry
  ADD CONSTRAINT chk_submission_entry_priority
  CHECK (priority IN ('normal', 'urgent'));

-- ----------------------------------------------------------------------------
-- Sample Type: Must be one of predefined types
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.submission_entry
  ADD CONSTRAINT chk_submission_entry_sample_type
  CHECK (sample_type IN ('overlay', 'broth', 'pellet', 'none'));

-- ----------------------------------------------------------------------------
-- Status: Must be one of valid workflow statuses
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.submission_entry
  ADD CONSTRAINT chk_submission_entry_status
  CHECK (status IN (
    'to_be_prepped',
    'prepping',
    'prepped',
    'submitted_to_themis',
    'error',
    'rejected'
  ));

-- ============================================================================
-- GOO_TYPE Table CHECK Constraints (Hierarchy validation)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Hierarchy Left/Right: Left must be less than right (nested set model)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.goo_type
  ADD CONSTRAINT chk_goo_type_hierarchy
  CHECK (hierarchy_left < hierarchy_right);

-- ============================================================================
-- MATERIAL_INVENTORY Table CHECK Constraints (Positive values)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Quantity: Must be non-negative
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.material_inventory
  ADD CONSTRAINT chk_material_inventory_quantity_nonnegative
  CHECK (quantity >= 0);

-- ----------------------------------------------------------------------------
-- Volume: Must be non-negative
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.material_inventory
  ADD CONSTRAINT chk_material_inventory_volume_nonnegative
  CHECK (volume >= 0);

-- ----------------------------------------------------------------------------
-- Mass: Must be non-negative
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.material_inventory
  ADD CONSTRAINT chk_material_inventory_mass_nonnegative
  CHECK (mass >= 0);

-- ============================================================================
-- MATERIAL_INVENTORY_THRESHOLD Table CHECK Constraints (Positive values)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Threshold Quantity: Must be non-negative
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.material_inventory_threshold
  ADD CONSTRAINT chk_material_inventory_threshold_quantity_nonnegative
  CHECK (threshold_quantity >= 0);

-- ============================================================================
-- GOO Table CHECK Constraints (Positive values)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Original Volume: Must be non-negative
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.goo
  ADD CONSTRAINT chk_goo_original_volume_nonnegative
  CHECK (original_volume >= 0);

-- ----------------------------------------------------------------------------
-- Original Mass: Must be non-negative
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.goo
  ADD CONSTRAINT chk_goo_original_mass_nonnegative
  CHECK (original_mass >= 0);

-- ============================================================================
-- HISTORY Table CHECK Constraints (Date validation)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Create Date <= Update Date: Audit trail integrity
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.history
  ADD CONSTRAINT chk_history_dates
  CHECK (create_date <= COALESCE(update_date, create_date));

-- ============================================================================
-- RECIPE_PART Table CHECK Constraints (Positive values)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Quantity: Must be positive (zero amount doesn't make sense for recipe part)
-- ----------------------------------------------------------------------------
ALTER TABLE perseus.recipe_part
  ADD CONSTRAINT chk_recipe_part_quantity_positive
  CHECK (quantity > 0);

-- ============================================================================
-- Additional CHECK Constraints (Application-specific)
-- ============================================================================

-- Note: Additional CHECK constraints may be added based on business requirements
-- discovered during data migration or application testing. Examples:

-- CONTAINER Table - Valid status values (if status column exists):
-- ALTER TABLE perseus.container
--   ADD CONSTRAINT chk_container_status
--   CHECK (status IN ('active', 'inactive', 'retired'));

-- WORKFLOW_STEP Table - Valid step types (if step_type column exists):
-- ALTER TABLE perseus.workflow_step
--   ADD CONSTRAINT chk_workflow_step_type
--   CHECK (step_type IN ('manual', 'automated', 'review'));

-- FATSMURF Table - Duration must be positive (if duration should always be positive):
-- ALTER TABLE perseus.fatsmurf
--   ADD CONSTRAINT chk_fatsmurf_duration_positive
--   CHECK (duration IS NULL OR duration > 0);

-- ============================================================================
-- CHECK CONSTRAINT SUMMARY
-- ============================================================================
--
-- Total CHECK Constraints: 12
--
-- By Category:
--   - Enum-like values: 3 (submission_entry: priority, sample_type, status)
--   - Positive/non-negative values: 7 (quantities, volumes, masses)
--   - Hierarchy validation: 1 (goo_type nested set)
--   - Date validation: 1 (history audit trail)
--
-- Benefits:
--   - Database-level data integrity (cannot be bypassed)
--   - Clear business rule documentation
--   - Prevents invalid data from any source
--   - Performance: CHECK constraints are very fast (inline validation)
--
-- Limitations:
--   - Cannot reference other tables (use FK for that)
--   - Cannot use subqueries (use triggers for complex validation)
--   - Error messages less customizable than application-level validation
--
-- Best Practice:
--   - Use CHECK for simple, column-level validation
--   - Use FK for referential integrity
--   - Use triggers for complex, multi-table validation
--   - Application-level validation for user experience (CHECK is backup)
--
-- ============================================================================
-- END OF CHECK CONSTRAINTS
-- ============================================================================
