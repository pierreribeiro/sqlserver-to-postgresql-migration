CREATE OR REPLACE FUNCTION perseus_dbo.getdownstream(IN "@StartPoint" INTEGER)
RETURNS TABLE (start_point INTEGER, end_point INTEGER)
AS
$BODY$
# variable_conflict use_column
BEGIN
    DROP TABLE IF EXISTS getdownstream$tmptbl;
    CREATE TEMPORARY TABLE getdownstream$tmptbl
    (start_point INTEGER,
        end_point INTEGER);
    WITH RECURSIVE tree
    AS (
    /* Anchor member definition */
    SELECT
        NULL AS parent, g.id AS child
        FROM perseus_dbo.goo AS g
        WHERE g.id = "@StartPoint"
    UNION ALL
    /* Recursive member definition */
    SELECT
        g.id, c.id
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
            > g.tree_left_key
            /*
            [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
            tree_left_key
            */
            AND c.tree_right_key
            /*
            [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
            tree_right_key
            */
            < g.tree_right_key
            /*
            [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
            tree_right_key
            */
        JOIN tree AS r
            ON g.id = r.child
    UNION ALL
    SELECT
        gr.parent, gr.child
        FROM perseus_dbo.goo AS g
        JOIN perseus_dbo.goo_relationship AS gr
            ON g.id = gr.parent
        JOIN tree AS r
            ON gr.parent = r.child)
    INSERT INTO getdownstream$tmptbl
    SELECT
        "@StartPoint", child
        FROM tree;
    RETURN QUERY
    SELECT
        *
        FROM getdownstream$tmptbl;
    DROP TABLE IF EXISTS getdownstream$tmptbl;
    RETURN;
END;
$BODY$
LANGUAGE  plpgsql;

