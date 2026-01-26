-- ============================================================================
-- Object: goo_type_combine_component
-- Type: TABLE
-- Priority: P1
-- Description: Defines which goo_type components can be combined (many-to-many)
-- ============================================================================

DROP TABLE IF EXISTS perseus.goo_type_combine_component CASCADE;

CREATE TABLE perseus.goo_type_combine_component (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    combine_id INTEGER NOT NULL,
    component_id INTEGER NOT NULL,
    CONSTRAINT pk_goo_type_combine_component PRIMARY KEY (id),
    CONSTRAINT uq_goo_type_combine_component UNIQUE (combine_id, component_id)
);

CREATE INDEX idx_goo_type_combine_component_combine ON perseus.goo_type_combine_component(combine_id);
CREATE INDEX idx_goo_type_combine_component_component ON perseus.goo_type_combine_component(component_id);

COMMENT ON TABLE perseus.goo_type_combine_component IS
'Defines which goo_type components can be combined - enables material combination rules.
Example: combine_id=10 (reagent mix) can include component_id=5 (buffer) + component_id=7 (enzyme).
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.goo_type_combine_component.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.goo_type_combine_component.combine_id IS 'Foreign key to goo_type - the combination target type';
COMMENT ON COLUMN perseus.goo_type_combine_component.component_id IS 'Foreign key to goo_type - the component type that can be included';
