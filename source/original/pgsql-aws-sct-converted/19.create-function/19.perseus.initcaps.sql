CREATE OR REPLACE FUNCTION perseus_dbo.initcaps(IN "@sInitCaps" CITEXT)
RETURNS CITEXT
AS
$BODY$
DECLARE
    var_nNumSpaces INTEGER;
    var_sParseString CITEXT;
    var_sParsedString CITEXT;
BEGIN
    SELECT
        (LENGTH("@sInitCaps") - LENGTH(regexp_replace("@sInitCaps", ' ', '', 'gi'))) + 1
        INTO var_nNumSpaces;
    SELECT
        regexp_replace("@sInitCaps", ' ', '%', 'gi')
        INTO "@sInitCaps";

    WHILE var_nNumSpaces > 0 LOOP
        IF (STRPOS("@sInitCaps", '%')::CITEXT <> 0) THEN
            SELECT
                SUBSTR("@sInitCaps", 1, STRPOS("@sInitCaps", '%'))
                INTO var_sParseString;
            SELECT
                SUBSTR("@sInitCaps", (STRPOS("@sInitCaps", '%') + 1), LENGTH("@sInitCaps"))
                INTO "@sInitCaps";
            SELECT
                var_nNumSpaces - 1
                INTO var_nNumSpaces;
        ELSE
            SELECT
                var_nNumSpaces - 1
                INTO var_nNumSpaces;
            SELECT
                "@sInitCaps"
                INTO var_sParseString;
        END IF;
        SELECT
            regexp_replace(COALESCE(var_sParsedString, '') ||
            CASE
                WHEN LENGTH(var_sParseString) = 1 THEN UPPER(var_sParseString)
                ELSE UPPER(SUBSTR(var_sParseString, 1, 1)) || LOWER(SUBSTR(var_sParseString, 2, LENGTH(var_sParseString)))
            END, '%', ' ', 'gi')
            INTO var_sParsedString;
    END LOOP;
    RETURN (var_sParsedString);
END;
$BODY$
LANGUAGE  plpgsql;

