CREATE TABLE perseus_dbo.cm_unit_dimensions(
    id INTEGER NOT NULL,
    mass NUMERIC(10,2),
    length NUMERIC(10,2),
    time NUMERIC(10,2),
    electric_current NUMERIC(10,2),
    thermodynamic_temperature NUMERIC(10,2),
    amount_of_substance NUMERIC(10,2),
    luminous_intensity NUMERIC(10,2),
    default_unit_id INTEGER NOT NULL,
    name CITEXT NOT NULL
)
        WITH (
        OIDS=FALSE
        );

