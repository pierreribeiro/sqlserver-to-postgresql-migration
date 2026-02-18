CREATE TABLE perseus_dbo.submission(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    submitter_id INTEGER NOT NULL,
    added_on TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    label CITEXT
)
        WITH (
        OIDS=FALSE
        );

