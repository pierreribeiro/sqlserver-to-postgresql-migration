CREATE TABLE perseus_dbo.goo_type(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    color CITEXT,
    left_id INTEGER NOT NULL,
    right_id INTEGER NOT NULL,
    scope_id CITEXT NOT NULL,
    disabled INTEGER NOT NULL DEFAULT (0),
    casrn CITEXT,
    iupac CITEXT,
    depth INTEGER NOT NULL DEFAULT (0),
    abbreviation CITEXT,
    density_kg_l DOUBLE PRECISION
)
        WITH (
        OIDS=FALSE
        );

