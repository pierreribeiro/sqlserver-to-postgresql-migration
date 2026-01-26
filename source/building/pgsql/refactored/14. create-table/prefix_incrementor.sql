-- ============================================================================
-- Object: prefix_incrementor
-- Type: TABLE (Tier 0 - Sequence generator)
-- Priority: P2
-- Description: General-purpose prefix-based ID counter
-- ============================================================================

DROP TABLE IF EXISTS perseus.prefix_incrementor CASCADE;

CREATE TABLE perseus.prefix_incrementor (
    prefix VARCHAR(50) NOT NULL,
    counter INTEGER NOT NULL,

    CONSTRAINT pk_prefix_incrementor PRIMARY KEY (prefix)
);

COMMENT ON TABLE perseus.prefix_incrementor IS
'General-purpose prefix-based ID counter for custom ID generation schemes.
Used by ID generation procedures. Updated: 2026-01-26';

COMMENT ON COLUMN perseus.prefix_incrementor.prefix IS 'ID prefix string (e.g., "M-", "S-", "P-")';
COMMENT ON COLUMN perseus.prefix_incrementor.counter IS 'Current counter value for this prefix';
