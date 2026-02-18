ALTER TABLE perseus_dbo.saved_search
ADD CONSTRAINT saved_search_fk_1_1861581670 FOREIGN KEY (added_by) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

