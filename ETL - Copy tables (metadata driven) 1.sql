--============================================================
-- Solution Overview
--============================================================
-- This solution copies multiple tables using a metadata-driven approach.
-- A control table (dbo.TableCopyMeta) defines:
--   - Source (Linked Server / Database / Schema / Table)
--   - Destination (Schema / Table)
--   - Copy behavior (standard copy vs customized SQL)
--
-- Benefits:
--   - Easily add/remove tables without changing core logic
--   - Centralized control for all table copy operations
--   - Supports both simple SELECT INTO and complex custom queries
--
-- Execution Flow:
--   Step 1: Define metadata in dbo.TableCopyMeta
--   Step 2: Execute copy process driven entirely by metadata
--============================================================


--============================================================
-- Step 1: Setup Metadata Table
--============================================================
DROP TABLE IF EXISTS dbo.TableCopyMeta;


--============================================================
-- Important Notes
--============================================================
-- • ALL T-SQL scripts execute on the CURRENT SQL SERVER
-- • LinkedServer refers to a SQL Server Linked Server object
--   (search: "Create a linked server to another SQL Server instance")
-- • Scripts are designed to correctly handle LinkedServer access
--
-- Copy Logic Based on Customerized Flag:
--
-- When Customerized = 0 (Standard Copy):
--   Executes:
--     SELECT * 
--     INTO DestSchema.DestTable
--     FROM LinkedServer.SourceDatabase.SourceSchema.SourceTable
--
-- When Customerized = 1 (Customized Copy):
--   1. Executes Customerized_SQL via OPENQUERY against LinkedServer
--   2. Then executes Patched_SQL locally (optional, can be NULL/empty)
--============================================================


CREATE TABLE dbo.TableCopyMeta (
    ID INT IDENTITY PRIMARY KEY,

    LinkedServer     SYSNAME       NOT NULL,              -- Linked Server name to copy data from
    SourceDatabase   SYSNAME       NOT NULL,              -- Source database name
    SourceSchema     SYSNAME       NOT NULL,              -- Source schema name
    SourceTable      SYSNAME       NOT NULL,              -- Source table name

    DestSchema       SYSNAME       NOT NULL,              -- Destination schema name (current server)
    DestTable        SYSNAME       NOT NULL,              -- Destination table name (recreated if exists)

    Customerized     BIT           NOT NULL DEFAULT 0,    -- 0 = standard copy, 1 = customized copy
    Customerized_SQL NVARCHAR(MAX) NULL,                 -- Custom SELECT SQL (used only when Customerized = 1)
    Patched_SQL      NVARCHAR(MAX) NULL                  -- Post-copy patch SQL (used only when Customerized = 1)
);


--============================================================
-- Example Metadata Entries
--============================================================
-- • First row: Standard copy (Customerized = 0)
-- • Second row: Customized copy with filtering and post-copy cleanup
--============================================================
INSERT INTO dbo.TableCopyMeta
(LinkedServer, SourceDatabase, SourceSchema, SourceTable, DestSchema, DestTable, Customerized, Customerized_SQL, Patched_SQL)
VALUES	
('LinkedServer1','AdventureWorks','Sales', 'Customers', 'Sales', 'SalesCustomers_Copy', '0', '',''),
('LinkedServer2','AdventureWorks','Sales', 'Orders',    'Sales', 'Orders_Copy',        '0', 'select top 5 * from Sales.Orders','DELETE FROM Sales.Orders_Copy WHERE price=0')
;


--============================================================
-- Validate Metadata Configuration
--============================================================
SELECT * FROM dbo.TableCopyMeta;

