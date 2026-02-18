CREATE OR REPLACE FUNCTION perseus_dbo.getfermentationfatsmurf(IN "@GooUid" CITEXT)
RETURNS INTEGER
AS
$BODY$
/* ============================================= */
/* Author:		Dolan, Chris */
/* Create date: 2/27/2014 */
/* Description:	Get Fatsmurf for one Parent Run for a Material */
/* ============================================= */
DECLARE
    var_FatsmurfID INTEGER;
BEGIN
    SELECT
        fs.id
        INTO var_FatsmurfID
        FROM perseus_dbo.m_upstream AS us
        /*
        [7823 - Severity HIGH - PostgreSQL doesn't support table hints in DML statements. Revise your code to use PostgreSQL methods for performance tuning.]
        WITH(NOLOCK)
        */
        JOIN perseus_dbo.transition_material AS tm
        /*
        [7823 - Severity HIGH - PostgreSQL doesn't support table hints in DML statements. Revise your code to use PostgreSQL methods for performance tuning.]
        WITH(NOLOCK)
        */
            ON tm.material_id = us.end_point
        JOIN perseus_dbo.fatsmurf AS fs
        /*
        [7823 - Severity HIGH - PostgreSQL doesn't support table hints in DML statements. Revise your code to use PostgreSQL methods for performance tuning.]
        WITH(NOLOCK)
        */
            ON fs.uid = tm.transition_id
        INNER JOIN (SELECT
            start_point, MIN(us.level) AS first
            FROM perseus_dbo.m_upstream AS us
            /*
            [7823 - Severity HIGH - PostgreSQL doesn't support table hints in DML statements. Revise your code to use PostgreSQL methods for performance tuning.]
            WITH(NOLOCK)
            */
            JOIN perseus_dbo.transition_material AS tm
            /*
            [7823 - Severity HIGH - PostgreSQL doesn't support table hints in DML statements. Revise your code to use PostgreSQL methods for performance tuning.]
            WITH(NOLOCK)
            */
                ON tm.material_id = us.end_point
            JOIN perseus_dbo.fatsmurf AS fs
            /*
            [7823 - Severity HIGH - PostgreSQL doesn't support table hints in DML statements. Revise your code to use PostgreSQL methods for performance tuning.]
            WITH(NOLOCK)
            */
                ON fs.uid = tm.transition_id
            WHERE fs.smurf_id = 22
            GROUP BY start_point) AS innersmurf
            ON (innersmurf.first = us.level AND innersmurf.start_point = us.start_point)
        WHERE fs.smurf_id = 22 AND us.start_point = "@GooUid"
        LIMIT 1;
    RETURN var_FatsmurfID;
END;
$BODY$
LANGUAGE  plpgsql;

