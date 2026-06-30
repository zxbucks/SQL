/*
Purpose:
    Capture actual execution plans for a short troubleshooting window.

Notes:
    - query_post_execution_showplan captures actual plans.
    - It can be expensive. Start it, run the test, then stop it.
    - Use a unique piece of SQL text from the target statement for safer filtering.
*/

CREATE EVENT SESSION [XE_ActualPlan_Capture]
ON SERVER
ADD EVENT sqlserver.query_post_execution_showplan
(
    ACTION
    (
        sqlserver.database_name,
        sqlserver.session_id,
        sqlserver.sql_text
    )
    WHERE
    (
        sqlserver.database_name = N'<DatabaseName>'
        AND sqlserver.sql_text LIKE N'%<UniqueStatementText>%'
    )
)
ADD TARGET package0.event_file
(
    SET filename = N'<FilePath>\XE_ActualPlan_Capture.xel',
        max_file_size = 100,
        max_rollover_files = 5
)
WITH
(
    MAX_MEMORY = 4096 KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 5 SECONDS,
    TRACK_CAUSALITY = ON,
    STARTUP_STATE = OFF
);
GO

ALTER EVENT SESSION [XE_ActualPlan_Capture]
ON SERVER
STATE = START;
GO

-- Run the test here.

ALTER EVENT SESSION [XE_ActualPlan_Capture]
ON SERVER
STATE = STOP;
GO
