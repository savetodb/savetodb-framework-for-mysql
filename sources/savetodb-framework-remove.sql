-- =============================================
-- SaveToDB Framework for MySQL
-- Version 10.6, December 13, 2022
--
-- Copyright 2013-2022 Gartle LLC
--
-- License: MIT
-- =============================================

DROP PROCEDURE IF EXISTS xls.xl_actions_add_to_xls_developers;
DROP PROCEDURE IF EXISTS xls.xl_actions_add_to_xls_formats;
DROP PROCEDURE IF EXISTS xls.xl_actions_add_to_xls_users;
DROP PROCEDURE IF EXISTS xls.xl_actions_remove_from_xls_developers;
DROP PROCEDURE IF EXISTS xls.xl_actions_remove_from_xls_formats;
DROP PROCEDURE IF EXISTS xls.xl_actions_remove_from_xls_users;
DROP PROCEDURE IF EXISTS xls.xl_update_table_format;

DROP VIEW IF EXISTS xls.view_columns;
DROP VIEW IF EXISTS xls.view_formats;
DROP VIEW IF EXISTS xls.view_handlers;
DROP VIEW IF EXISTS xls.view_objects;
DROP VIEW IF EXISTS xls.view_queries;
DROP VIEW IF EXISTS xls.view_translations;
DROP VIEW IF EXISTS xls.view_workbooks;
DROP VIEW IF EXISTS xls.queries;
DROP VIEW IF EXISTS xls.users;

DROP TABLE IF EXISTS xls.columns;
DROP TABLE IF EXISTS xls.objects;
DROP TABLE IF EXISTS xls.handlers;
DROP TABLE IF EXISTS xls.formats;
DROP TABLE IF EXISTS xls.translations;
DROP TABLE IF EXISTS xls.workbooks;

DROP SCHEMA IF EXISTS xls;

-- print SaveToDB Framework removed
