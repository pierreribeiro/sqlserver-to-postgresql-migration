CREATE OR REPLACE FUNCTION perseus_dbo.reversepath(IN "@source" CITEXT)
RETURNS CITEXT
AS
$BODY$
/* ============================================= */
/* Author:		Dolan */
/* Create date: 7/14/2014 */
/* Description:	Given a path of format /uid/uid2/uid3/ */
/* reverse to /uid3/uid2/uid/. */
/* Used to reverse mirror the m_ustream */
/* table in m_downstream. */
/* ============================================= */
DECLARE
    var_dest CITEXT;
BEGIN
    var_dest := '';

    IF LENGTH("@source")::CITEXT > 0 THEN
        /* chop off initial / (indexed by 1) */
        "@source" := SUBSTR("@source", 2, LENGTH("@source"));

        WHILE LENGTH("@source")::CITEXT > 0 LOOP
            var_dest := SUBSTR("@source", 0, STRPOS("@source", '/')) || '/' || var_dest;
            "@source" := SUBSTR("@source", STRPOS("@source", '/') + 1, LENGTH("@source"));
        END LOOP;
        var_dest := '/' || var_dest;
    END IF;
    RETURN var_dest;
END;
$BODY$
LANGUAGE  plpgsql;

