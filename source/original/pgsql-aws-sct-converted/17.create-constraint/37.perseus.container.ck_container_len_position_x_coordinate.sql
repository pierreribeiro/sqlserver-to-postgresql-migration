ALTER TABLE perseus_dbo.container
ADD CONSTRAINT ck_container_len_position_x_coordinate CHECK (length(position_x_coordinate::text) <= 50);

