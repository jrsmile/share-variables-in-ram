#include '_SharedVar.au3'
#include '_GUIConsole.au3'


; NOTE: For definitions read more in _SharedVar.au3




_GUIConsole_Create(Default,$COLOR_BLUE,$COLOR_WHITE,701,580)



_GUIConsole_Out('In which way you want to share the *info with the *target_process ?'&@CRLF& _
				'Enter 1 to share the *info using pointer to memory address (Recommended and default).'&@CRLF& _
				'Enter 0 to share the *info using pointer to a hidden GUI window.')
;


While 1
	_GUIConsole_Out('Your answer: ',0)
	$iMode = Number(_GUIConsole_In())
	Switch $iMode
		Case $SharedVar_PTR_Hidden_GUI_Mode,$SharedVar_PTR_MEM_ADDRESS_Mode
			ExitLoop
		Case Else
			_GUIConsole_Out('Your must enter 0 or 1.')
	EndSwitch
WEnd



_GUIConsole_Out(@CRLF&'Preparing for declaration...')



; SETP 1
_SharedVar_InitializeShare($iMode) ; Set the way of how the *Info will be shared.
Switch $iMode
	Case $SharedVar_PTR_Hidden_GUI_Mode
		_GUIConsole_Out('Pointer to hidden GUI (Pointer type 0): ',0)
	Case $SharedVar_PTR_MEM_ADDRESS_Mode
		_GUIConsole_Out('Pointer to memory address (Pointer type 1): ',0)
EndSwitch
_GUIConsole_Out($gg_sv_pPointer4vars)


_GUIConsole_Out(@CRLF&'This process ( This is the *target_process from the viewpoint of Process B):'&@CRLF& _
				'	PID: '&@AutoItPID &@CRLF& _
				'	Pointer for *info: '&$gg_sv_pPointer4vars &@CRLF& _
				'	Pointer type: '&$iMode,2)
;



_SharedVar_SetTargetProcess(0)
; NOTE 1: If you use 0 in this function, then before this you must first call to _SharedVar_InitializeShare !
; NOTE 2: If set to 0 then it will not set *target_process. It will just set this process..



;You first need to declare the variable normaly. then you give the normal variable to _SharedVar_DeclareVar.
;_SharedVar_DeclareVar will upgrade the variable to be shared variable.
;
;** NOTE: before you give the variable to _SharedVar_DeclareVar, first you must keep the following rules:
;A) The value of the variable will be unique identifier. the unique identifier must be only number. * not x.x(for example 0.5 or 1.2). only x (for example: 1)
;Example:: Correct: "$var = 1, $var2 = 2 ...". Wrong: "$var = 1, $var2 = 1 ...".
;   In this case $var2 can't have value 1 because it is the value of $var1.
;   $var2 can store any value except 1.
;   The variables must not contain values like 0.1,1.1 ... (x.*)
; B) The data type of the same variable will be EXACTLY the same in all processes.
;	Example::: Correct:: Inside "Process A": data type of $var is "char[20]". And Inside "Process B":
;	the data type of $var is "char[20]". Wrong:: Inside "Process A": data type of $var is "char[20]". And Inside "Process B":
;	the data type of $var is "char[19]".
; C) You will never change the variable normally. You do it only with  _sv_write(*)
; declare the variables
; D) The unique identifier of the variable will be the same in the other process.
;   Example::: Correct:: Inside "Process A": $var = 1. And Inside "Process B": $var = 1. Wrong:: Inside "Process A": $var = 1. And Inside "Process B": $var = 2.
; E) If the value of the variable stored in C++ process, make sure that no reallocation will occur!
; 	If the value stored in Autoit process then it should be safe Because probably in autoit you don't
; 	have option to paly with it enough to get reallocation.


_GUIConsole_Out('Declaring *shared_variable(s) ...')


$iValue1 = 1
$sValue2 = 2


; NOTE: You must first call to _SharedVar_SetTargetProcess or _SharedVar_SetNewTargetProcess before calling _SharedVar_DeclareVar
;		And enure that no error occurred

;							   vv Data type must be the same in the *target_process
_SharedVar_DeclareVar($iValue1,'int',10) ; Declare var1 so it will store integer value. And (optional) write the value 10
_SharedVar_DeclareVar($sValue2,'char[255]','Hello world!') ; Declare var2 so it will store string value. And (optional) write the value 'Hello world!'




_GUIConsole_Out(@CRLF&'Declared *shared_variable(s) (source values inside this process):' &@CRLF& _
				'iValue1 = '& _sv_read($iValue1) _ ; <- This is how you read the value
				&@CRLF&'sValue2 = '&_sv_read($sValue2) _ ; <- This is how you read the value
				,2)


_GUIConsole_Out('Info: when the process from outside will try to connect to these *shared_variable(s), it will get this *info :'&@CRLF&@TAB& _
$gg_sv_sDeclaredVars&@CRLF&@TAB&'using the pointer '&$gg_sv_pPointer4vars& ' (Pointer type '&$iMode&')',3)



_GUIConsole_Out('Would you like to open Process B now? Select y/Y for yes, any key for no.')
_GUIConsole_Out('Your answer: ',0)
If StringLower(_GUIConsole_In()) = 'y' Then
	Local $ProcessB_Pid = ShellExecute(@ScriptDir&'\Example - [Autoit] Process B.exe',@AutoItPID&' '&$gg_sv_pPointer4vars&' '&$iMode,@ScriptDir)
	If Not $ProcessB_Pid Then _GUIConsole_Out('Failed to open the exe file. You need to open it manually.',2)
EndIf




_GUIConsole_Out(@CRLF&'What do you want to do now?'&@CRLF& _
'1 = Print iValue1 , 2 = Print sValue2 , 3 = change iValue1 , 4 = change sValue2 , 5 = Exit')
While 1
	Switch Number(_GUIConsole_In(1))
		Case 1
			_GUIConsole_Out(' -> The value of iValue1 is '&_sv_read($iValue1))
		Case 2
			_GUIConsole_Out(' -> The value of sValue2 is '&_sv_read($sValue2))

		Case 3
			_GUIConsole_Out(' -> Write the new value for iValue1 (must be int): ',0)
			$NewValue = Number(_GUIConsole_In(1))
			_sv_write($iValue1,$NewValue) ; <- This is how you write the value
			If Not @error Then
				_GUIConsole_Out(' -> The value changed to '&$NewValue&' .')
			Else
				_GUIConsole_Out(' -> Failed to change the value to '&$NewValue&' .')
			EndIf
		Case 4
			_GUIConsole_Out(' -> Write the new value for sValue2 (must be string char[255]): ',0)
			$NewValue = _GUIConsole_In(1)
			_sv_write($sValue2,$NewValue) ; <- This is how you write the value
			If Not @error Then
				_GUIConsole_Out(' -> The value changed to '&$NewValue&' .')
			Else
				_GUIConsole_Out(' -> Failed to change the value to '&$NewValue&' .')
			EndIf
		Case 5
			_GUIConsole_Out(' -> Are you sure you want to exit? (y = yes, n = no): ',0)
			If _GUIConsole_In(1) = 'y' Then
				Sleep(500)
				Exit
			EndIf
			_GUIConsole_Out('')
		Case Else
			_GUIConsole_Out(@CRLF&'Only 1,2,3,4,5 are valid.')
	EndSwitch

WEnd













#Region Debug
Func Exit1()
	Exit
EndFunc
#EndRegion