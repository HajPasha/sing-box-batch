@echo off
:: Check for administrative permissions
REM -------------------------------------
:: Check if the script is running with admin rights
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

:: If the error level is not zero, we don't have admin rights
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else (
    goto gotAdmin
)

:UACPrompt
    :: Create a VBS script to request admin privileges
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %*", "", "runas", 1 >> "%temp%\getadmin.vbs"

    :: Execute the VBS script
    "%temp%\getadmin.vbs"

    :: Clean up the VBS script
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    :: Change directory to the location of the batch file
    pushd "%CD%"
    CD /D "%~dp0"
REM --------------------------------------

:: Execute the PowerShell script using PowerShell 7
PowerShell -NoProfile -ExecutionPolicy Bypass -File "Updater.ps1"

:: Pause to keep the command window open
pause
