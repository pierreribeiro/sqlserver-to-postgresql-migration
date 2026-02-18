CREATE TABLE perseus_demeter.barcodes(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    barcode CITEXT NOT NULL,
    seedvial_id INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

