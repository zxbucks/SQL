--Create an extended event session
CREATE EVENT SESSION [what_queries_are_failing] 
ON SERVER 
ADD EVENT sqlserver.error_reported(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,
	sqlserver.query_hash_signed,sqlserver.server_principal_name,sqlserver.sql_text,sqlserver.tsql_stack)
    WHERE ([severity]>(10)))
ADD TARGET package0.event_file
(SET filename=N'C:\Temp\XEvents_what_queries_are_failing.xel',
     max_file_size=(50),
	 max_rollover_files=(5),
     metadatafile=N'C:\Temp\XEvents_what_queries_are_failing.xem')
WITH (
	EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
	MAX_DISPATCH_LATENCY=30 SECONDS,
	TRACK_CAUSALITY=ON,
	STARTUP_STATE=OFF
)

GO

-- Start the session
ALTER EVENT SESSION [what_queries_are_failing]
ON SERVER STATE = START
GO


-- Stop your Extended Events session
ALTER EVENT SESSION [what_queries_are_failing] ON SERVER
STATE = STOP;
GO

-- Clean up your session from the server
DROP EVENT SESSION [what_queries_are_failing] ON SERVER;
GO
