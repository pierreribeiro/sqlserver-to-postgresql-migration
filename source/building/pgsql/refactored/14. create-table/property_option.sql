-- ============================================================================
-- Object: property_option
-- Type: TABLE
-- Priority: P2
-- Description: Valid option values for properties (dropdown/select lists)
-- ============================================================================

DROP TABLE IF EXISTS perseus.property_option CASCADE;

CREATE TABLE perseus.property_option (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    property_id INTEGER NOT NULL,
    option_value VARCHAR(100) NOT NULL,
    option_label VARCHAR(100),
    option_order INTEGER,
    is_default BOOLEAN DEFAULT FALSE,
    CONSTRAINT pk_property_option PRIMARY KEY (id)
);

CREATE INDEX idx_property_option_property_id ON perseus.property_option(property_id);

COMMENT ON TABLE perseus.property_option IS
'Valid option values for properties - enables dropdown/select list UI controls.
Example: property_id=5 (color) has options: RED, BLUE, GREEN.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.property_option.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.property_option.property_id IS 'Foreign key to property table';
COMMENT ON COLUMN perseus.property_option.option_value IS 'Internal value (stored in database)';
COMMENT ON COLUMN perseus.property_option.option_label IS 'Display label (shown in UI)';
COMMENT ON COLUMN perseus.property_option.option_order IS 'Display order for option';
COMMENT ON COLUMN perseus.property_option.is_default IS 'Whether this is the default option (default: FALSE)';
