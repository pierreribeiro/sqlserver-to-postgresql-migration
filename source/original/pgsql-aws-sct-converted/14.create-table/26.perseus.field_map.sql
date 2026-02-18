CREATE TABLE perseus_dbo.field_map(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    field_map_block_id INTEGER NOT NULL,
    name CITEXT,
    description CITEXT,
    display_order INTEGER,
    setter CITEXT,
    lookup CITEXT,
    lookup_service CITEXT,
    nullable INTEGER,
    field_map_type_id INTEGER NOT NULL,
    database_id CITEXT,
    save_sequence INTEGER NOT NULL,
    onchange CITEXT,
    field_map_set_id INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

