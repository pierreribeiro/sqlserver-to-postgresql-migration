-- ============================================================================
-- Object: cm_project
-- Type: TABLE (Tier 0 - CM)
-- ============================================================================

DROP TABLE IF EXISTS perseus.cm_project CASCADE;

CREATE TABLE perseus.cm_project (
    project_id SMALLINT NOT NULL,
    label VARCHAR(200) NOT NULL,
    is_active BOOLEAN NOT NULL,
    display_order SMALLINT NOT NULL,
    group_id INTEGER,

    CONSTRAINT pk_cm_project PRIMARY KEY (project_id)
);

COMMENT ON TABLE perseus.cm_project IS 'CM: Project definitions. Updated: 2026-01-26';
