EXEC sp_Blitz @CheckServerInfo=1;
EXEC sp_BlitzFirst @SinceStartup=1, @OutputType='Top10';

EXEC sp_BlitzFirst @seconds= 60, @ExpertMode=1;
--  Tuning: Check top wait stat and focus on 3 numbers.
--     1. Total database size (and quanlity)
--     2. Batch Requests per Sec
--     3. Wait Time Ratio: Wait Time per Core per Sec
--  PAGEIOLATCH_EX:            EXEC sp_BlitzIndex @GetAllDatabases = 1;
--                             EXEC sp_BlitzCache @SortOrder = 'read';
--  SOS_SCHEDULER_YIELD        EXEC sp_BlitzCache @SortOrder = 'cpu';
--                             EXEC sp_BlitzCache @SortOrder = 'cpu', @StoredProcName='usp_Report2';
--  LCK:                       Index tuning: torward the 5 & 5
--                             Query tuning: (Long running low CPU): EXEC sp_BlitzCache @SortOrder = 'duration';
--                             Magic button: Change Isolation Levels(RCSI/SI)
--  THREADPOOL                 (Find the lead blocker, and open transctions)
--  RESOURCES_SEMAPHORE        EXEC sp_BlitzCache @SortOrder = 'memory grant';
--                             EXEC sp_BlitzCache @SortOrder = 'unused grant';
--  Hardware-Sounding Waits    WRITELOG, HADR_SYNC_COMMIT, ASYNC_NETWORK_IO

EXEC sp_WhoIsActive @get_locks = 1, @get_plans = 1;
