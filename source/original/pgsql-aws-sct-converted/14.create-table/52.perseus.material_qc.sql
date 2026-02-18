CREATE TABLE perseus_dbo.material_qc(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    material_id INTEGER NOT NULL,
    entity_type_name CITEXT NOT NULL,
    foreign_entity_id INTEGER NOT NULL,
    qc_process_uid CITEXT NOT NULL
)
        WITH (
        OIDS=FALSE
        );

