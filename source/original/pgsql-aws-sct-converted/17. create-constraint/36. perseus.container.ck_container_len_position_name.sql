ALTER TABLE perseus_dbo.container
ADD CONSTRAINT ck_container_len_position_name CHECK (length(position_name::text) <= 50);

