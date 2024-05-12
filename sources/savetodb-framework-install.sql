-- =============================================
-- SaveToDB Framework for MySQL
-- Version 10.13, April 29, 2024
--
-- Copyright 2013-2024 Gartle LLC
--
-- License: MIT
-- =============================================

CREATE SCHEMA IF NOT EXISTS xls DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS xls.columns (
    ID INT NOT NULL AUTO_INCREMENT
    , TABLE_SCHEMA VARCHAR(64) NOT NULL
    , TABLE_NAME VARCHAR(64) NOT NULL
    , COLUMN_NAME VARCHAR(64) NOT NULL
    , ORDINAL_POSITION INTEGER NOT NULL
    , IS_PRIMARY_KEY BIT(1)
    , IS_NULLABLE BIT(1)
    , IS_IDENTITY BIT(1)
    , IS_COMPUTED BIT(1)
    , COLUMN_DEFAULT VARCHAR(255)
    , DATA_TYPE VARCHAR(64) NULL
    , CHARACTER_MAXIMUM_LENGTH INTEGER
    , `PRECISION` SMALLINT
    , SCALE SMALLINT
    , PRIMARY KEY (ID)
);

ALTER TABLE xls.columns ADD UNIQUE INDEX ix_columns USING BTREE (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME);

CREATE TABLE IF NOT EXISTS xls.formats (
    ID INT NOT NULL AUTO_INCREMENT
    , TABLE_SCHEMA VARCHAR(64) NOT NULL
    , TABLE_NAME VARCHAR(64) NOT NULL
    , TABLE_EXCEL_FORMAT_XML MEDIUMTEXT
    , APP VARCHAR(50)
    , PRIMARY KEY (ID)
);

ALTER TABLE xls.formats ADD UNIQUE INDEX ix_formats USING BTREE (TABLE_SCHEMA, TABLE_NAME, APP);

CREATE TABLE IF NOT EXISTS xls.handlers (
    ID INT NOT NULL AUTO_INCREMENT
    , TABLE_SCHEMA VARCHAR(64) NOT NULL
    , TABLE_NAME VARCHAR(64) NOT NULL
    , COLUMN_NAME VARCHAR(64)
    , EVENT_NAME VARCHAR(50) NOT NULL
    , HANDLER_SCHEMA VARCHAR(64)
    , HANDLER_NAME VARCHAR(64)
    , HANDLER_TYPE VARCHAR(64)
    , HANDLER_CODE MEDIUMTEXT
    , TARGET_WORKSHEET VARCHAR(256)
    , MENU_ORDER SMALLINT
    , EDIT_PARAMETERS BIT(1)
    , PRIMARY KEY (ID)
);

ALTER TABLE xls.handlers ADD UNIQUE INDEX ix_handlers USING BTREE (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME);

CREATE TABLE IF NOT EXISTS xls.objects (
    ID INT NOT NULL AUTO_INCREMENT
    , TABLE_SCHEMA VARCHAR(64) NOT NULL
    , TABLE_NAME VARCHAR(64) NOT NULL
    , TABLE_TYPE VARCHAR(64) NOT NULL
    , TABLE_CODE MEDIUMTEXT
    , INSERT_OBJECT MEDIUMTEXT
    , UPDATE_OBJECT MEDIUMTEXT
    , DELETE_OBJECT MEDIUMTEXT
    , PRIMARY KEY (ID)
);

ALTER TABLE xls.objects ADD UNIQUE INDEX ix_objects USING BTREE (TABLE_SCHEMA, TABLE_NAME);

CREATE TABLE IF NOT EXISTS xls.translations (
    ID INT NOT NULL AUTO_INCREMENT
    , TABLE_SCHEMA VARCHAR(64)
    , TABLE_NAME VARCHAR(64)
    , COLUMN_NAME VARCHAR(64)
    , LANGUAGE_NAME VARCHAR(10) NOT NULL
    , TRANSLATED_NAME VARCHAR(64)
    , TRANSLATED_DESC VARCHAR(1024)
    , TRANSLATED_COMMENT VARCHAR(2000)
    , PRIMARY KEY (ID)
);

ALTER TABLE xls.translations ADD UNIQUE INDEX ix_translations USING BTREE (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, LANGUAGE_NAME);

CREATE TABLE IF NOT EXISTS xls.workbooks (
    ID INT NOT NULL AUTO_INCREMENT
    , NAME VARCHAR(128) NOT NULL
    , TEMPLATE VARCHAR(255)
    , DEFINITION MEDIUMTEXT NOT NULL
    , TABLE_SCHEMA VARCHAR(64)
    , PRIMARY KEY (ID)
);

ALTER TABLE xls.workbooks ADD UNIQUE INDEX IX_workbooks USING BTREE (NAME);

CREATE OR REPLACE VIEW xls.queries
AS
SELECT
    t.TABLE_SCHEMA
    , t.TABLE_NAME
    , t.TABLE_TYPE
    , NULL AS TABLE_CODE
    , NULL AS INSERT_PROCEDURE
    , NULL AS UPDATE_PROCEDURE
    , NULL AS DELETE_PROCEDURE
    , NULL AS PROCEDURE_TYPE
FROM
    information_schema.tables t
WHERE
    NOT t.TABLE_SCHEMA IN ('information_schema', 'mysql', 'performance_schema', 'sys', 'xls', 'savetodb_dev', 'savetodb_xls')
    AND NOT t.TABLE_NAME LIKE 'xl_%'
UNION ALL
SELECT
    r.ROUTINE_SCHEMA AS TABLE_SCHEMA
    , r.ROUTINE_NAME AS TABLE_NAME
    , r.ROUTINE_TYPE AS TABLE_TYPE
    , NULL AS TABLE_CODE
    , NULL AS INSERT_PROCEDURE
    , NULL AS UPDATE_PROCEDURE
    , NULL AS DELETE_PROCEDURE
    , NULL AS PROCEDURE_TYPE
FROM
    information_schema.routines r
WHERE
    NOT r.ROUTINE_SCHEMA IN ('information_schema', 'mysql', 'performance_schema', 'sys', 'xls', 'savetodb_dev', 'savetodb_xls')
    AND r.ROUTINE_TYPE = 'PROCEDURE'
    AND NOT (
        r.ROUTINE_NAME LIKE '%_insert'
        OR r.ROUTINE_NAME LIKE '%_update'
        OR r.ROUTINE_NAME LIKE '%_delete'
        OR r.ROUTINE_NAME LIKE '%_merge'
        OR r.ROUTINE_NAME LIKE '%_change'
        OR r.ROUTINE_NAME LIKE 'xl_%'
    )
UNION ALL
SELECT
    o.TABLE_SCHEMA
    , o.TABLE_NAME
    , o.TABLE_TYPE
    , o.TABLE_CODE
    , o.INSERT_OBJECT AS INSERT_PROCEDURE
    , o.UPDATE_OBJECT AS UPDATE_PROCEDURE
    , o.DELETE_OBJECT AS DELETE_PROCEDURE
    , NULL AS PROCEDURE_TYPE
FROM
    xls.objects o
WHERE
    o.TABLE_TYPE IN ('CODE', 'HTTP', 'TEXT')
    AND o.TABLE_SCHEMA IS NOT NULL
    AND o.TABLE_NAME IS NOT NULL
    AND o.TABLE_CODE IS NOT NULL
    AND NOT o.TABLE_NAME LIKE 'xl_%'
ORDER BY
    TABLE_SCHEMA
    , TABLE_NAME;

CREATE OR REPLACE VIEW xls.users
AS
SELECT
    User
FROM
    mysql.user;

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

INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'savetodb_framework', 'version', 'Information', NULL, NULL, 'ATTRIBUTE', '10.13', NULL, NULL, NULL);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'handlers', 'EVENT_NAME', 'ValidationList', NULL, NULL, 'VALUES', 'Actions, AddHyperlinks, AddStateColumn, Authentication, BitColumn, Change, ContextMenu, ConvertFormulas, DataTypeBinary, DataTypeBinary16, DataTypeBit, DataTypeBoolean, DataTypeDate, DataTypeDateTime, DataTypeDateTimeOffset, DataTypeDouble, DataTypeInt, DataTypeGuid, DataTypeString, DataTypeTime, DataTypeTimeSpan, DefaultListObject, DefaultValue, DependsOn, DoNotAddChangeHandler, DoNotAddDependsOn, DoNotAddManyToMany, DoNotAddValidation, DoNotChange, DoNotConvertFormulas, DoNotKeepComments, DoNotKeepFormulas, DoNotSave, DoNotSelect, DoNotSort, DoNotTranslate, DoubleClick, DynamicColumns, Format, Formula, FormulaValue, HideByDefault, Information, JsonForm, KeepFormulas, KeepComments, License, LoadFormat, ManyToMany, ParameterValues, ProtectRows, RegEx, SaveFormat, SaveWithoutTransaction, SelectionChange, SelectionList, SelectPeriod, SyncParameter, UpdateChangedCellsOnly, UpdateEntireRow, ValidationList, WhereByDefault', NULL, NULL, NULL);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'handlers', 'HANDLER_TYPE', 'ValidationList', NULL, NULL, 'VALUES', 'TABLE, VIEW, PROCEDURE, FUNCTION, CODE, HTTP, TEXT, MACRO, CMD, VALUES, RANGE, REFRESH, MENUSEPARATOR, PDF, REPORT, SHOWSHEETS, HIDESHEETS, SELECTSHEET, ATTRIBUTE', NULL, NULL, NULL);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'objects', 'TABLE_TYPE', 'ValidationList', NULL, NULL, 'VALUES', 'TABLE, VIEW, PROCEDURE, CODE, HTTP, TEXT, HIDDEN', NULL, NULL, NULL);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'handlers', 'HANDLER_CODE', 'DoNotConvertFormulas', NULL, NULL, 'ATTRIBUTE', NULL, NULL, NULL, NULL);

INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'columns', NULL, 'Actions', 'xls', 'Developer Guide', 'HTTP', 'https://www.savetodb.com/dev-guide/xls-columns.htm', NULL, 13, NULL);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'formats', NULL, 'Actions', 'xls', 'Developer Guide', 'HTTP', 'https://www.savetodb.com/dev-guide/xls-formats.htm', NULL, 13, NULL);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'handlers', NULL, 'Actions', 'xls', 'Developer Guide', 'HTTP', 'https://www.savetodb.com/dev-guide/xls-handlers.htm', NULL, 13, NULL);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'objects', NULL, 'Actions', 'xls', 'Developer Guide', 'HTTP', 'https://www.savetodb.com/dev-guide/xls-objects.htm', NULL, 13, NULL);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'queries', NULL, 'Actions', 'xls', 'Developer Guide', 'HTTP', 'https://www.savetodb.com/dev-guide/xls-queries.htm', NULL, 13, NULL);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'translations', NULL, 'Actions', 'xls', 'Developer Guide', 'HTTP', 'https://www.savetodb.com/dev-guide/xls-translations.htm', NULL, 13, NULL);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'workbooks', NULL, 'Actions', 'xls', 'Developer Guide', 'HTTP', 'https://www.savetodb.com/dev-guide/xls-workbooks.htm', NULL, 13, NULL);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'users', NULL, 'Actions', 'xls', 'Developer Guide', 'HTTP', 'https://www.savetodb.com/dev-guide/xls-users.htm', NULL, 13, NULL);

INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'users', NULL, 'ContextMenu', 'xls', 'xl_actions_add_to_xls_users', 'PROCEDURE', NULL, '_Reload', 31, 1);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'users', NULL, 'ContextMenu', 'xls', 'xl_actions_add_to_xls_formats', 'PROCEDURE', NULL, '_Reload', 32, 1);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'users', NULL, 'ContextMenu', 'xls', 'xl_actions_add_to_xls_developers', 'PROCEDURE', NULL, '_Reload', 33, 1);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'users', NULL, 'ContextMenu', 'xls', 'MenuSeparator40', 'MENUSEPARATOR', NULL, NULL, 40, NULL);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'users', NULL, 'ContextMenu', 'xls', 'xl_actions_remove_from_xls_users', 'PROCEDURE', NULL, '_Reload', 41, 1);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'users', NULL, 'ContextMenu', 'xls', 'xl_actions_remove_from_xls_formats', 'PROCEDURE', NULL, '_Reload', 42, 1);
INSERT INTO xls.handlers (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, EVENT_NAME, HANDLER_SCHEMA, HANDLER_NAME, HANDLER_TYPE, HANDLER_CODE, TARGET_WORKSHEET, MENU_ORDER, EDIT_PARAMETERS) VALUES ('xls', 'users', NULL, 'ContextMenu', 'xls', 'xl_actions_remove_from_xls_developers', 'PROCEDURE', NULL, '_Reload', 43, 1);

INSERT INTO xls.formats (TABLE_SCHEMA, TABLE_NAME, TABLE_EXCEL_FORMAT_XML) VALUES ('xls', 'columns', '<table name="xls.columns"><columnFormats><column name="" property="ListObjectName" value="columns" type="String"/><column name="" property="ShowTotals" value="False" type="Boolean"/><column name="" property="TableStyle.Name" value="TableStyleMedium15" type="String"/><column name="" property="ShowTableStyleColumnStripes" value="False" type="Boolean"/><column name="" property="ShowTableStyleFirstColumn" value="False" type="Boolean"/><column name="" property="ShowShowTableStyleLastColumn" value="False" type="Boolean"/><column name="" property="ShowTableStyleRowStripes" value="False" type="Boolean"/><column name="_RowNum" property="EntireColumn.Hidden" value="True" type="Boolean"/><column name="_RowNum" property="Address" value="$B$4" type="String"/><column name="_RowNum" property="NumberFormat" value="General" type="String"/><column name="ID" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="ID" property="Address" value="$C$4" type="String"/><column name="ID" property="ColumnWidth" value="4.43" type="Double"/><column name="ID" property="NumberFormat" value="General" type="String"/><column name="ID" property="Validation.Type" value="1" type="Double"/><column name="ID" property="Validation.Operator" value="1" type="Double"/><column name="ID" property="Validation.Formula1" value="-2147483648" type="String"/><column name="ID" property="Validation.Formula2" value="2147483647" type="String"/><column name="ID" property="Validation.AlertStyle" value="2" type="Double"/><column name="ID" property="Validation.IgnoreBlank" value="True" type="Boolean"/><column name="ID" property="Validation.InCellDropdown" value="True" type="Boolean"/><column name="ID" property="Validation.ErrorTitle" value="Datatype Control" type="String"/><column name="ID" property="Validation.ErrorMessage" value="The column requires values of the int datatype." type="String"/><column name="ID" property="Validation.ShowInput" value="True" type="Boolean"/><column name="ID" property="Validation.ShowError" value="True" type="Boolean"/><column name="TABLE_SCHEMA" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_SCHEMA" property="Address" value="$D$4" type="String"/><column name="TABLE_SCHEMA" property="ColumnWidth" value="16.57" type="Double"/><column name="TABLE_SCHEMA" property="NumberFormat" value="General" type="String"/><column name="TABLE_SCHEMA" property="Validation.Type" value="6" type="Double"/><column name="TABLE_SCHEMA" property="Validation.Operator" value="8" type="Double"/><column name="TABLE_SCHEMA" property="Validation.Formula1" value="128" type="String"/><column name="TABLE_SCHEMA" property="Validation.AlertStyle" value="2" type="Double"/><column name="TABLE_SCHEMA" property="Validation.IgnoreBlank" value="True" type="Boolean"/><column name="TABLE_SCHEMA" property="Validation.InCellDropdown" value="True" type="Boolean"/><column name="TABLE_SCHEMA" property="Validation.ErrorTitle" value="Datatype Control" type="String"/><column name="TABLE_SCHEMA" property="Validation.ErrorMessage" value="The column requires values of the nvarchar(128) datatype." type="String"/><column name="TABLE_SCHEMA" property="Validation.ShowInput" value="True" type="Boolean"/><column name="TABLE_SCHEMA" property="Validation.ShowError" value="True" type="Boolean"/><column name="TABLE_NAME" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_NAME" property="Address" value="$E$4" type="String"/><column name="TABLE_NAME" property="ColumnWidth" value="15.43" type="Double"/><column name="TABLE_NAME" property="NumberFormat" value="General" type="String"/><column name="TABLE_NAME" property="Validation.Type" value="6" type="Double"/><column name="TABLE_NAME" property="Validation.Operator" value="8" type="Double"/><column name="TABLE_NAME" property="Validation.Formula1" value="128" type="String"/><column name="TABLE_NAME" property="Validation.AlertStyle" value="2" type="Double"/><column name="TABLE_NAME" property="Validation.IgnoreBlank" value="True" type="Boolean"/><column name="TABLE_NAME" property="Validation.InCellDropdown" value="True" type="Boolean"/><column name="TABLE_NAME" property="Validation.ErrorTitle" value="Datatype Control" type="String"/><column name="TABLE_NAME" property="Validation.ErrorMessage" value="The column requires values of the nvarchar(128) datatype." type="String"/><column name="TABLE_NAME" property="Validation.ShowInput" value="True" type="Boolean"/><column name="TABLE_NAME" property="Validation.ShowError" value="True" type="Boolean"/><column name="COLUMN_NAME" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="COLUMN_NAME" property="Address" value="$F$4" type="String"/><column name="COLUMN_NAME" property="ColumnWidth" value="27.86" type="Double"/><column name="COLUMN_NAME" property="NumberFormat" value="General" type="String"/><column name="COLUMN_NAME" property="Validation.Type" value="6" type="Double"/><column name="COLUMN_NAME" property="Validation.Operator" value="8" type="Double"/><column name="COLUMN_NAME" property="Validation.Formula1" value="128" type="String"/><column name="COLUMN_NAME" property="Validation.AlertStyle" value="2" type="Double"/><column name="COLUMN_NAME" property="Validation.IgnoreBlank" value="True" type="Boolean"/><column name="COLUMN_NAME" property="Validation.InCellDropdown" value="True" type="Boolean"/><column name="COLUMN_NAME" property="Validation.ErrorTitle" value="Datatype Control" type="String"/><column name="COLUMN_NAME" property="Validation.ErrorMessage" value="The column requires values of the nvarchar(128) datatype." type="String"/><column name="COLUMN_NAME" property="Validation.ShowInput" value="True" type="Boolean"/><column name="COLUMN_NAME" property="Validation.ShowError" value="True" type="Boolean"/><column name="ORDINAL_POSITION" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="ORDINAL_POSITION" property="Address" value="$G$4" type="String"/><column name="ORDINAL_POSITION" property="ColumnWidth" value="20.43" type="Double"/><column name="ORDINAL_POSITION" property="NumberFormat" value="General" type="String"/><column name="ORDINAL_POSITION" property="Validation.Type" value="1" type="Double"/><column name="ORDINAL_POSITION" property="Validation.Operator" value="1" type="Double"/><column name="ORDINAL_POSITION" property="Validation.Formula1" value="-2147483648" type="String"/><column name="ORDINAL_POSITION" property="Validation.Formula2" value="2147483647" type="String"/><column name="ORDINAL_POSITION" property="Validation.AlertStyle" value="2" type="Double"/><column name="ORDINAL_POSITION" property="Validation.IgnoreBlank" value="True" type="Boolean"/><column name="ORDINAL_POSITION" property="Validation.InCellDropdown" value="True" type="Boolean"/><column name="ORDINAL_POSITION" property="Validation.ErrorTitle" value="Datatype Control" type="String"/><column name="ORDINAL_POSITION" property="Validation.ErrorMessage" value="The column requires values of the int datatype." type="String"/><column name="ORDINAL_POSITION" property="Validation.ShowInput" value="True" type="Boolean"/><column name="ORDINAL_POSITION" property="Validation.ShowError" value="True" type="Boolean"/><column name="IS_PRIMARY_KEY" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="IS_PRIMARY_KEY" property="Address" value="$H$4" type="String"/><column name="IS_PRIMARY_KEY" property="ColumnWidth" value="17.86" type="Double"/><column name="IS_PRIMARY_KEY" property="NumberFormat" value="General" type="String"/><column name="IS_PRIMARY_KEY" property="HorizontalAlignment" value="-4108" type="Double"/><column name="IS_PRIMARY_KEY" property="Font.Size" value="10" type="Double"/><column name="IS_NULLABLE" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="IS_NULLABLE" property="Address" value="$I$4" type="String"/><column name="IS_NULLABLE" property="ColumnWidth" value="14" type="Double"/><column name="IS_NULLABLE" property="NumberFormat" value="General" type="String"/><column name="IS_NULLABLE" property="HorizontalAlignment" value="-4108" type="Double"/><column name="IS_NULLABLE" property="Font.Size" value="10" type="Double"/><column name="IS_IDENTITY" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="IS_IDENTITY" property="Address" value="$J$4" type="String"/><column name="IS_IDENTITY" property="ColumnWidth" value="13.14" type="Double"/><column name="IS_IDENTITY" property="NumberFormat" value="General" type="String"/><column name="IS_IDENTITY" property="HorizontalAlignment" value="-4108" type="Double"/><column name="IS_IDENTITY" property="Font.Size" value="10" type="Double"/><column name="IS_COMPUTED" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="IS_COMPUTED" property="Address" value="$K$4" type="String"/><column name="IS_COMPUTED" property="ColumnWidth" value="15.57" type="Double"/><column name="IS_COMPUTED" property="NumberFormat" value="General" type="String"/><column name="IS_COMPUTED" property="HorizontalAlignment" value="-4108" type="Double"/><column name="IS_COMPUTED" property="Font.Size" value="10" type="Double"/><column name="COLUMN_DEFAULT" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="COLUMN_DEFAULT" property="Address" value="$L$4" type="String"/><column name="COLUMN_DEFAULT" property="ColumnWidth" value="19.86" type="Double"/><column name="COLUMN_DEFAULT" property="NumberFormat" value="General" type="String"/><column name="COLUMN_DEFAULT" property="Validation.Type" value="6" type="Double"/><column name="COLUMN_DEFAULT" property="Validation.Operator" value="8" type="Double"/><column name="COLUMN_DEFAULT" property="Validation.Formula1" value="256" type="String"/><column name="COLUMN_DEFAULT" property="Validation.AlertStyle" value="2" type="Double"/><column name="COLUMN_DEFAULT" property="Validation.IgnoreBlank" value="True" type="Boolean"/><column name="COLUMN_DEFAULT" property="Validation.InCellDropdown" value="True" type="Boolean"/><column name="COLUMN_DEFAULT" property="Validation.ErrorTitle" value="Datatype Control" type="String"/><column name="COLUMN_DEFAULT" property="Validation.ErrorMessage" value="The column requires values of the nvarchar(256) datatype." type="String"/><column name="COLUMN_DEFAULT" property="Validation.ShowInput" value="True" type="Boolean"/><column name="COLUMN_DEFAULT" property="Validation.ShowError" value="True" type="Boolean"/><column name="DATA_TYPE" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="DATA_TYPE" property="Address" value="$M$4" type="String"/><column name="DATA_TYPE" property="ColumnWidth" value="12.71" type="Double"/><column name="DATA_TYPE" property="NumberFormat" value="General" type="String"/><column name="DATA_TYPE" property="Validation.Type" value="6" type="Double"/><column name="DATA_TYPE" property="Validation.Operator" value="8" type="Double"/><column name="DATA_TYPE" property="Validation.Formula1" value="128" type="String"/><column name="DATA_TYPE" property="Validation.AlertStyle" value="2" type="Double"/><column name="DATA_TYPE" property="Validation.IgnoreBlank" value="True" type="Boolean"/><column name="DATA_TYPE" property="Validation.InCellDropdown" value="True" type="Boolean"/><column name="DATA_TYPE" property="Validation.ErrorTitle" value="Datatype Control" type="String"/><column name="DATA_TYPE" property="Validation.ErrorMessage" value="The column requires values of the nvarchar(128) datatype." type="String"/><column name="DATA_TYPE" property="Validation.ShowInput" value="True" type="Boolean"/><column name="DATA_TYPE" property="Validation.ShowError" value="True" type="Boolean"/><column name="CHARACTER_MAXIMUM_LENGTH" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="CHARACTER_MAXIMUM_LENGTH" property="Address" value="$N$4" type="String"/><column name="CHARACTER_MAXIMUM_LENGTH" property="ColumnWidth" value="32.71" type="Double"/><column name="CHARACTER_MAXIMUM_LENGTH" property="NumberFormat" value="General" type="String"/><column name="CHARACTER_MAXIMUM_LENGTH" property="Validation.Type" value="1" type="Double"/><column name="CHARACTER_MAXIMUM_LENGTH" property="Validation.Operator" value="1" type="Double"/><column name="CHARACTER_MAXIMUM_LENGTH" property="Validation.Formula1" value="-2147483648" type="String"/><column name="CHARACTER_MAXIMUM_LENGTH" property="Validation.Formula2" value="2147483647" type="String"/><column name="CHARACTER_MAXIMUM_LENGTH" property="Validation.AlertStyle" value="2" type="Double"/><column name="CHARACTER_MAXIMUM_LENGTH" property="Validation.IgnoreBlank" value="True" type="Boolean"/><column name="CHARACTER_MAXIMUM_LENGTH" property="Validation.InCellDropdown" value="True" type="Boolean"/><column name="CHARACTER_MAXIMUM_LENGTH" property="Validation.ErrorTitle" value="Datatype Control" type="String"/><column name="CHARACTER_MAXIMUM_LENGTH" property="Validation.ErrorMessage" value="The column requires values of the int datatype." type="String"/><column name="CHARACTER_MAXIMUM_LENGTH" property="Validation.ShowInput" value="True" type="Boolean"/><column name="CHARACTER_MAXIMUM_LENGTH" property="Validation.ShowError" value="True" type="Boolean"/><column name="PRECISION" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="PRECISION" property="Address" value="$O$4" type="String"/><column name="PRECISION" property="ColumnWidth" value="12" type="Double"/><column name="PRECISION" property="NumberFormat" value="General" type="String"/><column name="PRECISION" property="Validation.Type" value="1" type="Double"/><column name="PRECISION" property="Validation.Operator" value="1" type="Double"/><column name="PRECISION" property="Validation.Formula1" value="0" type="String"/><column name="PRECISION" property="Validation.Formula2" value="255" type="String"/><column name="PRECISION" property="Validation.AlertStyle" value="2" type="Double"/><column name="PRECISION" property="Validation.IgnoreBlank" value="True" type="Boolean"/><column name="PRECISION" property="Validation.InCellDropdown" value="True" type="Boolean"/><column name="PRECISION" property="Validation.ErrorTitle" value="Datatype Control" type="String"/><column name="PRECISION" property="Validation.ErrorMessage" value="The column requires values of the tinyint datatype." type="String"/><column name="PRECISION" property="Validation.ShowInput" value="True" type="Boolean"/><column name="PRECISION" property="Validation.ShowError" value="True" type="Boolean"/><column name="SCALE" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="SCALE" property="Address" value="$P$4" type="String"/><column name="SCALE" property="ColumnWidth" value="7.86" type="Double"/><column name="SCALE" property="NumberFormat" value="General" type="String"/><column name="SCALE" property="Validation.Type" value="1" type="Double"/><column name="SCALE" property="Validation.Operator" value="1" type="Double"/><column name="SCALE" property="Validation.Formula1" value="0" type="String"/><column name="SCALE" property="Validation.Formula2" value="255" type="String"/><column name="SCALE" property="Validation.AlertStyle" value="2" type="Double"/><column name="SCALE" property="Validation.IgnoreBlank" value="True" type="Boolean"/><column name="SCALE" property="Validation.InCellDropdown" value="True" type="Boolean"/><column name="SCALE" property="Validation.ErrorTitle" value="Datatype Control" type="String"/><column name="SCALE" property="Validation.ErrorMessage" value="The column requires values of the tinyint datatype." type="String"/><column name="SCALE" property="Validation.ShowInput" value="True" type="Boolean"/><column name="SCALE" property="Validation.ShowError" value="True" type="Boolean"/><column name="TABLE_SCHEMA" property="FormatConditions(1).AppliesTo.Address" value="$D$4:$D$423" type="String"/><column name="TABLE_SCHEMA" property="FormatConditions(1).Type" value="2" type="Double"/><column name="TABLE_SCHEMA" property="FormatConditions(1).Priority" value="5" type="Double"/><column name="TABLE_SCHEMA" property="FormatConditions(1).Formula1" value="=ISBLANK(D4)" type="String"/><column name="TABLE_SCHEMA" property="FormatConditions(1).Interior.Color" value="65535" type="Double"/><column name="TABLE_NAME" property="FormatConditions(1).AppliesTo.Address" value="$E$4:$E$423" type="String"/><column name="TABLE_NAME" property="FormatConditions(1).Type" value="2" type="Double"/><column name="TABLE_NAME" property="FormatConditions(1).Priority" value="6" type="Double"/><column name="TABLE_NAME" property="FormatConditions(1).Formula1" value="=ISBLANK(E4)" type="String"/><column name="TABLE_NAME" property="FormatConditions(1).Interior.Color" value="65535" type="Double"/><column name="COLUMN_NAME" property="FormatConditions(1).AppliesTo.Address" value="$F$4:$F$423" type="String"/><column name="COLUMN_NAME" property="FormatConditions(1).Type" value="2" type="Double"/><column name="COLUMN_NAME" property="FormatConditions(1).Priority" value="7" type="Double"/><column name="COLUMN_NAME" property="FormatConditions(1).Formula1" value="=ISBLANK(F4)" type="String"/><column name="COLUMN_NAME" property="FormatConditions(1).Interior.Color" value="65535" type="Double"/><column name="ORDINAL_POSITION" property="FormatConditions(1).AppliesTo.Address" value="$G$4:$G$423" type="String"/><column name="ORDINAL_POSITION" property="FormatConditions(1).Type" value="2" type="Double"/><column name="ORDINAL_POSITION" property="FormatConditions(1).Priority" value="8" type="Double"/><column name="ORDINAL_POSITION" property="FormatConditions(1).Formula1" value="=ISBLANK(G4)" type="String"/><column name="ORDINAL_POSITION" property="FormatConditions(1).Interior.Color" value="65535" type="Double"/><column name="IS_PRIMARY_KEY" property="FormatConditions(1).AppliesTo.Address" value="$H$4:$H$423" type="String"/><column name="IS_PRIMARY_KEY" property="FormatConditions(1).Type" value="6" type="Double"/><column name="IS_PRIMARY_KEY" property="FormatConditions(1).Priority" value="4" type="Double"/><column name="IS_PRIMARY_KEY" property="FormatConditions(1).ShowIconOnly" value="True" type="Boolean"/><column name="IS_PRIMARY_KEY" property="FormatConditions(1).IconSet.ID" value="8" type="Double"/><column name="IS_PRIMARY_KEY" property="FormatConditions(1).IconCriteria(1).Type" value="3" type="Double"/><column name="IS_PRIMARY_KEY" property="FormatConditions(1).IconCriteria(1).Operator" value="7" type="Double"/><column name="IS_PRIMARY_KEY" property="FormatConditions(1).IconCriteria(2).Type" value="0" type="Double"/><column name="IS_PRIMARY_KEY" property="FormatConditions(1).IconCriteria(2).Value" value="0.5" type="Double"/><column name="IS_PRIMARY_KEY" property="FormatConditions(1).IconCriteria(2).Operator" value="7" type="Double"/><column name="IS_PRIMARY_KEY" property="FormatConditions(1).IconCriteria(3).Type" value="0" type="Double"/><column name="IS_PRIMARY_KEY" property="FormatConditions(1).IconCriteria(3).Value" value="1" type="Double"/><column name="IS_PRIMARY_KEY" property="FormatConditions(1).IconCriteria(3).Operator" value="7" type="Double"/><column name="IS_NULLABLE" property="FormatConditions(1).AppliesTo.Address" value="$I$4:$I$423" type="String"/><column name="IS_NULLABLE" property="FormatConditions(1).Type" value="6" type="Double"/><column name="IS_NULLABLE" property="FormatConditions(1).Priority" value="3" type="Double"/><column name="IS_NULLABLE" property="FormatConditions(1).ShowIconOnly" value="True" type="Boolean"/><column name="IS_NULLABLE" property="FormatConditions(1).IconSet.ID" value="8" type="Double"/><column name="IS_NULLABLE" property="FormatConditions(1).IconCriteria(1).Type" value="3" type="Double"/><column name="IS_NULLABLE" property="FormatConditions(1).IconCriteria(1).Operator" value="7" type="Double"/><column name="IS_NULLABLE" property="FormatConditions(1).IconCriteria(2).Type" value="0" type="Double"/><column name="IS_NULLABLE" property="FormatConditions(1).IconCriteria(2).Value" value="0.5" type="Double"/><column name="IS_NULLABLE" property="FormatConditions(1).IconCriteria(2).Operator" value="7" type="Double"/><column name="IS_NULLABLE" property="FormatConditions(1).IconCriteria(3).Type" value="0" type="Double"/><column name="IS_NULLABLE" property="FormatConditions(1).IconCriteria(3).Value" value="1" type="Double"/><column name="IS_NULLABLE" property="FormatConditions(1).IconCriteria(3).Operator" value="7" type="Double"/><column name="IS_IDENTITY" property="FormatConditions(1).AppliesTo.Address" value="$J$4:$J$423" type="String"/><column name="IS_IDENTITY" property="FormatConditions(1).Type" value="6" type="Double"/><column name="IS_IDENTITY" property="FormatConditions(1).Priority" value="2" type="Double"/><column name="IS_IDENTITY" property="FormatConditions(1).ShowIconOnly" value="True" type="Boolean"/><column name="IS_IDENTITY" property="FormatConditions(1).IconSet.ID" value="8" type="Double"/><column name="IS_IDENTITY" property="FormatConditions(1).IconCriteria(1).Type" value="3" type="Double"/><column name="IS_IDENTITY" property="FormatConditions(1).IconCriteria(1).Operator" value="7" type="Double"/><column name="IS_IDENTITY" property="FormatConditions(1).IconCriteria(2).Type" value="0" type="Double"/><column name="IS_IDENTITY" property="FormatConditions(1).IconCriteria(2).Value" value="0.5" type="Double"/><column name="IS_IDENTITY" property="FormatConditions(1).IconCriteria(2).Operator" value="7" type="Double"/><column name="IS_IDENTITY" property="FormatConditions(1).IconCriteria(3).Type" value="0" type="Double"/><column name="IS_IDENTITY" property="FormatConditions(1).IconCriteria(3).Value" value="1" type="Double"/><column name="IS_IDENTITY" property="FormatConditions(1).IconCriteria(3).Operator" value="7" type="Double"/><column name="IS_COMPUTED" property="FormatConditions(1).AppliesTo.Address" value="$K$4:$K$423" type="String"/><column name="IS_COMPUTED" property="FormatConditions(1).Type" value="6" type="Double"/><column name="IS_COMPUTED" property="FormatConditions(1).Priority" value="1" type="Double"/><column name="IS_COMPUTED" property="FormatConditions(1).ShowIconOnly" value="True" type="Boolean"/><column name="IS_COMPUTED" property="FormatConditions(1).IconSet.ID" value="8" type="Double"/><column name="IS_COMPUTED" property="FormatConditions(1).IconCriteria(1).Type" value="3" type="Double"/><column name="IS_COMPUTED" property="FormatConditions(1).IconCriteria(1).Operator" value="7" type="Double"/><column name="IS_COMPUTED" property="FormatConditions(1).IconCriteria(2).Type" value="0" type="Double"/><column name="IS_COMPUTED" property="FormatConditions(1).IconCriteria(2).Value" value="0.5" type="Double"/><column name="IS_COMPUTED" property="FormatConditions(1).IconCriteria(2).Operator" value="7" type="Double"/><column name="IS_COMPUTED" property="FormatConditions(1).IconCriteria(3).Type" value="0" type="Double"/><column name="IS_COMPUTED" property="FormatConditions(1).IconCriteria(3).Value" value="1" type="Double"/><column name="IS_COMPUTED" property="FormatConditions(1).IconCriteria(3).Operator" value="7" type="Double"/><column name="SortFields(1)" property="KeyfieldName" value="TABLE_SCHEMA" type="String"/><column name="SortFields(1)" property="SortOn" value="0" type="Double"/><column name="SortFields(1)" property="Order" value="1" type="Double"/><column name="SortFields(1)" property="DataOption" value="2" type="Double"/><column name="SortFields(2)" property="KeyfieldName" value="TABLE_NAME" type="String"/><column name="SortFields(2)" property="SortOn" value="0" type="Double"/><column name="SortFields(2)" property="Order" value="1" type="Double"/><column name="SortFields(2)" property="DataOption" value="2" type="Double"/><column name="SortFields(3)" property="KeyfieldName" value="ORDINAL_POSITION" type="String"/><column name="SortFields(3)" property="SortOn" value="0" type="Double"/><column name="SortFields(3)" property="Order" value="1" type="Double"/><column name="SortFields(3)" property="DataOption" value="2" type="Double"/><column name="SortFields(4)" property="KeyfieldName" value="COLUMN_NAME" type="String"/><column name="SortFields(4)" property="SortOn" value="0" type="Double"/><column name="SortFields(4)" property="Order" value="1" type="Double"/><column name="SortFields(4)" property="DataOption" value="2" type="Double"/><column name="" property="ActiveWindow.DisplayGridlines" value="False" type="Boolean"/><column name="" property="ActiveWindow.FreezePanes" value="True" type="Boolean"/><column name="" property="ActiveWindow.Split" value="True" type="Boolean"/><column name="" property="ActiveWindow.SplitRow" value="0" type="Double"/><column name="" property="ActiveWindow.SplitColumn" value="-2" type="Double"/><column name="" property="PageSetup.Orientation" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesWide" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesTall" value="1" type="Double"/></columnFormats></table>');
INSERT INTO xls.formats (TABLE_SCHEMA, TABLE_NAME, TABLE_EXCEL_FORMAT_XML) VALUES ('xls', 'formats', '<table name="xls.formats"><columnFormats><column name="" property="ListObjectName" value="formats" type="String"/><column name="" property="ShowTotals" value="False" type="Boolean"/><column name="" property="TableStyle.Name" value="TableStyleMedium15" type="String"/><column name="" property="ShowTableStyleColumnStripes" value="False" type="Boolean"/><column name="" property="ShowTableStyleFirstColumn" value="False" type="Boolean"/><column name="" property="ShowShowTableStyleLastColumn" value="False" type="Boolean"/><column name="" property="ShowTableStyleRowStripes" value="False" type="Boolean"/><column name="_RowNum" property="EntireColumn.Hidden" value="True" type="Boolean"/><column name="_RowNum" property="Address" value="$B$4" type="String"/><column name="_RowNum" property="NumberFormat" value="General" type="String"/><column name="_RowNum" property="VerticalAlignment" value="-4160" type="Double"/><column name="ID" property="EntireColumn.Hidden" value="True" type="Boolean"/><column name="ID" property="Address" value="$C$4" type="String"/><column name="ID" property="NumberFormat" value="General" type="String"/><column name="ID" property="VerticalAlignment" value="-4160" type="Double"/><column name="TABLE_SCHEMA" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_SCHEMA" property="Address" value="$D$4" type="String"/><column name="TABLE_SCHEMA" property="ColumnWidth" value="16.57" type="Double"/><column name="TABLE_SCHEMA" property="NumberFormat" value="General" type="String"/><column name="TABLE_SCHEMA" property="VerticalAlignment" value="-4160" type="Double"/><column name="TABLE_NAME" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_NAME" property="Address" value="$E$4" type="String"/><column name="TABLE_NAME" property="ColumnWidth" value="30" type="Double"/><column name="TABLE_NAME" property="NumberFormat" value="General" type="String"/><column name="TABLE_NAME" property="VerticalAlignment" value="-4160" type="Double"/><column name="TABLE_EXCEL_FORMAT_XML" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_EXCEL_FORMAT_XML" property="Address" value="$F$4" type="String"/><column name="TABLE_EXCEL_FORMAT_XML" property="ColumnWidth" value="42.29" type="Double"/><column name="TABLE_EXCEL_FORMAT_XML" property="NumberFormat" value="General" type="String"/><column name="SortFields(1)" property="KeyfieldName" value="TABLE_SCHEMA" type="String"/><column name="SortFields(1)" property="SortOn" value="0" type="Double"/><column name="SortFields(1)" property="Order" value="1" type="Double"/><column name="SortFields(1)" property="DataOption" value="0" type="Double"/><column name="SortFields(2)" property="KeyfieldName" value="TABLE_NAME" type="String"/><column name="SortFields(2)" property="SortOn" value="0" type="Double"/><column name="SortFields(2)" property="Order" value="1" type="Double"/><column name="SortFields(2)" property="DataOption" value="0" type="Double"/><column name="" property="ActiveWindow.DisplayGridlines" value="False" type="Boolean"/><column name="" property="ActiveWindow.FreezePanes" value="True" type="Boolean"/><column name="" property="ActiveWindow.Split" value="True" type="Boolean"/><column name="" property="ActiveWindow.SplitRow" value="0" type="Double"/><column name="" property="ActiveWindow.SplitColumn" value="-2" type="Double"/><column name="" property="PageSetup.Orientation" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesWide" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesTall" value="1" type="Double"/></columnFormats></table>');
INSERT INTO xls.formats (TABLE_SCHEMA, TABLE_NAME, TABLE_EXCEL_FORMAT_XML) VALUES ('xls', 'handlers', '<table name="xls.handlers"><columnFormats><column name="" property="ListObjectName" value="handlers" type="String"/><column name="" property="ShowTotals" value="False" type="Boolean"/><column name="" property="TableStyle.Name" value="TableStyleMedium15" type="String"/><column name="" property="ShowTableStyleColumnStripes" value="False" type="Boolean"/><column name="" property="ShowTableStyleFirstColumn" value="False" type="Boolean"/><column name="" property="ShowShowTableStyleLastColumn" value="False" type="Boolean"/><column name="" property="ShowTableStyleRowStripes" value="False" type="Boolean"/><column name="_RowNum" property="EntireColumn.Hidden" value="True" type="Boolean"/><column name="_RowNum" property="Address" value="$B$4" type="String"/><column name="_RowNum" property="NumberFormat" value="General" type="String"/><column name="_RowNum" property="VerticalAlignment" value="-4160" type="Double"/><column name="ID" property="EntireColumn.Hidden" value="True" type="Boolean"/><column name="ID" property="Address" value="$C$4" type="String"/><column name="ID" property="NumberFormat" value="General" type="String"/><column name="ID" property="VerticalAlignment" value="-4160" type="Double"/><column name="TABLE_SCHEMA" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_SCHEMA" property="Address" value="$D$4" type="String"/><column name="TABLE_SCHEMA" property="ColumnWidth" value="16.57" type="Double"/><column name="TABLE_SCHEMA" property="NumberFormat" value="General" type="String"/><column name="TABLE_SCHEMA" property="VerticalAlignment" value="-4160" type="Double"/><column name="TABLE_NAME" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_NAME" property="Address" value="$E$4" type="String"/><column name="TABLE_NAME" property="ColumnWidth" value="30" type="Double"/><column name="TABLE_NAME" property="NumberFormat" value="General" type="String"/><column name="TABLE_NAME" property="VerticalAlignment" value="-4160" type="Double"/><column name="COLUMN_NAME" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="COLUMN_NAME" property="Address" value="$F$4" type="String"/><column name="COLUMN_NAME" property="ColumnWidth" value="17.43" type="Double"/><column name="COLUMN_NAME" property="NumberFormat" value="General" type="String"/><column name="COLUMN_NAME" property="VerticalAlignment" value="-4160" type="Double"/><column name="EVENT_NAME" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="EVENT_NAME" property="Address" value="$G$4" type="String"/><column name="EVENT_NAME" property="ColumnWidth" value="21.57" type="Double"/><column name="EVENT_NAME" property="NumberFormat" value="General" type="String"/><column name="EVENT_NAME" property="VerticalAlignment" value="-4160" type="Double"/><column name="HANDLER_SCHEMA" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="HANDLER_SCHEMA" property="Address" value="$H$4" type="String"/><column name="HANDLER_SCHEMA" property="ColumnWidth" value="19.71" type="Double"/><column name="HANDLER_SCHEMA" property="NumberFormat" value="General" type="String"/><column name="HANDLER_SCHEMA" property="VerticalAlignment" value="-4160" type="Double"/><column name="HANDLER_NAME" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="HANDLER_NAME" property="Address" value="$I$4" type="String"/><column name="HANDLER_NAME" property="ColumnWidth" value="31.14" type="Double"/><column name="HANDLER_NAME" property="NumberFormat" value="General" type="String"/><column name="HANDLER_NAME" property="VerticalAlignment" value="-4160" type="Double"/><column name="HANDLER_TYPE" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="HANDLER_TYPE" property="Address" value="$J$4" type="String"/><column name="HANDLER_TYPE" property="ColumnWidth" value="16.29" type="Double"/><column name="HANDLER_TYPE" property="NumberFormat" value="General" type="String"/><column name="HANDLER_TYPE" property="VerticalAlignment" value="-4160" type="Double"/><column name="HANDLER_CODE" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="HANDLER_CODE" property="Address" value="$K$4" type="String"/><column name="HANDLER_CODE" property="ColumnWidth" value="70.71" type="Double"/><column name="HANDLER_CODE" property="NumberFormat" value="General" type="String"/><column name="HANDLER_CODE" property="VerticalAlignment" value="-4160" type="Double"/><column name="TARGET_WORKSHEET" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TARGET_WORKSHEET" property="Address" value="$L$4" type="String"/><column name="TARGET_WORKSHEET" property="ColumnWidth" value="21.71" type="Double"/><column name="TARGET_WORKSHEET" property="NumberFormat" value="General" type="String"/><column name="TARGET_WORKSHEET" property="VerticalAlignment" value="-4160" type="Double"/><column name="MENU_ORDER" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="MENU_ORDER" property="Address" value="$M$4" type="String"/><column name="MENU_ORDER" property="ColumnWidth" value="15.43" type="Double"/><column name="MENU_ORDER" property="NumberFormat" value="General" type="String"/><column name="MENU_ORDER" property="VerticalAlignment" value="-4160" type="Double"/><column name="EDIT_PARAMETERS" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="EDIT_PARAMETERS" property="Address" value="$N$4" type="String"/><column name="EDIT_PARAMETERS" property="ColumnWidth" value="19.57" type="Double"/><column name="EDIT_PARAMETERS" property="NumberFormat" value="General" type="String"/><column name="EDIT_PARAMETERS" property="HorizontalAlignment" value="-4108" type="Double"/><column name="EDIT_PARAMETERS" property="VerticalAlignment" value="-4160" type="Double"/><column name="EDIT_PARAMETERS" property="Font.Size" value="10" type="Double"/><column name="SortFields(1)" property="KeyfieldName" value="EVENT_NAME" type="String"/><column name="SortFields(1)" property="SortOn" value="0" type="Double"/><column name="SortFields(1)" property="Order" value="1" type="Double"/><column name="SortFields(1)" property="DataOption" value="0" type="Double"/><column name="SortFields(2)" property="KeyfieldName" value="TABLE_SCHEMA" type="String"/><column name="SortFields(2)" property="SortOn" value="0" type="Double"/><column name="SortFields(2)" property="Order" value="1" type="Double"/><column name="SortFields(2)" property="DataOption" value="0" type="Double"/><column name="SortFields(3)" property="KeyfieldName" value="TABLE_NAME" type="String"/><column name="SortFields(3)" property="SortOn" value="0" type="Double"/><column name="SortFields(3)" property="Order" value="1" type="Double"/><column name="SortFields(3)" property="DataOption" value="0" type="Double"/><column name="SortFields(4)" property="KeyfieldName" value="COLUMN_NAME" type="String"/><column name="SortFields(4)" property="SortOn" value="0" type="Double"/><column name="SortFields(4)" property="Order" value="1" type="Double"/><column name="SortFields(4)" property="DataOption" value="0" type="Double"/><column name="SortFields(5)" property="KeyfieldName" value="MENU_ORDER" type="String"/><column name="SortFields(5)" property="SortOn" value="0" type="Double"/><column name="SortFields(5)" property="Order" value="1" type="Double"/><column name="SortFields(5)" property="DataOption" value="0" type="Double"/><column name="SortFields(6)" property="KeyfieldName" value="HANDLER_SCHEMA" type="String"/><column name="SortFields(6)" property="SortOn" value="0" type="Double"/><column name="SortFields(6)" property="Order" value="1" type="Double"/><column name="SortFields(6)" property="DataOption" value="0" type="Double"/><column name="SortFields(7)" property="KeyfieldName" value="HANDLER_NAME" type="String"/><column name="SortFields(7)" property="SortOn" value="0" type="Double"/><column name="SortFields(7)" property="Order" value="1" type="Double"/><column name="SortFields(7)" property="DataOption" value="0" type="Double"/><column name="" property="ActiveWindow.DisplayGridlines" value="False" type="Boolean"/><column name="" property="ActiveWindow.FreezePanes" value="True" type="Boolean"/><column name="" property="ActiveWindow.Split" value="True" type="Boolean"/><column name="" property="ActiveWindow.SplitRow" value="0" type="Double"/><column name="" property="ActiveWindow.SplitColumn" value="-2" type="Double"/><column name="" property="PageSetup.Orientation" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesWide" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesTall" value="1" type="Double"/></columnFormats></table>');
INSERT INTO xls.formats (TABLE_SCHEMA, TABLE_NAME, TABLE_EXCEL_FORMAT_XML) VALUES ('xls', 'objects', '<table name="xls.objects"><columnFormats><column name="" property="ListObjectName" value="objects" type="String"/><column name="" property="ShowTotals" value="False" type="Boolean"/><column name="" property="TableStyle.Name" value="TableStyleMedium15" type="String"/><column name="" property="ShowTableStyleColumnStripes" value="False" type="Boolean"/><column name="" property="ShowTableStyleFirstColumn" value="False" type="Boolean"/><column name="" property="ShowShowTableStyleLastColumn" value="False" type="Boolean"/><column name="" property="ShowTableStyleRowStripes" value="False" type="Boolean"/><column name="_RowNum" property="EntireColumn.Hidden" value="True" type="Boolean"/><column name="_RowNum" property="Address" value="$B$4" type="String"/><column name="_RowNum" property="NumberFormat" value="General" type="String"/><column name="_RowNum" property="VerticalAlignment" value="-4160" type="Double"/><column name="ID" property="EntireColumn.Hidden" value="True" type="Boolean"/><column name="ID" property="Address" value="$C$4" type="String"/><column name="ID" property="NumberFormat" value="General" type="String"/><column name="ID" property="VerticalAlignment" value="-4160" type="Double"/><column name="TABLE_SCHEMA" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_SCHEMA" property="Address" value="$D$4" type="String"/><column name="TABLE_SCHEMA" property="ColumnWidth" value="16.57" type="Double"/><column name="TABLE_SCHEMA" property="NumberFormat" value="General" type="String"/><column name="TABLE_SCHEMA" property="VerticalAlignment" value="-4160" type="Double"/><column name="TABLE_NAME" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_NAME" property="Address" value="$E$4" type="String"/><column name="TABLE_NAME" property="ColumnWidth" value="30" type="Double"/><column name="TABLE_NAME" property="NumberFormat" value="General" type="String"/><column name="TABLE_NAME" property="VerticalAlignment" value="-4160" type="Double"/><column name="TABLE_TYPE" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_TYPE" property="Address" value="$F$4" type="String"/><column name="TABLE_TYPE" property="ColumnWidth" value="13.14" type="Double"/><column name="TABLE_TYPE" property="NumberFormat" value="General" type="String"/><column name="TABLE_TYPE" property="VerticalAlignment" value="-4160" type="Double"/><column name="TABLE_TYPE" property="Validation.Type" value="3" type="Double"/><column name="TABLE_TYPE" property="Validation.Operator" value="1" type="Double"/><column name="TABLE_TYPE" property="Validation.Formula1" value="TABLE; VIEW; PROCEDURE; CODE; HTTP; TEXT; HIDDEN" type="String"/><column name="TABLE_TYPE" property="Validation.AlertStyle" value="1" type="Double"/><column name="TABLE_TYPE" property="Validation.IgnoreBlank" value="True" type="Boolean"/><column name="TABLE_TYPE" property="Validation.InCellDropdown" value="True" type="Boolean"/><column name="TABLE_TYPE" property="Validation.ShowInput" value="True" type="Boolean"/><column name="TABLE_TYPE" property="Validation.ShowError" value="True" type="Boolean"/><column name="TABLE_CODE" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_CODE" property="Address" value="$G$4" type="String"/><column name="TABLE_CODE" property="ColumnWidth" value="13.57" type="Double"/><column name="TABLE_CODE" property="NumberFormat" value="General" type="String"/><column name="TABLE_CODE" property="VerticalAlignment" value="-4160" type="Double"/><column name="INSERT_OBJECT" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="INSERT_OBJECT" property="Address" value="$H$4" type="String"/><column name="INSERT_OBJECT" property="ColumnWidth" value="27.86" type="Double"/><column name="INSERT_OBJECT" property="NumberFormat" value="General" type="String"/><column name="INSERT_OBJECT" property="VerticalAlignment" value="-4160" type="Double"/><column name="UPDATE_OBJECT" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="UPDATE_OBJECT" property="Address" value="$I$4" type="String"/><column name="UPDATE_OBJECT" property="ColumnWidth" value="27.86" type="Double"/><column name="UPDATE_OBJECT" property="NumberFormat" value="General" type="String"/><column name="UPDATE_OBJECT" property="VerticalAlignment" value="-4160" type="Double"/><column name="DELETE_OBJECT" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="DELETE_OBJECT" property="Address" value="$J$4" type="String"/><column name="DELETE_OBJECT" property="ColumnWidth" value="27.86" type="Double"/><column name="DELETE_OBJECT" property="NumberFormat" value="General" type="String"/><column name="DELETE_OBJECT" property="VerticalAlignment" value="-4160" type="Double"/><column name="SortFields(1)" property="KeyfieldName" value="TABLE_SCHEMA" type="String"/><column name="SortFields(1)" property="SortOn" value="0" type="Double"/><column name="SortFields(1)" property="Order" value="1" type="Double"/><column name="SortFields(1)" property="DataOption" value="2" type="Double"/><column name="SortFields(2)" property="KeyfieldName" value="TABLE_NAME" type="String"/><column name="SortFields(2)" property="SortOn" value="0" type="Double"/><column name="SortFields(2)" property="Order" value="1" type="Double"/><column name="SortFields(2)" property="DataOption" value="2" type="Double"/><column name="" property="ActiveWindow.DisplayGridlines" value="False" type="Boolean"/><column name="" property="ActiveWindow.FreezePanes" value="True" type="Boolean"/><column name="" property="ActiveWindow.Split" value="True" type="Boolean"/><column name="" property="ActiveWindow.SplitRow" value="0" type="Double"/><column name="" property="ActiveWindow.SplitColumn" value="-2" type="Double"/><column name="" property="PageSetup.Orientation" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesWide" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesTall" value="1" type="Double"/></columnFormats></table>');
INSERT INTO xls.formats (TABLE_SCHEMA, TABLE_NAME, TABLE_EXCEL_FORMAT_XML) VALUES ('xls', 'queries', '<table name="xls.queries"><columnFormats><column name="" property="ListObjectName" value="queries" type="String"/><column name="" property="ShowTotals" value="False" type="Boolean"/><column name="" property="TableStyle.Name" value="TableStyleMedium15" type="String"/><column name="" property="ShowTableStyleColumnStripes" value="False" type="Boolean"/><column name="" property="ShowTableStyleFirstColumn" value="False" type="Boolean"/><column name="" property="ShowShowTableStyleLastColumn" value="False" type="Boolean"/><column name="" property="ShowTableStyleRowStripes" value="False" type="Boolean"/><column name="_RowNum" property="EntireColumn.Hidden" value="True" type="Boolean"/><column name="_RowNum" property="Address" value="$B$4" type="String"/><column name="_RowNum" property="NumberFormat" value="General" type="String"/><column name="TABLE_SCHEMA" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_SCHEMA" property="Address" value="$C$4" type="String"/><column name="TABLE_SCHEMA" property="ColumnWidth" value="16.57" type="Double"/><column name="TABLE_SCHEMA" property="NumberFormat" value="General" type="String"/><column name="TABLE_NAME" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_NAME" property="Address" value="$D$4" type="String"/><column name="TABLE_NAME" property="ColumnWidth" value="30" type="Double"/><column name="TABLE_NAME" property="NumberFormat" value="General" type="String"/><column name="TABLE_TYPE" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_TYPE" property="Address" value="$E$4" type="String"/><column name="TABLE_TYPE" property="ColumnWidth" value="13.14" type="Double"/><column name="TABLE_TYPE" property="NumberFormat" value="General" type="String"/><column name="TABLE_CODE" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_CODE" property="Address" value="$F$4" type="String"/><column name="TABLE_CODE" property="ColumnWidth" value="13.57" type="Double"/><column name="TABLE_CODE" property="NumberFormat" value="General" type="String"/><column name="INSERT_PROCEDURE" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="INSERT_PROCEDURE" property="Address" value="$G$4" type="String"/><column name="INSERT_PROCEDURE" property="ColumnWidth" value="27.86" type="Double"/><column name="INSERT_PROCEDURE" property="NumberFormat" value="General" type="String"/><column name="UPDATE_PROCEDURE" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="UPDATE_PROCEDURE" property="Address" value="$H$4" type="String"/><column name="UPDATE_PROCEDURE" property="ColumnWidth" value="27.86" type="Double"/><column name="UPDATE_PROCEDURE" property="NumberFormat" value="General" type="String"/><column name="DELETE_PROCEDURE" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="DELETE_PROCEDURE" property="Address" value="$I$4" type="String"/><column name="DELETE_PROCEDURE" property="ColumnWidth" value="27.86" type="Double"/><column name="DELETE_PROCEDURE" property="NumberFormat" value="General" type="String"/><column name="PROCEDURE_TYPE" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="PROCEDURE_TYPE" property="Address" value="$J$4" type="String"/><column name="PROCEDURE_TYPE" property="ColumnWidth" value="18.86" type="Double"/><column name="PROCEDURE_TYPE" property="NumberFormat" value="General" type="String"/><column name="SortFields(1)" property="KeyfieldName" value="TABLE_SCHEMA" type="String"/><column name="SortFields(1)" property="SortOn" value="0" type="Double"/><column name="SortFields(1)" property="Order" value="1" type="Double"/><column name="SortFields(1)" property="DataOption" value="2" type="Double"/><column name="SortFields(2)" property="KeyfieldName" value="TABLE_NAME" type="String"/><column name="SortFields(2)" property="SortOn" value="0" type="Double"/><column name="SortFields(2)" property="Order" value="1" type="Double"/><column name="SortFields(2)" property="DataOption" value="2" type="Double"/><column name="" property="ActiveWindow.DisplayGridlines" value="False" type="Boolean"/><column name="" property="ActiveWindow.FreezePanes" value="True" type="Boolean"/><column name="" property="ActiveWindow.Split" value="True" type="Boolean"/><column name="" property="ActiveWindow.SplitRow" value="0" type="Double"/><column name="" property="ActiveWindow.SplitColumn" value="-2" type="Double"/><column name="" property="PageSetup.Orientation" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesWide" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesTall" value="1" type="Double"/></columnFormats></table>');
INSERT INTO xls.formats (TABLE_SCHEMA, TABLE_NAME, TABLE_EXCEL_FORMAT_XML) VALUES ('xls', 'translations', '<table name="xls.translations"><columnFormats><column name="" property="ListObjectName" value="translations" type="String"/><column name="" property="ShowTotals" value="False" type="Boolean"/><column name="" property="TableStyle.Name" value="TableStyleMedium15" type="String"/><column name="" property="ShowTableStyleColumnStripes" value="False" type="Boolean"/><column name="" property="ShowTableStyleFirstColumn" value="False" type="Boolean"/><column name="" property="ShowShowTableStyleLastColumn" value="False" type="Boolean"/><column name="" property="ShowTableStyleRowStripes" value="False" type="Boolean"/><column name="_RowNum" property="EntireColumn.Hidden" value="True" type="Boolean"/><column name="_RowNum" property="Address" value="$B$4" type="String"/><column name="_RowNum" property="NumberFormat" value="General" type="String"/><column name="_RowNum" property="VerticalAlignment" value="-4160" type="Double"/><column name="ID" property="EntireColumn.Hidden" value="True" type="Boolean"/><column name="ID" property="Address" value="$C$4" type="String"/><column name="ID" property="NumberFormat" value="General" type="String"/><column name="ID" property="VerticalAlignment" value="-4160" type="Double"/><column name="TABLE_SCHEMA" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_SCHEMA" property="Address" value="$D$4" type="String"/><column name="TABLE_SCHEMA" property="ColumnWidth" value="16.57" type="Double"/><column name="TABLE_SCHEMA" property="NumberFormat" value="General" type="String"/><column name="TABLE_SCHEMA" property="VerticalAlignment" value="-4160" type="Double"/><column name="TABLE_NAME" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_NAME" property="Address" value="$E$4" type="String"/><column name="TABLE_NAME" property="ColumnWidth" value="32.14" type="Double"/><column name="TABLE_NAME" property="NumberFormat" value="General" type="String"/><column name="TABLE_NAME" property="VerticalAlignment" value="-4160" type="Double"/><column name="COLUMN_NAME" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="COLUMN_NAME" property="Address" value="$F$4" type="String"/><column name="COLUMN_NAME" property="ColumnWidth" value="20.71" type="Double"/><column name="COLUMN_NAME" property="NumberFormat" value="General" type="String"/><column name="COLUMN_NAME" property="VerticalAlignment" value="-4160" type="Double"/><column name="LANGUAGE_NAME" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="LANGUAGE_NAME" property="Address" value="$G$4" type="String"/><column name="LANGUAGE_NAME" property="ColumnWidth" value="19.57" type="Double"/><column name="LANGUAGE_NAME" property="NumberFormat" value="General" type="String"/><column name="LANGUAGE_NAME" property="VerticalAlignment" value="-4160" type="Double"/><column name="TRANSLATED_NAME" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TRANSLATED_NAME" property="Address" value="$H$4" type="String"/><column name="TRANSLATED_NAME" property="ColumnWidth" value="30" type="Double"/><column name="TRANSLATED_NAME" property="NumberFormat" value="General" type="String"/><column name="TRANSLATED_NAME" property="VerticalAlignment" value="-4160" type="Double"/><column name="TRANSLATED_DESC" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TRANSLATED_DESC" property="Address" value="$I$4" type="String"/><column name="TRANSLATED_DESC" property="ColumnWidth" value="19.57" type="Double"/><column name="TRANSLATED_DESC" property="NumberFormat" value="General" type="String"/><column name="TRANSLATED_DESC" property="VerticalAlignment" value="-4160" type="Double"/><column name="TRANSLATED_COMMENT" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TRANSLATED_COMMENT" property="Address" value="$J$4" type="String"/><column name="TRANSLATED_COMMENT" property="ColumnWidth" value="25" type="Double"/><column name="TRANSLATED_COMMENT" property="NumberFormat" value="General" type="String"/><column name="TRANSLATED_COMMENT" property="VerticalAlignment" value="-4160" type="Double"/><column name="SortFields(1)" property="KeyfieldName" value="LANGUAGE_NAME" type="String"/><column name="SortFields(1)" property="SortOn" value="0" type="Double"/><column name="SortFields(1)" property="Order" value="1" type="Double"/><column name="SortFields(1)" property="DataOption" value="2" type="Double"/><column name="SortFields(2)" property="KeyfieldName" value="TABLE_SCHEMA" type="String"/><column name="SortFields(2)" property="SortOn" value="0" type="Double"/><column name="SortFields(2)" property="Order" value="1" type="Double"/><column name="SortFields(2)" property="DataOption" value="2" type="Double"/><column name="SortFields(3)" property="KeyfieldName" value="TABLE_NAME" type="String"/><column name="SortFields(3)" property="SortOn" value="0" type="Double"/><column name="SortFields(3)" property="Order" value="1" type="Double"/><column name="SortFields(3)" property="DataOption" value="2" type="Double"/><column name="SortFields(4)" property="KeyfieldName" value="COLUMN_NAME" type="String"/><column name="SortFields(4)" property="SortOn" value="0" type="Double"/><column name="SortFields(4)" property="Order" value="1" type="Double"/><column name="SortFields(4)" property="DataOption" value="2" type="Double"/><column name="" property="ActiveWindow.DisplayGridlines" value="False" type="Boolean"/><column name="" property="ActiveWindow.FreezePanes" value="True" type="Boolean"/><column name="" property="ActiveWindow.Split" value="True" type="Boolean"/><column name="" property="ActiveWindow.SplitRow" value="0" type="Double"/><column name="" property="ActiveWindow.SplitColumn" value="-2" type="Double"/><column name="" property="PageSetup.Orientation" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesWide" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesTall" value="1" type="Double"/></columnFormats></table>');
INSERT INTO xls.formats (TABLE_SCHEMA, TABLE_NAME, TABLE_EXCEL_FORMAT_XML) VALUES ('xls', 'workbooks', '<table name="xls.workbooks"><columnFormats><column name="" property="ListObjectName" value="workbooks" type="String"/><column name="" property="ShowTotals" value="False" type="Boolean"/><column name="" property="TableStyle.Name" value="TableStyleMedium15" type="String"/><column name="" property="ShowTableStyleColumnStripes" value="False" type="Boolean"/><column name="" property="ShowTableStyleFirstColumn" value="False" type="Boolean"/><column name="" property="ShowShowTableStyleLastColumn" value="False" type="Boolean"/><column name="" property="ShowTableStyleRowStripes" value="False" type="Boolean"/><column name="_RowNum" property="EntireColumn.Hidden" value="True" type="Boolean"/><column name="_RowNum" property="Address" value="$B$4" type="String"/><column name="_RowNum" property="NumberFormat" value="General" type="String"/><column name="_RowNum" property="VerticalAlignment" value="-4160" type="Double"/><column name="ID" property="EntireColumn.Hidden" value="True" type="Boolean"/><column name="ID" property="Address" value="$C$4" type="String"/><column name="ID" property="NumberFormat" value="General" type="String"/><column name="ID" property="VerticalAlignment" value="-4160" type="Double"/><column name="NAME" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="NAME" property="Address" value="$D$4" type="String"/><column name="NAME" property="ColumnWidth" value="42.14" type="Double"/><column name="NAME" property="NumberFormat" value="General" type="String"/><column name="NAME" property="VerticalAlignment" value="-4160" type="Double"/><column name="TEMPLATE" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TEMPLATE" property="Address" value="$E$4" type="String"/><column name="TEMPLATE" property="ColumnWidth" value="30" type="Double"/><column name="TEMPLATE" property="NumberFormat" value="General" type="String"/><column name="TEMPLATE" property="VerticalAlignment" value="-4160" type="Double"/><column name="DEFINITION" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="DEFINITION" property="Address" value="$F$4" type="String"/><column name="DEFINITION" property="ColumnWidth" value="70.71" type="Double"/><column name="DEFINITION" property="NumberFormat" value="General" type="String"/><column name="DEFINITION" property="VerticalAlignment" value="-4160" type="Double"/><column name="TABLE_SCHEMA" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="TABLE_SCHEMA" property="Address" value="$G$4" type="String"/><column name="TABLE_SCHEMA" property="ColumnWidth" value="16.57" type="Double"/><column name="TABLE_SCHEMA" property="NumberFormat" value="General" type="String"/><column name="TABLE_SCHEMA" property="VerticalAlignment" value="-4160" type="Double"/><column name="SortFields(1)" property="KeyfieldName" value="TABLE_SCHEMA" type="String"/><column name="SortFields(1)" property="SortOn" value="0" type="Double"/><column name="SortFields(1)" property="Order" value="1" type="Double"/><column name="SortFields(1)" property="DataOption" value="0" type="Double"/><column name="SortFields(2)" property="KeyfieldName" value="NAME" type="String"/><column name="SortFields(2)" property="SortOn" value="0" type="Double"/><column name="SortFields(2)" property="Order" value="1" type="Double"/><column name="SortFields(2)" property="DataOption" value="0" type="Double"/><column name="" property="ActiveWindow.DisplayGridlines" value="False" type="Boolean"/><column name="" property="ActiveWindow.FreezePanes" value="True" type="Boolean"/><column name="" property="ActiveWindow.Split" value="True" type="Boolean"/><column name="" property="ActiveWindow.SplitRow" value="0" type="Double"/><column name="" property="ActiveWindow.SplitColumn" value="-2" type="Double"/><column name="" property="PageSetup.Orientation" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesWide" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesTall" value="1" type="Double"/></columnFormats></table>');
INSERT INTO xls.formats (TABLE_SCHEMA, TABLE_NAME, TABLE_EXCEL_FORMAT_XML) VALUES ('xls', 'users', '<table name="xls.users"><columnFormats><column name="" property="ListObjectName" value="users" type="String"/><column name="" property="ShowTotals" value="False" type="Boolean"/><column name="" property="TableStyle.Name" value="TableStyleMedium15" type="String"/><column name="" property="ShowTableStyleColumnStripes" value="False" type="Boolean"/><column name="" property="ShowTableStyleFirstColumn" value="False" type="Boolean"/><column name="" property="ShowShowTableStyleLastColumn" value="False" type="Boolean"/><column name="" property="ShowTableStyleRowStripes" value="False" type="Boolean"/><column name="_RowNum" property="EntireColumn.Hidden" value="True" type="Boolean"/><column name="_RowNum" property="Address" value="$B$4" type="String"/><column name="_RowNum" property="NumberFormat" value="General" type="String"/><column name="user" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="user" property="Address" value="$C$4" type="String"/><column name="user" property="ColumnWidth" value="22.14" type="Double"/><column name="user" property="NumberFormat" value="General" type="String"/><column name="role" property="EntireColumn.Hidden" value="False" type="Boolean"/><column name="role" property="Address" value="$D$4" type="String"/><column name="role" property="ColumnWidth" value="20.71" type="Double"/><column name="role" property="NumberFormat" value="General" type="String"/><column name="" property="ActiveWindow.DisplayGridlines" value="False" type="Boolean"/><column name="" property="ActiveWindow.FreezePanes" value="True" type="Boolean"/><column name="" property="ActiveWindow.Split" value="True" type="Boolean"/><column name="" property="ActiveWindow.SplitRow" value="0" type="Double"/><column name="" property="ActiveWindow.SplitColumn" value="-2" type="Double"/><column name="" property="PageSetup.Orientation" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesWide" value="1" type="Double"/><column name="" property="PageSetup.FitToPagesTall" value="1" type="Double"/></columnFormats></table>');

INSERT INTO xls.workbooks (NAME, TEMPLATE, DEFINITION, TABLE_SCHEMA) VALUES ('savetodb_configuration.xlsx', NULL,
'objects=xls.objects,(Default),False,$B$3,,{"Parameters":{"TABLE_SCHEMA":null,"TABLE_TYPE":null},"ListObjectName":"objects"}
handlers=xls.handlers,(Default),False,$B$3,,{"Parameters":{"TABLE_SCHEMA":null,"EVENT_NAME":null,"HANDLER_TYPE":null},"ListObjectName":"handlers"}
columns=xls.columns,(Default),False,$B$3,,{"Parameters":{"TABLE_SCHEMA":null,"TABLE_NAME":null},"ListObjectName":"columns"}
translations=xls.translations,(Default),False,$B$3,,{"Parameters":{"TABLE_SCHEMA":null,"LANGUAGE_NAME":null},"ListObjectName":"translations"}
workbooks=xls.workbooks,(Default),False,$B$3,,{"Parameters":{"TABLE_SCHEMA":null},"ListObjectName":"workbooks"}
users=xls.users,(Default),False,$B$3,,{"Parameters":{},"ListObjectName":"users"}', 'xls');

-- print SaveToDB Framework installed
