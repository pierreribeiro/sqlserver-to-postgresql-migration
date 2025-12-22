ALTER TABLE perseus_dbo.m_downstream
ADD CONSTRAINT ck_m_downstream_len_path CHECK (length(path::text) <= 500);

