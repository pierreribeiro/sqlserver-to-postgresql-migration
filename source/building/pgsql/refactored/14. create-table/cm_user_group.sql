-- ============================================================================
-- Object: cm_user_group
-- Type: TABLE (Tier 0 - CM)
-- ============================================================================

DROP TABLE IF EXISTS perseus.cm_user_group CASCADE;

CREATE TABLE perseus.cm_user_group (
    user_id INTEGER NOT NULL,
    group_id INTEGER NOT NULL,

    CONSTRAINT pk_cm_user_group PRIMARY KEY (user_id, group_id)
);

COMMENT ON TABLE perseus.cm_user_group IS 'CM: User-to-group mapping (many-to-many). Updated: 2026-01-26';
