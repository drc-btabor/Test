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


print 'Rem Run AG Setup'
--checks if currently there has AG setup on src
if ((select count(*) from sys.databases
where name = @vdb_n
and replica_id is not null) > 0)
begin
  --Generates commands to run on the dest_primary and dest_secondary
  print 'Rem Gen the AG command'
  print 'sqlcmd -S '+ @vdest_inst_n + ' -Q "exec dba_analysis..dba_gen_replica '''+@vdb_n+''', ''ag_'+ @vdest_srv_n+ '_'+ @vdest_replica_srv_n +'''" -o replica_add.sql'
  print 'Rem Run the Gen AG command'
  print 'sqlcmd -S '+ @vdest_inst_n + ' -i .\replica_add.sql'
 
end
else
begin
   print 'rem No Replica Needed'
end

