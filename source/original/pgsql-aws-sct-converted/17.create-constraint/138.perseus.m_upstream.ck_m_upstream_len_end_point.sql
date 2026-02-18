ALTER TABLE perseus_dbo.m_upstream
ADD CONSTRAINT ck_m_upstream_len_end_point CHECK (length(end_point::text) <= 50);

