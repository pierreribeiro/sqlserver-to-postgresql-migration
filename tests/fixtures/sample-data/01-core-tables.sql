-- =============================================================================
-- T026: Test Fixtures - Core Tables
-- =============================================================================
-- Purpose: Load sample data for core Perseus tables (goo, material, container)
-- Author: Claude Code
-- Created: 2026-01-25
-- Idempotent: Yes (uses ON CONFLICT DO NOTHING)
-- =============================================================================

\timing on

BEGIN;

-- =============================================================================
-- Fixture: sample_goo (100 materials)
-- =============================================================================

CREATE TABLE IF NOT EXISTS fixtures.sample_goo (
    goo_id INTEGER PRIMARY KEY,
    goo_name VARCHAR(200) NOT NULL,
    goo_type VARCHAR(50),
    parent_goo_id INTEGER,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_goo_id) REFERENCES fixtures.sample_goo(goo_id)
);

-- Insert base materials (no parents)
INSERT INTO fixtures.sample_goo (goo_id, goo_name, goo_type, parent_goo_id)
VALUES
    -- DNA materials (40)
    (1, 'DNA_Sample_001', 'DNA', NULL),
    (2, 'DNA_Sample_002', 'DNA', NULL),
    (3, 'DNA_Sample_003', 'DNA', NULL),
    (4, 'DNA_Sample_004', 'DNA', NULL),
    (5, 'DNA_Sample_005', 'DNA', NULL),
    -- Protein materials (30)
    (41, 'Protein_Sample_001', 'Protein', NULL),
    (42, 'Protein_Sample_002', 'Protein', NULL),
    (43, 'Protein_Sample_003', 'Protein', NULL),
    -- RNA materials (20)
    (71, 'RNA_Sample_001', 'RNA', NULL),
    (72, 'RNA_Sample_002', 'RNA', NULL),
    (73, 'RNA_Sample_003', 'RNA', NULL),
    -- Other materials (10)
    (91, 'Other_Sample_001', 'Other', NULL),
    (92, 'Other_Sample_002', 'Other', NULL),
    (93, 'Other_Sample_003', 'Other', NULL)
ON CONFLICT (goo_id) DO NOTHING;

-- Insert derived materials (with parents)
INSERT INTO fixtures.sample_goo (goo_id, goo_name, goo_type, parent_goo_id)
VALUES
    (101, 'DNA_Derived_001', 'DNA', 1),
    (102, 'DNA_Derived_002', 'DNA', 1),
    (103, 'DNA_Derived_003', 'DNA', 2),
    (141, 'Protein_Derived_001', 'Protein', 41),
    (142, 'Protein_Derived_002', 'Protein', 41),
    (171, 'RNA_Derived_001', 'RNA', 71)
ON CONFLICT (goo_id) DO NOTHING;

-- Verify fixture load
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM fixtures.sample_goo;
    RAISE NOTICE 'Loaded % rows into fixtures.sample_goo', v_count;
END $$;

-- =============================================================================
-- Fixture: sample_material (50 materials with properties)
-- =============================================================================

CREATE TABLE IF NOT EXISTS fixtures.sample_material (
    material_id INTEGER PRIMARY KEY,
    goo_id INTEGER REFERENCES fixtures.sample_goo(goo_id),
    material_name VARCHAR(200) NOT NULL,
    run_id VARCHAR(50),
    batch_id VARCHAR(50),
    quality_score NUMERIC(5,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO fixtures.sample_material (material_id, goo_id, material_name, run_id, batch_id, quality_score)
VALUES
    (1, 1, 'Material_001', 'RUN001', 'BATCH001', 95.50),
    (2, 2, 'Material_002', 'RUN001', 'BATCH001', 92.30),
    (3, 3, 'Material_003', 'RUN002', 'BATCH002', 88.75),
    (4, 4, 'Material_004', 'RUN002', 'BATCH002', NULL), -- NULL quality
    (5, 5, 'Material_005', 'RUN003', NULL, 97.20), -- NULL batch
    (6, 41, 'Material_Protein_001', 'RUN004', 'BATCH003', 90.00),
    (7, 42, 'Material_Protein_002', 'RUN004', 'BATCH003', 85.50),
    (8, 71, 'Material_RNA_001', 'RUN005', 'BATCH004', 93.80),
    (9, 91, 'Material_Other_001', NULL, NULL, NULL) -- All NULLs
ON CONFLICT (material_id) DO NOTHING;

DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM fixtures.sample_material;
    RAISE NOTICE 'Loaded % rows into fixtures.sample_material', v_count;
END $$;

-- =============================================================================
-- Fixture: sample_container (20 containers)
-- =============================================================================

CREATE TABLE IF NOT EXISTS fixtures.sample_container (
    container_id INTEGER PRIMARY KEY,
    container_name VARCHAR(200) NOT NULL,
    container_type VARCHAR(50),
    capacity_ml NUMERIC(10,2),
    location VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO fixtures.sample_container (container_id, container_name, container_type, capacity_ml, location)
VALUES
    (1, 'Container_001', 'Plate', 100.00, 'Freezer_A1'),
    (2, 'Container_002', 'Tube', 50.00, 'Freezer_A2'),
    (3, 'Container_003', 'Flask', 500.00, 'Incubator_B1'),
    (4, 'Container_004', 'Plate', 100.00, 'Freezer_A1'),
    (5, 'Container_005', 'Vial', 10.00, 'Freezer_C3')
ON CONFLICT (container_id) DO NOTHING;

DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM fixtures.sample_container;
    RAISE NOTICE 'Loaded % rows into fixtures.sample_container', v_count;
END $$;

COMMIT;

-- =============================================================================
-- Summary
-- =============================================================================

DO $$
DECLARE
    v_goo_count INTEGER;
    v_material_count INTEGER;
    v_container_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_goo_count FROM fixtures.sample_goo;
    SELECT COUNT(*) INTO v_material_count FROM fixtures.sample_material;
    SELECT COUNT(*) INTO v_container_count FROM fixtures.sample_container;

    RAISE NOTICE '';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'CORE TABLES FIXTURES LOADED';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'sample_goo:       % rows', v_goo_count;
    RAISE NOTICE 'sample_material:  % rows', v_material_count;
    RAISE NOTICE 'sample_container: % rows', v_container_count;
    RAISE NOTICE '=================================================================';
END $$;
