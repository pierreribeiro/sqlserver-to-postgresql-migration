ALTER TABLE perseus_dbo.m_downstream
ADD CONSTRAINT ck_m_downstream_len_start_point CHECK (length(start_point::text) <= 50);

