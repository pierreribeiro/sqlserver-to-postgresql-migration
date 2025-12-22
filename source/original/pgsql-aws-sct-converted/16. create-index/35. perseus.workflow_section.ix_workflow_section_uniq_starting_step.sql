CREATE UNIQUE INDEX ix_workflow_section_uniq_starting_step
ON perseus_dbo.workflow_section
USING BTREE (starting_step_id ASC);

