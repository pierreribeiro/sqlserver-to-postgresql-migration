ALTER TABLE perseus_dbo.container
ADD CONSTRAINT ck_container_len_position_y_coordinate CHECK (length(position_y_coordinate::text) <= 50);

