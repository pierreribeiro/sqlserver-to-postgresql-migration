CREATE OR REPLACE  VIEW perseus_dbo.vw_tom_perseus_sample_prep_materials (material_id) AS
SELECT
    ds.end_point AS material_id
    FROM perseus_dbo.goo AS g
    JOIN perseus_dbo.m_downstream AS ds
        ON ds.start_point = g.uid
    WHERE g.goo_type_id IN (40, 62)
UNION
SELECT
    g.uid AS material_id
    FROM perseus_dbo.goo AS g
    WHERE g.goo_type_id IN (40, 62);

