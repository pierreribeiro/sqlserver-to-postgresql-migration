ALTER TABLE perseus_dbo.container_type_position
ADD CONSTRAINT ck_container_type_position_len_position_x_coordinate CHECK (length(position_x_coordinate::text) <= 50);

