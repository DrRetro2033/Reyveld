@echo off

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------
SETLOCAL

REM Define variables
SET APP_NAME=arceus
SET INSTALL_DIR=%AppData%\%APP_NAME%

REM Create the install directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Copy the executable to the install directory
copy /Y "%~dp0%APP_NAME%.exe" "%INSTALL_DIR%"

REM Add the install directory to the PATH if it's not already present
for %%i in ("%PATH:;=" "%") do if "%%~i"=="%INSTALL_DIR%" goto :end
setx PATH "%PATH%;%INSTALL_DIR%"

echo %APP_NAME% installed successfully!
:end
pause
