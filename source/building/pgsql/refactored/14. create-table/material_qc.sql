-- ============================================================================
-- Object: material_qc
-- Type: TABLE
-- Priority: P2
-- Description: Quality control records for materials
-- ============================================================================

DROP TABLE IF EXISTS perseus.material_qc CASCADE;

CREATE TABLE perseus.material_qc (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    goo_id INTEGER NOT NULL,
    qc_date DATE NOT NULL,
    qc_passed BOOLEAN NOT NULL,
    qc_notes TEXT,
    qc_by INTEGER NOT NULL,
    CONSTRAINT pk_material_qc PRIMARY KEY (id)
);

CREATE INDEX idx_material_qc_goo_id ON perseus.material_qc(goo_id);
CREATE INDEX idx_material_qc_qc_date ON perseus.material_qc(qc_date);
CREATE INDEX idx_material_qc_qc_by ON perseus.material_qc(qc_by);

COMMENT ON TABLE perseus.material_qc IS
'Quality control records for materials - tracks QC test results.
Updated: 2026-01-26 | Owner: Perseus DBA Team';
