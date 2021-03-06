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
when filename like 'e:\%sql_log%' then 'f:\dev3\sql_log\' 
when filename like 'e:\%sql_data%' then 'f:\dev3\sql_data\' 
when filename like 'f:\%sql_log%' then 'g:\dev3\sql_log\' 
when filename like 'f:\%sql_data%' then 'g:\dev3\sql_data\' 
when filename like 'J:\mnt01\%sql_log%' then 'i:\dev3\sql_log\' 
when filename like 'J:\mnt01\%sql_data%' then 'i:\dev3\sql_data\' 
when filename like 'J:\mnt02\%sql_log%' then 'j:\dev3\sql_log\' 
when filename like 'J:\mnt02\%sql_data%' then 'j:\dev3\sql_data\' 
when filename like 'g:\%sql_log%' then 'f:\dev4\sql_log\' 
when filename like 'g:\%sql_data%' then 'f:\dev4\sql_data\' 
when filename like 'k:\mnt01\%sql_log%' then 'i:\dev4\sql_log\' 
when filename like 'k:\mnt01\%sql_data%' then 'i:\dev4\sql_data\' 
when filename like 'k:\mnt02\%sql_log%' then 'j:\dev4\sql_log\' 
when filename like 'k:\mnt02\%sql_data%' then 'j:\dev4\sql_data\' 
when filename like 'h:\%sql_log%' then 'f:\dev5\sql_log\' 
when filename like 'h:\%sql_data%' then 'f:\dev5\sql_data\' 
when filename like 'i:\%sql_log%' then 'g:\dev5\sql_log\' 
when filename like 'i:\%sql_data%' then 'g:\dev5\sql_data\' 
when filename like 'l:\mnt01\%sql_log%' then 'i:\dev5\sql_log\' 
when filename like 'l:\mnt01\%sql_data%' then 'i:\dev5\sql_data\' 
when filename like 'l:\mnt02\%sql_log%' then 'j:\dev5\sql_log\' 
when filename like 'l:\mnt02\%sql_data%' then 'j:\dev5\sql_data\' 
else 'f:\sql\sql_dataz\' 
end   +substring(filename,len(filename) - charindex('\', reverse(filename))+2,50)+''')' + char(10)
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

