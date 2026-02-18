CREATE INDEX ix_container_ix_container_scope_id_left_id_right_id_depth
ON perseus_dbo.container
USING BTREE (scope_id ASC, left_id ASC, right_id ASC, depth ASC);

