CREATE OR REPLACE FUNCTION perseus_dbo.usp_updatemdownstream()
AS
$BODY$
BEGIN
    /* SET NOCOUNT ON added to prevent extra result sets from */
    /* interfering with SELECT statements. */
    PERFORM perseus_dbo.goolist$aws$f('"var_DsGooUids$aws$tmp"');
    /*
    [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
    BEGIN TRANSACTION
    */
    INSERT INTO "var_DsGooUids$aws$tmp"
    SELECT DISTINCT
        uid
        FROM (SELECT
            g.uid
            FROM perseus_dbo.material_transition_material AS mtm
            JOIN perseus_dbo.goo AS g
                ON g.uid = mtm.start_point
            WHERE NOT EXISTS (SELECT
                *
                FROM perseus_dbo.m_downstream AS us
                WHERE us.start_point = mtm.start_point)
            ORDER BY g.added_on DESC NULLS LAST
            LIMIT 500) AS d;
    INSERT INTO perseus_dbo.m_downstream (start_point, end_point, path, level)
    SELECT
        start_point, end_point, path, level
        FROM perseus_dbo.mcgetdownstreambylist("var_DsGooUids$aws$tmp");
    /*
    [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
    COMMIT
    */
    /*
    [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
    BEGIN TRANSACTION
    */
    /* create paths to newly created downstream items that wouldn't */
    /* be caught by the above, which only creates new downstream items */
    /* where the upstream doesn't exist. */
    INSERT INTO perseus_dbo.m_downstream (start_point, end_point, path, level)
    SELECT
        end_point, start_point, perseus_dbo.reversepath(path), level
        FROM perseus_dbo.m_upstream AS up
        WHERE NOT EXISTS (SELECT
            1
            FROM perseus_dbo.m_downstream AS down
            WHERE up.end_point = down.start_point AND up.start_point = down.end_point AND perseus_dbo.reversepath(up.path) = down.path)
        LIMIT 500;
    /*
    [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
    COMMIT
    */
END;
$BODY$
LANGUAGE  plpgsql;

