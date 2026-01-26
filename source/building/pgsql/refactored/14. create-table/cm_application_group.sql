-- ============================================================================
-- Object: cm_application_group
-- Type: TABLE (Tier 0 - CM)
-- ============================================================================

DROP TABLE IF EXISTS perseus.cm_application_group CASCADE;

CREATE TABLE perseus.cm_application_group (
    application_group_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    label VARCHAR(200) NOT NULL,

    CONSTRAINT pk_cm_application_group PRIMARY KEY (application_group_id)
);

COMMENT ON TABLE perseus.cm_application_group IS 'CM: Application group definitions. Updated: 2026-01-26';
