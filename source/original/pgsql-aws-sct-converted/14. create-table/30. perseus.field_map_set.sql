CREATE TABLE perseus_dbo.field_map_set(
    id INTEGER NOT NULL,
    tab_group_id INTEGER,
    display_order INTEGER,
    name CITEXT,
    color CITEXT,
    size INTEGER
)
        WITH (
        OIDS=FALSE
        );

