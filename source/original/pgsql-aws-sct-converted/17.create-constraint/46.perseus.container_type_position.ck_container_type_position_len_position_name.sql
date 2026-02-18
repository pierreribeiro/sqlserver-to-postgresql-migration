ALTER TABLE perseus_dbo.container_type_position
ADD CONSTRAINT ck_container_type_position_len_position_name CHECK (length(position_name::text) <= 50);

