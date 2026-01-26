-- ============================================================================
-- Object: cm_application
-- Type: TABLE (Tier 0 - Configuration Management)
-- Priority: P3
-- Description: Application configuration metadata
-- ============================================================================

DROP TABLE IF EXISTS perseus.cm_application CASCADE;

CREATE TABLE perseus.cm_application (
    application_id INTEGER NOT NULL,
    label VARCHAR(200) NOT NULL,
    description VARCHAR(500) NOT NULL,
    is_active BOOLEAN NOT NULL,
    application_group_id INTEGER,
    url VARCHAR(500),
    owner_user_id INTEGER,
    jira_id VARCHAR(50),

    CONSTRAINT pk_cm_application PRIMARY KEY (application_id)
);

CREATE INDEX idx_cm_application_label ON perseus.cm_application(label);
CREATE INDEX idx_cm_application_active ON perseus.cm_application(is_active);

COMMENT ON TABLE perseus.cm_application IS
'Configuration Management: Application metadata. Updated: 2026-01-26';
