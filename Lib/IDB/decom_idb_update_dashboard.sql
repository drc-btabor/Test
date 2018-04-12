--on dcwmsqp145\sql, used when decom idb databases
use Insight_Dashboard_prod
go

--check are theses the one that are decom, if so then run statement below
SELECT *
  FROM [Insight_Dashboard_prod].[config].[db_list]
  where is_active=1
  and last_call_d < dateadd(d,-1,getdate())
  order by last_call_d asc


begin tran 
update [Insight_Dashboard_prod].[config].[db_list]
set  is_active=0
where is_active=1
  and last_call_d < dateadd(d,-1,getdate())

  commit
