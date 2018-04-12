/*
USE [master]
GO
DROP WORKLOAD GROUP top_group
DROP WORKLOAD GROUP mid_group
drop RESOURCE POOL top_pool
drop RESOURCE POOL mid_pool
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO
*/
/***
-- ssms Application Name=<YOUR APP NAME>
3)	Create a resource pool for applications in general, and under that pool, create a workload group for each relevant application (or group of applications). In this case, there will be workload groups for:

a)	Requests from Web server(s)
b)	Requests from application server(s)
c)	Requests from applications or hosts you do not recognize
Here is sample code for creating this resource pool and its workload groups:
**/
CREATE RESOURCE POOL [top_pool] WITH(max_cpu_percent=100, AFFINITY SCHEDULER = AUTO);
GO
CREATE RESOURCE POOL [mid_pool]WITH(max_cpu_percent=30, AFFINITY SCHEDULER = AUTO);
GO
ALTER RESOURCE POOL [default] WITH(max_cpu_percent=10, 	AFFINITY SCHEDULER = AUTO);
GO
ALTER WORKLOAD GROUP [default] WITH(max_dop=1)
GO

CREATE WORKLOAD GROUP top_group WITH(max_dop=1)
	USING [top_pool];
GO
CREATE WORKLOAD GROUP mid_group WITH(max_dop=1)
	USING [mid_pool];
GO


/**
6)	Create a classifier function that will route the requests to 
the proper workload group. This can be a little more daunting, 
because you do not want any of the unrecognized requests landing in the wrong workload group:
**/
use master
go
--drop function classifier_governor_udb
CREATE FUNCTION dbo.classifier_governor_udb()
RETURNS SYSNAME
WITH SCHEMABINDING
AS
BEGIN
	DECLARE
		@app SYSNAME,
		@group SYSNAME
		
	SELECT	
		@app = APP_NAME();

		
	SELECT @group = CASE
	   WHEN @app ='insight client services'
	   	  or @app='udbservice'
			THEN N'top_group'
	   WHEN @app ='eweb'
			THEN N'mid_group'
		ELSE
			N'default'
		END;
	
	RETURN (@group);
END
GO

/***
7)	Enable the Resource Governor with this classifier function:
***/

--need when modify classifier
ALTER RESOURCE GOVERNOR
	WITH (CLASSIFIER_FUNCTION = null);
GO
--

ALTER RESOURCE GOVERNOR
	WITH (CLASSIFIER_FUNCTION = dbo.classifier_governor_udb);
GO

ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

/***
8)	Verify the Resource Governor configuration:
***/

SELECT 
	c.classifier_function_id,
	function_name = OBJECT_SCHEMA_NAME(c.classifier_function_id) 
	+ '.' + OBJECT_NAME(c.classifier_function_id),
	c.is_enabled, 
	m.is_reconfiguration_pending
FROM sys.resource_governor_configuration AS c 
CROSS JOIN sys.dm_resource_governor_configuration AS m;

SELECT * FROM sys.resource_governor_resource_pools;

SELECT * FROM sys.resource_governor_workload_groups;

/***
A.	How many users from each workload group are currently connected, 
and which of them are currently running queries?
****/

SELECT 
	g.group_id, 
	GroupName = g.name,
	ConnectedSessions = COALESCE(s.SessionCount, 0),
	ActiveRequests = g.active_request_count
FROM
	sys.dm_resource_governor_workload_groups AS g
LEFT OUTER JOIN
(
	SELECT group_id, SessionCount = COUNT(*)
	FROM sys.dm_exec_sessions
	GROUP BY group_id
) AS s
ON
	g.group_id = s.group_id;	
/***
B.	Is any resource pool experiencing a high number of query optimizations or suboptimal plan generations?
****/
	SELECT 
	      p.pool_id,
	      p.name,
	      g.group_id,
	      g.name,
	      g.total_query_optimization_count,
	      g.total_suboptimal_plan_generation_count
	FROM
	      sys.dm_resource_governor_workload_groups AS g
	INNER JOIN
	      sys.dm_resource_governor_resource_pools AS p
	ON
	      g.pool_id = p.pool_id
	ORDER BY
	      g.total_suboptimal_plan_generation_count DESC	

/****
C.	What is the average CPU time per request in each resource pool to date?
dynamic management views (DMVs) 
***/
SELECT
		p.pool_id,
		p.name,
		total_request_count = COALESCE(SUM(t.total_request_count), 0),
		total_cpu_usage_ms = COALESCE(SUM(t.total_cpu_usage_ms), 0),
		avg_cpu_usage_ms = CASE 
			WHEN SUM(t.total_request_count) > 0 THEN
				SUM(t.total_cpu_usage_ms) 
/ SUM(t.total_request_count)
ELSE
				0 
	    		END
	FROM
	    sys.dm_resource_governor_resource_pools AS p
	LEFT OUTER JOIN
	(
	    SELECT 
			g.pool_id,
			g.total_request_count,
			g.total_cpu_usage_ms
	    FROM
			sys.dm_resource_governor_workload_groups AS g
	    WHERE
			g.pool_id > 1
	) AS t
	ON 
	    p.pool_id = t.pool_id
	GROUP BY
	    p.pool_id,
	    p.name;
/****
D.	How is the system utilizing cache, compile and total memory within each pool and across all pools?
***/

;WITH poolmemory AS
(
SELECT
		pool_id, 
		cache_memory_kb,
		compile_memory_kb,
		used_memory_kb
FROM
		sys.dm_resource_governor_resource_pools
),
totalmemory AS
(
SELECT
		cache = SUM(cache_memory_kb),
		compile = SUM(compile_memory_kb),
		used = COALESCE(NULLIF(SUM(used_memory_kb), 0), -1)
FROM
		poolmemory
)
SELECT
pool_id,
cache_memory_kb,
compile_memory_kb,
used_memory_kb,

	-- % of cache/compile/total this pool is using among total:
	-- (100% is the sum going *down* any of these columns)

	cache_across_pools = cache_memory_kb * 100.0 / cache,
	compile_across_pools = compile_memory_kb * 100.0 / compile,
	used_across_pools = used_memory_kb * 100.0 / used,

	-- % of this pool's memory being used for cache/compile:
	-- (100% is the sum going *across* these two columns)

	pool_cache = cache_memory_kb * 100.0 / 
		COALESCE(NULLIF(used_memory_kb, 0), -1),
	pool_compile = compile_memory_kb * 100.0 / 
	COALESCE(NULLIF(used_memory_kb, 0), -1)
FROM
	poolmemory
CROSS JOIN
	totalmemory;

--give me counts of logins in the pool, 1,2,256,257 internal, default,top_pool, mid_pool 258,259
select login_name, group_id, count(*) as session_count
  from sys.dm_exec_sessions
  where group_id > 1
  group by login_name, group_id
 

select login_name, group_id,* 
  from sys.dm_exec_sessions
  where group_id > 1
  and login_name like 'load%'

 -- dba_analysis..dba_kill_all 'DRCClientI_udb_loadtesting'