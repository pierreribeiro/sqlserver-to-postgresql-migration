ALTER TABLE perseus_dbo.field_map_display_type_user
ADD CONSTRAINT field_map_display_type_user_fk_2_999062695 FOREIGN KEY (user_id) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

