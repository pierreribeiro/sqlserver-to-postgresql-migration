CREATE INDEX ix_submission_ix_submission_added_on
ON perseus_dbo.submission
USING BTREE (added_on ASC)
WITH (FILLFACTOR = 90);

