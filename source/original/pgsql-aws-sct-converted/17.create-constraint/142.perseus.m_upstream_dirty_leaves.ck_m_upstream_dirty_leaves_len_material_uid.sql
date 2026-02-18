ALTER TABLE perseus_dbo.m_upstream_dirty_leaves
ADD CONSTRAINT ck_m_upstream_dirty_leaves_len_material_uid CHECK (length(material_uid::text) <= 50);

