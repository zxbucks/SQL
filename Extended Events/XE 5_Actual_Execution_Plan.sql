/*
Purpose:
    Capture actual execution plans for a short troubleshooting window.

Notes:
    - query_post_execution_showplan captures actual plans.
    - It can be expensive. Start it, run the test, then stop it.
    - Use a unique piece of SQL text from the target statement for safer filtering.
*/

CREATE EVENT SESSION [ExecutionPlansOnAdventureWorks2014] ON SERVER 
ADD EVENT sqlserver.query_post_execution_showplan
    (
    ACTION (sqlserver.client_app_name,
            sqlserver.client_hostname,
            sqlserver.database_name,
            sqlserver.sql_text,
            sqlserver.username)
    WHERE ([sqlserver].[equal_i_sql_unicode_string] ([sqlserver].[database_name], N'AdventureWorks2014')
           AND [sqlserver].[like_i_sql_unicode_string] ([sqlserver].[sql_text], N'%Person.Person%'))
    ) 
ADD TARGET package0.event_file
    (
    SET filename = N'C:\temp\ExecutionPlansOnAdventureWorks2014_v3.xel',
        max_file_size = (100),
        max_rollover_files = (5)
    )
WITH  (
        MAX_MEMORY = 4096 KB,
        EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
        MAX_DISPATCH_LATENCY = 30 SECONDS,
        MAX_EVENT_SIZE = 0 KB,
        MEMORY_PARTITION_MODE = NONE,
        TRACK_CAUSALITY = ON,
        STARTUP_STATE = OFF
      );



--Test Script:

USE AdventureWorks2014;
GO
DECLARE @PlanHandle VARBINARY(64);
SELECT @PlanHandle = deqs.plan_handle
FROM sys.dm_exec_query_stats AS deqs
CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) AS dest
WHERE dest.text LIKE '%Person.Person%';
IF @PlanHandle IS NOT NULL
BEGIN
DBCC FREEPROCCACHE(@PlanHandle);
END;
GO

SELECT p.LastName + ', ' + p.FirstName ,
p.Title ,
pp.PhoneNumber
FROM Person.Person AS p
JOIN Person.PersonPhone AS pp
ON pp.BusinessEntityID = p.BusinessEntityID
JOIN Person.PhoneNumberType AS pnt
ON pnt.PhoneNumberTypeID = pp.PhoneNumberTypeID
WHERE pnt.Name = 'Cell'
AND p.LastName = 'Dempsey';
GO
