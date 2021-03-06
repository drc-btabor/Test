set nocount on


declare @vdb_n varchar(1000)='$(db_n)'
,@vinst_n varchar(1000) = '$(dest_inst_n)'
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
print ':on error exit'


--change connection
--print ':Connect ' + @vinst_n
print 'use master'
print 'go'

print ' '
select @sql=''
--put them back
 select @sql=@sql+'if ((select size from [' + db_n+ '].sys.sysfiles where name = '''+ name+ ''') < '+cast(size as varchar(10)) +')
 ALTER DATABASE [' + db_n+ '] MODIFY FILE ( NAME = ['+ name+ '], SIZE = '+ cast(FILE_SIZE_MB as varchar(10)) + 'MB ) ' + char(10)

from #jk
where dbid >4
and FILE_SIZE_MB > 1024
and FREE_SPACE_MB > 20480 -- 20GB
and  db_n <> 'dba_analysis'
order by FILE_SIZE_MB 
if len(@sql) > 0 
begin 
  print @sql
  print 'go'
end
else
 begin
  print '-- no post step need'
 end 

