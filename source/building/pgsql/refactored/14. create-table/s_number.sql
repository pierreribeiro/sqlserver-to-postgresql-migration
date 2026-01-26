-- ============================================================================
-- Object: s_number
-- Type: TABLE (Tier 0 - Sequence generator)
-- Priority: P2
-- Description: S-number sequence generator (starts at 1100000)
-- ============================================================================

DROP TABLE IF EXISTS perseus.s_number CASCADE;

CREATE TABLE perseus.s_number (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1100000),

    CONSTRAINT pk_s_number PRIMARY KEY (id)
);

COMMENT ON TABLE perseus.s_number IS
'S-number sequence generator for strain identifiers (starts at 1100000).
Used by ID generation procedures. Updated: 2026-01-26';

COMMENT ON COLUMN perseus.s_number.id IS 'Sequential S-number (auto-increment from 1100000)';
