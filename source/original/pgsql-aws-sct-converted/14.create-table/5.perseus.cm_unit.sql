CREATE TABLE perseus_dbo.cm_unit(
    id INTEGER NOT NULL,
    description CITEXT,
    longname CITEXT,
    dimensions_id INTEGER,
    name CITEXT,
    factor NUMERIC(20,10),
    "offset" NUMERIC(20,10)
)
        WITH (
        OIDS=FALSE
        );

