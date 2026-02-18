CREATE TABLE perseus_dbo.tmp_messy_links(
    source_transition CITEXT NOT NULL,
    source_name CITEXT,
    destination_transition CITEXT NOT NULL,
    desitnation_name CITEXT,
    material_id CITEXT NOT NULL
)
        WITH (
        OIDS=FALSE
        );

