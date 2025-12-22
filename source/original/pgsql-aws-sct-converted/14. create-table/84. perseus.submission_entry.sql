CREATE TABLE perseus_dbo.submission_entry(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    assay_type_id INTEGER NOT NULL,
    material_id INTEGER NOT NULL,
    status CITEXT NOT NULL,
    priority CITEXT NOT NULL,
    submission_id INTEGER NOT NULL,
    prepped_by_id INTEGER,
    themis_tray_id INTEGER,
    sample_type CITEXT NOT NULL
)
        WITH (
        OIDS=FALSE
        );

