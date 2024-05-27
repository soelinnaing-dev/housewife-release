@echo off
NET SESSION >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please run the script as an administrator.
    pause
    exit /b
)
echo Database setup and configruing necessaries processes....
echo * * * * * * * * * * * * * * * * * * * * * * * * * * *
echo.
echo.
for /f "tokens=*" %%A in ('hostname') do set server=%%A\SQLEXPRESS
set scripts_dir=%~dp0

chcp 65001 > nul

for /f "tokens=*" %%f in ('dir /b /on "%scripts_dir%\*.sql"') do (
    sqlcmd -S %server% -E -f 65001 -i "%scripts_dir%\%%f"
)

sc query "SQLAgent$SQLEXPRESS" | find "STATE" | find "RUNNING" >nul
if %errorlevel% equ 0 (
    echo SQL Server Agent service is already running.
    goto :EndScript
)
sc qc "SQLAgent$SQLEXPRESS" | find "START_TYPE" | find "DISABLED" >nul
if %errorlevel% equ 0 (
    echo SQL Server Agent service is disabled. Enabling and starting...
    sc config "SQLAgent$SQLEXPRESS" start=auto
    net start "SQLAgent$SQLEXPRESS"
    if %errorlevel% equ 0 (
        echo SQL Server Agent service started successfully.
    ) else (
        echo Failed to start SQL Server Agent service.
    )
) else (
    echo Starting SQL Server Agent service...
    net start "SQLAgent$SQLEXPRESS"
    if %errorlevel% equ 0 (
        echo SQL Server Agent service started successfully.
    ) else (
        echo Failed to start SQL Server Agent service.
    )
)

:EndScript
pause

