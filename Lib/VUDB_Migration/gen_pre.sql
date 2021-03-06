set nocount on
:on error exit
 

declare @vdb_n varchar(1000)='$(db_n)'

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


if ((select count(1) from #jk where db_n = @vdb_n) = 0 )
begin
   raiserror ('db_n does not exists',16,1)
 end


--main
print ':on error exit'


print ' '
select @sql = ''
--checks if currently there has AG setup on src
if ((select count(*) from sys.databases
where name = @vdb_n
and replica_id is not null) > 0)
begin
  --Generates commands to remove db from ag
  print '--remove AG db'
  select @sql='ALTER AVAILABILITY GROUP ['+a.name+'] REMOVE DATABASE ['+@vdb_n+'];'
from sys.availability_groups a
inner join sys.availability_databases_cluster b
on a.group_id = b.group_id
where database_name = @vdb_n
print @sql
print ' waitfor delay ''00:00:20'''
print 'go'
 
end
else
begin
   print '--No Replica removal Needed'
end

select @sql = ''
--/*  give me shrink
select @sql=@sql+'use '+ db_N + '; DBCC SHRINKFILE (N'''+name+''' , 0, truncateonly)'+ char(10)
from #jk
where dbid > 4
and FILE_SIZE_MB > 1024
and FREE_SPACE_MB > 20480 -- 20GB
and db_n <> 'dba_analysis'
order by FILE_SIZE_MB 
--*/
print @sql
print 'go'

print 'use master'
print 'go'
print ' '
print 'exec dba_analysis..dba_kill_all @db_n='''+@vdb_n+''''
print 'exec sp_detach_db '''+@vdb_n+''''
print 'Go'


