CREATE OR REPLACE  VIEW perseus_dbo.downstream (start_point, end_point, path, level) AS
WITH RECURSIVE downstream
AS (SELECT
    pt.source_material AS start_point, pt.source_material AS parent, pt.destination_material AS child, CAST ('/' AS VARCHAR(255)) AS path, 1 AS level
    FROM perseus_dbo.translated AS pt
UNION ALL
SELECT
    r.start_point, pt.source_material, pt.destination_material, CAST (r.path || r.child || '/' AS VARCHAR(255)), r.level + 1
    FROM perseus_dbo.translated AS pt
    JOIN downstream AS r
        ON pt.source_material = r.child
    WHERE pt.source_material != pt.destination_material)
SELECT
    start_point, child AS end_point, path, level
    FROM downstream;

