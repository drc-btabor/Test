 use ent_rpt
go
--counts
select inst_n, count(*)
from health.errorlog
where last_updt_t > dateadd(d,-1,getdate())
and not msg= 'The Service Broker endpoint is in disabled or stopped state.'
and not msg like 'Starting up database%'
group by inst_n
order by 2 desc

select * from health.errorlog
where last_updt_t > dateadd(d,-1,getdate())
and not msg= 'The Service Broker endpoint is in disabled or stopped state.'
and not msg like 'Starting up database%'
and inst_n like 'DCWMSQP048\SQL'
----order by inst_n, logdate


select srv_n, count(*) from health.event_system
where last_updt_t > dateadd(d,-1,getdate())
group by srv_n


select * from health.event_system
where last_updt_t > dateadd(d,-1,getdate())
and srv_n not in ('DCWRPTP011','DCWRPTP014')


select * from health.event_application
where last_updt_t > dateadd(d,-1,getdate())
and srv_n not in ('DCWRPTP011','DCWRPTP014'
