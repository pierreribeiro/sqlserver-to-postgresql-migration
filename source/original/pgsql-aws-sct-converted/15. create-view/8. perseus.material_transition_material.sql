CREATE OR REPLACE  VIEW perseus_dbo.material_transition_material (start_point, transition_id, end_point) AS
SELECT
    source_material AS start_point, transition_id, destination_material AS end_point
    FROM perseus_dbo.translated;

