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

select @sql=null
select @sql=coalesce(@sql+ ',',' ') +' (name='''+ name + ''', filename='''+ 
case
when groupid =0 then 'g:\sql\sql_log\' 
else 'f:\sql\sql_data\' 
end  +substring(filename,len(filename) - charindex('\', reverse(filename))+2,50)+''')' + char(10)
    from #jk
where dbid > 4
and db_n <> 'dba_analysis'
order by dbid, fileid

select @sql = 'create database [' + @vdb_n+ '] on '+ char(10) +@sql+ ' for attach'
print @sql
print 'go'
print ' '

print 'exec dba_analysis..dba_change_owner  @db_n=''' + @vdb_n + ''''
print 'go'

