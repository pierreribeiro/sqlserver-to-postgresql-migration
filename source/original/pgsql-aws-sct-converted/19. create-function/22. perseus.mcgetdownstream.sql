CREATE OR REPLACE FUNCTION perseus_dbo.mcgetdownstream(IN "@StartPoint" CITEXT)
RETURNS TABLE (start_point VARCHAR, end_point VARCHAR, neighbor VARCHAR, path VARCHAR, level INTEGER)
AS
$BODY$
# variable_conflict use_column
BEGIN
    DROP TABLE IF EXISTS mcgetdownstream$tmptbl;
    CREATE TEMPORARY TABLE mcgetdownstream$tmptbl
    (start_point CITEXT,
        end_point CITEXT,
        neighbor CITEXT,
        path CITEXT,
        level INTEGER);
    WITH RECURSIVE downstream
    AS (SELECT
        pt.source_material AS start_point, pt.source_material AS parent, pt.destination_material AS child, CAST ('/' AS VARCHAR(500)) AS path, 1 AS level
        FROM perseus_dbo.translated AS pt
        WHERE (pt.source_material = "@StartPoint" OR pt.transition_id = "@StartPoint")
    UNION ALL
    SELECT
        r.start_point, pt.source_material, pt.destination_material, CAST (r.path || r.child || '/' AS VARCHAR(500)), r.level + 1
        FROM perseus_dbo.translated AS pt
        JOIN downstream AS r
            ON pt.source_material = r.child
        WHERE pt.source_material != pt.destination_material)
    INSERT INTO mcgetdownstream$tmptbl
    SELECT
        start_point, child AS end_point, parent, path, level
        FROM downstream;
    INSERT INTO mcgetdownstream$tmptbl
    VALUES ("@StartPoint", "@StartPoint", NULL, '', 0);
    RETURN QUERY
    SELECT
        *
        FROM mcgetdownstream$tmptbl;
    DROP TABLE IF EXISTS mcgetdownstream$tmptbl;
    RETURN;
END;
/* SELECT * FROM McGetDownStream('m5963') */
$BODY$
LANGUAGE  plpgsql;

