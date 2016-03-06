#include '_SharedVar.au3'
#include '_GUIConsole.au3'



; NOTE: For definitions read more in _SharedVar.au3



_GUIConsole_Create(Default,$COLOR_GREEN,$COLOR_WHITE,701,580)
_GUIConsole_Out('The PID of this process = '&@AutoItPID,2)



Local $ProcessA_Pid,$ProcessA_Pointer,$ProcessA_PointerType




If @Compiled And $CmdLine[0] = 3 Then
	$ProcessA_Pid = $CmdLine[1]
	$ProcessA_Pointer = $CmdLine[2]
	$ProcessA_PointerType = Number($CmdLine[3])
	_GUIConsole_Out('(Got the necessary information for the connection to the *shared_variable(s) in Process A from the cmdline parameters) ',0)
Else

	_GUIConsole_Out('Write the *target_process information:')
	_GUIConsole_Out('	Enter the PID of Process A: ',0)
	$ProcessA_Pid = Number(_GUIConsole_In())
	_GUIConsole_Out('	Enter the pointer for *info of Process A: ',0)
	$ProcessA_Pointer = Number(_GUIConsole_In())
	_GUIConsole_Out('	Enter the pointer type: ',0)
	$ProcessA_PointerType = Number(_GUIConsole_In())
EndIf



_GUIConsole_Out(@CRLF&@CRLF&'*target_process (Process A):'&@CRLF& _
				'	PID of Process A: '&$ProcessA_Pid &@CRLF& _
				'	Pointer for *info of Process A: '&$ProcessA_Pointer &@CRLF& _
				'	Pointer type of Process A: '&$ProcessA_PointerType,2)
;


; Set *target_process to be Process A
_SharedVar_SetNewTargetProcess($ProcessA_Pid,$ProcessA_Pointer,$ProcessA_PointerType)



;You first need to declare the variable normaly. then you give the normal variable to _SharedVar_DeclareVar.
;_SharedVar_DeclareVar will upgrade the variable to be shared variable.
;
;** NOTE: before you give the variable to _SharedVar_DeclareVar, first you must keep the following rules:
;A) The value of the variable will be unique identifier. the unique identifier must be only number. * not x.x(for example 0.5 or 1.2). only x (for example: 1)
;Example:: Correct: "$var = 1, $var2 = 2 ...". Wrong: "$var = 1, $var2 = 1 ...".
;   In this case $var2 can't have value 1 because it is the value of $var1.
;   $var2 can store any value except 1.
;   The variables must not contain values like 0.1,1.1 ... (x.*)
; B) The data type of the same variable will be exactly the same in all processes.
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


_GUIConsole_Out('Declaring variables (Make connection to the *shared_variable(s) in the "Process A") ...',2)

$iValue1 = 1
$sValue2 = 2


; NOTE: You must first call to _SharedVar_SetTargetProcess or _SharedVar_SetNewTargetProcess before calling _SharedVar_DeclareVar
;		And enure that no error occurred


_SharedVar_DeclareVar($iValue1,'int') ; Declare iValue1 -> Connect iValue1 (inside Process B) to iValue1 (inside Process A)
_SharedVar_DeclareVar($sValue2,'char[255]') ; Declare sValue2 -> Connect sValue2 (inside Process B) to sValue2 (inside Process A)
; NOTE 1: Because we set *target_process to be not this process, this functions make "only" connection to the *shared_variable that stored in *target_process.
;		  Because of this you can't set value in this function (it will get the value from the *target_process)

If @error Then
	_GUIConsole_Out('!!! An error occurred in declaration of variables. The error occurred in line '&@error&' . !!!')
	Sleep(10000)
	Exit
EndIf


; Print the shared variables
_GUIConsole_Out('Declared *shared_variable(s) (Stored in Process A):' &@CRLF& _
				'iValue1 = '& _sv_read($iValue1) _ ; <- This is how you read the value
				&@CRLF&'sValue2 = '&_sv_read($sValue2) _ ; <- This is how you read the value
				,2)



Sleep(500)


_GUIConsole_Out('What do you want to do now?'&@CRLF& _
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

