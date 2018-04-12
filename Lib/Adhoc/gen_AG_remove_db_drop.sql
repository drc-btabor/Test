/***** Do Not Run Blindly ****
* The Avamar agent should be removed from ag roles prior to executing sql (else remove listener will fail)
* Run command one by one, instead of big batch due to no error_handling
* Verify each command completion prior to next command
* SQL will generate sql to remove db from ag, remove listener and drop AG
*
**********************************************************************/

set nocount on
declare @sql varchar(max) =''

--check if primary
if not exists( select 1 from sys.dm_hadr_availability_group_states where primary_replica =@@SERVERNAME )
      goto error_handler

select @sql=coalesce(@sql + char(10),'') + ' 
ALTER AVAILABILITY GROUP ['+a.name+'] REMOVE DATABASE ['+database_name+'];
waitfor delay ''00:00:15''
exec dba_analysis..dba_kill_all @db_n='''+database_name+'''
alter database '+database_name+ ' set offline'
from sys.availability_groups a
inner join sys.availability_databases_cluster b
on a.group_id = b.group_id

select @sql=@sql+char(10)+ '
waitfor delay ''00:00:15''
ALTER AVAILABILITY GROUP ['+ a.name+ '] REMOVE LISTENER N'''+b.dns_name+''';
waitfor delay ''00:00:15''
DROP AVAILABILITY GROUP ['+a.name+'];
go
'
from sys.availability_groups a
inner join sys.availability_group_listeners b
on a.group_id = b.group_id
order by a.name

print @sql

goto eof

error_handler:
    raiserror ('Must be ran on Primary Replcia', 16,1)

eof:
go
