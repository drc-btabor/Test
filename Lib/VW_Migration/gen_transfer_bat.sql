set nocount on
-- This Generates the transfer main bat file.

declare @vdb_n varchar(1000)='$(db_n)'
,@vsrc_inst_n varchar(1000) ='$(src_inst_n)'
,@vdest_inst_n varchar(1000) ='$(dest_inst_n)'
,@vdest_srv_n varchar(1000) ='$(dest_srv_n)'
,@vdest_replica_srv_n varchar(1000) ='$(dest_replica_srv_n)'
declare @sql varchar(max)

create table  #jk  (
    dbid int
	,FILEID int
	,groupid int
	,FILE_SIZE_MB int
	,SPACE_USED_MB int
	,FREE_SPACE_MB int
	,NAME varchar(500)
	,filename varchar(1000)
	,size int
	,db_n varchar(100)
)

exec sp_msforeachdb 'use [?]; insert into #jk select
	db_id(),
	a.FILEID,
	a.groupid,
	[FILE_SIZE_MB] = 
		convert(int,round(a.size/128.000,2)),
	[SPACE_USED_MB] =
		convert(int,round(fileproperty(a.name,''SpaceUsed'')/128.000,2)),
	[FREE_SPACE_MB] =
		convert(int,round((a.size-fileproperty(a.name,''SpaceUsed''))/128.000,2)) ,
	NAME = left(a.NAME,135),
	FILENAME = left(a.FILENAME,140)
	,size
	,db_name()
from
	dbo.sysfiles a'

--give me just the db i want
delete from #jk
where db_n <> @vdb_n


--main
print '@echo off'

print ' ' 
print 'set ent_inst=sqlprod014\prd14'
print 'sqlcmd -S%ent_inst% -dent_rpt -Q"insert into dba_patch_fact(server_n, patch_n, start_d) values ('''+@vdb_n+ ''',''VUDB'', GETDATE())"'
print 'sqlcmd -S%ent_inst% -dent_rpt -Q"update dba_patch_fact set start_d = getdate() where server_n='''+@vdb_n+ ''' and patch_n = ''VUDB''"'


print 'Rem Run pre'
print 'sqlcmd -S '+ @vsrc_inst_n + ' -i udb_pre.sql' 
print 'if not %errorlevel%==0 (set rc=%errorlevel%
       echo ****** error in udb_pre.sql
	  goto :die_happy)'

print ' '
print 'Rem Run Robocopy'
select @sql = ''
--robocopy  exit code 1 means file copied over
select @sql=@sql+'ROBOCOPY '+ substring(filename,1, len(filename) - charindex('\', reverse(filename))) +' \\'+@vdest_srv_n+ 
case
when filename like 'e:\%sql_log%' then '\f$\dev3\sql_log ' 
when filename like 'e:\%sql_data%' then '\f$\dev3\sql_data ' 
when filename like 'f:\%sql_log%' then '\g$\dev3\sql_log ' 
when filename like 'f:\%sql_data%' then '\g$\dev3\sql_data ' 
when filename like 'J:\mnt01\%sql_log%' then '\i$\dev3\sql_log ' 
when filename like 'J:\mnt01\%sql_data%' then '\i$\dev3\sql_data ' 
when filename like 'J:\mnt02\%sql_log%' then '\j$\dev3\sql_log ' 
when filename like 'J:\mnt02\%sql_data%' then '\j$\dev3\sql_data ' 
when filename like 'g:\%sql_log%' then '\f$\dev4\sql_log ' 
when filename like 'g:\%sql_data%' then '\f$\dev4\sql_data ' 
when filename like 'k:\mnt01\%sql_log%' then '\i$\dev4\sql_log ' 
when filename like 'k:\mnt01\%sql_data%' then '\i$\dev4\sql_data ' 
when filename like 'k:\mnt02\%sql_log%' then '\j$\dev4\sql_log ' 
when filename like 'k:\mnt02\%sql_data%' then '\j$\dev4\sql_data ' 
when filename like 'h:\%sql_log%' then '\f$\dev5\sql_log ' 
when filename like 'h:\%sql_data%' then '\f$\dev5\sql_data ' 
when filename like 'i:\%sql_log%' then '\g$\dev5\sql_log ' 
when filename like 'i:\%sql_data%' then '\g$\dev5\sql_data ' 
when filename like 'l:\mnt01\%sql_log%' then '\i$\dev5\sql_log ' 
when filename like 'l:\mnt01\%sql_data%' then '\i$\dev5\sql_data ' 
when filename like 'l:\mnt02\%sql_log%' then '\j$\dev5\sql_log ' 
when filename like 'l:\mnt02\%sql_data%' then '\j$\dev5\sql_data ' 
else '\f$\sql\sql_dataz ' 
end 
+substring(filename,len(filename) - charindex('\', reverse(filename))+2,50) + char(13)+ char(10) + 
'if not %errorlevel%==1 (set rc=%errorlevel%
       echo ****** error in robocopy
	  goto :eof)' + char(13)+ char(10)
from  #jk
where dbid > 4
and db_n <> 'dba_analysis'
print @sql

print ' '
print 'Rem Create_db'
print 'sqlcmd -S '+ @vdest_inst_n + ' -i udb_create_db.sql' 
print 'if not %errorlevel%==0 (set rc=%errorlevel%
       echo ****** error in udb_create_db.sql
	  goto :die_happy)'


print ' '
print 'Rem Run Post'
print 'sqlcmd -S '+ @vdest_inst_n + ' -i udb_post.sql' 
print 'if not %errorlevel%==0 (set rc=%errorlevel%
       echo ****** error in udb_post.sql
	  goto :die_happy)'

print 'set rc=%errorlevel%'
print 'sqlcmd -S%ent_inst% -dent_rpt -Q"update dba_patch_fact set finish_d = getdate(), return_c=%rc% where server_n='''+@vdb_n+ ''' and patch_n = ''VUDB''"'
print 'goto :eof'

print ' '
print ':die_happy'
print 'sqlcmd -S%ent_inst% -dent_rpt -Q"update dba_patch_fact set finish_d = getdate(), return_c=%rc% where server_n='''+@vdb_n+ ''' and patch_n = ''VUDB''"'
