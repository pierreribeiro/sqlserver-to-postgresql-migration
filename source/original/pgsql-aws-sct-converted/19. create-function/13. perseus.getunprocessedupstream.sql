CREATE OR REPLACE FUNCTION perseus_dbo.getunprocessedupstream(IN "@StartPoint" CITEXT)
RETURNS TABLE (start_point VARCHAR, end_point VARCHAR, neighbor VARCHAR, path VARCHAR, level INTEGER)
AS
$BODY$
# variable_conflict use_column
BEGIN
    DROP TABLE IF EXISTS getunprocessedupstream$tmptbl;
    CREATE TEMPORARY TABLE getunprocessedupstream$tmptbl
    (start_point CITEXT,
        end_point CITEXT,
        neighbor CITEXT,
        path CITEXT,
        level INTEGER);
    WITH RECURSIVE upstream
    AS (SELECT
        pt.destination_material AS start_point, pt.destination_material AS parent, pt.source_material AS child, CAST ('/' AS VARCHAR(255)) AS path, 1 AS level
        FROM perseus_dbo.translated AS pt
        JOIN perseus_dbo.fatsmurf AS fs
            ON fs.uid = pt.transition_id
        WHERE (pt.destination_material = "@StartPoint" OR pt.transition_id = "@StartPoint") AND fs.smurf_id IN (110, 111)
    UNION ALL
    SELECT
        r.start_point, pt.destination_material, pt.source_material, CAST (r.path || r.child || '/' AS VARCHAR(255)), r.level + 1
        FROM perseus_dbo.translated AS pt
        JOIN perseus_dbo.fatsmurf AS fs
            ON fs.uid = pt.transition_id
        JOIN upstream AS r
            ON pt.destination_material = r.child
        WHERE pt.destination_material != pt.source_material AND fs.smurf_id IN (110, 111))
    INSERT INTO getunprocessedupstream$tmptbl
    SELECT
        start_point, child AS end_point, parent, path, level
        FROM upstream;
    INSERT INTO getunprocessedupstream$tmptbl
    VALUES ("@StartPoint", "@StartPoint", NULL, '', 0);
    RETURN QUERY
    SELECT
        *
        FROM getunprocessedupstream$tmptbl;
    DROP TABLE IF EXISTS getunprocessedupstream$tmptbl;
    RETURN;
END;
$BODY$
LANGUAGE  plpgsql;

