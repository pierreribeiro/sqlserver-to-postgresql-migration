CREATE TABLE perseus_dbo.recipe(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    goo_type_id INTEGER NOT NULL,
    description CITEXT,
    sop CITEXT,
    workflow_id INTEGER,
    added_by INTEGER NOT NULL,
    added_on TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    is_preferred NUMERIC(1,0) NOT NULL DEFAULT (0),
    qc NUMERIC(1,0) NOT NULL DEFAULT (0),
    is_archived NUMERIC(1,0) NOT NULL DEFAULT (0),
    feed_type_id INTEGER,
    stock_concentration DOUBLE PRECISION,
    sterilization_method CITEXT,
    inoculant_percent DOUBLE PRECISION,
    post_inoc_volume_ml DOUBLE PRECISION
)
        WITH (
        OIDS=FALSE
        );

