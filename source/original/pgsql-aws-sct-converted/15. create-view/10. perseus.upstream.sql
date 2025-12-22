CREATE OR REPLACE  VIEW perseus_dbo.upstream (start_point, end_point, path, level) AS
WITH RECURSIVE upstream
AS (SELECT
    pt.destination_material AS start_point, pt.destination_material AS parent, pt.source_material AS child, CAST ('/' AS VARCHAR(255)) AS path, 1 AS level
    FROM perseus_dbo.translated AS pt
UNION ALL
SELECT
    r.start_point, pt.destination_material, pt.source_material, CAST (r.path || r.child || '/' AS VARCHAR(255)), r.level + 1
    FROM perseus_dbo.translated AS pt
    JOIN upstream AS r
        ON pt.destination_material = r.child
    WHERE pt.destination_material != pt.source_material)
SELECT
    start_point, child AS end_point, path, level
    FROM upstream;

