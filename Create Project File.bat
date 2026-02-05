@echo off
REM Create Project with Symlinks
REM Usage:
REM   - Double-click to be prompted for project name
REM   - Or run from cmd: "Create Project with Symlinks.bat MyProject"
REM This version will ALWAYS wait at the end (or on early exit) so the window does not close automatically.
REM It also creates additional project folders as requested.

setlocal enabledelayedexpansion

rem Get project name from first argument or prompt
if "%~1"=="" (
  set /p PROJECT_NAME=Enter project name:
) else (
  set PROJECT_NAME=%~1
)

if "%PROJECT_NAME%"=="" (
  echo No project name supplied. Exiting.
  goto :finish
)

rem Target folder in the current directory (where script is run)
set "TARGET=%CD%\%PROJECT_NAME%"

if exist "%TARGET%" (
  echo Target "%TARGET%" already exists.
  set /p CONT="Overwrite contents / create links anyway? (Y/N): "
  if /I not "%CONT%"=="Y" (
    echo Aborting.
    goto :finish
  )
)

echo Creating project folder: "%TARGET%"
mkdir "%TARGET%" 2>nul

rem Path to the directory containing this script
set "SCRIPT_DIR=%~dp0"

echo Copying configuration files from "%SCRIPT_DIR%" to "%TARGET%"

rem Copy plain files (suppress error messages if source missing; show a warning)
for %%F in (mise.toml selene.toml wally.toml default.project.json) do (
  if exist "%SCRIPT_DIR%%%F" (
    copy /Y "%SCRIPT_DIR%%%F" "%TARGET%\%%F" >nul
    echo Copied %%F
  ) else (
    echo WARNING: "%SCRIPT_DIR%%%F" not found.
  )
)

rem Copy utils directory (use robocopy if available; fallback to xcopy)
if exist "%SCRIPT_DIR%utils\" (
  echo Copying utils folder...
  robocopy "%SCRIPT_DIR%utils" "%TARGET%\utils" /E /NFL /NDL /NJH /NJS >nul 2>&1
  if errorlevel 1 (
    xcopy "%SCRIPT_DIR%utils" "%TARGET%\utils\" /E /I /Y >nul 2>&1
  )
  echo utils copied
) else (
  echo WARNING: "%SCRIPT_DIR%utils" folder not found.
)

rem Create additional folders requested by the user inside the project
echo Creating additional project folders...

rem Ensure parent src directories exist
mkdir "%TARGET%\src" 2>nul
mkdir "%TARGET%\src\ReplicatedStorage" 2>nul
mkdir "%TARGET%\src\ServerStorage" 2>nul

rem ReplicatedStorage subfolders
mkdir "%TARGET%\src\ReplicatedStorage\Controllers" 2>nul
if errorlevel 1 echo WARNING: Could not create "%TARGET%\src\ReplicatedStorage\Controllers"

mkdir "%TARGET%\src\ReplicatedStorage\Packages" 2>nul
if errorlevel 1 echo WARNING: Could not create "%TARGET%\src\ReplicatedStorage\Packages"

mkdir "%TARGET%\src\ReplicatedStorage\Resources" 2>nul
if errorlevel 1 echo WARNING: Could not create "%TARGET%\src\ReplicatedStorage\Resources"

rem New subfolders inside ReplicatedStorage\Resources
mkdir "%TARGET%\src\ReplicatedStorage\Resources\Shared" 2>nul
if errorlevel 1 echo WARNING: Could not create "%TARGET%\src\ReplicatedStorage\Resources\Shared"

mkdir "%TARGET%\src\ReplicatedStorage\Resources\Client" 2>nul
if errorlevel 1 echo WARNING: Could not create "%TARGET%\src\ReplicatedStorage\Resources\Client"

mkdir "%TARGET%\src\ReplicatedStorage\Settings" 2>nul
if errorlevel 1 echo WARNING: Could not create "%TARGET%\src\ReplicatedStorage\Settings"

rem ServerStorage subfolders
mkdir "%TARGET%\src\ServerStorage\Resources" 2>nul
if errorlevel 1 echo WARNING: Could not create "%TARGET%\src\ServerStorage\Resources"

mkdir "%TARGET%\src\ServerStorage\Services" 2>nul
if errorlevel 1 echo WARNING: Could not create "%TARGET%\src\ServerStorage\Services"

echo Additional folders created (or warnings shown if creation failed).

echo Creating symlinks...

call :create_dir_link "%TARGET%\src\ReplicatedStorage\MangoClient"  "%SCRIPT_DIR%src\ReplicatedStorage\MangoClient"
call :create_dir_link "%TARGET%\src\ReplicatedStorage\MangoResources" "%SCRIPT_DIR%src\ReplicatedStorage\MangoResources"
call :create_dir_link "%TARGET%\src\ReplicatedStorage\MangoControllers" "%SCRIPT_DIR%src\ReplicatedStorage\MangoControllers"
call :create_dir_link "%TARGET%\src\ServerStorage\MangoServer" "%SCRIPT_DIR%src\ServerStorage\MangoServer"
call :create_dir_link "%TARGET%\src\ServerStorage\MangoServices" "%SCRIPT_DIR%src\ServerStorage\MangoServices"
call :create_dir_link "%TARGET%\src\ServerStorage\MangoResources" "%SCRIPT_DIR%src\ServerStorage\MangoResources"

call :create_file_link "%TARGET%\src\ServerScriptService\MangoServerRuntime.server.luau" "%SCRIPT_DIR%src\ServerScriptService\MangoServerRuntime.server.luau"
call :create_file_link "%TARGET%\src\StarterPlayer\StarterPlayerScripts\MangoClientRuntime.client.luau" "%SCRIPT_DIR%src\StarterPlayer\StarterPlayerScripts\MangoClientRuntime.client.luau"

echo.
echo Finished. Review any WARNING lines above if some sources were missing.
echo Note: mklink may require Administrator privileges or Developer Mode enabled on Windows.

goto :finish

rem ============================================================
rem Subroutines
rem ============================================================

:create_dir_link
rem %1 = link full path, %2 = target full path
set "LINK=%~1"
set "TARGET_PATH=%~2"

for %%I in ("%LINK%") do set "LINK_PARENT=%%~dpI"
if not exist "%LINK_PARENT%" mkdir "%LINK_PARENT%" 2>nul

if exist "%LINK%" (
  rmdir "%LINK%" /S /Q 2>nul
  if exist "%LINK%" del "%LINK%" /F /Q 2>nul
)

if not exist "%TARGET_PATH%" (
  echo WARNING: target "%TARGET_PATH%" does not exist. Creating link anyway.
)

echo Creating directory symlink:
echo   Link: "%LINK%"
echo   Target: "%TARGET_PATH%"
mklink /D "%LINK%" "%TARGET_PATH%" >nul 2>&1
if errorlevel 1 (
  echo FAILED to create directory symlink "%LINK%". You may need to run this script as Administrator or enable Developer Mode.
) else (
  echo OK
)
exit /b

:create_file_link
rem %1 = link full path, %2 = target full path
set "LINK=%~1"
set "TARGET_PATH=%~2"

for %%I in ("%LINK%") do set "LINK_PARENT=%%~dpI"
if not exist "%LINK_PARENT%" mkdir "%LINK_PARENT%" 2>nul

if exist "%LINK%" (
  del "%LINK%" /F /Q 2>nul
)

if not exist "%TARGET_PATH%" (
  echo WARNING: target file "%TARGET_PATH%" does not exist. Creating link will still be attempted.
)

echo Creating file symlink:
echo   Link: "%LINK%"
echo   Target: "%TARGET_PATH%"
mklink "%LINK%" "%TARGET_PATH%" >nul 2>&1
if errorlevel 1 (
  echo FAILED to create file symlink "%LINK%". You may need to run this script as Administrator or enable Developer Mode.
) else (
  echo OK
)
exit /b

:finish
echo.
echo ===== Script finished =====
echo Press any key to exit...
pause >nul
endlocal
exit /b 0