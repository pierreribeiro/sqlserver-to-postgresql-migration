CREATE TABLE perseus_dbo.goo_process_queue_type(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL
)
        WITH (
        OIDS=FALSE
        );

