@echo off
SETLOCAL

REM Define variables
SET APP_NAME=my_app
SET INSTALL_DIR=%ProgramFiles%\%APP_NAME%

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
