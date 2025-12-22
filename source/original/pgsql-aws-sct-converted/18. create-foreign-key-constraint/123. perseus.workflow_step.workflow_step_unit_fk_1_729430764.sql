ALTER TABLE perseus_dbo.workflow_step
ADD CONSTRAINT workflow_step_unit_fk_1_729430764 FOREIGN KEY (goo_amount_unit_id) 
REFERENCES perseus_dbo.unit (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

