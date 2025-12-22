CREATE OR REPLACE FUNCTION perseus_dbo.fn_updateworkflowstepdepth()
RETURNS trigger
AS
$BODY$
DECLARE
    update$scope_id BOOLEAN;
    update$left_id BOOLEAN;
    update$right_id BOOLEAN;
BEGIN
    /* CREATING TEMPORARY TABLES */
    IF (TG_OP = 'INSERT') THEN
        CREATE TEMPORARY TABLE IF NOT EXISTS deleted$ad6a1e78
        AS
        TABLE inserted$ad6a1e78
        WITH NO DATA;
    ELSIF (TG_OP = 'DELETE') THEN
        CREATE TEMPORARY TABLE IF NOT EXISTS inserted$ad6a1e78
        AS
        TABLE deleted$ad6a1e78
        WITH NO DATA;
    END IF;
    CASE TG_OP
        WHEN 'INSERT' THEN
            update$scope_id = TRUE;
        WHEN 'UPDATE' THEN
            update$scope_id = ((SELECT
                array_agg(scope_id)
                FROM deleted$ad6a1e78) != (SELECT
                array_agg(scope_id)
                FROM inserted$ad6a1e78));
        ELSE
            update$scope_id := FALSE;
    END CASE;
    CASE TG_OP
        WHEN 'INSERT' THEN
            update$left_id = TRUE;
        WHEN 'UPDATE' THEN
            update$left_id = ((SELECT
                array_agg(left_id)
                FROM deleted$ad6a1e78) != (SELECT
                array_agg(left_id)
                FROM inserted$ad6a1e78));
        ELSE
            update$left_id := FALSE;
    END CASE;
    CASE TG_OP
        WHEN 'INSERT' THEN
            update$right_id = TRUE;
        WHEN 'UPDATE' THEN
            update$right_id = ((SELECT
                array_agg(right_id)
                FROM deleted$ad6a1e78) != (SELECT
                array_agg(right_id)
                FROM inserted$ad6a1e78));
        ELSE
            update$right_id := FALSE;
    END CASE;

    IF (update$scope_id OR update$left_id OR update$right_id) THEN
        UPDATE perseus_dbo.workflow_step AS rw
        SET depth = d.parent_count
        FROM perseus_dbo.workflow_step AS rw_dml
        JOIN inserted$ad6a1e78 AS ins
            ON ins.id = rw_dml.id
        JOIN (SELECT
            rw_dml.id, COUNT(*) AS parent_count
            FROM perseus_dbo.workflow_step AS rw_dml
            JOIN perseus_dbo.workflow_step AS p_rw
                ON rw_dml.scope_id = p_rw.scope_id AND p_rw.left_id <= rw_dml.left_id AND p_rw.right_id >= rw_dml.right_id
            GROUP BY rw_dml.id) AS d
            ON d.id = rw_dml.id
            WHERE rw.id = rw_dml.id;
    END IF;
    RETURN NULL;
END;
$BODY$
LANGUAGE  plpgsql;

