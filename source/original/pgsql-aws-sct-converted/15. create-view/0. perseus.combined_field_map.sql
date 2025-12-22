CREATE OR REPLACE  VIEW perseus_dbo.combined_field_map (id, field_map_block_id, name, description, display_order, setter, lookup, lookup_service, nullable, field_map_type_id, database_id, save_sequence, onchange, field_map_set_id) AS
/* Field Views */
SELECT
    id, field_map_block_id, name, description, display_order, setter, lookup, lookup_service, nullable, field_map_type_id, database_id, save_sequence, onchange, field_map_set_id
    FROM perseus_dbo.field_map
UNION
SELECT
    *
    FROM perseus_dbo.combined_sp_field_map;

