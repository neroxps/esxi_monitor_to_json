@echo off

REM -------------------------------------------------------------------------------------------------------------------
REM
REM    tgz2vib5.cmd
REM
REM    Version
REM       2.3
REM
REM    Author:
REM       Andreas Peetz (ESXi-CPT@v-front.de)
REM
REM    Purpose:
REM       A script that automates the process of creating a VIB (VMware Installation Bundle) version 5 file
REM       from a oem.tgz-style ESXi 5.x/6.x driver or software package
REM
REM    Instructions, requirements and support:
REM       Please see http://ESXi-CPT.v-front.de
REM
REM    Licensing:
REM       tgz2vib5.cmd is licensed under the GNU GPL version 3
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
call :setup_screen
call :logCons This is %SCRIPTNAME% v%SCRIPTVERSION% ...
call :logCons Getting parameters ...
"%GETPARAMS%" "%PARAMSFILE%"
if not "%ERRORLEVEL%"=="0" call :logCons Script canceled. & exit /b 1

call :read_params

echo off

call :init_dynamic_env
call :reCreateLogFile || exit /b 1

call :logCons --- INFO: Logging verbose output to "%LOGFILE%" ...
call :logFile This is %SCRIPTNAME% v%SCRIPTVERSION% ...
call :logFile Called with parameters:
call :logFile ... inputType          = "%inputType%"
call :logFile ... fOEM               = "%fOEM%"
call :logFile ... fOEMDir            = "%fOEMDir%"
call :logFile ... wDir               = "%wDir%"
call :logFile ... vibType            = "%vibType%"
call :logFile ... repackOpt          = "%repackOpt%"
call :logFile ... useChecksums       = "%useChecksums%"
call :logFile ... dxEdit             = "%dxEdit%"
call :logFile ... updateCheck        = "%updateCheck%"
call :logFile ... vibName            = "%vibName%"
call :logFile ... vibVersion         = "%vibVersion%"
call :logFile ... vibVendor          = "%vibVendor%"
call :logFile ... vibSummary         = "%vibSummary%"
call :logFile ... vibDescription     = "%vibDescription%"
call :logFile ... vibKBURL           = "%vibKBURL%"
call :logFile ... vibDependencies    = "%vibDependencies%"
call :logFile ... vibSoftwareTags    = "%vibSoftwareTags%"
call :logFile ... acceptanceLevel    = "%acceptanceLevel%"
call :logFile ... maintModeReq       = "%maintModeReq%"
call :logFile ... cimonRestart       = "%cimonRestart%"
call :logFile ... liveInstallAllowed = "%liveInstallAllowed%"
call :logFile ... liveRemoveAllowed  = "%liveRemoveAllowed%"
call :logFile ... statelessReady     = "%statelessReady%"
call :logFile ... overlay            = "%overlay%"

call :log Re-creating the temp directory ...
call :reCreateTMPDIR || exit /b 1

if "%updateCheck%"=="1" call :doUpdateCheck || exit /b 1

call :log Creating the VIB directory ...
call :logRun mkdir "%VIBDIR%"
if not exist "%VIBDIR%" ( call :fatal Cannot create VIB directory '%VIBDIR%' & exit /b 1)

if "%inputType%"=="0" (
   call :log Creating the OEM directory ...
   call :logRun mkdir "%OEMDIR%"
   if not exist "%OEMDIR%" ( call :fatal Cannot create OEM directory '%OEMDIR%' & exit /b 1)
   call :log Copy oem.tgz to "%TMPDIR%" ...
   call :logRun copy /y "%fOEM%" "%TMPDIR%\oem.tgz"
   if not exist "%TMPDIR%\oem.tgz" ( call :fatal Error copying oem.tgz & exit /b 1)
   call :log Un-compressing the OEM.tgz file ...
   "%BUSYBOX%" gunzip -c "%TMPDIR%\oem.tgz" >"%TMPDIR%\oem.tar"
   if not exist "%TMPDIR%\oem.tar" ( call :fatal Error uncompressing oem.tgz & exit /b 1)
   pushd "%OEMDIR%"
   call :log Un-taring OEM.tar ...
   call :logRun "%BUSYBOX%" tar -xf "%TMPDIR%\oem.tar"
   if not "!RC!"=="0" ( call :fatal Error un-taring OEM.tar & exit /b 1)
) else (
   call :logFile inputType=1, OEMDIR will be set to %fOEMDir%, repackOpt to 1 ...
   set OEMDIR=%fOEMDir%
   set repackOpt=1
   pushd "!OEMDIR!"
)

call :check41oem || exit /b 1

if "!repackOpt!"=="2" call :handleAdvEdit || exit /b 1

call :log Creating OEM file list ...
"%BUSYBOX%" find * -type f >"%TMPDIR%\oemfiles.lst"

if "%inputType%"=="0" (
   call :logFile --- [DEBUG: Contents of the original TGZ file]
   "%BUSYBOX%" tar -tvf "%TMPDIR%\oem.tar" | "%BUSYBOX%" unix2dos -d >>"%LOGFILE%"
   call :logFile --- [End of file]
)

if "!repackOpt!" GTR "0" (
   if "%inputType%"=="0" (
      call :logFile Deleting old oem.tar ...
      call :logRun del /f /q "%TMPDIR%\oem.tar"
      if exist "%TMPDIR%\oem.tar" ( call :fatal Error deleting old OEM.tar & exit /b 1)
   )
   call :log Re-/creating OEM.tar ...
   call :logRun "%BUSYBOX%" tar -cf "%TMPDIR%\oem.tar" *
   if not "!RC!"=="0" ( call :fatal Error re-/creating OEM.tar & exit /b 1)
   call :logFile --- [DEBUG: Contents of the repacked/edited TGZ file]
   "%BUSYBOX%" tar -tvf "%TMPDIR%\oem.tar" | "%BUSYBOX%" unix2dos -d >>"%LOGFILE%"
   call :logFile --- [End of file]
)

if "%useChecksums%"=="1" (
   call :log Calculating OEM.tar's sha1 checksum ...
   "%BUSYBOX%" sha1sum "%TMPDIR%\oem.tar" >"%TMPDIR%\sha1sum.tmp"
   if not "%ERRORLEVEL%"=="0" ( call :fatal Error calculating OEM.tar's sha1 checksum & exit /b 1)
   for /F "tokens=1" %%c in ('type "%TMPDIR%\sha1sum.tmp"') do set vibPayloadfileChecksum1=%%c
)

if "!repackOpt!" GTR "0" (
   call :log Re-/compressing the OEM.tar file ...
   "%BUSYBOX%" gzip -c "%TMPDIR%\oem.tar" >"%TMPDIR%\oem.tgz"
)

popd

call :log Setting VIB release date to now ...
for /f %%d in ('"%BUSYBOX%" date -u +%%Y-%%m-%%dT%%H:%%M:%%S.000000+00:00') do set vibReleaseDate=%%d

set vibPayloadFileName=!vibName:~0,8!
call :log The VIB payload file will be named "!vibPayloadFileName!". Copying it now ...
call :logRun copy /y "%TMPDIR%\oem.tgz" "%VIBDIR%\!vibPayloadFileName!"
if not "!RC!"=="0" ( call :fatal Error copying OEM.TGZ file to VIB directory & exit /b 1)

for %%u in ("%VIBDIR%\!vibPayloadFileName!") do set vibPayloadFileSize=%%~zu
call :log Payload file size is %vibPayloadFileSize% ...

if "%useChecksums%" == "1" (
   call :log Calculating the payload file's sha-256 checksum ...
   "%BUSYBOX%" sha256sum "%VIBDIR%\!vibPayloadFileName!" >"%TMPDIR%\sha256sum.tmp"
   if not "%ERRORLEVEL%"=="0" ( call :fatal Error calculating sha256sum of payload file & exit /b 1)
   for /F "tokens=1" %%c in ('type "%TMPDIR%\sha256sum.tmp"') do set vibPayloadfileChecksum=%%c
)

call :log Creating the VIB descriptor.xml ...

if "%maintModeReq%" == "1" (set _mm=true) else (set _mm=false)
if "%cimonRestart%" == "1" (set _cr=true) else (set _cr=false)
if "%liveInstallAllowed%" == "1" (set _li=true) else (set _li=false)
if "%liveRemoveAllowed%" == "1" (set _lr=true) else (set _lr=false)
if "%statelessReady%" == "1" (set _sr=true) else (set _sr=false)
if "%overlay%" == "1" (set _ov=true) else (set _ov=false)

"%BUSYBOX%" echo -n "<vib version=\"5.0\"><type>%vibType%</type>">"%VIBDIR%\descriptor.xml"
"%BUSYBOX%" echo -n "<name>%vibName%</name>">>"%VIBDIR%\descriptor.xml"
"%BUSYBOX%" echo -n "<version>%vibVersion%</version>">>"%VIBDIR%\descriptor.xml"
"%BUSYBOX%" echo -n "<vendor>%vibVendor%</vendor>">>"%VIBDIR%\descriptor.xml"
"%BUSYBOX%" echo -n "<summary>%vibSummary%</summary>">>"%VIBDIR%\descriptor.xml"
"%BUSYBOX%" echo -n "<description>%vibDescription%</description>">>"%VIBDIR%\descriptor.xml"
"%BUSYBOX%" echo -n "<release-date>%vibReleaseDate%</release-date>">>"%VIBDIR%\descriptor.xml"

if "%vibKBURL%"=="" (
	"%BUSYBOX%" echo -n "<urls/>">>"%VIBDIR%\descriptor.xml"
) else (
	"%BUSYBOX%" echo -n "<urls><url key=\"kb\">%vibKBURL%</url></urls>">>"%VIBDIR%\descriptor.xml"
)

"%BUSYBOX%" echo -n "<relationships><depends>">>"%VIBDIR%\descriptor.xml"
for %%c in (%vibDependencies%) do (
   "%BUSYBOX%" echo -n "<constraint name=\"%%c\"/>">>"%VIBDIR%\descriptor.xml"
)
"%BUSYBOX%" echo -n "</depends><conflicts/><replaces/><provides/><compatibleWith/></relationships><software-tags>">>"%VIBDIR%\descriptor.xml"
for %%t in (%vibSoftwareTags%) do (
   "%BUSYBOX%" echo -n "<tag>%%t</tag>">>"%VIBDIR%\descriptor.xml"
)
"%BUSYBOX%" echo -n "</software-tags><system-requires><maintenance-mode>%_mm%</maintenance-mode></system-requires><file-list>">>"%VIBDIR%\descriptor.xml"
for /f %%f in ('type "%TMPDIR%\oemfiles.lst"') do "%BUSYBOX%" echo -n "<file>%%f</file>">>"%VIBDIR%\descriptor.xml"
"%BUSYBOX%" echo -n "</file-list><acceptance-level>%acceptanceLevel%</acceptance-level><live-install-allowed>%_li%</live-install-allowed><live-remove-allowed>%_lr%</live-remove-allowed><cimom-restart>%_cr%</cimom-restart><stateless-ready>%_sr%</stateless-ready><overlay>%_ov%</overlay>">>"%VIBDIR%\descriptor.xml"
"%BUSYBOX%" echo -n "<payloads><payload name=\"%vibPayloadFileName%\" type=\"tgz\" size=\"%vibPayloadFileSize%\">">>"%VIBDIR%\descriptor.xml"
if "%useChecksums%" == "1" (
   "%BUSYBOX%" echo -n "<checksum checksum-type=\"sha-256\">%vibPayloadfileChecksum%</checksum>">>"%VIBDIR%\descriptor.xml"
   "%BUSYBOX%" echo -n "<checksum checksum-type=\"sha-1\" verify-process=\"gunzip\">%vibPayloadfileChecksum1%</checksum>">>"%VIBDIR%\descriptor.xml"
)
"%BUSYBOX%" echo -n "</payload></payloads>">>"%VIBDIR%\descriptor.xml"
"%BUSYBOX%" echo -n "<^!-- This package was created with %SCRIPTNAME% v%SCRIPTVERSION% (%SCRIPTURL%) --></vib>">>"%VIBDIR%\descriptor.xml"

call :log Creating an empty signature file ...
call :logRun "%BUSYBOX%" touch "%VIBDIR%\sig.pkcs7"
if not "!RC!"=="0" ( call :fatal Error creating the signature file & exit /b 1)

if "%dxEdit%"=="1" call :handleDxEdit || exit /b 1

call :log Creating the VIB archive now ...
set vibArchive=!wDir!\!vibName!-!vibVersion!.x86_64.vib
if not exist "!vibArchive!" goto :newvib
call :logWarning VIB-file already exists, will be overwritten ...
call :logRun del /f /q "!vibArchive!"
if exist "!vibArchive!" call :earlyFatal Cannot delete old VIB file '!vibArchive!' & exit /b 1
:newvib
pushd "%VIBDIR%"
call :logRun "%AR%" qDv "!vibArchive!" descriptor.xml sig.pkcs7 "!vibPayloadFileName!"
call :logCRLF
popd
if not "!RC!"=="0" ( call :fatal Error creating the VIB archive & exit /b 1)

call :logFile ------------------------------------------------------------------------------------
call :logFile --- INFO: All done - the VIB file was created as
call :logFile ---       !vibArchive!
call :logFile ------------------------------------------------------------------------------------
call :logRun "%MSGBOX%" 266304 "All done - the VIB file was created as&n   '!vibArchive!'."

goto :cleanup

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
   set TOOLS=%~dp0tools
   set AR=%TOOLS%\cygwin\ar.exe
   set BUSYBOX=%TOOLS%\busybox.exe
   set MSGBOX=%TOOLS%\MsgBox.exe
   set EXPLORER=%SystemRoot%\explorer.exe
   set NOTEPAD=%SystemRoot%\notepad.exe
   set CYGWIN=nodosfilewarning
   set SCRIPTNAME=TGZ2VIB5
   set SCRIPTVERSION=2.3
   set SCRIPTURL=http://ESXi-CPT.v-front.de
   set GETPARAMS=%TOOLS%\%SCRIPTNAME%-GetParams.exe
   set PARAMSFILE=%TEMP%\%SCRIPTNAME%-Params.cmd
   set ESXI50FAQ_URL=http://www.v-front.de/2011/08/how-esxi-customizer-supports-esxi-50.html
   set updateCheckURL=http://vibsdepot.v-front.de/tools/%SCRIPTNAME%-CurrentVersion.cmd
goto :eof

:read_params
   call "%PARAMSFILE%"
   if "%wDIR:~-1%"=="\" set wDir=%wDIR:~0,-1%
goto :eof

:init_dynamic_env
   set LOGFILE=!wDIR!\%SCRIPTNAME%.log
   set TMPDIR=!wDIR!\%SCRIPTNAME%.tmp
   set OEMDIR=!TMPDIR!\oem
   set VIBDIR=!TMPDIR!\vib
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
      call :log The temp-directory "%TMPDIR%" already exists. Removing it ...
      call :logRun rmdir /s /q "%TMPDIR%"
      if exist "%TMPDIR%" ( call :fatal Cannot remove existing temp-directory '%TMPDIR%' & exit /b 1)
   )
   call :log Creating the temp-directory "%TMPDIR%" ...
   call :logRun mkdir "%TMPDIR%"
   if not exist "%TMPDIR%" ( call :fatal Cannot create temp-directory '%TMPDIR%' & exit /b 1)
goto :eof

:handleAdvEdit
   call :log Advanced editing enabled.
   call :log --- INFO: Pausing to allow manual editing of TGZ content files ...
   call :logFile --- --- The OEM.tgz content files are at:       [%OEMDIR%]
   call :logFile --- Launching explorer.exe ...
   "%EXPLORER%" "%OEMDIR%"
   call :logRun "%MSGBOX%" 266304 "Pausing script to allow manual editing of files:&n&n--- The OEM.tgz content files are at: [%OEMDIR%]&n&nWhen editing text files use an editor that preserves UNIX line feeds, like Notepad++. Press OK when you have finished editing."
   call :logFile Finished advanced edit mode.
goto :eof

:handleDxEdit
   call :log Editing of descriptor.xml enabled.
   call :log --- INFO: Pausing to allow manual editing of descriptor.xml ...
   call :logFile --- --- The descriptor.xml file is here: [%VIBDIR%]
   call :logFile --- Launching explorer.exe ...
   "%EXPLORER%" "%VIBDIR%"
   call :logRun "%MSGBOX%" 266304 "Pausing script to allow manual editing of descriptor.xml:&n&n--- The descriptor.xml file is here: [%VIBDIR%]&n&nWhen editing the file use an editor that preserves UNIX line feeds, like Notepad++. Press OK when you have finished editing."
   call :logFile Finished dxEdit mode.
goto :eof

:check41oem
   if not exist "!OEMDIR!\etc\vmware\simple.map" goto :eof
   call :logFile --- WARNING: It looks like you are using an OEM.tgz driver file that was made for ESXi 4.x to create.
   call :logFile ---          a VIB file for ESXi 5.x.
   call :logFile ---          Please note that this is useless because ESXi 5.x cannot use drivers made for ESXi 4.x.
   call :logFile ---          Press 'Yes' to continue anyway or 'No' to cancel now and browse to a page
   call :logFile ---          with more information.
   call :logRun "%MSGBOX%" 266548 "Caution:&n&nIt looks like you are using an OEM.tgz driver file that was made for ESXi 4.x to create a VIB file for ESXi 5.x. Please note that this is useless because ESXi 5.x cannot use drivers made for ESXi 4.x.&n&nPress 'Yes' to continue anyway or 'No' to cancel now and browse to a page with more information.&n"
   if "!RC!"=="0" (
      call :logFile Cancel script and go to '%ESXI50FAQ_URL%' ...
      start "" "%ESXI50FAQ_URL%"
      goto :cleanup
   ) else (
      call :logFile Anyway continuing the script ...
   )
goto :eof

:doUpdateCheck
   call :log Checking for updated version of this script ...
   call :logRun "%BUSYBOX%" wget --header "Pragma: no-cache" "%updateCheckURL%" -O "%TMPDIR%\CurrentVersion.cmd"
   call :logCRLF
   if exist "%TMPDIR%\CurrentVersion.cmd" (
      call :logFile [Debug] Contents of CurrentVersion.cmd:
      type "%TMPDIR%\CurrentVersion.cmd" >>"%LOGFILE%"
      call :logCRLF
      call :logFile [Debug] End of File
      call "%TMPDIR%\CurrentVersion.cmd"
      if "!SCRIPTVERSION!" LSS "!CurrentVersion!" (
         call :logFile --- INFO: A newer version !CurrentVersion! of %SCRIPTNAME% is available.
         call :logFile ---       Do you want to update now?
         call :logRun "%MSGBOX%" 266276 "A newer version !CurrentVersion! of %SCRIPTNAME% is available.&nDo you want to cancel the script now and visit &n   %SCRIPTURL%&nto update the ESXi Community Packaging Tools?"
         if "!RC!"=="0" (
            call :logFile Do not update now. Continuing the script ...
         ) else (
            call :logFile Cancel script and go to '%SCRIPTURL%' ...
            start "" "%SCRIPTURL%"
            goto :cleanup
         )
      ) else (
         call :log --- INFO: There is no newer version available.
      )
   ) else (
      call :logWarning UpdateCheck failed, check your internet connection.
      call :logRun "%MSGBOX%" 266288 "UpdateCheck failed. Please check your internet connection.&nPress OK to continue." 5
   )
   title %SCRIPTNAME% v%SCRIPTVERSION% - %SCRIPTURL%
goto :eof

REM ===== entry points for script exits ======

:earlyFatal
   setlocal disabledelayedexpansion
   call :logCons !-----------------------------------------------------------------------------------
   call :logCons !-- FATAL ERROR: %*!
   call :logCons !-----------------------------------------------------------------------------------
   "%MSGBOX%" 266256 "FATAL ERROR:&n   %*!"
exit /b 1

:fatal
   setlocal disabledelayedexpansion
   call :logFile !-----------------------------------------------------------------------------------
   call :logFile !-- FATAL ERROR: %*!
   call :logFile !-----------------------------------------------------------------------------------
   call :logRun "%MSGBOX%" 266260 "FATAL ERROR:&n   %*!&n&nSee log file '%LOGFILE%' for details! Do you want to open the log file in notepad now?"
   setlocal enabledelayedexpansion
   set OPENLOG=!RC!

:cleanup
   call :log Cleaning up ...
   del /f /q "%PARAMSFILE%" >nul: 2>&1
   call :logRun rmdir /s /q "%TMPDIR%"
   if exist "%TMPDIR%" (
      call :logWarning Could not delete "%TMPDIR%".
      call :log Please check and clean up manually.
   )
   call :logCons Good bye ...
   call :logFile This is the end.
   if "%OPENLOG%"=="1" start "" "%NOTEPAD%" "%LOGFILE%"
exit /b 1
