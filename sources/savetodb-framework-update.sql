-- =============================================
-- SaveToDB Framework for MySQL
-- Version 10.6, December 13, 2022
--
-- This script updates SaveToDB Framework 10 to the latest version
--
-- Copyright 2013-2022 Gartle LLC
--
-- License: MIT
-- =============================================

SELECT CASE WHEN 1006 <= CAST(substr(HANDLER_CODE, 1, instr(HANDLER_CODE, '.') - 1) AS unsigned) * 100 + CAST(substr(HANDLER_CODE, instr(HANDLER_CODE, '.') + 1) AS decimal) THEN 'SaveToDB Framework is up-to-date. Update skipped' ELSE HANDLER_CODE END AS check_version FROM xls.handlers WHERE TABLE_SCHEMA = 'xls' AND TABLE_NAME = 'savetodb_framework' AND COLUMN_NAME = 'version' AND EVENT_NAME = 'Information' LIMIT 1;

UPDATE xls.handlers t,
    (
    SELECT
        NULL AS TABLE_SCHEMA
        , NULL AS TABLE_NAME
        , NULL AS COLUMN_NAME
        , NULL AS EVENT_NAME
        , NULL AS HANDLER_SCHEMA
        , NULL AS HANDLER_NAME
        , NULL AS HANDLER_TYPE
        , NULL AS HANDLER_CODE
        , NULL AS TARGET_WORKSHEET
        , NULL AS MENU_ORDER
        , NULL AS EDIT_PARAMETERS

    UNION ALL SELECT 'xls', 'savetodb_framework', 'version', 'Information', NULL, NULL, 'ATTRIBUTE', '10.6', NULL, NULL, NULL
    UNION ALL SELECT 'xls', 'handlers', 'EVENT_NAME', 'ValidationList', NULL, NULL, 'VALUES', 'Actions, AddHyperlinks, AddStateColumn, Authentication, BitColumn, Change, ContextMenu, ConvertFormulas, DataTypeBit, DataTypeBoolean, DataTypeDate, DataTypeDateTime, DataTypeDateTimeOffset, DataTypeDouble, DataTypeInt, DataTypeGuid, DataTypeString, DataTypeTime, DataTypeTimeSpan, DefaultListObject, DefaultValue, DependsOn, DoNotAddChangeHandler, DoNotAddDependsOn, DoNotAddManyToMany, DoNotAddValidation, DoNotChange, DoNotConvertFormulas, DoNotKeepComments, DoNotKeepFormulas, DoNotSave, DoNotSelect, DoNotSort, DoNotTranslate, DoubleClick, DynamicColumns, Format, Formula, FormulaValue, Information, JsonForm, KeepFormulas, KeepComments, License, LoadFormat, ManyToMany, ParameterValues, ProtectRows, RegEx, SaveFormat, SaveWithoutTransaction, SelectionChange, SelectionList, SelectPeriod, SyncParameter, UpdateChangedCellsOnly, UpdateEntireRow, ValidationList', NULL, NULL, NULL

    ) s
SET
    t.HANDLER_CODE = s.HANDLER_CODE
    , t.TARGET_WORKSHEET = s.TARGET_WORKSHEET
    , t.MENU_ORDER = s.MENU_ORDER
    , t.EDIT_PARAMETERS = s.EDIT_PARAMETERS
WHERE
    s.TABLE_NAME IS NOT NULL
    AND t.TABLE_SCHEMA = s.TABLE_SCHEMA
    AND t.TABLE_NAME = s.TABLE_NAME
    AND COALESCE(t.COLUMN_NAME, '') = COALESCE(s.COLUMN_NAME, '')
    AND t.EVENT_NAME = s.EVENT_NAME
    AND COALESCE(t.HANDLER_SCHEMA, '') = COALESCE(s.HANDLER_SCHEMA, '')
    AND COALESCE(t.HANDLER_NAME, '') = COALESCE(s.HANDLER_NAME, '')
    AND COALESCE(t.HANDLER_TYPE, '') = COALESCE(s.HANDLER_TYPE, '')
    AND (
    NOT COALESCE(t.HANDLER_CODE, '') = COALESCE(s.HANDLER_CODE, '')
    OR NOT COALESCE(t.TARGET_WORKSHEET, '') = COALESCE(s.TARGET_WORKSHEET, '')
    OR NOT COALESCE(t.MENU_ORDER, -1) = COALESCE(s.MENU_ORDER, -1)
    OR NOT COALESCE(t.EDIT_PARAMETERS, 0) = COALESCE(s.EDIT_PARAMETERS, 0)
    );

INSERT INTO xls.handlers
    ( TABLE_SCHEMA
    , TABLE_NAME
    , COLUMN_NAME
    , EVENT_NAME
    , HANDLER_SCHEMA
    , HANDLER_NAME
    , HANDLER_TYPE
    , HANDLER_CODE
    , TARGET_WORKSHEET
    , MENU_ORDER
    , EDIT_PARAMETERS
    )
SELECT
    s.TABLE_SCHEMA
    , s.TABLE_NAME
    , s.COLUMN_NAME
    , s.EVENT_NAME
    , s.HANDLER_SCHEMA
    , s.HANDLER_NAME
    , s.HANDLER_TYPE
    , s.HANDLER_CODE
    , s.TARGET_WORKSHEET
    , s.MENU_ORDER
    , s.EDIT_PARAMETERS
FROM
    (
    SELECT
        NULL AS TABLE_SCHEMA
        , NULL AS TABLE_NAME
        , NULL AS COLUMN_NAME
        , NULL AS EVENT_NAME
        , NULL AS HANDLER_SCHEMA
        , NULL AS HANDLER_NAME
        , NULL AS HANDLER_TYPE
        , NULL AS HANDLER_CODE
        , NULL AS TARGET_WORKSHEET
        , NULL AS MENU_ORDER
        , NULL AS EDIT_PARAMETERS

    UNION ALL SELECT 'xls', 'savetodb_framework', 'version', 'Information', NULL, NULL, 'ATTRIBUTE', '10.6', NULL, NULL, NULL
    UNION ALL SELECT 'xls', 'handlers', 'EVENT_NAME', 'ValidationList', NULL, NULL, 'VALUES', 'Actions, AddHyperlinks, AddStateColumn, Authentication, BitColumn, Change, ContextMenu, ConvertFormulas, DataTypeBit, DataTypeBoolean, DataTypeDate, DataTypeDateTime, DataTypeDateTimeOffset, DataTypeDouble, DataTypeInt, DataTypeGuid, DataTypeString, DataTypeTime, DataTypeTimeSpan, DefaultListObject, DefaultValue, DependsOn, DoNotAddChangeHandler, DoNotAddDependsOn, DoNotAddManyToMany, DoNotAddValidation, DoNotChange, DoNotConvertFormulas, DoNotKeepComments, DoNotKeepFormulas, DoNotSave, DoNotSelect, DoNotSort, DoNotTranslate, DoubleClick, DynamicColumns, Format, Formula, FormulaValue, Information, JsonForm, KeepFormulas, KeepComments, License, LoadFormat, ManyToMany, ParameterValues, ProtectRows, RegEx, SaveFormat, SaveWithoutTransaction, SelectionChange, SelectionList, SelectPeriod, SyncParameter, UpdateChangedCellsOnly, UpdateEntireRow, ValidationList', NULL, NULL, NULL

    ) s
    LEFT OUTER JOIN xls.handlers t ON
        t.TABLE_SCHEMA = s.TABLE_SCHEMA
        AND t.TABLE_NAME = s.TABLE_NAME
        AND COALESCE(t.COLUMN_NAME, '') = COALESCE(s.COLUMN_NAME, '')
        AND t.EVENT_NAME = s.EVENT_NAME
        AND COALESCE(t.HANDLER_SCHEMA, '') = COALESCE(s.HANDLER_SCHEMA, '')
        AND COALESCE(t.HANDLER_NAME, '') = COALESCE(s.HANDLER_NAME, '')
        AND COALESCE(t.HANDLER_TYPE, '') = COALESCE(s.HANDLER_TYPE, '')
WHERE
    t.TABLE_NAME IS NULL
    AND s.TABLE_NAME IS NOT NULL;

DROP PROCEDURE IF EXISTS xls.xl_actions_add_to_xls_users;

DROP PROCEDURE IF EXISTS xls.xl_actions_add_to_xls_formats;

DROP PROCEDURE IF EXISTS xls.xl_actions_add_to_xls_developers;

DROP PROCEDURE IF EXISTS xls.xl_actions_remove_from_xls_users;

DROP PROCEDURE IF EXISTS xls.xl_actions_remove_from_xls_formats;

DROP PROCEDURE IF EXISTS xls.xl_actions_remove_from_xls_developers;

DROP PROCEDURE IF EXISTS xls.xl_update_table_format;

DELIMITER //

CREATE PROCEDURE xls.xl_actions_add_to_xls_developers (
    user VARCHAR(128)
    , host VARCHAR(128)
    )
BEGIN

SELECT 1 INTO @exist FROM mysql.user u WHERE u.user = user AND u.host = host;

IF @exist = 1 THEN

    SET @sql = CONCAT('GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON xls.* TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('SHOW GRANTS FOR ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    DEALLOCATE PREPARE stmt;

END IF;

END
//

CREATE PROCEDURE xls.xl_actions_add_to_xls_formats (
    user VARCHAR(128)
    , host VARCHAR(128)
    , extended bit(1)
    )
BEGIN

SELECT 1 INTO @exist FROM mysql.user u WHERE u.user = user AND u.host = host;

IF @exist = 1 AND extended = 0 THEN

    SET @sql = CONCAT('GRANT SELECT, INSERT, UPDATE, DELETE ON xls.formats TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('SHOW GRANTS FOR ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    DEALLOCATE PREPARE stmt;
END IF;

IF @exist = 1 AND extended = 1 THEN

    SET @sql = CONCAT('GRANT EXECUTE ON PROCEDURE xls.xl_update_table_format TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('SHOW GRANTS FOR ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    DEALLOCATE PREPARE stmt;
END IF;

END
//

CREATE PROCEDURE xls.xl_actions_add_to_xls_users (
    user VARCHAR(128)
    , host VARCHAR(128)
    , extended bit(1)
    )
BEGIN

SELECT 1 INTO @exist FROM mysql.user u WHERE u.user = user AND u.host = host;

IF @exist = 1 AND extended = 0 THEN

    SET @sql = CONCAT('GRANT SELECT ON xls.columns      TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.formats      TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.handlers     TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.objects      TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.translations TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.workbooks    TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.queries      TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('SHOW GRANTS FOR ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    DEALLOCATE PREPARE stmt;
END IF;

IF @exist = 1 AND extended = 1 THEN

    SET @sql = CONCAT('GRANT SELECT ON xls.view_columns       TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.view_formats       TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.view_handlers      TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.view_objects       TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.view_translations  TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.view_workbooks     TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.view_queries       TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('SHOW GRANTS FOR ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    DEALLOCATE PREPARE stmt;
END IF;

END
//

CREATE PROCEDURE xls.xl_actions_remove_from_xls_developers (
    user VARCHAR(128)
    , host VARCHAR(128)
    )
BEGIN

SELECT 1 INTO @exist FROM mysql.user u WHERE u.user = user AND u.host = host;

IF @exist = 1 THEN

    SET @sql = CONCAT('GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON xls.* TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT, INSERT, UPDATE, DELETE, EXECUTE ON xls.* FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('SHOW GRANTS FOR ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    DEALLOCATE PREPARE stmt;

END IF;

END
//

CREATE PROCEDURE xls.xl_actions_remove_from_xls_formats (
    user VARCHAR(128)
    , host VARCHAR(128)
    , extended bit(1)
    )
BEGIN

SELECT 1 INTO @exist FROM mysql.user u WHERE u.user = user AND u.host = host;

IF @exist = 1 AND extended = 0 THEN

    SET @sql = CONCAT('GRANT SELECT, INSERT, UPDATE, DELETE ON xls.formats TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT, INSERT, UPDATE, DELETE ON xls.formats FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('SHOW GRANTS FOR ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    DEALLOCATE PREPARE stmt;
END IF;

IF @exist = 1 AND extended = 1 THEN

    SET @sql = CONCAT('GRANT EXECUTE ON PROCEDURE xls.xl_update_table_format TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE EXECUTE ON PROCEDURE xls.xl_update_table_format FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('SHOW GRANTS FOR ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    DEALLOCATE PREPARE stmt;
END IF;

END
//

CREATE PROCEDURE xls.xl_actions_remove_from_xls_users (
    user VARCHAR(128)
    , host VARCHAR(128)
    , extended bit(1)
    )
BEGIN

SELECT 1 INTO @exist FROM mysql.user u WHERE u.user = user AND u.host = host;

IF @exist = 1 AND extended = 0 THEN

    SET @sql = CONCAT('GRANT SELECT ON xls.columns           TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.formats           TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.handlers          TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.objects           TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.translations      TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.workbooks         TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.queries           TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT ON xls.columns           FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT ON xls.formats           FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT ON xls.handlers          FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT ON xls.objects           FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT ON xls.translations      FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT ON xls.workbooks         FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT ON xls.queries           FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('SHOW GRANTS FOR ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    DEALLOCATE PREPARE stmt;
END IF;

IF @exist = 1 AND extended = 1 THEN

    SET @sql = CONCAT('GRANT SELECT ON xls.view_columns       TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.view_formats       TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.view_handlers      TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.view_objects       TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.view_translations  TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.view_workbooks     TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('GRANT SELECT ON xls.view_queries       TO ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT ON xls.view_columns       FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT ON xls.view_formats       FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT ON xls.view_handlers      FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT ON xls.view_objects       FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT ON xls.view_translations  FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT ON xls.view_workbooks     FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('REVOKE SELECT ON xls.view_queries       FROM ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    SET @sql = CONCAT('SHOW GRANTS FOR ''', user, '''@''', host, '''');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;

    DEALLOCATE PREPARE stmt;
END IF;

END
//

DELIMITER ;

-- print SaveToDB Framework updated
