CREATE TABLE perseus_dbo.perseustableandrowcounts(
    tablename CITEXT,
    rows CITEXT,
    updated_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
)
        WITH (
        OIDS=FALSE
        );

