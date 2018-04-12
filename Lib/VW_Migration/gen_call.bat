@echo off
rem used after scripts folder is created and populated, generates master bat file
rem run at root level folder
FOR /F "tokens=1-2" %%i in ('dir /ad /b .\sqldev003_dev3') DO call :createstep .\sqldev003_dev3\jk_runcopy3.bat %%i
FOR /F "tokens=1-2" %%i in ('dir /ad /b .\sqldev004_dev4') DO call :createstep .\sqldev004_dev4\jk_runcopy4.bat %%i
FOR /F "tokens=1-2" %%i in ('dir /ad /b .\sqldev005_dev5') DO call :createstep .\sqldev005_dev5\jk_runcopy5.bat %%i
goto :EOF

:createstep
set filestep=%1
echo cd \temp\%2 >> %filestep%
echo start "%2" transfer_main.bat >> %filestep%
echo timeout 20 >> %filestep%
