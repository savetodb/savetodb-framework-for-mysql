-- =============================================
-- SaveToDB Framework for MySQL
-- Version 10.13, April 29, 2024
--
-- Copyright 2013-2024 Gartle LLC
--
-- License: MIT
-- =============================================

SELECT
    t.TABLE_SCHEMA AS `SCHEMA`
    , t.TABLE_NAME AS `NAME`
    , t.TABLE_TYPE AS `TYPE`
FROM
    INFORMATION_SCHEMA.TABLES t
WHERE
    t.TABLE_SCHEMA IN ('xls')
UNION ALL
SELECT
    r.ROUTINE_SCHEMA AS `SCHEMA`
    , r.ROUTINE_NAME AS `NAME`
    , r.ROUTINE_TYPE AS `TYPE`
FROM
    INFORMATION_SCHEMA.ROUTINES r
WHERE
    r.ROUTINE_SCHEMA IN ('xls')
ORDER BY
    `TYPE`
    , `SCHEMA`
    , `NAME`
