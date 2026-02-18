CREATE TABLE perseus_dbo.smurf_group_member(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    smurf_group_id INTEGER NOT NULL,
    smurf_id INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

