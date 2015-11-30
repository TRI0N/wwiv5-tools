@ECHO OFF

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "%1", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------

:SWITCHES
IF [%1] EQU [] GOTO START
IF [%1] EQU [?] GOTO USAGE
IF [%1] EQU [-?] GOTO USAGE
IF [%1] EQU [/?] GOTO USAGE

:START 
set olddir=%CD%
CLS
ECHO.
ECHO *** MAKE SURE WWIV, BINKP.CMD AND TELNET SERVER ARE CLOSED BEFORE PROCEEDING ***
ECHO.
PAUSE
GOTO CHECKAPPS

:CHECKAPPS
REM CHECK FOR REQUIRED APPS
CLS

:WGET64
IF EXIST "%PROGRAMFILES(x86)%\GnuWin32\bin\wget.exe" (GOTO CHECK7Z) ELSE (GOTO WGET32)

:WGET32
IF EXIST "%PROGRAMFILES%\GnuWin32\bin\wget.exe" (
GOTO CHECK7Z
) ELSE (
ECHO THIS PROGRAM REQUIRES WGET
ECHO http://gnuwin32.sourceforge.net/packages/wget.htm
ECHO.
GOTO DONE
)

:CHECK7Z
IF EXIST "%PROGRAMFILES%\7-Zip\7z.exe" (
GOTO CHECKOS
) ELSE (
ECHO THIS PROGRAM REQUIRES Z-Zip
ECHO http://www.7-zip.org/download.html
ECHO.
GOTO DONE
)

:CHECKOS
REM Check 64bit or 32bit OS
IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT) ELSE (GOTO 32BIT)

:64BIT
SET WGETPATH%PROGRAMFILES(x86)%
SET NOT32=1
ECHO.
ECHO WARNING ONLY WWIV Will Be Updated - WWIVNET is Not Supported on 64bit OS.
PAUSE
GOTO BACKUP

:32BIT
SET WGETPATH=%PROGRAMFILES%
GOTO BACKUP

:BACKUP
REM CREATE UNIQUE FILE NAME FOR BACKUP
SET local 
SET year=%DATE:~-4,4% 
SET month=%DATE:~-7,2% 
SET day=%DATE:~-10,2% 
SET hour=%TIME:~0,2% 
REM REMOVE HOUR LEADING ZEROS 
IF '%hour:~0,1%' EQU ' ' set hour=0%hour:~1,1% 
SET minute=%time:~3,2% 
SET seconds=%time:~6,2% 
SET timestamp=%year%%month%%day%%hour%%minute%%seconds%
REM TRIM OUT SPACES
SET timestamp=%timestamp: =%

REM BACKUP WWIV
set BACKUP_FILE=%USERPROFILE%\documents\%timestamp%_wwiv-backup.zip
cd "%PROGRAMFILES%\7-Zip\"
7z.exe a -r -y %BACKUP_FILE% C:\wwiv\*.*

:WWIVUPDATE
REM CREATE PATCH FOLDER
IF EXIST %USERPROFILE%\documents\wwiv-patch (
CD %USERPROFILE%\documents\wwiv-patch
) ELSE (
CD %USERPROFILE%\documents
MD wwiv-patch
CD wwiv-patch
)
GOTO WWIV

:WWIV
REM FETCH LATEST BUILD AND PAtCH WWIV
"%WGETPATH%"\GnuWin32\bin\wget.exe -r -np -nd --accept zip,ZIP --reject=htm,html,php,asp,txt,md --timestamping -e robots=off http://build.wwivbbs.org/job/wwiv/lastSuccessfulBuild/label=windows/artifact/
DEL /Q archive.zip
DIR /B wwiv-build-win*.zip > dir_file1.txt
FOR /f "tokens=* delims= " %%a IN (dir_file1.txt) DO (
SET FILENAME1=%%a
)
TIMEOUT /T 2
"%PROGRAMFILES%\7-Zip\7z.exe" e -oc:\wwiv -y %FILENAME1% *.exe
TIMEOUT /T 2
"%PROGRAMFILES%\7-Zip\7z.exe" e -oc:\wwiv -y %FILENAME1% *.dll
TIMEOUT /T 2
"%PROGRAMFILES%\7-Zip\7z.exe" e -o%SYSTEMROOT%\system32 -y %FILENAME1% *.dll
GOTO WWIVNET

:WWIVNET
REM FETCH LATEST BUILD AND PATCH WWIVNET
IF [%NOT32%] EQU [1] (
GOTO CLEANUP
) ELSE (
"%WGETPATH%"\GnuWin32\bin\wget.exe -r -np -nd --accept zip,ZIP --reject=htm,html,php,asp,txt,md --timestamping -e robots=off http://build.wwivbbs.org/job/wwivnet/lastSuccessfulBuild/label=windows/artifact/
DEL /Q archive.zip
DIR /B wwivnet-*.zip > dir_file2.txt
FOR /f "tokens=* delims= " %%a IN (dir_file2.txt) DO (
SET FILENAME2=%%a
)
TIMEOUT /T 2
"%PROGRAMFILES%\7-Zip\7z.exe" e -oc:\wwiv\nets\wwivnet -y %FILENAME2% *.*
GOTO NET38

:NET38
REM FETCH LATEST BUILD AND PATCH NET38
"%WGETPATH%"\GnuWin32\bin\wget.exe --no-check-certificate https://storage.googleapis.com/build-iv/net38/net38b6.zip
DIR /B net38*.zip > dir_file3.txt
FOR /f "tokens=* delims= " %%a IN (dir_file3.txt) DO (
SET FILENAME3=%%a
)
TIMEOUT /T 2
"%PROGRAMFILES%\7-Zip\7z.exe" e -oc:\wwiv -y %FILENAME3% *.exe
)
GOTO CLEANUP

:CLEANUP
DEL /Q *.zip
DEL /Q *.txt
GOTO RUNWWIV

:USAGE
CLS
ECHO How to Use WWIV 5.0 Patch
ECHO.
ECHO     SYNTAX: wwiv-patch.bat
ECHO.
ECHO     Paths and files names are based on your environment
ECHO     Requires WGET and 7-Zip. Links in the Comments.
ECHO.
ECHO     Backup will be placed here: 
ECHO         %USERPROFILE%\documents\timestamp_wwiv-backup.zip
ECHO.
GOTO DONE

:RUNWWIV
CLS
ECHO.
ECHO PLEASE CHOOSE AN OPTION
ECHO.
ECHO 1) Launch WWIV with WWIVNet
ECHO 2) Launch WWIV Only
ECHO 3) Launch Nothing and Exit
ECHO.
set /p run_wwiv="Select Option: "
ECHO.
IF [%run_wwiv%] EQU [1] GOTO LAUNCHWWIVNET IF NOT GOTO RUNWWIV
IF [%run_wwiv%] EQU [2] GOTO LAUNCHWWIV IF NOT GOTO RUNWWIV
IF [%run_wwiv%] EQU [3] GOTO CHANGES IF NOT GOTO RUNWWIV

:LAUNCHWWIVNET
CD \wwiv
START /MIN C:\wwiv\WWIV5TelnetServer.exe
TIMEOUT /T 2
START C:\wwiv\bbs.exe -N1 -M
TIMEOUT /T 2
START /MIN C:\wwiv\binkp.cmd
GOTO CHANGES

:LAUNCHWWIV
CD \wwiv
START /MIN C:\wwiv\WWIV5TelnetServer.exe
TIMEOUT /T 2
C:\wwiv\bbs.exe -N1 -M
GOTO CHANGES

:CHANGES
START http://build.wwivbbs.org/job/wwiv/lastSuccessfulBuild/label=windows/changes
TIMEOUT /T 5
IF [%NOT32%] NEQ [1] (START http://build.wwivbbs.org/job/wwivnet/lastSuccessfulBuild/label=windows/changes)
GOTO DONE

:DONE
CD "%olddir%"
ECHO.
ECHO.
ECHO PATCH COMPLETE!
EXIT /B