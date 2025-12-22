CREATE OR REPLACE  VIEW perseus_dbo.translated (source_material, destination_material, transition_id) AS
SELECT
    mt.material_id AS source_material, tm.material_id AS destination_material, mt.transition_id
    FROM perseus_dbo.material_transition AS mt
    JOIN perseus_dbo.transition_material AS tm
        ON tm.transition_id = mt.transition_id;

