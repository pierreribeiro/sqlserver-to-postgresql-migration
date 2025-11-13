CREATE OR REPLACE PROCEDURE perseus_dbo.sp_move_node(IN par_myid INTEGER, IN par_parentid INTEGER)
AS 
$BODY$
DECLARE
    var_myFormerScope VARCHAR(100);
    var_myFormerLeft INTEGER;
    var_myFormerRight INTEGER;
    var_myParentScope VARCHAR(100);
    var_myParentLeft INTEGER;
BEGIN
    SELECT
        tree_scope_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_scope_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_scope_key
        */, tree_left_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_left_key
        */
        INTO var_myParentScope, var_myParentLeft
        FROM perseus_dbo.goo
        WHERE id = par_parentId;
    SELECT
        g.tree_scope_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_scope_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_scope_key
        */, g.tree_left_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_left_key
        */, g.tree_right_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_right_key
        */
        INTO var_myFormerScope, var_myFormerLeft, var_myFormerRight
        FROM perseus_dbo.goo AS g
        WHERE g.id = par_myId;
    UPDATE perseus_dbo.goo
    SET tree_left_key
    /*
    [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    tree_left_key
    */
    = tree_left_key
    /*
    [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    tree_left_key
    */
    + (var_myFormerRight - var_myFormerLeft) + 1
        WHERE tree_left_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_left_key
        */
        > var_myParentLeft AND tree_scope_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_scope_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_scope_key
        */
        = var_myParentScope::VARCHAR;
    UPDATE perseus_dbo.goo
    SET tree_right_key
    /*
    [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    tree_right_key
    */
    = tree_right_key
    /*
    [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    tree_right_key
    */
    + (var_myFormerRight - var_myFormerLeft) + 1
        WHERE tree_right_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_right_key
        */
        > var_myParentLeft AND tree_scope_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_scope_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_scope_key
        */
        = var_myParentScope::VARCHAR;
    UPDATE perseus_dbo.goo
    SET tree_scope_key
    /*
    [9997 - Severity HIGH - Unable to resolve the object tree_scope_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    tree_scope_key
    */
    = var_myParentScope, tree_left_key
    /*
    [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    tree_left_key
    */
    = var_myParentLeft + (tree_left_key
    /*
    [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    tree_left_key
    */
    - var_myFormerLeft) + 1, tree_right_key
    /*
    [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    tree_right_key
    */
    = var_myParentLeft + (tree_right_key
    /*
    [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    tree_right_key
    */
    - var_myFormerLeft) + 1
        WHERE tree_scope_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_scope_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_scope_key
        */
        = var_myFormerScope::VARCHAR AND tree_left_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_left_key
        */
        >= var_myFormerLeft AND tree_right_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_right_key
        */
        <= var_myFormerRight;
    UPDATE perseus_dbo.goo
    SET tree_left_key
    /*
    [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    tree_left_key
    */
    = tree_left_key
    /*
    [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    tree_left_key
    */
    - (var_myFormerRight - var_myFormerLeft) - 1
        WHERE tree_left_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_left_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_left_key
        */
        > var_myFormerRight AND tree_scope_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_scope_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_scope_key
        */
        = var_myFormerScope::VARCHAR;
    UPDATE perseus_dbo.goo
    SET tree_right_key
    /*
    [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    tree_right_key
    */
    = tree_right_key
    /*
    [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
    tree_right_key
    */
    - (var_myFormerRight - var_myFormerLeft) - 1
        WHERE tree_right_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_right_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_right_key
        */
        > var_myFormerRight AND tree_scope_key
        /*
        [9997 - Severity HIGH - Unable to resolve the object tree_scope_key. Verify if the unresolved object is present in the database. If it isn't, check the object name or add the object. If the object is present, transform the code manually.]
        tree_scope_key
        */
        = var_myFormerScope::VARCHAR;
END;
$BODY$
LANGUAGE plpgsql;

