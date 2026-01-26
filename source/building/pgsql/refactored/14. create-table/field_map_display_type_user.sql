-- ============================================================================
-- Object: field_map_display_type_user
-- Type: TABLE
-- Priority: P2
-- Description: User-specific display type preferences
-- ============================================================================

DROP TABLE IF EXISTS perseus.field_map_display_type_user CASCADE;

CREATE TABLE perseus.field_map_display_type_user (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    perseus_user_id INTEGER NOT NULL,
    field_map_display_type_id INTEGER NOT NULL,
    CONSTRAINT pk_field_map_display_type_user PRIMARY KEY (id)
);

CREATE INDEX idx_field_map_display_type_user_user_id ON perseus.field_map_display_type_user(perseus_user_id);
CREATE INDEX idx_field_map_display_type_user_fmdt_id ON perseus.field_map_display_type_user(field_map_display_type_id);

COMMENT ON TABLE perseus.field_map_display_type_user IS
'User-specific display type preferences - enables personalized UI layouts.
Updated: 2026-01-26 | Owner: Perseus DBA Team';
