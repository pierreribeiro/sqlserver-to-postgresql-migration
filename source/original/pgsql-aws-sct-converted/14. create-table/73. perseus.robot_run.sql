CREATE TABLE perseus_dbo.robot_run(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    robot_id INTEGER,
    name CITEXT NOT NULL,
    all_qc_passed NUMERIC(1,0),
    all_themis_submitted NUMERIC(1,0)
)
        WITH (
        OIDS=FALSE
        );

