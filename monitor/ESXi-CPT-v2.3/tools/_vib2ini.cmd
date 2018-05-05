@echo off

REM -------------------------------------------------------------------------------------------------------------------
REM
REM    _vib2ini.cmd
REM
REM    Version
REM       1.0
REM
REM    Author:
REM       Andreas Peetz (ESXi-CPT@v-front.de)
REM
REM    Purpose:
REM       Auxilliary script to extract metadata from a VIB file and store it to
REM       a VIB2ZIP compatible INI-file.
REM       Part of the ESXi Community Packaging Tools - for internal use only -
REM
REM    Parameters:
REM       %1 = directory to look for VIB file
REM       %2 = INI-file to write
REM
REM    Licensing:
REM       _vib2ini.cmd is licensed under the GNU GPL version 3
REM       (see the included file COPYING.txt).
REM       For licensing of the included tools see tools\README.txt!
REM
REM    Disclaimer:
REM       The author of this script expressly disclaims any warranty for it. The script and any related documentation
REM       is provided "as is" without warranty of any kind, either express or implied, including, without limitation,
REM       the implied warranties or merchantability, fitness for a particular purpose, or non-infringement. The entire
REM       risk arising out of use or performance of the script remains with you.
REM       In no event shall the author of this Software be liable for any damages whatsoever (including, without
REM       limitation, damages for loss of business profits, business interruption, loss of business information, or
REM       any other pecuniary loss) arising out of the use of or inability to use this product, even if the author of
REM       this script has been advised of the possibility of such damages.
REM
REM -------------------------------------------------------------------------------------------------------------------

setlocal enabledelayedexpansion

call :init_constants
call :init_dynamic_env
call :setup_screen

call :logCons This is %SCRIPTNAME% v%SCRIPTVERSION% ...
call :logCons --- INFO: Logging verbose output to "%LOGFILE%" ...

call :reCreateLogFile || exit /b 1
call :logFile This is %SCRIPTNAME% v%SCRIPTVERSION% ...
call :logFile Called with parameters:
call :logFile ... p1 = %1
call :logFile ... p2 = %2

call :logFile Re-creating the temp directory ...
call :reCreateTMPDIR || exit /b 1

set iniFile=%2
REM Passed directory name MUST be already enclosed in quotes!
pushd %1
set vibFile=null
( for /f %%v in ('dir /b /od *.vib') do set vibFile=%%v ) 2>nul:
if "!vibFile!"=="null" (
  call :logRun "%MSGBOX%" 266256 "No VIB files found in directory!" 2
  call :fatal "No VIB files found here."
  exit /b 1
)

call :logFile Dealing with VIB file "!vibFile!" ...

call :logFile Unpacking VIB descriptor.xml file ...
call :logRun "%SEVENZIP%" x -y -o"%TMPDIR%" "!vibFile!" descriptor.xml
if not "!RC!"=="0" ( call :fatal Error unpacking the VIB descriptor.xml file & exit /b 1)

if not exist "%TMPDIR%\descriptor.xml" ( call :fatal Corrupt VIB file. Descriptor.xml not found & exit /b 1)
call :logFile Parsing "%TMPDIR%\descriptor.xml" ...
call :ParseVibXML "%TMPDIR%\descriptor.xml" ob "%TMPDIR%\parsevib.tmp.cmd"

call :logFile Writing INI file %iniFile% ...
echo [Settings]>%iniFile%
echo obName=%obName%>>%iniFile%
echo obVersion=%obVersion%>>%iniFile%
echo obVendor=%obVendor%>>%iniFile%
echo obDescription=%obDescription%>>%iniFile%
echo obKBURL=%obKBURL%>>%iniFile%

popd

call :logRun "%MSGBOX%" 266304 "Loading metadata from !vibFile!..." 2
call :cleanup & exit /b 0

REM ============= sub routines for logging ==================

:logCons
   echo [%DATE% %TIME%] %*
goto :eof

:logFile
   echo [%DATE% %TIME%] %* >>"%LOGFILE%"
goto :eof

:log
   echo [%DATE% %TIME%] %*
   echo [%DATE% %TIME%] %* >>"%LOGFILE%"
goto :eof

:logWarning
   echo [%DATE% %TIME%] --- WARNING: %*
   echo [%DATE% %TIME%] --- WARNING: %* >>"%LOGFILE%"
goto :eof

:logRun
   set RC=0
   echo [%DATE% %TIME%] Run: %* >>"%LOGFILE%"
   %* >>"%LOGFILE%" 2>&1 || set RC=1
goto :eof

:logCRLF
   echo. >>"%LOGFILE%"
goto :eof

REM === sub routines for environment handling ====

:init_constants
   set TOOLS=%~dp0
   set SEVENZIP=%TOOLS%7zip\7z.exe
   set BUSYBOX=%TOOLS%busybox.exe
   set SED=%TOOLS%unxutils\sed.exe
   set MSGBOX=%TOOLS%MsgBox.exe
   set CYGWIN=nodosfilewarning
   set SCRIPTNAME=_VIB2INI
   set SCRIPTVERSION=1.0
   set SCRIPTURL=http://ESXi-CPT.v-front.de
goto :eof

:init_dynamic_env
   set LOGFILE=%TEMP%\%SCRIPTNAME%.log
   set TMPDIR=%TEMP%\%SCRIPTNAME%.tmp
goto :eof

REM ===== common sub-routines ======

:setup_screen
   mode 120,50
   title %SCRIPTNAME% v%SCRIPTVERSION% - %SCRIPTURL%
goto :eof

:reCreateLogFile
   if exist "%LOGFILE%" (
      del /f /q "%LOGFILE%" >nul: 2>&1
      if exist "%LOGFILE%" call :earlyFatal Cannot delete old log file '%LOGFILE%' & exit /b 1
   )
   ( echo. >"%LOGFILE%" ) 2>nul:
   if not exist "%LOGFILE%" call :earlyFatal Cannot create log file '%LOGFILE%' & exit /b 1
goto :eof

:reCreateTMPDIR
   if exist "%TMPDIR%" (
      call :logFile The temp-directory "%TMPDIR%" already exists. Removing it ...
      call :logRun rmdir /s /q "%TMPDIR%"
      if exist "%TMPDIR%" ( call :fatal Cannot remove existing temp-directory '%TMPDIR%' & exit /b 1)
   )
   call :logFile Creating the temp-directory "%TMPDIR%" ...
   call :logRun mkdir "%TMPDIR%"
   if not exist "%TMPDIR%" ( call :fatal Cannot create temp-directory '%TMPDIR%' & exit /b 1)
goto :eof

:ParseVibXML
   findstr /I /L "<name>" %1 | "%SED%" -e "s#.*<name>#set %2Name=#I;s#</name>.*##I" >>%3
   echo.>>%3
   findstr /I /L "<version>" %1 | "%SED%" -e "s#.*<version>#set %2Version=#I;s#</version>.*##I" >>%3
   echo.>>%3
   findstr /I /L "<vendor>" %1 | "%SED%" -e "s#.*<vendor>#set %2Vendor=#I;s#</vendor>.*##I" >>%3
   echo.>>%3
   findstr /I /L "<summary>" %1 | "%SED%" -e "s#.*<summary>#set %2Description=#I;s#</summary>.*##I" >>%3
   echo.>>%3
   findstr /I /C:"<url key=\"kb\">" %1 | "%SED%" -e "s#.*<url key=\"kb\">#set %2KBURL=#I;s#</url>.*##I" >>%3
   echo.>>%3
   type %3 >>"%LOGFILE%" 2>&1
   call %3
goto :eof

:earlyFatal
   setlocal disabledelayedexpansion
   call :logCons !-----------------------------------------------------------------------------------
   call :logCons !-- FATAL ERROR: %*!
   call :logCons !-----------------------------------------------------------------------------------
exit /b 1

:fatal
   setlocal disabledelayedexpansion
   call :logFile !-----------------------------------------------------------------------------------
   call :logFile !-- FATAL ERROR: %*!
   call :logFile !-----------------------------------------------------------------------------------
   setlocal enabledelayedexpansion

:cleanup
   call :log Cleaning up ...
   call :logRun rmdir /s /q "%TMPDIR%"
   if exist "%TMPDIR%" (
      call :logWarning Could not delete "%TMPDIR%".
      call :log Please check and clean up manually.
   )
   call :log Good bye ...
goto :eof
