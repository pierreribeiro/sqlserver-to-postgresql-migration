ALTER TABLE perseus_dbo.perseustableandrowcounts
ADD CONSTRAINT ck_perseustableandrowcounts_len_rows CHECK (length(rows::text) <= 11);

