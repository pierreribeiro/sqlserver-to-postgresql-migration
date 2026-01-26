-- ============================================================================
-- Object: cm_user
-- Type: TABLE (Tier 0 - CM)
-- ============================================================================

DROP TABLE IF EXISTS perseus.cm_user CASCADE;

CREATE TABLE perseus.cm_user (
    user_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    domain_id VARCHAR(100),
    is_active BOOLEAN NOT NULL,
    name VARCHAR(200) NOT NULL,
    login VARCHAR(100),
    email VARCHAR(200),
    object_id UUID,

    CONSTRAINT pk_cm_user PRIMARY KEY (user_id)
);

CREATE INDEX idx_cm_user_login ON perseus.cm_user(login);
CREATE INDEX idx_cm_user_active ON perseus.cm_user(is_active);

COMMENT ON TABLE perseus.cm_user IS 'CM: User account records. Updated: 2026-01-26';
