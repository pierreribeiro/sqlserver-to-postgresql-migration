CREATE OR REPLACE  VIEW perseus_dbo.vw_process_upstream (source_process, destination_process, source_process_type, destination_process_type, connecting_material) AS
SELECT
    tm.transition_id AS source_process, mt.transition_id AS destination_process, fs.smurf_id AS source_process_type, fs2.smurf_id AS destination_process_type, mt.material_id AS connecting_material
    FROM perseus_dbo.material_transition AS mt
    JOIN perseus_dbo.transition_material AS tm
        ON tm.material_id = mt.material_id
    JOIN perseus_dbo.fatsmurf AS fs
        ON mt.transition_id = fs.uid
    JOIN perseus_dbo.fatsmurf AS fs2
        ON tm.transition_id = fs2.uid;

