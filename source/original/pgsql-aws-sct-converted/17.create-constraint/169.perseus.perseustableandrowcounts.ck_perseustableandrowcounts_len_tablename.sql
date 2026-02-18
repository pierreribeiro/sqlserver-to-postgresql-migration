ALTER TABLE perseus_dbo.perseustableandrowcounts
ADD CONSTRAINT ck_perseustableandrowcounts_len_tablename CHECK (length(tablename::text) <= 128);

