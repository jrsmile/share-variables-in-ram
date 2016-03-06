#include-once
#include <ColorConstants.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#Include <ScrollBarConstants.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>

#Region Declaration of variables
Global $gg_gc_hGUI,$gg_gc_hGUI_Edit
#EndRegion




; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIConsole_Create
; Description ...: Create alternative GUI console (Similar to c++ console but better
; Syntax ........: _GUIConsole_Create([$sTitle = Default[, $hBkColor = Default[, $hTextColor = Default[, $x_size = 690[,
;                  $y_size = 298]]]]])
; Parameters ....: $sTitle              - [optional] The title of the console. Default is Default.
;                  $hBkColor            - [optional] The background color of the console. Default is Default.
;                  $hTextColor          - [optional] The color of the text in the console. Default is Default.
;                  $x_size              - [optional] The x size of the console. Default is 690.
;                  $y_size              - [optional] The y size of the console. Default is 298.
; Return values .: handle of the console (You need this if you create more then one console and you switch between them.
; Author ........: gil900
; Link ..........: https://www.autoitscript.com/forum/topic/180608-_guiconsole-create-and-write-to-alternative-console/
; Example .......: YES
; ===============================================================================================================================
Func _GUIConsole_Create($sTitle = Default,$hBkColor = Default,$hTextColor = Default,$x_size = 690,$y_size = 298)

	Local $sScriptName
	If Not @Compiled Then
		$sScriptName = @ScriptName
	Else
		$sScriptName = @AutoItExe
	EndIf
	Local $tmp = StringInStr($sScriptName,'\',0,-1)
	If $tmp Then $sScriptName = StringTrimLeft($sScriptName,$tmp)

	Local $sTitle_start = $sScriptName

	If $sTitle = Default Then $sTitle = 'Autoit Alternative console (by gil900)'
	If $sTitle Then
		$sTitle = $sTitle_start&': '&$sTitle
	Else
		$sTitle = $sTitle_start
	EndIf

	Local $aOutput[2], $x_pos = -1,$y_pos = -1
	If $hBkColor = Default Then $hBkColor = 0x000000
	If $hTextColor = Default Then $hTextColor = 0xFFFFFF

	If $gg_gc_hGUI Then
		Local Const $iDiffSpace = 50
		Local $pos = WinGetPos($gg_gc_hGUI)
		$x_pos = $pos[0]+$iDiffSpace
		$y_pos = $pos[1]+$iDiffSpace
		If $x_pos+$x_size > @DesktopWidth Then $x_pos = @DesktopWidth-$x_size
		If $y_pos+$y_size > @DesktopHeight Then $y_pos = @DesktopHeight-$y_size
	EndIf

	$aOutput[0] = GUICreate($sTitle, $x_size, $y_size,$x_pos,$y_pos,$WS_OVERLAPPEDWINDOW)
	$aOutput[1] = GUICtrlCreateEdit("", 0, 0, $x_size-1, $y_size-1,BitOR($GUI_SS_DEFAULT_EDIT,$ES_READONLY))
	GUICtrlSetColor(-1, $hTextColor)
	GUICtrlSetBkColor(-1, $hBkColor)
	_WinAPI_SetWindowLong($aOutput[0], $GWL_STYLE, BitXOr(_WinAPI_GetWindowLong($aOutput[0], $GWL_STYLE), $WS_SYSMENU))
	;WinSetOnTop($gg_gc_hGUI,'',1)
	GUISetState(@SW_SHOW)
	_GUIConsole_SetActiveConsole($aOutput)
	Return $aOutput
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIConsole_Out
; Description ...: Print text data in the console
; Syntax ........: _GUIConsole_Out($sText[, $iAddLines = 1[, $sAddChar = @CRLF]])
; Parameters ....: $sText               - A string value.
;                  $iAddLines           - An integer value. Default is 1.
;										[optional] If set to 0, It will not add "ENTER" (@CRLF of something else you set in the next parameter)
;										after the text.
;										If set bigger then 0 then it will add $iAddLines times "ENTER"(or something else) after the text.
;                  $sAddChar            - [optional] Default is @CRLF. This variable matter if $iAddLines > 0. It will add $iAddLines times
;										$sAddChar ( @CRLF in this case if set to default)
; Return values .: None
; Author ........: gil900
; Link ..........: https://www.autoitscript.com/forum/topic/180608-_guiconsole-create-and-write-to-alternative-console/
; Example .......: YES
; ===============================================================================================================================
Func _GUIConsole_Out($sText,$iAddLines = 1,$sAddChar = @CRLF)
	If $iAddLines Then
		For $a = 1 To $iAddLines
			$sText &= $sAddChar
		Next
	EndIf
	GUISwitch($gg_gc_hGUI)
	Local $iEnd = StringLen(GUICtrlRead($gg_gc_hGUI_Edit))
	_GUICtrlEdit_SetSel($gg_gc_hGUI_Edit, $iEnd, $iEnd)
	_GUICtrlEdit_Scroll($gg_gc_hGUI_Edit, $SB_SCROLLCARET)
	GUICtrlSetData($gg_gc_hGUI_Edit,$sText,1)
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIConsole_In
; Description ...: Get input from the console
; Syntax ........: _GUIConsole_In()
; Parameters ....: $bCleanEnter				- [optional] If set to 1 then it will remove the enter that the user enter...
; Return values .: Return the text that entered in the console
; Author ........: gil900
; Example .......: YES
; ===============================================================================================================================
Func _GUIConsole_In($bCleanEnter = 0)
	_GUICtrlEdit_SetReadOnly($gg_gc_hGUI_Edit,False)

	Local $sBeforeChange = GUICtrlRead($gg_gc_hGUI_Edit), $sBeforeChange_Len = StringLen($sBeforeChange), _
	$sRead = $sBeforeChange,$sRead_old = $sBeforeChange

	While Sleep(25)

		If _GUICtrlEdit_GetSel($gg_gc_hGUI_Edit)[0] < $sBeforeChange_Len Then _
		_GUICtrlEdit_SetSel($gg_gc_hGUI_Edit, $sBeforeChange_Len, $sBeforeChange_Len)

		$sRead = GUICtrlRead($gg_gc_hGUI_Edit)
		If $sRead <> $sRead_old Then
			If Not StringInStr($sRead,$sBeforeChange,0,1,1,$sBeforeChange_Len) Then
				GUICtrlSetData($gg_gc_hGUI_Edit,$sBeforeChange)
				_GUICtrlEdit_SetSel($gg_gc_hGUI_Edit, $sBeforeChange_Len, $sBeforeChange_Len)
				$sRead = $sBeforeChange
			EndIf

			If StringInStr($sRead,@CRLF,0,1,$sBeforeChange_Len) Then ExitLoop

			$sRead_old = $sRead
		EndIf
	WEnd
	_GUICtrlEdit_SetReadOnly($gg_gc_hGUI_Edit,True)
	If $bCleanEnter Then GUICtrlSetData($gg_gc_hGUI_Edit,StringTrimRight($sRead,1))
	Local $sOut = StringReplace(StringTrimLeft($sRead,$sBeforeChange_Len),@CRLF,'')
	;
	Local $sLen = StringLen($sRead)
	_GUICtrlEdit_SetSel($gg_gc_hGUI_Edit, $sLen, $sLen)
	Return $sOut
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIConsole_Clean
; Description ...: Remove all text that printed in the console
; Syntax ........: _GUIConsole_Clean()
; Return values .: None
; Author ........: gil900
; Example .......: Yes
; ===============================================================================================================================
Func _GUIConsole_Clean()
	GUICtrlSetData($gg_gc_hGUI_Edit,'')
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIConsole_Delete
; Description ...: Delete the Console GUI
; Syntax ........: _GUIConsole_Delete()
; Return values .: None
; Author ........: gil900
; Link ..........: https://www.autoitscript.com/forum/topic/180608-_guiconsole-create-and-write-to-alternative-console/
; Example .......: YES
; ===============================================================================================================================
Func _GUIConsole_Delete()
	If Not $gg_gc_hGUI Then Return SetError(1,0,ConsoleWrite('Error in _GUIConsole_Delete: There is no GUIConsole open.'&@CRLF))
	GUIDelete($gg_gc_hGUI)
	$gg_gc_hGUI = 0
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIConsole_SetActiveConsole
; Description ...: Set in which console the data will be printed
; Syntax ........: _GUIConsole_SetActiveConsole($haConsole)
; Parameters ....: $haConsole           - The handle for the target console that returned from _GUIConsole_Create.
; Return values .: Failure: sets the @error the line number of the error.
; Author ........: gil900
; Link ..........: https://www.autoitscript.com/forum/topic/180608-_guiconsole-create-and-write-to-alternative-console/
; Example .......: YES
; ===============================================================================================================================
Func _GUIConsole_SetActiveConsole($haConsole)
	If UBound($haConsole) <> 2 Then Return SetError(@ScriptLineNumber) ; The handle for the console is not valid..
	$gg_gc_hGUI = $haConsole[0]
	$gg_gc_hGUI_Edit = $haConsole[1]
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIConsole_Flash
; Description ...: Flash this console - Useful if there is something important to see in the console
; Syntax ........: _GUIConsole_Flash($haConsole[, $iFlashes = 4[, $iDelay = 500]])
; Parameters ....: $haConsole           - The handle for the target console that returned from _GUIConsole_Create.
;                  $iFlashes            - [optional] The amount of times to flash the console. Default 4.
;                  $iDelay              - [optional] The time in milliseconds to sleep between each flash. Default 500 ms.
; Return values .: None
; Author ........: gil900
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.autoitscript.com/forum/topic/180608-_guiconsole-create-and-write-to-alternative-console/
; Example .......: YES
; ===============================================================================================================================
Func _GUIConsole_Flash($haConsole,$iFlashes = 4,$iDelay = 500)
	If UBound($haConsole) <> 2 Then Return SetError(@ScriptLineNumber) ; The handle for the console is not valid..
	Local $isTop = __WinIsOnTop($haConsole[0])
	If Not $isTop Then WinSetOnTop($haConsole[0],'',1)
	WinFlash($haConsole[0],'',$iFlashes,$iDelay)
	If Not $isTop Then WinSetOnTop($haConsole[0],'',0)
EndFunc



#Region Internal use
Func __WinIsOnTop($hWnd)
    If IsHWnd($hWnd) = 0 And WinExists($hWnd) Then $hWnd = WinGetHandle($hWnd)
	$hWinStyle = _WinAPI_GetWindowLong ($hWnd,$GWL_EXSTYLE)
	If @error Then Return SetError(1)
    If BitAND($WS_EX_TOPMOST,$hWinStyle) Then Return 1
EndFunc
#EndRegion