import "dart:io";

import "package:version/version.dart";

Future<void> main(List<String> args) async {
  final folder = args[0];
  final versionFile = File("$folder/version.txt");
  final appFile = File("$folder/lib/version.dart");
  final version = Version.parse(await versionFile.readAsString());
  // print(await appFile.exists());
  // print("Current version is $version");
  if (args.length > 1) {
    final command = args[1];
    Version newVersion = version;
    switch (command) {
      case "refresh":
        newVersion = Version(version.major, version.minor, version.patch,
            preRelease: version.preRelease);
      case "patch":
        newVersion = Version(version.major, version.minor, version.patch + 1,
            preRelease: version.preRelease);
      case "minor":
        newVersion = Version(version.major, version.minor + 1, 0,
            preRelease: version.preRelease);
      case "major":
        newVersion =
            Version(version.major + 1, 0, 0, preRelease: version.preRelease);
    }
    await versionFile.writeAsString(newVersion.toString());
    await appFile.writeAsString("""
import 'package:version/version.dart';

final currentVersion = Version(${newVersion.major}, ${newVersion.minor}, ${newVersion.patch}, preRelease: [${newVersion.preRelease.map((e) => "\"$e\"").join(", ")}]);""");
    await _updateWindowsInstaller(folder, newVersion);
    print("Updated $version -> $newVersion!");
  }
}

Future<void> _updateWindowsInstaller(String folder, Version version) async {
  final file = File("$folder/scripts/installers/windows/install.bat");
  await file.writeAsString("""
@echo off

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\\SysWOW64\\cacls.exe" "%SYSTEMROOT%\\SysWOW64\\config\\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\\system32\\cacls.exe" "%SYSTEMROOT%\\system32\\config\\system"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\\getadmin.vbs"

    "%temp%\\getadmin.vbs"
    del "%temp%\\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------
SETLOCAL

REM Define variables
SET APP_NAME=arceus
SET VERSION=${version.toString()}
SET INSTALL_DIR=%AppData%\\%APP_NAME%\\server\\%VERSION%

REM Create the install directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Copy the executable to the install directory
copy /Y "%~dp0%APP_NAME%.exe" "%INSTALL_DIR%"

echo %APP_NAME% installed successfully!
:end
pause
""");
}

// REM Add the install directory to the PATH if it's not already present
// for %%i in ("%PATH:;=" "%") do if "%%~i"=="%INSTALL_DIR%" goto :end
// setx PATH "%PATH%;%INSTALL_DIR%"
