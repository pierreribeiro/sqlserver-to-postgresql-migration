CREATE TABLE perseus_dbo.container_type(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    is_parent INTEGER NOT NULL DEFAULT (1),
    is_equipment INTEGER NOT NULL DEFAULT (0),
    is_single INTEGER NOT NULL DEFAULT (1),
    is_restricted INTEGER NOT NULL DEFAULT (0),
    is_gooable INTEGER NOT NULL DEFAULT (0)
)
        WITH (
        OIDS=FALSE
        );

