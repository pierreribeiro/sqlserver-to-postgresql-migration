-- ============================================================================
-- Object: cm_group
-- Type: TABLE (Tier 0 - CM)
-- ============================================================================

DROP TABLE IF EXISTS perseus.cm_group CASCADE;

CREATE TABLE perseus.cm_group (
    group_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(200) NOT NULL,
    domain_id VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL,
    last_modified TIMESTAMP NOT NULL,

    CONSTRAINT pk_cm_group PRIMARY KEY (group_id)
);

COMMENT ON TABLE perseus.cm_group IS 'CM: User group definitions. Updated: 2026-01-26';
