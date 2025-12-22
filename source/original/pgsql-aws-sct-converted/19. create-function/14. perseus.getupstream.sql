CREATE OR REPLACE FUNCTION perseus_dbo.getupstream(IN "@StartPoint" INTEGER)
RETURNS TABLE (start_point INTEGER, end_point INTEGER, level INTEGER)
AS
$BODY$
# variable_conflict use_column
BEGIN
    DROP TABLE IF EXISTS getupstream$tmptbl;
    CREATE TEMPORARY TABLE getupstream$tmptbl
    (start_point INTEGER,
        end_point INTEGER,
        level INTEGER);
    WITH RECURSIVE tree
    AS (
    /* Anchor member definition */
    SELECT
        NULL AS child, g.id AS parent, 0 AS level
        FROM perseus_dbo.goo AS g
        WHERE g.id = "@StartPoint"
    UNION ALL
    /* Recursive member definition */
    SELECT
        g.id, c.id, r.level + 1
        FROM perseus_dbo.goo AS g
        JOIN perseus_dbo.goo AS c
            ON c.tree_scope_key
            /*
            [9997 - Severity HIGH - Unable to resolve the object tree_scope_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
            tree_scope_key
            */
            = g.tree_scope_key
            /*
            [9997 - Severity HIGH - Unable to resolve the object tree_scope_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
            tree_scope_key
            */
            AND c.tree_left_key
            /*
            [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
            tree_left_key
            */
            < g.tree_left_key
            /*
            [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
            tree_left_key
            */
            AND c.tree_right_key
            /*
            [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
            tree_right_key
            */
            > g.tree_right_key
            /*
            [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
            tree_right_key
            */
        JOIN tree AS r
            ON g.id = r.parent
    UNION ALL
    SELECT
        gr.child, gr.parent, r.level + 1
        FROM perseus_dbo.goo AS g
        JOIN perseus_dbo.goo_relationship AS gr
            ON g.id = gr.child
        JOIN tree AS r
            ON gr.child = r.parent)
    INSERT INTO getupstream$tmptbl
    SELECT
        "@StartPoint", parent, MIN(level) AS level
        FROM tree
        GROUP BY parent;
    RETURN QUERY
    SELECT
        *
        FROM getupstream$tmptbl;
    DROP TABLE IF EXISTS getupstream$tmptbl;
    RETURN;
END;
$BODY$
LANGUAGE  plpgsql;

