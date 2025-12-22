ALTER TABLE perseus_dbo.m_upstream
ADD CONSTRAINT ck_m_upstream_len_start_point CHECK (length(start_point::text) <= 50);

