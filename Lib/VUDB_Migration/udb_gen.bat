@echo off 
rem Syntax:  udb_gen.bat <db_n> <src_inst_n> <dest_inst_n> <dest_replica_srv_n>
rem example: udb_gen.bat jk_test dmclus01\dev1 dmclus02\dev2           --without a replica
rem example: udb_gen.bat jk_test dmclus01\dev1 dmclus02\dev2 dmclus03   --with a replica

set db_n=%1
set src_inst_n=%2
set dest_inst_n=%3
set dest_replica_srv_n=%4
IF [%dest_replica_srv_n%] == [] set dest_replica_srv_n=empty 

rem change the backslash to underscores
set src_inst_n_flat=%src_inst_n:\=_%

set script_dir=c:\temp\vudb\%src_inst_n_flat%

rem parse the first part, to get srv_n
for /f "tokens=1 delims=\" %%a in ("%dest_inst_n%") do set "dest_srv_n=%%a"

if not exist %script_dir%\%db_n% mkdir %script_dir%\%db_n%

rem pre_step
sqlcmd -S %src_inst_n%  -i .\gen_pre.sql -o %script_dir%\%db_n%\udb_pre.sql -v db_n =%db_n%
if not %errorlevel%==0 echo ****** error in gen_pre.sql

rem transfer_main_step
sqlcmd -S %src_inst_n%  -i .\gen_transfer_bat.sql -o %script_dir%\%db_n%\transfer_main.bat -v db_n =%db_n% src_inst_n =%src_inst_n% dest_srv_n =%dest_srv_n% dest_inst_n =%dest_inst_n% dest_replica_srv_n =%dest_replica_srv_n%
if not %errorlevel%==0 echo ****** error in gen_bat.sql

rem create_db_step
sqlcmd -S %2  -i .\gen_create_db.sql -o %script_dir%\%db_n%\udb_create_db.sql -v db_n =%db_n%
if not %errorlevel%==0 echo ****** error in gen_create_db.sql

rem post_step
sqlcmd -S %2  -i .\gen_post.sql -o %script_dir%\%db_n%\udb_post.sql -v db_n =%db_n%
if not %errorlevel%==0 echo ****** error in gen_post.sql
