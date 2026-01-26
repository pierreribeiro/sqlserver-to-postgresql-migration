-- ============================================================================
-- Object: goo_process_queue_type
-- Type: TABLE (Tier 0 Lookup)
-- Priority: P3
-- Description: Processing queue type definitions
-- ============================================================================

DROP TABLE IF EXISTS perseus.goo_process_queue_type CASCADE;

CREATE TABLE perseus.goo_process_queue_type (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(100) NOT NULL,

    CONSTRAINT pk_goo_process_queue_type PRIMARY KEY (id)
);

CREATE INDEX idx_goo_process_queue_type_name ON perseus.goo_process_queue_type(name);

COMMENT ON TABLE perseus.goo_process_queue_type IS
'Processing queue type definitions. Updated: 2026-01-26';
