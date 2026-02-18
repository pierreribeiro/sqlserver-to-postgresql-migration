CREATE OR REPLACE  VIEW perseus_dbo.combined_field_map_display_type (id, field_map_id, display_type_id, display, display_layout_id, manditory) AS
/* Display View */
SELECT
    id, field_map_id, display_type_id, display, display_layout_id, manditory
    FROM perseus_dbo.field_map_display_type
UNION
SELECT
    *
    FROM perseus_dbo.combined_sp_field_map_display_type;

