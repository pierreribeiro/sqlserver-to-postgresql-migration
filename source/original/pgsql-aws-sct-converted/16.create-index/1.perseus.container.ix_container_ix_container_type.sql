CREATE INDEX ix_container_ix_container_type
ON perseus_dbo.container
USING BTREE (container_type_id ASC) INCLUDE(id, mass)
WITH (FILLFACTOR = 70);

