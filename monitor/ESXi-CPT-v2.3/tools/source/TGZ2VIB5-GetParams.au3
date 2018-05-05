#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=ESXiCust.ico
#AutoIt3Wrapper_Outfile=..\TGZ2VIB5-GetParams.exe
#AutoIt3Wrapper_Res_Description=TGZ2VIB5 Get Parameters GUI
#AutoIt3Wrapper_Res_Fileversion=2.3.0.0
#AutoIt3Wrapper_Res_ProductVersion=2.3
#AutoIt3Wrapper_Res_LegalCopyright=(C) Andreas Peetz, licensed under the GNU GPL v3
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_Field=ProductName|ESXi Community Packaging Tools
#AutoIt3Wrapper_Res_Field=ProductVersion|2.3
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Script name:    TGZ2VIB5-GetParams.au3
 Script version: 2.3
 Author:         Andreas Peetz (ESXi-CPT@v-front.de)

 Script Function:
	Get the parameters for TGZ2VIB5

 License: This source code and its compiled executable are licensed
          under the GNU GPL v3. A copy of the license terms is included
		  in the file GPL-v3.txt

#ce ----------------------------------------------------------------------------

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#Include <GuiEdit.au3>
#include <ComboConstants.au3>

Opt("GuiCoordMode",0)
Opt("GuiResizeMode", $GUI_DOCKLEFT + $GUI_DOCKTOP + $GUI_DOCKSIZE)

if $CmdLine[0] <> 1 Then
	MsgBox(0, "Error", "Usage: " & @ScriptName & " <file-to-store-parameters>")
	Exit(2)
EndIf

$INIFile = @AppDataDir & "\TGZ2VIB5.ini"

; Create the GUI elements
$GUI = GUICreate("TGZ2VIB5 - ESXi-CPT.v-front.de", 500, 840, 250, 50, $WS_CAPTION + $WS_SYSMENU + $WS_MINIMIZEBOX + $WS_SIZEBOX)
GUICtrlCreateLabel("Select",10,10)
Dim $iradio[2]
$iradio[0] = GUICtrlCreateRadio("an OEM.tgz file", 35, -4)
GUICtrlSetTip(-1, "Use a pre-packaged TGZ file as input")
GUICtrlCreateLabel("-OR-", 95, 4)
$iradio[1] = GUICtrlCreateRadio("a build directory", 30, -4, 110, 20)
GUICtrlSetTip(-1, "Build TGZ file from directory - Do not use this option" & @LF & "if you want to add executable binaries, because they" & @LF & "won't be added with eXec-permissions!")
$OEM_Browse = GUICtrlCreateButton(" Browse... ", -160, 22)
GUICtrlSetTip(-1, "Click to browse for TGZ file or build directory")
$OEM_Input = GUICtrlCreateInput("", 65, 3, 410, 20, $ES_LEFT)
GUICtrlCreateLabel("Select the working directory:", -65, 30, 400)
$WD_Browse = GUICtrlCreateButton(" Browse... ", 0, 18)
GUICtrlSetTip(-1, "Click to browse for Working directory")
$WD_Input = GUICtrlCreateInput("", 65, 3, 410, 20, $ES_LEFT)

GUICtrlCreateGroup("VIB type", -65, 40, 480, 45)

Dim $tradio[2]
$tradio[0] = GUICtrlCreateRadio("bootbank", 10, 15, 60, 20)
GUICtrlSetTip(-1, "Build VIB of standard type bootbank," & @LF & "used in most cases, e.g. for drivers")
$tradio[1] = GUICtrlCreateRadio("locker", 75, 0, 60, 20)
GUICtrlSetTip(-1, "Build VIB of type locker," & @LF & "currently only used for tools-light")

GUICtrlCreateGroup("VIB description data", -85, 40, 480, 210)

GUICtrlCreateLabel("Name:",10,30)
$vibName = GUICtrlCreateInput("", 65, -3, 240, 20, $ES_LEFT)
GUICtrlSetTip(-1, "Enter the name of the VIB package. If it is a hardware driver" & @LF & "then prefix it with net-, scsi-, ata- or sata-.")
GUICtrlCreateLabel("(e.g. net-sky2)",250,3)

GUICtrlCreateLabel("Version:",-315,30)
$vibVersion = GUICtrlCreateInput("", 65, -3, 240, 20, $ES_LEFT)
GUICtrlSetTip(-1, "Use the version of the original Linux driver/package and" & @LF & "add a build number suffix like -1." & @LF & "Format: major.minor.release-build")
GUICtrlCreateLabel("(e.g. 1.0.0-23)",250,3)

GUICtrlCreateLabel("Vendor:",-315,30)
$vibVendor = GUICtrlCreateInput("", 65, -3, 240, 20, $ES_LEFT)
GUICtrlSetTip(-1, "Enter the vendor/author of the original Linux driver/package.")
GUICtrlCreateLabel("(e.g. Marvell)",250,3)

GUICtrlCreateLabel("Summary:",-315,30)
$vibSummary = GUICtrlCreateInput("", 65, -3, 240, 20, $ES_LEFT + $ES_AUTOHSCROLL)
GUICtrlSetTip(-1, "Short summary of the package's contents")
GUICtrlCreateLabel("(e.g. Driver for Marvell NICs)",250,3)

GUICtrlCreateLabel("Description:",-315,30)
$vibDescription = GUICtrlCreateInput("", 65, -3, 240, 20, $ES_LEFT + $ES_AUTOHSCROLL)
GUICtrlSetTip(-1, "The purpose of the package, credits and other information")
GUICtrlCreateLabel("(detailed description)",250,3)

GUICtrlCreateLabel("Details URL:",-315,30)
$vibKBURL = GUICtrlCreateInput("", 65, -3, 240, 20, $ES_LEFT + $ES_AUTOHSCROLL)
GUICtrlSetTip(-1, "A URL with details about the package, e.g. a KB article (optional).")
GUICtrlCreateLabel("(e.g. link to web site or KB)",250,3)

GUICtrlCreateGroup("Package properties", -325, 40, 480, 215)

GUICtrlCreateLabel("Load presets for:",130,30)
$preset = GUICtrlCreateCombo("Last session", 85, -3, 110, 20, BitOr($GUI_SS_DEFAULT_COMBO, $CBS_DROPDOWNLIST) )
GUICtrlSetData(-1, "Driver (ESXi 5.0+)|Driver (ESXi 5.1+)|Driver (ESXi 5.5+)|Driver (ESXi 6.0+)|Firewall rule|esxcli plugin|VMware Tools", "")
GUICtrlSetTip(-1, "Select the preset to load or 'Last session' to load last session's settings.")
$PresetLoader = GUICtrlCreateButton(" Load ", 120, -3)
GUICtrlSetTip(-1, "Click to load the selected presets.")

GUICtrlCreateLabel("Dependencies:",-325,35)
$vibDependencies = GUICtrlCreateInput("", 80, -3, 255, 20, $ES_LEFT + $ES_AUTOHSCROLL)
GUICtrlSetTip(-1,"Translates to XML tags <depends><constraint name=... /></depends>")
GUICtrlCreateLabel("(space separated list)",265,3)

GUICtrlCreateLabel("Software tags:",-345,30)
$vibSoftwareTags = GUICtrlCreateInput("", 80, -3, 255, 20, $ES_LEFT + $ES_AUTOHSCROLL)
GUICtrlSetTip(-1,"Translates to XML tags <software-tags><tag>...</tag></software-tags>")
GUICtrlCreateLabel("(space separated list)",265,3)

GUICtrlCreateLabel("Installation flags:",-345,30)
$maintModeReq = GUICtrlCreateCheckbox("Needs Maintenance mode", 100, -3)
GUICtrlSetTip(-1, "Installation requires host to be in maintenance mode")
$cimonRestart = GUICtrlCreateCheckbox("CIMON restart required", 160, 0)
GUICtrlSetTip(-1, "Restart CIMON daemon after installation")
$liveInstallAllowed = GUICtrlCreateCheckbox("Live Install Allowed", -160, 20)
GUICtrlSetTip(-1, "Installation does not require a reboot")
$liveRemoveAllowed = GUICtrlCreateCheckbox("Live Remove Allowed", 160, 0)
GUICtrlSetTip(-1, "Later Un-Installation will not require a reboot")
$statelessReady = GUICtrlCreateCheckbox("Stateless ready", -160, 20)
GUICtrlSetTip(-1, "Package is compatible with auto-deployed hosts")
$overlay = GUICtrlCreateCheckbox("Overlay", 160, 0)
GUICtrlSetTip(-1, "Package overwrites existing files from other packages" & @LF & "(NOT allowed with the Community acceptance level!)")
GUICtrlCreateLabel("Acceptance Level:",-260,35)
$acceptanceLevel = GUICtrlCreateCombo("community",100,-5,100,20,BitOr($GUI_SS_DEFAULT_COMBO, $CBS_DROPDOWNLIST) )
GUICtrlSetData(-1, "partner|accepted|certified", "")
GUICtrlSetTip(-1,"Be sure to read the documentation about the implications" & @LF & "of choosing a different acceptance level!")

GUICtrlCreateGroup("Packaging options", -110, 40, 480, 90)
$radioLabel = GUICtrlCreateLabel("TGZ handling (for pre-packaged TGZ files only, see tooltips for further information)",50,20)
Dim $radio[3]
$radio[0] = GUICtrlCreateRadio("Do not touch", -25, 15, 90, 20)
GUICtrlSetTip(-1, "Uses the package as is, preserves symbolic links," & @LF & "special permissions (e.g. for executables) etc.")
$radio[1] = GUICtrlCreateRadio("Force repacking", 90, 0, 110, 20)
GUICtrlSetTip(-1, "To fix bad TGZ packages that cause 'Corrupt boot image'" & @LF & "messages when booting the installed system." & @LF & "This was the default in older versions.")
$radio[2] = GUICtrlCreateRadio("Force repacking and pause for adv. editing", 110, 0, 240, 20)
GUICtrlSetTip(-1, "Use this (at your own risk!) if you want to make manual" & @LF & "changes to the contents of the TGZ file")
$useChecksums = GUICtrlCreateCheckbox("Generate checksums for payload file", -200, 25)

GUICtrlCreateGroup("Runtime options", -25, 40, 480, 65)
$dxEdit = GUICtrlCreateCheckbox("Pause execution for manual editing of descriptor.xml", 10, 15)
GUICtrlSetTip(-1, "Only for experienced users who understand the" & @LF & "meaning of the XML tags used in there")

$updateCheck = GUICtrlCreateCheckbox("Enable automatic update check (requires working Internet connection)", 0, 20)
GUICtrlSetTip(-1, "Please keep this enabled unless you are not connected to the Internet!")

$Launcher = GUICtrlCreateButton(" Run! ", 170, 40)
$Canceler = GUICtrlCreateButton(" Cancel ", 60, 0)

; Set initial GUI controls' state
GUICtrlSetState($OEM_Input, $GUI_DISABLE)
GUICtrlSetState($WD_Input, $GUI_DISABLE)
GUICtrlSetState($Launcher, $GUI_DISABLE)

; Load last settings from ini-file
$inputType = IniRead($INIFile, "Settings", "inputType", "0")
GUICtrlSetState($iradio[$inputType], $GUI_CHECKED)
GUICtrlSetState($iradio[1-$inputType], $GUI_UNCHECKED)
$OEM_File = IniRead($INIFile, "Settings", "fOEM", "")
If NOT FileExists($OEM_File) Then $OEM_File = ""
$OEM_Dir = IniRead($INIFile, "Settings", "fOEMDir", @MyDocumentsDir)
If NOT FileExists($OEM_Dir) Then $OEM_Dir = @MyDocumentsDir
If $inputType = 0 Then
	GUICtrlSetData($OEM_Input, $OEM_File)
Else
	GUICtrlSetData($OEM_Input, $OEM_Dir)
	GUICtrlSetData($OEM_Input,$OEM_Dir)
	for $i = 0 to 2
		GUICtrlSetState($radio[$i],$GUI_DISABLE)
	Next
	GUICtrlSetState($radioLabel,$GUI_DISABLE)
EndIf
$vibType = IniRead($INIFile, "Settings", "vibType", "0")
GUICtrlSetState($tradio[$vibType], $GUI_CHECKED)
GUICtrlSetState($tradio[1-$vibType], $GUI_UNCHECKED)
$WorkDir = IniRead($INIFile, "Settings", "wDir", "")
if $WorkDir = "" OR NOT FileExists($WorkDir) Then $WorkDir = @MyDocumentsDir
GUICtrlSetData($WD_Input, $WorkDir)
$repackOpt = IniRead($INIFile, "Settings", "repackOpt", "1")
GUICtrlSetState($radio[$repackOpt], $GUI_CHECKED)
GUICtrlSetState($radio[Mod($repackOpt+1,3)], $GUI_UNCHECKED)
GUICtrlSetState($radio[Mod($repackOpt+2,3)], $GUI_UNCHECKED)
GUICtrlSetState($useChecksums,IniLoadCheckbox("Settings", "useChecksums", "1"))
GUICtrlSetState($dxEdit,IniLoadCheckbox("Settings", "dxEdit", "0"))
GUICtrlSetState($updateCheck,IniLoadCheckbox("Settings", "updateCheck", "1"))
GUICtrlSetData($vibName, IniRead($INIFile, "Settings", "vibName", ""))
GUICtrlSetData($vibVersion, IniRead($INIFile, "Settings", "vibVersion", ""))
GUICtrlSetData($vibVendor, IniRead($INIFile, "Settings", "vibVendor", ""))
GUICtrlSetData($vibSummary, IniRead($INIFile, "Settings", "vibSummary", ""))
GUICtrlSetData($vibDescription, IniRead($INIFile, "Settings", "vibDescription", ""))
GUICtrlSetData($vibKBURL, IniRead($INIFile, "Settings", "vibKBURL", ""))
GUICtrlSetData($vibDependencies, IniRead($INIFile, "Settings", "vibDependencies", "vmkapi_2_0_0_0 com.vmware.driverAPI-9.2.0.0"))
GUICtrlSetData($vibSoftwareTags, IniRead($INIFile, "Settings", "vibSoftwareTags", "driver module"))
GUICtrlSetState($maintModeReq,IniLoadCheckbox("Settings", "maintModeReq", "1"))
GUICtrlSetState($cimonRestart,IniLoadCheckbox("Settings", "cimonRestart", "0"))
GUICtrlSetState($liveInstallAllowed,IniLoadCheckbox("Settings", "liveInstallAllowed", "0"))
GUICtrlSetState($liveRemoveAllowed,IniLoadCheckbox("Settings", "liveRemoveAllowed", "0"))
GUICtrlSetState($statelessReady,IniLoadCheckbox("Settings", "statelessReady", "1"))
GUICtrlSetState($overlay,IniLoadCheckbox("Settings", "overlay", "0"))
GUICtrlSetData($acceptanceLevel, IniRead($INIFile, "Settings", "acceptanceLevel", "community"))

; characters not allowed in file names (will cause errors in the script)
$InvalidChars = "%&!()"
$AllowedChars = "[:alnum:]-_."

; function to test a filename for invalid characters
Func TestInvalidFilenameChars($testString)
	if StringRegExp($testString,"[" & $InvalidChars & "]") Then
		MsgBox(0,"Invalid character in file name", "The name of the selected file contains an invalid character (" & $InvalidChars & ") that will cause errors with the script. Please rename the file and re-select it!")
		return 1
	Else
		return 0
	EndIf
EndFunc

Func TestInvalidAttrChars($testString, $attrName)
	if StringRegExp($testString,"[^" & $AllowedChars & "]") Then
		MsgBox(0,"Invalid character in VIB attribute", "For the attributes Name, Version and Vendor only the following characters are allowed: a-z, A-Z, 0-9, ., - and _")
		return 1
	Else
		return 0
	EndIf
EndFunc

Func IniLoadCheckbox($Section, $Entry, $Default)
	If IniRead($INIFile, $Section, $Entry, $Default) = "1" Then
		Return $GUI_CHECKED
	Else
		Return $GUI_UNCHECKED
	EndIf
EndFunc

Func IniSaveCheckbox($Section, $Entry, $BoxValue)
	If $BoxValue = $GUI_CHECKED Then
		IniWrite($INIFile, $Section, $Entry, "1")
	Else
		IniWrite($INIFile, $Section, $Entry, "0")
	EndIf
EndFunc

Func CmdSaveCheckbox($Entry, $BoxValue)
	If $BoxValue = $GUI_CHECKED Then
		FileWriteLine($parFile,"set " & $Entry & "=1")
	Else
		FileWriteLine($parFile,"set " & $Entry & "=0")
	EndIf
EndFunc

Func SetVibType($Value)
	$vibType = $Value
	GUICtrlSetState($tradio[$vibType], $GUI_CHECKED)
    GUICtrlSetState($tradio[1-$vibType], $GUI_UNCHECKED)
EndFunc

; Show the GUI
GUISetState()

; scroll these input boxes to the left:
_GUICtrlEdit_SetSel($vibSummary, 0, 0)
_GUICtrlEdit_SetSel($vibDescription, 0, 0)
_GUICtrlEdit_SetSel($vibKBURL, 0, 0)
_GUICtrlEdit_SetSel($vibDependencies, 0, 0)
_GUICtrlEdit_SetSel($vibSoftwareTags, 0, 0)

$focus = ""
; Get and react on messages
While 1
	; Enable the Run-Button if all parameters are set
	If GUICtrlRead($OEM_Input) <> "" AND GUICtrlRead($WD_Input) <> "" AND GUICtrlRead($vibName) <> "" AND GUICtrlRead($vibVersion) <> "" AND GUICtrlRead($vibVendor) <> "" AND GUICtrlRead($vibSummary) <> "" AND GUICtrlRead($vibDescription) <> "" Then
		if BitAnd(GuiCtrlGetState($Launcher), $GUI_DISABLE) > 0 Then GUICtrlSetState($Launcher, $GUI_ENABLE)
	Else
		if BitAnd(GuiCtrlGetState($Launcher), $GUI_ENABLE) > 0 Then GUICtrlSetState($Launcher, $GUI_DISABLE)
	EndIf
	; Get message
	$msg = GUIGetMsg()

	$newfocus = ControlGetFocus("")
	; If focus has changed ...:
	if $focus <> $newfocus Then
		; if any of the following controls lost focus then scroll them to the left:
		if $focus = "Edit6" Then _GUICtrlEdit_SetSel($vibSummary, 0, 0)
		if $focus = "Edit7" Then _GUICtrlEdit_SetSel($vibDescription, 0, 0)
		if $focus = "Edit8" Then _GUICtrlEdit_SetSel($vibKBURL, 0, 0)
		if $focus = "Edit9" Then _GUICtrlEdit_SetSel($vibDependencies, 0, 0)
		if $focus = "Edit10" Then _GUICtrlEdit_SetSel($vibSoftwareTags, 0, 0)
		$focus = $newfocus
	EndIf

	for $i = 0 to 1
		if BitAND(GUICtrlRead($iradio[$i]), $GUI_CHECKED) = $GUI_CHECKED then $newInputType = $i
	Next
	if $newInputType <> $inputType Then
		$inputType = $newInputType
		if $inputType = 0 Then
			GUICtrlSetData($OEM_Input,$OEM_File)
			for $i = 0 to 2
				GUICtrlSetState($radio[$i],$GUI_ENABLE)
			Next
			GUICtrlSetState($radioLabel,$GUI_ENABLE)
		Else
			GUICtrlSetData($OEM_Input,$OEM_Dir)
			for $i = 0 to 2
				GUICtrlSetState($radio[$i],$GUI_DISABLE)
			Next
			GUICtrlSetState($radioLabel,$GUI_DISABLE)
		EndIf
	EndIf

    for $i = 0 to 1
		if BitAND(GUICtrlRead($tradio[$i]), $GUI_CHECKED) = $GUI_CHECKED then $vibType = $i
	Next

	Select
		; Cancel button clicked
		case $msg = $Canceler OR $msg = $GUI_EVENT_CLOSE
			$ExitCode = 1
			ExitLoop
		; Browse for OEM file or directory
		case $msg = $OEM_Browse
			if $inputType = 0 Then
				$OEM_File = GUICtrlRead($OEM_Input)
				if $OEM_File = "" Then
					$OEM_BrowseDir = @MyDocumentsDir
				Else
					$OEM_BrowseDir = StringLeft($OEM_File,StringInStr($OEM_File,"\",0,-1)-1)
				EndIf
				$OEM_Selection = FileOpenDialog("Select the OEM.tgz file", $OEM_BrowseDir, "TGZ files (*.tgz)", 1 )
				if $OEM_Selection <> "" AND Not TestInvalidFilenameChars($OEM_Selection) Then
					GUICtrlSetData($OEM_Input, $OEM_Selection)
					$OEM_File = $OEM_Selection
				EndIf
			Else
				$OEM_Dir = GUICtrlRead($OEM_Input)
				if $OEM_Dir = "" Then
					$OEM_Dir_Browse = @MyDocumentsDir
				Else
					$OEM_Dir_Browse = $OEM_Dir
				EndIf
				$OEM_Selection = FileSelectFolder("Select the build directory:", "", 1+2, $OEM_Dir_Browse)
				if $OEM_Selection <> "" AND Not TestInvalidFilenameChars($OEM_Selection) Then
					GUICtrlSetData($OEM_Input, $OEM_Selection)
					$OEM_Dir = $OEM_Selection
				EndIf
			EndIf
; Browse for working dir
		case $msg = $WD_Browse
			$WorkDir = GuiCtrlRead($WD_Input)
			If $WorkDir = "" Then
				$WorkDirBrowse = @MyDocumentsDir
			Else
				$WorkDirBrowse = $WorkDir
			EndIf
			$WD_Selection = FileSelectFolder("Select the working directory:", "", 1+2, $WorkDirBrowse)
			if $WD_Selection <> "" AND Not TestInvalidFilenameChars($WD_Selection) Then GUICtrlSetData($WD_Input, $WD_Selection)
		; Load preset button clicked
		case $msg = $PresetLoader
			;MsgBox(0,"Debug",GUICtrlRead($preset),10)
			Select
			case GUICtrlRead($preset) = "Last Session"
				GUICtrlSetData($vibDependencies, IniRead($INIFile, "Settings", "vibDependencies", "vmkapi_2_0_0_0 com.vmware.driverAPI-9.2.0.0"))
				GUICtrlSetData($vibSoftwareTags, IniRead($INIFile, "Settings", "vibSoftwareTags", "driver module"))
				GUICtrlSetState($maintModeReq,IniLoadCheckbox("Settings", "maintModeReq", "1"))
				GUICtrlSetState($cimonRestart,IniLoadCheckbox("Settings", "cimonRestart", "0"))
				GUICtrlSetState($liveInstallAllowed,IniLoadCheckbox("Settings", "liveInstallAllowed", "0"))
				GUICtrlSetState($liveRemoveAllowed,IniLoadCheckbox("Settings", "liveRemoveAllowed", "0"))
				GUICtrlSetState($statelessReady,IniLoadCheckbox("Settings", "statelessReady", "1"))
				GUICtrlSetState($overlay,IniLoadCheckbox("Settings", "overlay", "0"))
				GUICtrlSetData($acceptanceLevel, IniRead($INIFile, "Settings", "acceptanceLevel", "community"))
				SetVibType(IniRead($INIFile, "Settings", "vibType", "0"))
			case GUICtrlRead($preset) = "Driver (ESXi 5.0+)"
				GUICtrlSetData($vibDependencies, "vmkapi_2_0_0_0 com.vmware.driverAPI-9.2.0.0")
				GUICtrlSetData($vibSoftwareTags, "driver module")
				GUICtrlSetState($maintModeReq,$GUI_CHECKED)
				GUICtrlSetState($cimonRestart,$GUI_UNCHECKED)
				GUICtrlSetState($liveInstallAllowed,$GUI_UNCHECKED)
				GUICtrlSetState($liveRemoveAllowed,$GUI_UNCHECKED)
				GUICtrlSetState($statelessReady,$GUI_CHECKED)
				GUICtrlSetState($overlay,$GUI_UNCHECKED)
				GUICtrlSetData($acceptanceLevel, "community")
				SetVibType(0)
			case GUICtrlRead($preset) = "Driver (ESXi 5.1+)"
				GUICtrlSetData($vibDependencies, "vmkapi_2_1_0_0 com.vmware.driverAPI-9.2.1.0")
				GUICtrlSetData($vibSoftwareTags, "driver module")
				GUICtrlSetState($maintModeReq,$GUI_CHECKED)
				GUICtrlSetState($cimonRestart,$GUI_UNCHECKED)
				GUICtrlSetState($liveInstallAllowed,$GUI_UNCHECKED)
				GUICtrlSetState($liveRemoveAllowed,$GUI_UNCHECKED)
				GUICtrlSetState($statelessReady,$GUI_CHECKED)
				GUICtrlSetState($overlay,$GUI_UNCHECKED)
				GUICtrlSetData($acceptanceLevel, "community")
				SetVibType(0)
			case GUICtrlRead($preset) = "Driver (ESXi 5.5+)"
				GUICtrlSetData($vibDependencies, "vmkapi_2_2_0_0 com.vmware.driverAPI-9.2.2.0")
				GUICtrlSetData($vibSoftwareTags, "driver module")
				GUICtrlSetState($maintModeReq,$GUI_CHECKED)
				GUICtrlSetState($cimonRestart,$GUI_UNCHECKED)
				GUICtrlSetState($liveInstallAllowed,$GUI_UNCHECKED)
				GUICtrlSetState($liveRemoveAllowed,$GUI_UNCHECKED)
				GUICtrlSetState($statelessReady,$GUI_CHECKED)
				GUICtrlSetState($overlay,$GUI_UNCHECKED)
				GUICtrlSetData($acceptanceLevel, "community")
				SetVibType(0)
			case GUICtrlRead($preset) = "Driver (ESXi 6.0+)"
				GUICtrlSetData($vibDependencies, "vmkapi_2_3_0_0 com.vmware.driverAPI-9.2.3.0")
				GUICtrlSetData($vibSoftwareTags, "driver module")
				GUICtrlSetState($maintModeReq,$GUI_CHECKED)
				GUICtrlSetState($cimonRestart,$GUI_UNCHECKED)
				GUICtrlSetState($liveInstallAllowed,$GUI_UNCHECKED)
				GUICtrlSetState($liveRemoveAllowed,$GUI_UNCHECKED)
				GUICtrlSetState($statelessReady,$GUI_CHECKED)
				GUICtrlSetState($overlay,$GUI_UNCHECKED)
				GUICtrlSetData($acceptanceLevel, "community")
				SetVibType(0)
			case GUICtrlRead($preset) = "Firewall rule"
				GUICtrlSetData($vibDependencies, "")
				GUICtrlSetData($vibSoftwareTags, "")
				GUICtrlSetState($maintModeReq,$GUI_UNCHECKED)
				GUICtrlSetState($cimonRestart,$GUI_UNCHECKED)
				GUICtrlSetState($liveInstallAllowed,$GUI_CHECKED)
				GUICtrlSetState($liveRemoveAllowed,$GUI_CHECKED)
				GUICtrlSetState($statelessReady,$GUI_CHECKED)
				GUICtrlSetState($overlay,$GUI_UNCHECKED)
				GUICtrlSetData($acceptanceLevel, "community")
				SetVibType(0)
			case GUICtrlRead($preset) = "esxcli plugin"
				GUICtrlSetData($vibDependencies, "")
				GUICtrlSetData($vibSoftwareTags, "")
				GUICtrlSetState($maintModeReq,$GUI_UNCHECKED)
				GUICtrlSetState($cimonRestart,$GUI_UNCHECKED)
				GUICtrlSetState($liveInstallAllowed,$GUI_UNCHECKED)
				GUICtrlSetState($liveRemoveAllowed,$GUI_UNCHECKED)
				GUICtrlSetState($statelessReady,$GUI_CHECKED)
				GUICtrlSetState($overlay,$GUI_UNCHECKED)
				GUICtrlSetData($acceptanceLevel, "community")
				SetVibType(0)
			case GUICtrlRead($preset) = "VMware Tools"
				GUICtrlSetData($vibDependencies, "")
				GUICtrlSetData($vibSoftwareTags, "")
				GUICtrlSetState($maintModeReq,$GUI_UNCHECKED)
				GUICtrlSetState($cimonRestart,$GUI_UNCHECKED)
				GUICtrlSetState($liveInstallAllowed,$GUI_CHECKED)
				GUICtrlSetState($liveRemoveAllowed,$GUI_CHECKED)
				GUICtrlSetState($statelessReady,$GUI_CHECKED)
				GUICtrlSetState($overlay,$GUI_UNCHECKED)
				GUICtrlSetData($acceptanceLevel, "certified")
				SetVibType(1)
				GUICtrlSetData($vibName,"tools-light")
			EndSelect
			_GUICtrlEdit_SetSel($vibDependencies, 0, 0)
			_GUICtrlEdit_SetSel($vibSoftwareTags, 0, 0)
		; Run button clicked
		case $msg = $Launcher
			If TestInvalidAttrChars(GUICtrlRead($vibName), "Name") Then ContinueLoop
			If TestInvalidAttrChars(GUICtrlRead($vibVersion), "Version") Then ContinueLoop
			If TestInvalidAttrChars(GUICtrlRead($vibVendor), "Vendor") Then ContinueLoop
			IniWrite($INIFile, "Settings", "inputType", $inputType)
			IniWrite($INIFile, "Settings", "vibType", $vibType)
			IniWrite($INIFile, "Settings", "fOEM", $OEM_File)
			IniWrite($INIFile, "Settings", "fOEMDir", $OEM_Dir)
			IniWrite($INIFile, "Settings", "wDir", GUICtrlRead($WD_Input))
			for $i = 0 to 2
				if BitAND(GUICtrlRead($radio[$i]), $GUI_CHECKED) = $GUI_CHECKED then $repackOpt = $i
			Next
			IniWrite($INIFile, "Settings", "repackOpt", $repackOpt)
			IniSaveCheckbox("Settings", "useChecksums", GUICtrlRead($useChecksums))
			IniSaveCheckbox("Settings", "dxEdit", GUICtrlRead($dxEdit))
			IniSaveCheckbox("Settings", "updateCheck", GUICtrlRead($updateCheck))
			IniWrite($INIFile, "Settings", "vibName", GUICtrlRead($vibName))
			IniWrite($INIFile, "Settings", "vibVersion", GUICtrlRead($vibVersion))
			IniWrite($INIFile, "Settings", "vibVendor", GUICtrlRead($vibVendor))
			IniWrite($INIFile, "Settings", "vibSummary", GUICtrlRead($vibSummary))
			IniWrite($INIFile, "Settings", "vibDescription", GUICtrlRead($vibDescription))
			IniWrite($INIFile, "Settings", "vibKBURL", GUICtrlRead($vibKBURL))
			IniWrite($INIFile, "Settings", "vibDependencies", GUICtrlRead($vibDependencies))
			IniWrite($INIFile, "Settings", "vibSoftwareTags", GUICtrlRead($vibSoftwareTags))
			IniWrite($INIFile, "Settings", "acceptanceLevel", GUICtrlRead($acceptanceLevel))
			IniSaveCheckbox("Settings", "maintModeReq", GUICtrlRead($maintModeReq))
			IniSaveCheckbox("Settings", "cimonRestart", GUICtrlRead($cimonRestart))
			IniSaveCheckbox("Settings", "liveInstallAllowed", GUICtrlRead($liveInstallAllowed))
			IniSaveCheckbox("Settings", "liveRemoveAllowed", GUICtrlRead($liveRemoveAllowed))
			IniSaveCheckbox("Settings", "statelessReady", GUICtrlRead($statelessReady))
			IniSaveCheckbox("Settings", "overlay", GUICtrlRead($overlay))
			$parFile = FileOpen($CmdLine[1], 2)
			If $parFile = -1 Then
				MsgBox(0, "Error", "Cannot open output file " & $CmdLine[1])
				$ExitCode = 2
			Else
				FileWriteLine($parFile,"set inputType=" & $inputType)
				FileWriteLine($parFile,"set fOEM=" & $OEM_File)
				FileWriteLine($parFile,"set fOEMDir=" & $OEM_Dir)
				FileWriteLine($parFile,"set vibType=" & GUICtrlRead($tradio[$vibType],1))
				FileWriteLine($parFile,"set wDir=" & GUICtrlRead($WD_Input))
				FileWriteLine($parFile,"set repackOpt=" & $repackOpt)
				CmdSaveCheckbox("useChecksums", GUICtrlRead($useChecksums))
				CmdSaveCheckbox("dxEdit", GUICtrlRead($dxEdit))
				CmdSaveCheckbox("updateCheck", GUICtrlRead($updateCheck))
				FileWriteLine($parFile,"set vibName=" & GUICtrlRead($vibName))
				FileWriteLine($parFile,"set vibVersion=" & GUICtrlRead($vibVersion))
				FileWriteLine($parFile,"set vibVendor=" & GUICtrlRead($vibVendor))
				FileWriteLine($parFile,"set vibSummary=" & GUICtrlRead($vibSummary))
				FileWriteLine($parFile,"set vibDescription=" & GUICtrlRead($vibDescription))
				$url1 = StringReplace(GUICtrlRead($vibKBURL),"&","^&amp;")
				FileWriteLine($parFile,"set vibKBURL=" & $url1)
				FileWriteLine($parFile,"set vibDependencies=" & GUICtrlRead($vibDependencies))
				FileWriteLine($parFile,"set vibSoftwareTags=" & GUICtrlRead($vibSoftwareTags))
				FileWriteLine($parFile,"set acceptanceLevel=" & GUICtrlRead($acceptanceLevel))
				CmdSaveCheckbox("maintModeReq", GUICtrlRead($maintModeReq))
				CmdSaveCheckbox("cimonRestart", GUICtrlRead($cimonRestart))
				CmdSaveCheckbox("liveInstallAllowed", GUICtrlRead($liveInstallAllowed))
				CmdSaveCheckbox("liveRemoveAllowed", GUICtrlRead($liveRemoveAllowed))
				CmdSaveCheckbox("statelessReady", GUICtrlRead($statelessReady))
				CmdSaveCheckbox("overlay", GUICtrlRead($overlay))
				FileClose($parFile)
				$ExitCode = 0
			EndIf
			ExitLoop
	EndSelect
WEnd

GUIDelete()

Exit($ExitCode)