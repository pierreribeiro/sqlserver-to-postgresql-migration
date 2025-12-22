ALTER TABLE perseus_dbo.sequence_type
ADD CONSTRAINT ck_sequence_type_len_name CHECK (length(name::text) <= 25);

