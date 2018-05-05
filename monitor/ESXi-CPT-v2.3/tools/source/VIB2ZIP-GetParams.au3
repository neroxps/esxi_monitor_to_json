#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=ESXiCust.ico
#AutoIt3Wrapper_Outfile=..\VIB2ZIP-GetParams.Exe
#AutoIt3Wrapper_Res_Description=VIB2ZIP Get Parameters GUI
#AutoIt3Wrapper_Res_Fileversion=1.3.0.0
#AutoIt3Wrapper_Res_ProductVersion=2.3
#AutoIt3Wrapper_Res_LegalCopyright=(C) Andreas Peetz, licensed under the GNU GPL v3
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_Field=ProductName|ESXi Community Packaging Tools
#AutoIt3Wrapper_Res_Field=ProductVersion|2.3
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Script name:    VIB2ZIP-GetParams.au3
 Script version: 1.3
 Author:         Andreas Peetz (ESXi-CPT@v-front.de)

 Script Function:
	Get the parameters for VIB2ZIP

 License: This source code and its compiled executable are licensed
          under the GNU GPL v3. A copy of the license terms is included
		  in the file GPL-v3.txt

#ce ----------------------------------------------------------------------------

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#Include <GuiEdit.au3>

Opt("GuiCoordMode",0)
Opt("GuiResizeMode", $GUI_DOCKLEFT + $GUI_DOCKTOP + $GUI_DOCKSIZE)

if $CmdLine[0] <> 1 Then
	MsgBox(0, "Error", "Usage: " & @ScriptName & " <file-to-store-parameters>")
	Exit(2)
EndIf

$IniFile = @AppDataDir & "\VIB2ZIP.ini"

; Create the GUI elements
$GUI = GUICreate("VIB2ZIP - ESXi-CPT.v-front.de", 500, 480, 250, 250, $WS_CAPTION + $WS_SYSMENU + $WS_MINIMIZEBOX + $WS_SIZEBOX)
GUICtrlCreateLabel("Select the source VIB directory (all VIB files located here will be added to the Offline Bundle):", 10, 10, 480)
$VD_Browse = GUICtrlCreateButton(" Browse... ", 0, 18)
GUICtrlSetTip(-1, "Click to browse for the directory containing the VIB files to package.")
$VD_Input = GUICtrlCreateInput("", 65, 3, 410, 20, $ES_LEFT)
GUICtrlCreateLabel("Select the working directory (for temporary data and storage of the resulting Offline Bundle):", -65, 30, 480)
$WD_Browse = GUICtrlCreateButton(" Browse... ", 0, 18)
GUICtrlSetTip(-1, "Click to change the working directory (used for temp files, the log file and the output)")
$WD_Input = GUICtrlCreateInput("", 65, 3, 410, 20, $ES_LEFT)

GUICtrlCreateLabel("Enter Offline Bundle metadata: -OR- ",40,40)
$popIni = GUICtrlCreateButton("Load from VIB",172,-6)
GUICtrlSetTip(-1, "Preload metadata from most recent VIB file in build directory")

GUICtrlCreateLabel("Name/ID:",-277,35)
$obName = GUICtrlCreateInput("", 65, -3, 240, 20, $ES_LEFT)
GUICtrlSetTip(-1, "Enter a name for the Offline Bundle.")
GUICtrlCreateLabel("(bundle name)",250,3)

GUICtrlCreateLabel("Version:",-315,30)
$obVersion = GUICtrlCreateInput("", 65, -3, 240, 20, $ES_LEFT)
GUICtrlSetTip(-1, "Enter the version of the Offline Bundle in format major.minor.release-build.")
GUICtrlCreateLabel("(e.g. 1.0.0-1)",250,3)

GUICtrlCreateLabel("Vendor:",-315,30)
$obVendor = GUICtrlCreateInput("", 65, -3, 240, 20, $ES_LEFT)
GUICtrlSetTip(-1, "Enter the name of the software vendor or author.")
GUICtrlCreateLabel("(e.g. your name or nick)",250,3)

GUICtrlCreateLabel("Vendor code:",-315,30)
$obVendorCode = GUICtrlCreateInput("", 65, -3, 240, 20, $ES_LEFT)
GUICtrlSetTip(-1, "Enter the short code of the software vendor or author. No Blanks!")
GUICtrlCreateLabel("(e.g. a stock ticker symbol like HPQ)",250,3)

GUICtrlCreateLabel("Description:",-315,30)
$obDescription = GUICtrlCreateInput("", 65, -3, 240, 20, $ES_LEFT + $ES_AUTOHSCROLL)
GUICtrlSetTip(-1, "Enter the subject or purpose of the software package.")
GUICtrlCreateLabel("(bundle description)",250,3)

GUICtrlCreateLabel("KB-URL:",-315,30)
$obKBURL = GUICtrlCreateInput("", 65, -3, 240, 20, $ES_LEFT + $ES_AUTOHSCROLL)
GUICtrlSetTip(-1, "Enter a URL for useful information, documentation etc. (optional)")
GUICtrlCreateLabel("(URL of your web page, optional)",250,3)

GUICtrlCreateLabel("Contact:",-315,30)
$obContact = GUICtrlCreateInput("", 65, -3, 240, 20, $ES_LEFT)
GUICtrlSetTip(-1, "Enter a contact E-mail address (optional).")
GUICtrlCreateLabel("(Contact E-mail address, optional)",250,3)

GUICtrlCreateLabel("ESXi version compatibility:",-315,40)

Dim $mradio[5]
$mradio[0] = GUICtrlCreateCheckbox("5.*", 135, -4)
$mradio[1] = GUICtrlCreateCheckbox("5.0", 40, 0)
$mradio[2] = GUICtrlCreateCheckbox("5.1", 40, 0)
$mradio[3] = GUICtrlCreateCheckbox("5.5", 40, 0)
$mradio[4] = GUICtrlCreateCheckbox("6.0", 40, 0)

$advEdit = GUICtrlCreateCheckbox("Pause execution for advanced editing", -295, 30)
GUICtrlSetTip(-1, "Only for experienced users who understand the" & @LF & "format of the metadata XML files")

$updateCheck = GUICtrlCreateCheckbox("Enable automatic update check (requires working Internet connection)", 0, 20)
GUICtrlSetTip(-1, "Please disable this only if you do not have a working Internet connection.")

$Launcher = GUICtrlCreateButton(" Run! ", 190, 30)
GUICtrlSetTip(-1, "Press Run! to start the build process.")
$Canceler = GUICtrlCreateButton(" Cancel ", 60, 0)
GUICtrlSetTip(-1, "Press Cancel to quit without building.")

; Set initial GUI controls' state
GUICtrlSetState($VD_Input, $GUI_DISABLE)
GUICtrlSetState($WD_Input, $GUI_DISABLE)
GUICtrlSetState($Launcher, $GUI_DISABLE)

; Load last settings from ini-file
LoadSettingsFromIni($IniFile)

; characters not allowed in file names (will cause errors in the script)
$InvalidChars = "%&!()"
; characters allowed in attributes
$AllowedChars = "[:alnum:]-_."

; function to load settings from an INIFile
Func LoadSettingsFromIni($LIniFile)
   Global $vibDir = IniRead($LIniFile, "Settings", "vibDir", "")
   if $vibDir = "" OR NOT FileExists($vibDir) Then $vibDir = @MyDocumentsDir
   GUICtrlSetData($VD_Input, $vibDir)
   Global $WorkDir = IniRead($LIniFile, "Settings", "wDir", "")
   if $WorkDir = "" OR NOT FileExists($WorkDir) Then $WorkDir = @MyDocumentsDir
   GUICtrlSetData($WD_Input, $WorkDir)
   if IniRead($LIniFile, "Settings", "advEdit", "0") = "1" Then GUICtrlSetState($advEdit,$GUI_CHECKED)
   if IniRead($LIniFile, "Settings", "updateCheck", "1") = "1" Then GUICtrlSetState($updateCheck,$GUI_CHECKED)
   GUICtrlSetData($obName, IniRead($LIniFile, "Settings", "obName", ""))
   GUICtrlSetData($obVersion, IniRead($LIniFile, "Settings", "obVersion", ""))
   GUICtrlSetData($obVendor, IniRead($LIniFile, "Settings", "obVendor", ""))
   GUICtrlSetData($obVendorCode, IniRead($LIniFile, "Settings", "obVendorCode", ""))
   GUICtrlSetData($obDescription, IniRead($LIniFile, "Settings", "obDescription", ""))
   GUICtrlSetData($obKBURL, IniRead($LIniFile, "Settings", "obKBURL", ""))
   GUICtrlSetData($obContact, IniRead($LIniFile, "Settings", "obContact", ""))
   Global $obESXiVer5x = IniRead($LIniFile, "Settings", "obESXiVer5x", "1")
   Global $obESXiVer50 = IniRead($LIniFile, "Settings", "obESXiVer50", "1")
   Global $obESXiVer51 = IniRead($LIniFile, "Settings", "obESXiVer51", "1")
   Global $obESXiVer55 = IniRead($LIniFile, "Settings", "obESXiVer55", "1")
   Global $obESXiVer60 = IniRead($LIniFile, "Settings", "obESXiVer60", "1")
   SetCheckBox($mRadio[0], $obESXiVer5x, 0)
   if $obESXiVer5x = "1" Then
      $obESXiVer50 = 1
      $obESXiVer51 = 1
      $obESXiVer55 = 1
	  SetCheckBox($mRadio[1], $obESXiVer50, $GUI_DISABLE)
	  SetCheckBox($mRadio[2], $obESXiVer51, $GUI_DISABLE)
	  SetCheckBox($mRadio[3], $obESXiVer55, $GUI_DISABLE)
   Else
	  SetCheckBox($mRadio[1], $obESXiVer50, 0)
	  SetCheckBox($mRadio[2], $obESXiVer51, 0)
	  SetCheckBox($mRadio[3], $obESXiVer55, 0)
   EndIf
   SetCheckBox($mRadio[4], $obESXiVer60, 0)
EndFunc

Func LoadPartialSettingsFromIni($LIniFile)
   GUICtrlSetData($obName, IniRead($LIniFile, "Settings", "obName", ""))
   GUICtrlSetData($obVersion, IniRead($LIniFile, "Settings", "obVersion", ""))
   GUICtrlSetData($obVendor, IniRead($LIniFile, "Settings", "obVendor", ""))
   GUICtrlSetData($obVendorCode, IniRead($LIniFile, "Settings", "obVendorCode", ""))
   GUICtrlSetData($obDescription, IniRead($LIniFile, "Settings", "obDescription", ""))
   GUICtrlSetData($obKBURL, IniRead($LIniFile, "Settings", "obKBURL", ""))
   GUICtrlSetData($obContact, IniRead($LIniFile, "Settings", "obContact", ""))
EndFunc

; function to test a filename for invalid characters
Func TestInvalidFilenameChars($testString)
	if StringRegExp($testString,"[" & $InvalidChars & "]") Then
		MsgBox(0,"Invalid character in file name", "The name of the selected file contains an invalid character (" & $InvalidChars & ") that will cause errors with the script. Please rename the file and re-select it!")
		return 1
	Else
		return 0
	EndIf
EndFunc

; function to test for invalid chars in attributes
Func TestInvalidAttrChars($testString, $attrName)
	if StringRegExp($testString,"[^" & $AllowedChars & "]") Then
		MsgBox(0,"Invalid character in Offline Bundle attribute: " & $attrName, "For the attributes Name, Version and Vendor only the following characters are allowed: a-z, A-Z, 0-9, ., - and _")
		return 1
	Else
		return 0
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

Func SetCheckbox($Checkbox, $Value, $AddOpt)
   If $Value = 1 Then
	  GUICtrlSetState($Checkbox, $GUI_CHECKED + $AddOpt)
   Else
	  GUICtrlSetState($Checkbox, $GUI_UNCHECKED + $AddOpt)
   EndIf
EndFunc

Func GetCheckBox(ByRef $Checkbox)
   If GUICtrlRead($Checkbox) = $GUI_CHECKED Then
	  Return 1
   Else
	  Return 0
   EndIf
EndFunc


; Show the GUI
GUISetState()

_GUICtrlEdit_SetSel($obDescription, 0, 0)
_GUICtrlEdit_SetSel($obKBURL, 0, 0)

$focus = ""
; Get and react on messages
While 1
	; Enable the Run-Button if all parameters are set
	If GUICtrlRead($VD_Input) <> "" AND GUICtrlRead($WD_Input) <> "" AND GUICtrlRead($obName) <> "" AND GUICtrlRead($obVersion) <> "" _
	   AND GUICtrlRead($obVendor) <> "" AND GUICtrlRead($obVendorCode) <> "" AND GUICtrlRead($obDescription) <> "" _
	   AND ((GUICtrlRead($mRadio[0]) = $GUI_CHECKED) OR (GUICtrlRead($mRadio[1]) = $GUI_CHECKED) OR (GUICtrlRead($mRadio[2]) = $GUI_CHECKED) OR (GUICtrlRead($mRadio[3]) = $GUI_CHECKED) OR (GUICtrlRead($mRadio[4]) = $GUI_CHECKED)) Then
		if BitAnd(GuiCtrlGetState($Launcher), $GUI_DISABLE) > 0 Then GUICtrlSetState($Launcher, $GUI_ENABLE)
	Else
		if BitAnd(GuiCtrlGetState($Launcher), $GUI_ENABLE) > 0 Then GUICtrlSetState($Launcher, $GUI_DISABLE)
	EndIf
	; Get message
	$msg = GUIGetMsg()
	$newfocus = ControlGetFocus("")
	; If focus has changed ...:
	if $focus <> $newfocus Then
		; if "Description" ob "KBURKL control lost focus then scroll it to the left:
		if $focus = "Edit7" Then _GUICtrlEdit_SetSel($obDescription, 0, 0)
		if $focus = "Edit8" Then _GUICtrlEdit_SetSel($obKBURL, 0, 0)
		$focus = $newfocus
    EndIf
	; Handle ESXi version selection changes
	if BitAND(GUICtrlRead($mradio[0]), $GUI_CHECKED) = 0 Then
		$obESXiVer5xNEW = 0
	Else
		$obESXiVer5xNEW = 1
	EndIf
	; If Wildcard (5.*) was toggled:
	If $obESXiVer5xNEW <> $obESXiVer5x Then
		$obESXiVer5x = $obESXiVer5xNEW
		If $obESXiVer5x = 0 Then
			$obESXiVer50 = 0
			$obESXiVer51 = 0
			$obESXiVer55 = 1
			SetCheckBox($mRadio[1], $obESXiVer50, $GUI_ENABLE)
			SetCheckBox($mRadio[2], $obESXiVer51, $GUI_ENABLE)
			SetCheckBox($mRadio[3], $obESXiVer55, $GUI_ENABLE)
		Else
			$obESXiVer50 = 1
			$obESXiVer51 = 1
			$obESXiVer55 = 1
			SetCheckBox($mRadio[1], $obESXiVer50, $GUI_DISABLE)
			SetCheckBox($mRadio[2], $obESXiVer51, $GUI_DISABLE)
			SetCheckBox($mRadio[3], $obESXiVer55, $GUI_DISABLE)
		EndIf
	; If all of 5.0, 5.1 and 5.5 selected then activate wildcard 5.* (if not already active):
	ElseIf (($obESXiVer5x = 0) AND (BitAND(GUICtrlRead($mradio[1]), $GUI_CHECKED) = $GUI_CHECKED) _
							   AND (BitAND(GUICtrlRead($mradio[2]), $GUI_CHECKED) = $GUI_CHECKED) _
							   AND (BitAND(GUICtrlRead($mradio[3]), $GUI_CHECKED) = $GUI_CHECKED)) Then
		$obESXiVer5x = 1
		$obESXiVer50 = 1
		$obESXiVer51 = 1
		$obESXiVer55 = 1
		SetCheckBox($mRadio[0], $obESXiVer5x, 0)
		SetCheckBox($mRadio[1], $obESXiVer50, $GUI_DISABLE)
		SetCheckBox($mRadio[2], $obESXiVer51, $GUI_DISABLE)
		SetCheckBox($mRadio[3], $obESXiVer55, $GUI_DISABLE)
	EndIf

	Select
	    ; "Load from VIB" button clicked
	    case $msg = $popIni
		    $VIniFile = @TempDir & "\_vib2ini.ini"
			$pars = Chr(34) & $vibDir & Chr(34) & " " & Chr(34) & $VIniFile & Chr(34)
			$rc = ShellExecuteWait( @ScriptDir & "\_vib2ini.cmd", $pars, "", "", @SW_HIDE)
			; MsgBox(0, "debug", $rc)
			if $rc = 0 Then
			   LoadPartialSettingsFromIni($VIniFile)
			   _GUICtrlEdit_SetSel($obDescription, 0, 0)
			   _GUICtrlEdit_SetSel($obKBURL, 0, 0)
			EndIf

		; Cancel button clicked
		case $msg = $Canceler OR $msg = $GUI_EVENT_CLOSE
			$ExitCode = 1
			ExitLoop
		; Browse for VIB dir
		case $msg = $VD_Browse
			$vibDir = GUICtrlRead($VD_Input)
			if $vibDir = "" Then
				$vibDirBrowse = @MyDocumentsDir
			Else
				$vibDirBrowse = $vibDir
			EndIf
			$VD_Selection = FileSelectFolder("Select the source VIB directory:", "", 1+2, $vibDirBrowse)
			if $VD_Selection <> "" AND Not TestInvalidFilenameChars($VD_Selection) Then GUICtrlSetData($VD_Input, $VD_Selection)
			$vibDir = GUICtrlRead($VD_Input)
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
		; Run button clicked
		case $msg = $Launcher
			If TestInvalidAttrChars(GUICtrlRead($obName), "Name") Then ContinueLoop
			If TestInvalidAttrChars(GUICtrlRead($obVersion), "Version") Then ContinueLoop
			If TestInvalidAttrChars(GUICtrlRead($obVendor), "Vendor") Then ContinueLoop
			If TestInvalidAttrChars(GUICtrlRead($obVendorCode), "Vendor code") Then ContinueLoop
			IniWrite($IniFile, "Settings", "vibDir", GUICtrlRead($VD_Input))
			IniWrite($IniFile, "Settings", "wDir", GUICtrlRead($WD_Input))
			If GUICtrlRead($advEdit) = $GUI_CHECKED Then
				$advEdit_Flag = "1"
			Else
				$advEdit_Flag = "0"
			EndIf
			IniWrite($IniFile, "Settings", "advEdit", $advEdit_Flag)
			If GUICtrlRead($updateCheck) = $GUI_CHECKED Then
				$updateCheck_Flag = "1"
			Else
				$updateCheck_Flag = "0"
			EndIf
			IniWrite($IniFile, "Settings", "updateCheck", $updateCheck_Flag)
			IniWrite($IniFile, "Settings", "obName", GUICtrlRead($obName))
			IniWrite($IniFile, "Settings", "obVersion", GUICtrlRead($obVersion))
			IniWrite($IniFile, "Settings", "obVendor", GUICtrlRead($obVendor))
			IniWrite($IniFile, "Settings", "obVendorCode", GUICtrlRead($obVendorCode))
			IniWrite($IniFile, "Settings", "obDescription", GUICtrlRead($obDescription))
			IniWrite($IniFile, "Settings", "obKBURL", GUICtrlRead($obKBURL))
			IniWrite($IniFile, "Settings", "obContact", GUICtrlRead($obContact))
			IniSaveCheckbox("Settings", "obESXiVer5x", GUICtrlRead($mRadio[0]))
			IniSaveCheckbox("Settings", "obESXiVer50", GUICtrlRead($mRadio[1]))
			IniSaveCheckbox("Settings", "obESXiVer51", GUICtrlRead($mRadio[2]))
			IniSaveCheckbox("Settings", "obESXiVer55", GUICtrlRead($mRadio[3]))
			IniSaveCheckbox("Settings", "obESXiVer60", GUICtrlRead($mRadio[4]))
			$parFile = FileOpen($CmdLine[1], 2)
			If $parFile = -1 Then
				MsgBox(0, "Error", "Cannot open output file " & $CmdLine[1])
				$ExitCode = 2
			Else
				FileWriteLine($parFile,"set vibDir=" & GUICtrlRead($VD_Input))
				FileWriteLine($parFile,"set wDir=" & GUICtrlRead($WD_Input))
				FileWriteLine($parFile,"set advEdit=" & $advEdit_Flag)
				FileWriteLine($parFile,"set updateCheck=" & $updateCheck_Flag)
				FileWriteLine($parFile,"set obName=" & GUICtrlRead($obName))
				FileWriteLine($parFile,"set obVersion=" & GUICtrlRead($obVersion))
				FileWriteLine($parFile,"set obVendor=" & GUICtrlRead($obVendor))
				FileWriteLine($parFile,"set obVendorCode=" & GUICtrlRead($obVendorCode))
				FileWriteLine($parFile,"set obDescription=" & GUICtrlRead($obDescription))
				$url1 = StringReplace(GUICtrlRead($obKBURL),"&","^&amp;")
				FileWriteLine($parFile,"set obKBURL=" & $url1)
				FileWriteLine($parFile,"set obContact=" & GUICtrlRead($obContact))
				CmdSaveCheckbox("obESXiVer5x", GUICtrlRead($mRadio[0]))
				CmdSaveCheckbox("obESXiVer50", GUICtrlRead($mRadio[1]))
				CmdSaveCheckbox("obESXiVer51", GUICtrlRead($mRadio[2]))
				CmdSaveCheckbox("obESXiVer55", GUICtrlRead($mRadio[3]))
				CmdSaveCheckbox("obESXiVer60", GUICtrlRead($mRadio[4]))
				FileClose($parFile)
				$ExitCode = 0
			EndIf
			ExitLoop
	EndSelect
WEnd

GUIDelete()

Exit($ExitCode)