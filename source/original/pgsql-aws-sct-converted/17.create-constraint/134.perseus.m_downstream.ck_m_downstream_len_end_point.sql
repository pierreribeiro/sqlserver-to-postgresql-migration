ALTER TABLE perseus_dbo.m_downstream
ADD CONSTRAINT ck_m_downstream_len_end_point CHECK (length(end_point::text) <= 50);

