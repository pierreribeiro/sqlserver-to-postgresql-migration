CREATE OR REPLACE FUNCTION perseus_dbo.getupstreamcontainers(IN "@StartPoint" INTEGER, IN "@StartTime" TIMESTAMP WITHOUT TIME ZONE, IN "@EndTime" TIMESTAMP WITHOUT TIME ZONE)
RETURNS TABLE (start_point INTEGER, end_point INTEGER, neighbor INTEGER, path VARCHAR, level INTEGER)
AS
$BODY$
# variable_conflict use_column
BEGIN
    DROP TABLE IF EXISTS getupstreamcontainers$tmptbl;
    CREATE TEMPORARY TABLE getupstreamcontainers$tmptbl
    (start_point INTEGER,
        end_point INTEGER,
        neighbor INTEGER,
        path CITEXT,
        level INTEGER);

    IF "@EndTime" IS NULL THEN
        "@EndTime" := clock_timestamp();
    END IF;

    IF "@StartTime" IS NULL THEN
        "@StartTime" := clock_timestamp();
    END IF;
    WITH RECURSIVE upstream
    AS (SELECT
        ct.child_container_id
        /*
        [9997 - Severity HIGH - Unable to resolve the object child_container_id. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        child_container_id
        */
        AS start_point, ct.child_container_id
        /*
        [9997 - Severity HIGH - Unable to resolve the object child_container_id. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        child_container_id
        */
        AS parent, ct.parent_container_id
        /*
        [9997 - Severity HIGH - Unable to resolve the object parent_container_id. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        parent_container_id
        */
        AS child, CAST ('/' AS VARCHAR(255)) AS path, 1 AS level
        FROM container_relationship
        /*
        [9997 - Severity HIGH - Unable to resolve the object container_relationship. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        container_relationship
        */
        AS ct
        WHERE ct.child_container_id
        /*
        [9997 - Severity HIGH - Unable to resolve the object child_container_id. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        child_container_id
        */
        = "@StartPoint" AND ct.relationship_start
        /*
        [9997 - Severity HIGH - Unable to resolve the object relationship_start. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        relationship_start
        */
        <= "@EndTime" AND "@StartTime" <= COALESCE(ct.relationship_end
        /*
        [9997 - Severity HIGH - Unable to resolve the object relationship_end. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        relationship_end
        */, clock_timestamp())
    UNION ALL
    SELECT
        r.start_point, ct.child_container_id
        /*
        [9997 - Severity HIGH - Unable to resolve the object child_container_id. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        child_container_id
        */, ct.parent_container_id
        /*
        [9997 - Severity HIGH - Unable to resolve the object parent_container_id. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        parent_container_id
        */, CAST (r.path || CAST (r.child AS VARCHAR(25)) || '/' AS VARCHAR(255)), r.level + 1
        FROM container_relationship
        /*
        [9997 - Severity HIGH - Unable to resolve the object container_relationship. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        container_relationship
        */
        AS ct
        JOIN upstream AS r
            ON ct.child_container_id
            /*
            [9997 - Severity HIGH - Unable to resolve the object child_container_id. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
            child_container_id
            */
            = r.child
        WHERE ct.relationship_start
        /*
        [9997 - Severity HIGH - Unable to resolve the object relationship_start. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        relationship_start
        */
        <= "@EndTime" AND "@StartTime" <= COALESCE(ct.relationship_end
        /*
        [9997 - Severity HIGH - Unable to resolve the object relationship_end. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        relationship_end
        */, clock_timestamp()))
    INSERT INTO getupstreamcontainers$tmptbl
    SELECT
        start_point, child AS end_point, parent, path, level
        FROM upstream;
    INSERT INTO getupstreamcontainers$tmptbl
    VALUES ("@StartPoint", "@StartPoint", NULL, '', 0);
    RETURN QUERY
    SELECT
        *
        FROM getupstreamcontainers$tmptbl;
    DROP TABLE IF EXISTS getupstreamcontainers$tmptbl;
    RETURN;
END;
$BODY$
LANGUAGE  plpgsql;

