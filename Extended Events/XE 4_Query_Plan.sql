DROP EVENT SESSION [Execution_Plans_Cached] ON SERVER;


GO
CREATE EVENT SESSION [Execution_Plans_Cached] ON SERVER 
ADD EVENT sqlserver.query_post_execution_showplan
    (
    ACTION (sqlserver.client_app_name,
            sqlserver.database_name,
            sqlserver.query_hash,
            sqlserver.query_plan_hash,
            sqlserver.session_id,
            sqlserver.sql_text,
            sqlserver.username)
    WHERE (sqlserver.database_name = N'AdventureWorksDW2025'
           AND (duration > 5000000
                OR cpu_time > 5000000)
           AND NOT sqlserver.like_i_sql_unicode_string (sqlserver.sql_text, N'%sys.%'))
    ) 
ADD TARGET package0.event_file
    (
    SET filename = N'D:\Program Files\XEvents\Execution_Plan_Catched.xel',
        max_file_size = 50,
        max_rollover_files = 4
    )
WITH  (
        MAX_MEMORY = 4096 KB,
        EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
        MAX_DISPATCH_LATENCY = 5 SECONDS,
        STARTUP_STATE = ON
      );


GO
ALTER EVENT SESSION [Execution_Plans_Cached] ON SERVER 
STATE = START;
