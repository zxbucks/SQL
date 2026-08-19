IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'DeadlockOnly')
DROP EVENT SESSION [DeadlockOnly] ON SERVER;
GO

CREATE EVENT SESSION [CW_DeadlockOnly] ON SERVER 
ADD EVENT sqlserver.xml_deadlock_report(
    ACTION(sqlserver.client_hostname,sqlserver.database_name,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))
ADD TARGET package0.event_file(SET filename=N'DeadlockOnly.xel',max_file_size=(100),max_rollover_files=(10))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=3 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO



DECLARE @xel_path NVARCHAR(260) = N'E:\Program Files\Microsoft SQL Server\MSSQL1X.XXXXXXXX\MSSQL\Log\DeadlockOnly*.xel';

;WITH deadlocks AS (
    SELECT
        object_name,
        event_time_utc = CAST(event_data AS xml).value('(event/@timestamp)[1]', 'datetime2'),
        deadlock_xml = CAST(event_data AS xml).query('(event/data[@name="xml_report"]/value/deadlock)[1]')
    FROM sys.fn_xe_file_target_read_file(@xel_path, NULL, NULL, NULL)
    WHERE object_name = 'xml_deadlock_report'
),
processes AS (
    SELECT
        d.event_time_utc,
        process_id    = p.value('@id', 'varchar(50)'),
        session_id    = p.value('@spid', 'int'),
        client_pid    = p.value('@clientProcessID', 'varchar(50)'),
        db_name       = p.value('@currentdbname', 'varchar(128)'),
        login_name    = p.value('@loginname', 'varchar(128)'),
        host_name     = p.value('@hostname', 'varchar(128)'),
        client_app    = p.value('@clientapp', 'varchar(128)'),
        wait_resource = p.value('@waitresource', 'varchar(256)'),
        wait_time_ms  = p.value('@waittime', 'bigint'),
        isolation_lvl = p.value('@isolationlevel', 'varchar(50)'),
        proc_name     = p.value('(executionStack/frame/@procname)[1]', 'nvarchar(256)'),
        sql_text      = p.value('(inputbuf)[1]', 'nvarchar(max)')
    FROM deadlocks d
    CROSS APPLY d.deadlock_xml.nodes('//process-list/process') AS prc(p)
),
victims AS (
    SELECT
        d.event_time_utc,
        victim_id = v.value('@id', 'varchar(50)')
    FROM deadlocks d
    CROSS APPLY d.deadlock_xml.nodes('//victim-list/victimProcess') AS vic(v)
)
SELECT
    event_time_local = DATEADD(HOUR, DATEDIFF(HOUR, GETUTCDATE(), GETDATE()), p.event_time_utc),
    role        = CASE WHEN v.victim_id IS NOT NULL THEN 'VICTIM (rolled back)' ELSE 'SURVIVOR (blocker)' END,
    p.session_id,
    p.client_pid,
    p.db_name,
    p.login_name,
    p.host_name,
    p.client_app,
    p.wait_resource,
    p.wait_time_ms,
    p.isolation_lvl,
    object_involved = ISNULL(
        p.proc_name,
        CASE 
            WHEN p.sql_text LIKE '%Proc [Database Id =%' THEN
                OBJECT_NAME(
                    TRY_CAST(SUBSTRING(p.sql_text,
                        CHARINDEX('Object Id = ', p.sql_text) + 12,
                        CHARINDEX(']', p.sql_text) - (CHARINDEX('Object Id = ', p.sql_text) + 12)
                    ) AS int),
                    TRY_CAST(SUBSTRING(p.sql_text,
                        CHARINDEX('Database Id = ', p.sql_text) + 14,
                        CHARINDEX(' Object', p.sql_text) - (CHARINDEX('Database Id = ', p.sql_text) + 14)
                    ) AS int)
                )
            ELSE NULL
        END
    ),
    sql_text = CASE 
        WHEN p.sql_text LIKE '%Proc [Database Id =%' THEN '2'  -- replaced by object_involved above
        ELSE p.sql_text
    END
FROM processes p
LEFT JOIN victims v
    ON p.event_time_utc = v.event_time_utc
   AND p.process_id = v.victim_id
ORDER BY event_time_local DESC, role;
