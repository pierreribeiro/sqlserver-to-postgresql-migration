CREATE TABLE perseus_dbo.field_map_display_type_user(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    field_map_display_type_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

