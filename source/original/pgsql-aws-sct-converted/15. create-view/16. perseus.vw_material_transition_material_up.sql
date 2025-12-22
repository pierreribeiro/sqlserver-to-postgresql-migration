CREATE OR REPLACE  VIEW perseus_dbo.vw_material_transition_material_up (source_uid, destination_uid, transition_uid) AS
/* DROP VIEW [dbo].[vw_material_transition_material_up] */
SELECT
    mt.material_id AS source_uid, tm.material_id AS destination_uid, tm.transition_id AS transition_uid
    FROM perseus_dbo.transition_material AS tm
    LEFT OUTER JOIN perseus_dbo.material_transition AS mt
        ON tm.transition_id = mt.transition_id;

