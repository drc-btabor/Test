USE [msdb]
GO

--only to be placed on the primary idb client.

declare @db_n varchar(100)
SELECT top (1) @db_n= name from sys.databases where name like '%client%prod'
--print @db_n


/****** Object:  Job [DM_ClientLCSPurge]    Script Date: 11/18/2016 1:13:40 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 11/18/2016 1:13:40 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DM_ClientLCSPurge', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DATARECOGNITION\SQLJobsDM', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [one]    Script Date: 11/18/2016 1:13:40 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'one', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'set nocount on; 

--get config days
declare @Ping_Days int = 30
,@Sim_Days int = 180
 ,@Readiness_Days int = 180
,@Rows int = 1
,@Rows_commit int = 1000
,@total_commits int = 0

create table #lcs (
AdministrationID int not null
,Historical_Id bigint not null
)

-- pings, leaving latest unique lcsid 
insert into #lcs select top 500000 AdministrationID, Historical_Id 
from (
select row_number() over (partition by lcsid order by createdate desc) as row_num, AdministrationID, Historical_Id
 FROM [LCS_HistoricalData]
     where LcsDataType=''Ping''
  and createdate < dateadd(d,-@Ping_Days,getdate())
  ) a
  where a.row_num > 1

--rcd 
insert into  #lcs
select AdministrationID, Historical_Id
 FROM [LCS_HistoricalData]
     where LcsDataType=''Simulation''
  and createdate < dateadd(d,-@Sim_Days,getdate())

 CREATE NONCLUSTERED INDEX [ix1] ON #lcs (AdministrationID,historical_id)



--keep deleting until no rows are found to delete
while @Rows > 0
begin
	begin tran
	delete top (@Rows_commit)[dbo].[LCS_HistoricalData]
	from [dbo].[LCS_HistoricalData] a
	inner join #lcs b
	 on a.AdministrationID = b.AdministrationID
       and a.Historical_Id = b.Historical_Id
	select @Rows=@@ROWCOUNT
	commit tran
	select @total_commits=@total_commits+1
end
drop table #lcs

--rcd
--keep deleting until no rows are found to delete
set @rows=1
while @Rows > 0
begin
	begin tran
	  delete top (@Rows_commit) from Audit_Summary_Client
        where last_executed  < dateadd(d,-@Readiness_Days,getdate())
	   select @Rows=@@ROWCOUNT
	commit tran
	select @total_commits=@total_commits+1
end


print ''total commits: ''+ cast(@total_commits as varchar(5)) 
', 
		@database_name=@db_n,
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=64, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20161118, 
		@active_end_date=99991231, 
		@active_start_time=180000, 
		@active_end_time=235959 
		--@schedule_uid=N'5987c35b-d5aa-4352-ab7d-4c05d2b2f892'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


