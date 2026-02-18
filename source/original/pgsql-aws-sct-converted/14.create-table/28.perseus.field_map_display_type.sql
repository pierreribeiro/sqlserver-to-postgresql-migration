CREATE TABLE perseus_dbo.field_map_display_type(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    field_map_id INTEGER NOT NULL,
    display_type_id INTEGER NOT NULL,
    display CITEXT NOT NULL,
    display_layout_id INTEGER NOT NULL DEFAULT (1),
    manditory INTEGER NOT NULL DEFAULT (0)
)
        WITH (
        OIDS=FALSE
        );

