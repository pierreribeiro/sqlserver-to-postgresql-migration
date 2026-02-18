CREATE OR REPLACE FUNCTION perseus_dbo.mcgetupstream(IN "@StartPoint" CITEXT)
RETURNS TABLE (start_point VARCHAR, end_point VARCHAR, neighbor VARCHAR, path VARCHAR, level INTEGER)
AS
$BODY$
# variable_conflict use_column
BEGIN
    DROP TABLE IF EXISTS mcgetupstream$tmptbl;
    CREATE TEMPORARY TABLE mcgetupstream$tmptbl
    (start_point CITEXT,
        end_point CITEXT,
        neighbor CITEXT,
        path CITEXT,
        level INTEGER);
    WITH RECURSIVE upstream
    AS (SELECT
        pt.destination_material AS start_point, pt.destination_material AS parent, pt.source_material AS child, CAST ('/' AS VARCHAR(500)) AS path, 1 AS level
        FROM perseus_dbo.translated AS pt
        /*
        [7823 - Severity HIGH - PostgreSQL doesn't support table hints in DML statements. Revise your code to use PostgreSQL methods for performance tuning.]
        WITH (NOLOCK)
        */
        WHERE (pt.destination_material = "@StartPoint" OR pt.transition_id = "@StartPoint")
    UNION ALL
    SELECT
        r.start_point, pt.destination_material, pt.source_material, CAST (r.path || r.child || '/' AS VARCHAR(500)), r.level + 1
        FROM perseus_dbo.translated AS pt
        /*
        [7823 - Severity HIGH - PostgreSQL doesn't support table hints in DML statements. Revise your code to use PostgreSQL methods for performance tuning.]
        WITH (NOLOCK)
        */
        JOIN upstream AS r
            ON pt.destination_material = r.child
        WHERE pt.destination_material != pt.source_material)
    INSERT INTO mcgetupstream$tmptbl
    SELECT
        start_point, child AS end_point, parent, path, level
        FROM upstream
        /*
        [7823 - Severity HIGH - PostgreSQL doesn't support table hints in DML statements. Revise your code to use PostgreSQL methods for performance tuning.]
        WITH (NOLOCK)
        */;
    INSERT INTO mcgetupstream$tmptbl
    VALUES ("@StartPoint", "@StartPoint", NULL, '', 0);
    RETURN QUERY
    SELECT
        *
        FROM mcgetupstream$tmptbl;
    DROP TABLE IF EXISTS mcgetupstream$tmptbl;
    RETURN;
END;
$BODY$
LANGUAGE  plpgsql;

