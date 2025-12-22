CREATE OR REPLACE FUNCTION perseus_dbo.goolist$aws$f(IN variable_name VARCHAR)
RETURNS void
AS
$BODY$
BEGIN
    EXECUTE 'DROP TABLE IF EXISTS ' || variable_name;
    EXECUTE 'CREATE TEMPORARY TABLE ' || variable_name || ' of perseus_dbo.goolist$aws$t;';
END;
$BODY$
LANGUAGE  plpgsql;

