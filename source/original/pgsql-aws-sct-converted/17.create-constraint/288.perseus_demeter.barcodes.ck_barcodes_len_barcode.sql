ALTER TABLE perseus_demeter.barcodes
ADD CONSTRAINT ck_barcodes_len_barcode CHECK (length(barcode::text) <= 50);

