CREATE INDEX ix_person_ix_person_km_session_id
ON perseus_dbo.person
USING BTREE (km_session_id ASC)
WITH (FILLFACTOR = 90);

