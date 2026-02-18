CREATE TABLE perseus_dbo.field_map_block(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    filter CITEXT,
    scope CITEXT
)
        WITH (
        OIDS=FALSE
        );

