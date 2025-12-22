CREATE OR REPLACE PROCEDURE perseus_dbo.removearc(IN "@MaterialUid" CITEXT, IN "@TransitionUid" CITEXT, IN "@Direction" CITEXT)
AS 
$BODY$
/*
*
DECLARE @FormerDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
DECLARE @FormerUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
DECLARE @DeltaDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
DECLARE @DeltaUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
DECLARE @NewDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
DECLARE @NewUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))

INSERT INTO @FormerDownstream (start_point, end_point, path)
SELECT start_point, end_point, path FROM dbo.McGetDownStream(@MaterialUid)

INSERT INTO @FormerUpstream (start_point, end_point, path)
SELECT start_point, end_point, path FROM dbo.McGetUpStream(@MaterialUid)
*
*/
BEGIN
    IF LOWER("@Direction") = LOWER('PT')
    /*
    [7795 - Severity LOW - In PostgreSQL, string operations are case sensitive. Review the converted code to make sure that it compares strings correctly.]
    @Direction = 'PT'
    */
    THEN
        DELETE FROM perseus_dbo.material_transition
            WHERE material_id = "@MaterialUid" AND transition_id = "@TransitionUid";
    ELSE
        DELETE FROM perseus_dbo.transition_material
            WHERE material_id = "@MaterialUid" AND transition_id = "@TransitionUid";
    END IF;
END;
/*
*
INSERT INTO @NewDownstream (start_point, end_point, path)
SELECT start_point, end_point, path FROM dbo.McGetDownStream(@MaterialUid)

INSERT INTO @NewUpstream (start_point, end_point, path)
SELECT start_point, end_point, path FROM dbo.McGetUpStream(@MaterialUid)

INSERT INTO @DeltaUpstream (start_point, end_point, path)
SELECT start_point, end_point, path
FROM @FormerUpstream f
WHERE NOT EXISTS (SELECT * FROM @NewUpstream n WHERE f.start_point = n.start_point AND f.end_point = n.end_point AND f.path = n.path)

INSERT INTO @DeltaDownstream (start_point, end_point, path)
SELECT start_point, end_point, path
FROM @FormerDownstream f
WHERE NOT EXISTS (SELECT * FROM @NewDownstream n WHERE f.start_point = n.start_point AND f.end_point = n.end_point AND f.path = n.path)

DELETE FROM m_downstream
WHERE EXISTS (
	SELECT * FROM @DeltaUpstream r
	JOIN @FormerDownstream fds ON fds.start_point = r.start_point
	WHERE m_downstream.end_point = fds.end_point
	AND m_downstream.start_point = r.end_point
	AND r.start_point != r.end_point
)

DELETE FROM m_downstream
WHERE EXISTS (
	SELECT *
	FROM @DeltaDownstream r
	JOIN @FormerUpstream fu ON fu.start_point = r.start_point
	WHERE m_downstream.start_point = fu.end_point
	AND m_downstream.end_point = r.end_point
	AND r.start_point ! = r.end_point
)

--SELECT * FROM @DeltaUpstream
--SELECT * FROM @DeltaDownstream

DELETE FROM m_upstream
WHERE EXISTS (
	SELECT * FROM @DeltaDownstream r
	WHERE r.end_point = m_upstream.start_point
	AND r.start_point = m_upstream.end_point
)

DELETE FROM m_upstream
WHERE EXISTS (
	SELECT * FROM @FormerDownstream fds
	JOIN @DeltaUpstream r ON fds.start_point = r.start_point
	WHERE m_upstream.start_point = fds.end_point
	AND m_upstream.end_point = r.end_point
)

DELETE FROM m_upstream
WHERE EXISTS (
	SELECT * FROM @FormerDownstream fds
	JOIN @DeltaUpstream r ON fds.start_point = r.start_point
	WHERE m_upstream.start_point = r.end_point
	AND m_upstream.end_point = fds.end_point
)
*
*/
$BODY$
LANGUAGE plpgsql;

