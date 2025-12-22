ALTER TABLE perseus_dbo.m_upstream
ADD CONSTRAINT ck_m_upstream_len_path CHECK (length(path::text) <= 500);

