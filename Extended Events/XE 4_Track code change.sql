--******************
--https://www.brentozar.com/archive/2014/04/collecting-detailed-performance-measurements-extended-events/
--******************

CREATE EVENT SESSION [Production Perf Sample-Before] ON SERVER 

ADD EVENT sqlserver.sp_statement_completed(SET collect_object_name=(1)
    ACTION(sqlserver.client_app_name,sqlserver.database_id,
        sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id)
    WHERE ((([package0].[divides_by_uint64]([sqlserver].[session_id],(5))) 
	AND ([package0].[greater_than_uint64]([sqlserver].[database_id],(4)))) 
	AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))
	AND ([sqlserver].[query_hash]<>(0))
	)),

ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.client_app_name,sqlserver.database_id,
        sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id)
    WHERE ((([package0].[divides_by_uint64]([sqlserver].[session_id],(5))) 
	AND ([package0].[greater_than_uint64]([sqlserver].[database_id],(4)))) 
	AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))
	AND ([sqlserver].[query_hash]<>(0))
	)) 

ADD TARGET package0.event_file
	(SET filename=N'c:\Xevents\Traces\Production Perf Sample-Before')
WITH (
	EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
	MAX_DISPATCH_LATENCY=30 SECONDS,
	TRACK_CAUSALITY=ON,
	STARTUP_STATE=OFF
)
GO

--ALTER EVENT SESSION [Production Perf Sample-Before] ON SERVER STATE=START;
--GO

--ALTER EVENT SESSION [Production Perf Sample-Before] ON SERVER STATE=STOP;
--GO
