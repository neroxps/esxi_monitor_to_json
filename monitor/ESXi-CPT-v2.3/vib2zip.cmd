@echo off

REM -------------------------------------------------------------------------------------------------------------------
REM
REM    vib2zip.cmd
REM
REM    Version
REM       1.3
REM
REM    Author:
REM       Andreas Peetz (ESXi-CPT@v-front.de)
REM
REM    Purpose:
REM       A script that automates the process of creating a VMware Offline Bundle ZIP file
REM       from one or multiple ESXi 5.x/6.x VIB packages
REM
REM    Instructions, requirements and support:
REM       Please see http://ESXi-CPT.v-front.de
REM
REM    Licensing:
REM       vib2zip.cmd is licensed under the GNU GPL version 3
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
call :init_dynamic_env
call :reCreateLogFile || exit /b 1

call :logCons --- INFO: Logging verbose output to "%LOGFILE%" ...
call :logFile This is %SCRIPTNAME% v%SCRIPTVERSION% ...
call :logFile Called with parameters:
call :logFile ... vibDir           = "%vibDir%"
call :logFile ... wDir             = "%wDir%"
call :logFile ... advEdit          = "%advEdit%"
call :logFile ... updateCheck      = "%updateCheck%"
call :logFile ... obName           = "%obName%"
call :logFile ... obVersion        = "%obVersion%"
call :logFile ... obVendor         = "%obVendor%"
call :logFile ... obVendorCode     = "%obVendorCode%"
call :logFile ... obDescription    = "%obDescription%"
call :logFile ... obKBURL          = "%obKBURL%"
call :logFile ... obContact        = "%obContact%"
call :logFile ... obESXiVer5x      = "%obESXiVer5x%"
call :logFile ... obESXiVer50      = "%obESXiVer50%"
call :logFile ... obESXiVer51      = "%obESXiVer51%"
call :logFile ... obESXiVer55      = "%obESXiVer55%"
call :logFile ... obESXiVer60      = "%obESXiVer60%"

set METADATAZIP=%obVendor%-%obName%-%obVersion%-metadata.zip

call :log Re-creating the temp directory ...
call :reCreateTMPDIR || exit /b 1

if "%updateCheck%"=="1" call :doUpdateCheck || exit /b 1

call :logFile Check if there are any VIB files to add ...
if not exist "%vibDir%\*.vib" ( call :fatal There are no VIB files in '%vibDir%' & exit /b 1)

call :logFile Check if an Offline bundle with the target name already exists ...
if exist "!wDir!\%obName%-%obVersion%-offline_bundle.zip" call :logWarning The Offline bundle file already exists and will be overwritten!

call :log Setting up the work area ...

call :logFile Creating the Bundle build directory ...
call :logRun mkdir "%BDLDIR%"
if not exist "%BDLDIR%" ( call :fatal Cannot create Bundle build directory '%BDLDIR%' & exit /b 1)

call :logFile Creating the metadata directory ...
call :logRun mkdir "%METADIR%"
if not exist "%METADIR%" ( call :fatal Cannot create metadata directory '%METADIR%' & exit /b 1)

call :logFile Creating the metadata\bulletins directory ...
call :logRun mkdir "%METADIR%\bulletins"
if not exist "%METADIR%" ( call :fatal Cannot create metadata\bulletins directory '%METADIR%\bulletins' & exit /b 1)

call :logFile Creating the metadata\vibs directory ...
call :logRun mkdir "%METADIR%\vibs"
if not exist "%METADIR%" ( call :fatal Cannot create metadata\vibs directory '%METADIR%\vibs' & exit /b 1)

call :logFile Creating index.xml file ...
( "%BUSYBOX%" echo "<vendorList>"
  "%BUSYBOX%" echo "  <vendor>"
  "%BUSYBOX%" echo "    <name>%obVendor%</name>"
  "%BUSYBOX%" echo "    <code>%obVendorCode%</code>"
  "%BUSYBOX%" echo "    <indexfile>vendor-index.xml</indexfile>"
  "%BUSYBOX%" echo "    <patchUrl></patchUrl>"
  "%BUSYBOX%" echo "    <relativePath></relativePath>"
  "%BUSYBOX%" echo "    <content>"
  "%BUSYBOX%" echo "      <name>VMware ESX</name>"
  "%BUSYBOX%" echo "      <type>http://www.vmware.com/depotmanagement/esx</type>"
  "%BUSYBOX%" echo "    </content>"
  "%BUSYBOX%" echo "  </vendor>"
  "%BUSYBOX%" echo "  <^!-- This package was created with %SCRIPTNAME% v%SCRIPTVERSION% (%SCRIPTURL%) -->"
  "%BUSYBOX%" echo "</vendorList>"
) >"%BDLDIR%\index.xml"

call :logFile Creating vendor-index.xml file ...
"%BUSYBOX%" echo "<metaList>">"%BDLDIR%\vendor-index.xml"
if "%obESXiVer5x%"=="1" (
   call :addMetadataRecord 5.* >>"%BDLDIR%\vendor-index.xml"
) else (
   if "%obESXiVer50%"=="1" call :addMetadataRecord 5.0.0 >>"%BDLDIR%\vendor-index.xml"
   if "%obESXiVer51%"=="1" call :addMetadataRecord 5.1.0 >>"%BDLDIR%\vendor-index.xml"
   if "%obESXiVer55%"=="1" call :addMetadataRecord 5.5.0 >>"%BDLDIR%\vendor-index.xml"
)
if "%obESXiVer60%"=="1" call :addMetadataRecord 6.0.0 >>"%BDLDIR%\vendor-index.xml"
"%BUSYBOX%" echo "</metaList>">>"%BDLDIR%\vendor-index.xml"

call :logFile Copying vendor-index.xml to metadata dir ...
call :logRun copy /y "%BDLDIR%\vendor-index.xml" "%METADIR%"
if not "!RC!"=="0" ( call :fatal Error copying vendor-index.xml to metadata dir & exit /b 1)

call :logFile Determine current date ...
for /f %%d in ('"%BUSYBOX%" date -u +%%Y-%%m-%%dT%%H:%%M:%%S.000000') do set obDate1=%%d
for /f %%d in ('"%BUSYBOX%" date -u +%%Y-%%m-%%dT%%H:%%M:%%S+00:00') do set obDate2=%%d

call :logFile Starting metadata\vmware.xml ...
( "%BUSYBOX%" echo "<metadataResponse>"
  "%BUSYBOX%" echo "  <version>3.0</version>"
  "%BUSYBOX%" echo "  <timestamp>%obDate1%</timestamp>"
  "%BUSYBOX%" echo "  <bulletin>"
  "%BUSYBOX%" echo "    <id>%obName%-%obVersion%</id>"
  "%BUSYBOX%" echo "    <vendor>%obVendor%</vendor>"
  "%BUSYBOX%" echo "    <summary>%obDescription%</summary>"
  "%BUSYBOX%" echo "    <severity>general</severity>"
  "%BUSYBOX%" echo "    <category>general</category>"
  "%BUSYBOX%" echo "    <urgency>general</urgency>"
  "%BUSYBOX%" echo "    <releaseType>extension</releaseType>"
  "%BUSYBOX%" echo "    <description>%obDescription%</description>"
  "%BUSYBOX%" echo "    <kbUrl>%obKBURL%</kbUrl>"
  "%BUSYBOX%" echo "    <contact>%obContact%</contact>"
  "%BUSYBOX%" echo "    <releaseDate>%obDate2%</releaseDate>"
  "%BUSYBOX%" echo "    <platforms>"
) >"%METADIR%\vmware.xml"
if "%obESXiVer5x%"=="1" (
   "%BUSYBOX%" echo "      <softwarePlatform locale=\"\" version=\"5.*\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\vmware.xml"
) else (
   if "%obESXiVer50%"=="1" "%BUSYBOX%" echo "      <softwarePlatform locale=\"\" version=\"5.0.0\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\vmware.xml"
   if "%obESXiVer51%"=="1" "%BUSYBOX%" echo "      <softwarePlatform locale=\"\" version=\"5.1.0\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\vmware.xml"
   if "%obESXiVer55%"=="1" "%BUSYBOX%" echo "      <softwarePlatform locale=\"\" version=\"5.5.0\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\vmware.xml"
)
if "%obESXiVer60%"=="1" "%BUSYBOX%" echo "      <softwarePlatform locale=\"\" version=\"6.0.0\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\vmware.xml"
"%BUSYBOX%" echo "    </platforms>">>"%METADIR%\vmware.xml"
"%BUSYBOX%" echo "    <vibList>">>"%METADIR%\vmware.xml"

call :logFile Starting metadata\bulletins\%obName%-%obVersion%.xml ...
( "%BUSYBOX%" echo -n "<bulletin>"
  "%BUSYBOX%" echo -n "<id>%obName%-%obVersion%</id>"
  "%BUSYBOX%" echo -n "<vendor>%obVendor%</vendor>"
  "%BUSYBOX%" echo -n "<summary>%obDescription%</summary>"
  "%BUSYBOX%" echo -n "<severity>general</severity>"
  "%BUSYBOX%" echo -n "<category>general</category>"
  "%BUSYBOX%" echo -n "<urgency>general</urgency>"
  "%BUSYBOX%" echo -n "<releaseType>extension</releaseType>"
  "%BUSYBOX%" echo -n "<description>%obDescription%</description>"
  "%BUSYBOX%" echo -n "<kbUrl>%obKBURL%</kbUrl>"
  "%BUSYBOX%" echo -n "<contact>%obContact%</contact>"
  "%BUSYBOX%" echo -n "<releaseDate>%obDate2%</releaseDate>"
  "%BUSYBOX%" echo -n "<platforms>"
) >"%METADIR%\bulletins\%obName%-%obVersion%.xml"
if "%obESXiVer5x%"=="1" (
   "%BUSYBOX%" echo -n "<softwarePlatform locale=\"\" version=\"5.*\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\bulletins\%obName%-%obVersion%.xml"
) else (
   if "%obESXiVer50%"=="1" "%BUSYBOX%" echo -n "<softwarePlatform locale=\"\" version=\"5.0.0\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\bulletins\%obName%-%obVersion%.xml"
   if "%obESXiVer51%"=="1" "%BUSYBOX%" echo -n "<softwarePlatform locale=\"\" version=\"5.1.0\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\bulletins\%obName%-%obVersion%.xml"
   if "%obESXiVer55%"=="1" "%BUSYBOX%" echo -n "<softwarePlatform locale=\"\" version=\"5.5.0\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\bulletins\%obName%-%obVersion%.xml"
)
if "%obESXiVer60%"=="1" "%BUSYBOX%" echo -n "<softwarePlatform locale=\"\" version=\"6.0.0\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\bulletins\%obName%-%obVersion%.xml"
"%BUSYBOX%" echo -n "</platforms><vibList>">>"%METADIR%\bulletins\%obName%-%obVersion%.xml"

call :logFile Enter add VIBs loop ...
for %%v in ("%vibDir%\*.vib") do ( call :add2zip %%v || exit /b 1 )

call :logFile Finishing metadata\bulletins\%obName%-%obVersion%.xml ...
"%BUSYBOX%" echo -n "</vibList></bulletin>" >>"%METADIR%\bulletins\%obName%-%obVersion%.xml"

call :logFile Finishing metadata\vmware.xml ...
( "%BUSYBOX%" echo "    </vibList>"
  "%BUSYBOX%" echo "  </bulletin>"
  "%BUSYBOX%" echo "</metadataResponse>"
) >>"%METADIR%\vmware.xml"

if "%advEdit%"=="1" call :handleAdvEdit || exit /b 1

call :log Creating %METADATAZIP% ...
pushd "%METADIR%"
call :logRun "%SEVENZIP%" a -tzip -r "%BDLDIR%\%METADATAZIP%" *.*
popd
if not "!RC!"=="0" ( call :fatal Error creating the metadata.zip file & exit /b 1)

call :log Creating the Offline bundle ZIP file ...
if exist "!wDir!\%obName%-%obVersion%-offline_bundle.zip" call :logRun del /f /q "!wDir!\%obName%-%obVersion%-offline_bundle.zip"
pushd "%BDLDIR%"
call :logRun "%SEVENZIP%" a -tzip "!wDir!\%obName%-%obVersion%-offline_bundle.zip" *.*
popd
if not "!RC!"=="0" ( call :fatal Error creating the Offline bundle ZIP file & exit /b 1)

call :logFile ------------------------------------------------------------------------------------
call :logFile --- INFO: All done - the Offline bundle was created as
call :logFile ---       !wDir!\%obName%-%obVersion%-offline_bundle.zip
call :logFile ------------------------------------------------------------------------------------
call :logRun "%MSGBOX%" 266304 "All done - the Offline bundle was created as&n   '!wDir!\%obName%-%obVersion%-offline_bundle.zip'."

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
   set SEVENZIP=%TOOLS%\7zip\7z.exe
   set BUSYBOX=%TOOLS%\busybox.exe
   set SED=%TOOLS%\unxutils\sed.exe
   set MSGBOX=%TOOLS%\MsgBox.exe
   set EXPLORER=%SystemRoot%\explorer.exe
   set NOTEPAD=%SystemRoot%\notepad.exe
   set CYGWIN=nodosfilewarning
   set SCRIPTNAME=VIB2ZIP
   set SCRIPTVERSION=1.3
   set SCRIPTURL=http://ESXi-CPT.v-front.de
   set GETPARAMS=%TOOLS%\%SCRIPTNAME%-GetParams.exe
   set PARAMSFILE=%TEMP%\%SCRIPTNAME%-Params.cmd
   set updateCheckURL=http://vibsdepot.v-front.de/tools/%SCRIPTNAME%-CurrentVersion.cmd
goto :eof

:read_params
   call "%PARAMSFILE%"
   if "%wDIR:~-1%"=="\" set wDir=%wDIR:~0,-1%
goto :eof

:init_dynamic_env
   set LOGFILE=!wDIR!\%SCRIPTNAME%.log
   set TMPDIR=!wDIR!\%SCRIPTNAME%.tmp
   set BDLDIR=!TMPDIR!\bundle
   set METADIR=!TMPDIR!\metadata
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
   findstr /I /L "<type>" %1 | "%SED%" -e "s#.*<type>#set %2Type=#I;s#</type>.*##I" >%3
   echo.>>%3
   findstr /I /L "<name>" %1 | "%SED%" -e "s#.*<name>#set %2Name=#I;s#</name>.*##I" >>%3
   echo.>>%3
   findstr /I /L "<version>" %1 | "%SED%" -e "s#.*<version>#set %2Version=#I;s#</version>.*##I" >>%3
   echo.>>%3
   findstr /I /L "<vendor>" %1 | "%SED%" -e "s#.*<vendor>#set %2Vendor=#I;s#</vendor>.*##I" >>%3
   echo.>>%3
   findstr /I /L "<summary>" %1 | "%SED%" -e "s#.*<summary>#set %2Summary=#I;s#</summary>.*##I" >>%3
   echo.>>%3
   type %3 >>"%LOGFILE%" 2>&1
   call %3
goto :eof

:add2zip
   set vibFile=%*
   for %%v in ("!vibFile!") do set vibFileName=%%~nxv
   call :log Adding "!vibFileName!" ...

   call :logFile Getting VIB packed file size ...
   for %%u in ("!vibFile!") do set vibPackedSize=%%~zu

   call :logFile Determining VIB file sha-256 checksum ...
   "%BUSYBOX%" sha256sum "!vibFile!" >"%TMPDIR%\sha256sum.tmp"
   if not "%ERRORLEVEL%"=="0" ( call :fatal Error calculating sha256sum of VIB file & exit /b 1)
   for /F "tokens=1" %%c in ('type "%TMPDIR%\sha256sum.tmp"') do set vibChecksum=%%c

   call :logFile Copying "!vibFile!" to "%BDLDIR%" ...
   call :logRun copy /y "!vibFile!" "%BDLDIR%"
   if not "!RC!"=="0" ( call :fatal Error copying '!vibFile!' to bundle dir & exit /b 1)

   call :logFile Unpacking VIB descriptor.xml file ...
   call :logRun "%SEVENZIP%" x -y -o"%TMPDIR%" "!vibFile!" descriptor.xml
   if not "!RC!"=="0" ( call :fatal Error unpacking the VIB descriptor.xml file & exit /b 1)

   if not exist "%TMPDIR%\descriptor.xml" ( call :fatal Corrupt VIB file. Descriptor.xml not found & exit /b 1)
   call :logFile Parsing "%TMPDIR%\descriptor.xml" ...
   call :ParseVibXML "%TMPDIR%\descriptor.xml" vib "%TMPDIR%\parsevib.tmp.cmd"

   call :logFile Editing metadata\bulletins\%obName%-%obVersion%.xml ...
   "%BUSYBOX%" echo -n "<vibID>!vibVendor!_!vibType!_!vibName!_!vibVersion!</vibID>" >>"%METADIR%\bulletins\%obName%-%obVersion%.xml"

   call :logFile Editing metadata\vmware.xml ...
   ( "%BUSYBOX%" echo "      <vib>"
     "%BUSYBOX%" echo "        <vibVersion>1.4.5</vibVersion>"
     "%BUSYBOX%" echo "        <vibID>!vibVendor!_!vibType!_!vibName!_!vibVersion!</vibID>"
     "%BUSYBOX%" echo "        <name>!vibName!</name>"
     "%BUSYBOX%" echo "        <version>!vibVersion!</version>"
     "%BUSYBOX%" echo "        <vendor>!vibVendor!</vendor>"
     "%BUSYBOX%" echo "        <vibType>!vibType!</vibType>"
     "%BUSYBOX%" echo "        <summary>!vibSummary!</summary>"
     "%BUSYBOX%" echo "        <systemReqs>"
     findstr /I /L "<system-requires>" "%TMPDIR%\descriptor.xml" | "%SED%" -e "s#.*<system-requires>#          #I;s#</system-requires>.*##I"
	 "%BUSYBOX%" echo ""
   ) >>"%METADIR%\vmware.xml"
   if "%obESXiVer5x%"=="1" (
      "%BUSYBOX%" echo "          <swPlatform locale=\"\" version=\"5.*\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\vmware.xml"
   ) else (
      if "%obESXiVer50%"=="1" "%BUSYBOX%" echo "          <swPlatform locale=\"\" version=\"5.0.0\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\vmware.xml"
      if "%obESXiVer51%"=="1" "%BUSYBOX%" echo "          <swPlatform locale=\"\" version=\"5.1.0\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\vmware.xml"
      if "%obESXiVer55%"=="1" "%BUSYBOX%" echo "          <swPlatform locale=\"\" version=\"5.5.0\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\vmware.xml"
   )
   if "%obESXiVer60%"=="1" "%BUSYBOX%" echo "          <swPlatform locale=\"\" version=\"6.0.0\" productLineID=\"embeddedEsx\"/>">>"%METADIR%\vmware.xml"
   ( "%BUSYBOX%" echo "        </systemReqs>"
     "%BUSYBOX%" echo "        <relationships>"
     findstr /I /L "<relationships>" "%TMPDIR%\descriptor.xml" | "%SED%" -e "s#.*<relationships>#          #I;s#</relationships>.*##I"
     "%BUSYBOX%" echo ""
     "%BUSYBOX%" echo "        </relationships>"
     "%BUSYBOX%" echo "        <postInstall>"
	 findstr /I /L "<live-install-allowed>" "%TMPDIR%\descriptor.xml" | "%SED%" -e "s#.*<live-install-allowed>true#          <rebootRequired>false#I;s#.*<live-install-allowed>false#          <rebootRequired>true#I;s#</live-install-allowed>.*#</rebootRequired>#I"
     "%BUSYBOX%" echo ""
     "%BUSYBOX%" echo "          <hostdRestart>false</hostdRestart>"
     "%BUSYBOX%" echo "        </postInstall>"
     "%BUSYBOX%" echo "        <softwareTags>"
     findstr /I /L "<software-tags>" "%TMPDIR%\descriptor.xml" | "%SED%" -e "s#.*<software-tags>#          #I;s#</software-tags>.*##I"
     "%BUSYBOX%" echo ""
     "%BUSYBOX%" echo "        </softwareTags>"
     "%BUSYBOX%" echo "        <vibFile>"
     "%BUSYBOX%" echo "          <sourceUrl></sourceUrl>"
     "%BUSYBOX%" echo "          <relativePath>!vibFileName!</relativePath>"
     "%BUSYBOX%" echo "          <packedSize>!vibPackedSize!</packedSize>"
     "%BUSYBOX%" echo "          <checksum>"
     "%BUSYBOX%" echo "            <checksumType>sha-256</checksumType>"
     "%BUSYBOX%" echo "            <checksum>!vibChecksum!</checksum>"
     "%BUSYBOX%" echo "          </checksum>"
     "%BUSYBOX%" echo "        </vibFile>"
     "%BUSYBOX%" echo "      </vib>"
   ) >>"%METADIR%\vmware.xml"

   call :logFile Copying descriptor.xml to metadata\vibs ...
   call :logRun copy /y "%TMPDIR%\descriptor.xml" "%METADIR%\vibs\!vibName!-9999999990.xml"

   call :logFile Editing "%METADIR%\vibs\!vibName!-9999999990.xml" ...
   call :logRun "%SED%" -e "s#</vib>#<relative-path>!vibFileName!</relative-path><packed-size>!vibPackedSize!</packed-size><checksum checksum-type="""sha-256""">!vibChecksum!</checksum></vib>#I" -i "%METADIR%\vibs\!vibName!-9999999990.xml"

   call :logFile Removing "%TMPDIR%\descriptor.xml" ...
   call :logRun del /f /q "%TMPDIR%\descriptor.xml"
goto :eof

:handleAdvEdit
   call :log Advanced editing enabled.
   call :log --- INFO: Pausing to allow manual editing of files ...
   call :logFile --- --- The Offline bundle content files are at: [%BDLDIR%]
   call :logFile --- --- The metadata files are at:               [%METADIR%]
   call :logFile --- Launching explorer.exe ...
   "%EXPLORER%" "%TMPDIR%"
   call :logRun "%MSGBOX%" 266304 "Pausing script to allow manual editing of files:&n&n--- The Offline bundle content files are at: [%BDLDIR%]&n--- The metadata files are at: [%METADIR%]&n&nWhen editing text files use an editor that preserves UNIX line feeds, like Notepad++. Press OK when you have finished editing."
   call :logFile Finished advanced edit mode.
goto :eof

:addMetadataRecord
   "%BUSYBOX%" echo "  <metadata>"
   "%BUSYBOX%" echo "    <productId>embeddedEsx</productId>"
   "%BUSYBOX%" echo "    <version>%1</version>"
   "%BUSYBOX%" echo "    <locale></locale>"
   "%BUSYBOX%" echo "    <patchUrl></patchUrl>"
   "%BUSYBOX%" echo "    <url>%METADATAZIP%</url>"
   "%BUSYBOX%" echo "    <channelName>default</channelName>"
   "%BUSYBOX%" echo "  </metadata>"
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
