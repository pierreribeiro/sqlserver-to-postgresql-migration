-- ============================================================================
-- Object: m_number
-- Type: TABLE (Tier 0 - Sequence generator)
-- Priority: P2
-- Description: M-number sequence generator (starts at 900000)
-- ============================================================================

DROP TABLE IF EXISTS perseus.m_number CASCADE;

CREATE TABLE perseus.m_number (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 900000),

    CONSTRAINT pk_m_number PRIMARY KEY (id)
);

COMMENT ON TABLE perseus.m_number IS
'M-number sequence generator for material identifiers (starts at 900000).
Used by ID generation procedures. Updated: 2026-01-26';

COMMENT ON COLUMN perseus.m_number.id IS 'Sequential M-number (auto-increment from 900000)';
