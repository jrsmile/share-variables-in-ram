#include-once
#include <Array.au3>
#include <WinAPI.au3>

#cs
								_SharedVar*
								Version 2.3    6.3.2016
								By gil900/GilEli

								Donation link:
								https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MZ9W63LBV86AN
#ce
#AutoIt3Wrapper_Run_AU3Check=n

#cs
	################################################ Definitions ###############################################




		*shared_variable
		C type variable that represented by:
			a) constant (constant during the life time of the process) memory address (pointer)
			b) constant unique identifier


		*info
		Information that stored as a string value, that contains a list of all *shared_variable(s) that their value stored in the memory
		of the process that sharing them. The info look like this (this is the format):

			[ vvv Var 1 vvv] [vvvv Var 2  vvvv]   [vvvvv Var 3 vvvvv]
		   "1,  0x02E903D0   ;  2  , 0x02EA9018 ;   3  , 0x02E90110"
		   id    pointer      id2     pointer      id3     pointer
				to memory   of the	 to memory		      to memory
				 address.   value	  address.			   address.

		When a process need to declare a *shared_variable then,
			a) If the value of the variable is stored in another process (*target_process), this process needs to know where the value
				is stored in the memory of the another process. and it get it from this^ list.
			b) If the value of the variable is stored inside, then this process needs to update it's own list
				so when another process need to make a connection, the another process will know the memory address
				of the target variable from this list.

			Every process that have at least one *shared_variable that its value stored inside -
			manage and maintain such a list.





		*target_process
		The process from outside that share variables (*shared_variable) with this process
		(This process is also *target_process from the viewpoint of the *target_process)

		The *target_process is represented by:
		a) The process pid
		b) the pointer to the process *Info
		c) The type of the pointer (hidden gui or memory address)

		When you declare variable that it's source value stored in the memory of the *target_process (process from outside),
		then you need first to set the target process




		Read this (below) if you going to share variables with c++ process. Because in this case, there is no choice and you must to know few
		low-level stuf.

		*copy_variable / *parallel_variable
		In low level: *shared_variable is composed of:
		copy 1 in process 1
		copy 2 in process 2
		copy 3 in process 3
		copy n in process n
		....
;
;									(What you don't see in c++ version)
;									 (What you see in Autoit version)
;												High Level
		*copy_variable/*parallel_variable <--|*shared_variable|---> *parallel_variable/*copy_variable
;					Low-Level												Low-Level
;		(What you see in c++ version)								(What you see in c++ version)
;(What you don't see in Autoit version directly)				(What you don't see in Autoit version directly)


		Each copy is parallel_variable. Each parallel_variable should contain the same information (If you update it in each process).
		When you declare *shared_variable in Autoit, what happans in low level is that you declare *copy_variable

		The *copy_variable is *shared_variable and *shared_variable is *copy_variable.
		If you read the definition of *shared_variable, you should understand that the memory address must be always constant
		during the life time of the process.

		In Autoit you don't need to worry about it. but in c++ you must make sure that *copy_variable never been reallocated
		read more: http://lmgtfy.com/?q=c%2B%2B+prevent+reallocation


#ce


#Region Global variables declaration


; #VARIABLES FOR USER ===========================================================================================================




;
Global $gg_sv_sDeclaredVars ; The *Info
;							Variable that stores as string all declared variables that their value is stored inside
;							the memory of this process. the another process that need to access these variables, need this string
;							Because the string contains all the info needed for the connection to these variables.
;							The info in the string contains: [var id][the memory address of where the value stored]
;							Every time you declare *shared_variable that its value stored in the memory of this process, this string is
;							updated with the info about the new declared variable.

;							If you want to see the string as array, use:
;							$aArray = __SharedVar_DeclareVar_GetInfoAsArray($gg_sv_sDeclaredVars)
;							_ArrayDisplay($aArray)

Global $gg_sv_pPointer4vars ; The pointer to the *Info. only the process from outside need this.
;							from inside the *Info is accessible directly in $gg_sv_sDeclaredVars

Global Const $SharedVar_PTR_Hidden_GUI_Mode = 0
Global Const $SharedVar_PTR_MEM_ADDRESS_Mode = 1

Global $gg_sv_pPointer4vars_type  ; The type of the pointer. 0 = pointer to hidden GUI that contains this string ($SharedVar_PTR_Hidden_GUI_Mode)
;															 1 = pointer to memory address inside this process that ($SharedVar_PTR_MEM_ADDRESS_Mode)
;															     contains this string

; ===============================================================================================================================

Global $gg_sv_pPointer4vars_struct = -1
Global Const $gg_sv_pPointer4vars_struct_datatype = 'char[4000]'

; Array of opened process
Global Const $gg_sv_aOpenedPids_iMax = 5
Global Const $gg_sv_aOpenedPids_ix_iPid = 0 ; [n][$gg_sv_aOpenedPids_ix_iPid] = The pid of the process
Global Const $gg_sv_aOpenedPids_ix_hDll = 1 ; [n][$gg_sv_aOpenedPids_ix_hDll] = Handle kernel32.dll
Global Const $gg_sv_aOpenedPids_ix_hProcess = 2 ; [n][$gg_sv_aOpenedPids_ix_hProcess] = Handle WinAPI OpenProcess
Global Const $gg_sv_aOpenedPids_ix_Ptr4Vars = 3 ; [n][$gg_sv_aOpenedPids_ix_Ptr4Vars] = Pointer for *info that stored in the *target_process
Global Const $gg_sv_aOpenedPids_ix_Ptr4VarsType = 4 ; The type of the pointer. 0 = Pointer for hidden GUI with title that contains
;													the list of the *shared_variable s that stored in the process
;													1 = Pointer to memory address in the *target_process that contains exactly the same
;													information
Global $gg_sv_aOpenedPids[1][$gg_sv_aOpenedPids_iMax] = [[0]]
Global $gg_sv_iActivePidIndex = -1 ; The index of the active process (where the declarations will done... )
;




; Data structure (array) of list of declared *shared_variable(s) in the other  process
Global Const $gg_sv_aPtrsA_iMax = 2
Global Const $gg_sv_aPtrsA_ix_PtrId = 0 ; [n][$gg_sv_aPtrsA_ix_PtrId] = The ID of the pointer
Global Const $gg_sv_aPtrsA_ix_Ptr = 1 ; [n][$gg_sv_aPtrsA_ix_Ptr] = The pointer
;Global Const $gg_sv_aPtrsA_ix_DataType = 2 ; [n][$gg_sv_aPtrsA_ix_DataType] = The data type of the value that stored in the memory
;


; Array of all declared variables
Global $gg_Dec_vars[0]
;

; The data structure (array) for declared variable that its value stored in the memory of another process
Global Const $gg_sv_aVar_imax = 5
Global Const $gg_sv_aVar_ix_ptr = 0 ; [$gg_sv_aVar_ix_ptr] = The pointer for the memory address of where tha value is stored
Global Const $gg_sv_aVar_ix_DataType = 1 ; [$gg_sv_aVar_ix_DataType] = The data type of the value
Global Const $gg_sv_aVar_ix_StructIn = 2
Global Const $gg_sv_aVar_ix_hProcess = 3 ; [$gg_sv_aVar_ix_hProcess] = the handle for the process (output of _MemoryOpen(*) )
Global Const $gg_sv_aVar_ix_hDll = 4
;

; _SharedVar_OpenProcess - Output data structure
Global Const $gg_sv_haProc_imax = 3
Global Const $gg_sv_haProc_ix_Pid = 0 ; [$gg_sv_haProc_ix_Pid] = The pid of the process
Global Const $gg_sv_haProc_ix_Ptr4Vars = 1 ; [$gg_sv_haProc_ix_Ptr4Vars] = The pointer to *info that stored in the *target_process..
Global Const $gg_sv_haProc_ix_Ptr4VarsType = 2 ; [$gg_sv_haProc_ix_Ptr4VarsType] = The type of the pointer ..
;



Global Const $gg_sv_sPlit_2 = ';',$gg_sv_sPlit_3 = ','


; Var naming for Global $Struct ...
Global Const $g_sv_stuctname = 'gg_sv_stuctn'
;


; WinAPI Readprocessmemory error codes
; https://msdn.microsoft.com/en-us/library/windows/desktop/ms681382%28v=vs.85%29.aspx
Global Const $gg_sv_ERROR_PARTIAL_COPY = 299


#EndRegion


#Region Initialize
OnAutoItExitRegister('__SharedVar_OnAutoItExit')
#EndRegion


; #FUNCTION# ====================================================================================================================
; Name ..........: _SharedVar_InitializeShare
; Description ...: Initialize/set the way of how the variables that stored inside this process will be shared with
;					other processes. (Set the way of how the *Info will be shared)
; Syntax ........: _SharedVar_InitializeShare([$pProcessVarsType = 1])
;                  $pProcessVarsType    - [optional] The type of the pointer. Default is 1
;											If set to 0 then this *info will be stored in hidden GUI and $gg_sv_pPointer4vars is the
;											handle to the hidden GUI
;											If set to 1 (Recommended) then this *info will be stored in memory address and $gg_sv_pPointer4vars is the
;											memory address of where this *info is stored.
; Return values .: Success: Return the pointer by saving it in the global variable $gg_sv_pPointer4vars
;					The other process need this pointer in order to access the *info
;				:  Failure: Return @error and set it to the line number of the error.
; Author ........: gil900
; Example .......: yes
; ===============================================================================================================================
Func _SharedVar_InitializeShare($pProcessVarsType = 1)
	If $pProcessVarsType Then
		$gg_sv_pPointer4vars_struct = DllStructCreate($gg_sv_pPointer4vars_struct_datatype)
		$gg_sv_pPointer4vars = DllStructGetPtr($gg_sv_pPointer4vars_struct)
		If @error Then
			$gg_sv_pPointer4vars = 0
			Return SetError(@ScriptLineNumber) ; Error in allocating/accessing the memory of where $gg_sv_sDeclaredVars stored.
		EndIf
	Else
		$gg_sv_pPointer4vars = WinGetHandle(AutoItWinGetTitle())
		If Not $gg_sv_sDeclaredVars And _WinAPI_GetWindowText($gg_sv_pPointer4vars) Then _WinAPI_SetWindowText($gg_sv_pPointer4vars,'')
	EndIf
	$gg_sv_pPointer4vars_type = $pProcessVarsType
	;$gg_sv_iActivePidIndex = 0
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _SharedVar_SetTargetProcess
; Description ...: Set *target_process (not new process)
; Syntax ........: _SharedVar_SetTargetProcess([$iPid = 0])
; Parameters ....: $iPid                - [optional] an integer value. need to be the pid of the *target_process.
;													If set to 0 then the *target_process will be this process
;													use 0 if you want to declare variables that their values are stored
;													in the memory of this process.
;
; NOTE 1: If you use 0 in this function, then before this you must first call to _SharedVar_InitializeShare !
; NOTE 2: If set to 0 then it will not set *target_process. It will just set this process..
;
; Return values .: If Failure: Return @error and set it to the line number of the error.
; Author ........: gil900
; ===============================================================================================================================
Func _SharedVar_SetTargetProcess($iPid = 0)
	If Not $iPid Then
		If Not $gg_sv_pPointer4vars Then Return SetError(@ScriptLineNumber) ; You must call to _SharedVar_InitializeShare first
		$gg_sv_iActivePidIndex = 0
	Else
		Local $iPidIndex = _ArraySearch($gg_sv_aOpenedPids,$iPid,1,$gg_sv_aOpenedPids[0][0],0,0,1,$gg_sv_aOpenedPids_ix_iPid)
		If $iPidIndex <= 0 Then Return SetError(@ScriptLineNumber) ; The process is new and not added before / deletd
		$gg_sv_iActivePidIndex = $iPidIndex
	EndIf
EndFunc




; #FUNCTION# ====================================================================================================================
; Name ..........: _SharedVar_SetNewTargetProcess
; Description ...: Set and add the new *target_process of where to connect the variables during the declaration.
; Syntax ........: _SharedVar_SetNewTargetProcess($iPid, $pProcessVars[, $pProcessVarsType = 1])
; Parameters ....: $iPid                - an integer value. need to be the pid of the *target_process.
;                  $pProcessVars        - a pointer value. need to be pointer to memory address in the target_process that stores the *Info
;                  $pProcessVarsType    - [optional] The type of the pointer. Default is 1
;											If set to 0 then this *info will be stored in hidden GUI and $pProcessVars is the
;											handle to the hidden GUI
;											If set to 1 (Recommended) then this *info will be stored in memory address and $pProcessVars is the
;											memory address of where this *info is stored.
; Return values .: None
; Author ........: gil900
; ===============================================================================================================================
Func _SharedVar_SetNewTargetProcess($iPid,$pProcessVars,$pProcessVarsType = 1)

	If _ArraySearch($gg_sv_aOpenedPids,$iPid,1,$gg_sv_aOpenedPids[0][0],0,0,1,$gg_sv_aOpenedPids_ix_iPid) > 0 Then _
	Return SetError(@ScriptLineNumber) ; The process is not new

	Local $hker32 = DllOpen('kernel32.dll')
	If @error Then Return SetError(@ScriptLineNumber) ; Error opening kernel32.dll
	Local $hMem = DllCall($hker32, 'int', 'OpenProcess', 'int', 0x1F0FFF, 'int', 1, 'int', $iPid)
	If @error Then
		DllClose($hker32)
		Return SetError(@ScriptLineNumber) ; Error opening memory handle for the *target_process
	EndIf

	$gg_sv_aOpenedPids[0][0] += 1
	ReDim $gg_sv_aOpenedPids[$gg_sv_aOpenedPids[0][0]+1][$gg_sv_aOpenedPids_iMax]
	$gg_sv_iActivePidIndex = $gg_sv_aOpenedPids[0][0]
	$gg_sv_aOpenedPids[$gg_sv_iActivePidIndex][$gg_sv_aOpenedPids_ix_iPid] = $iPid
	$gg_sv_aOpenedPids[$gg_sv_iActivePidIndex][$gg_sv_aOpenedPids_ix_hDll] = $hker32
	$gg_sv_aOpenedPids[$gg_sv_iActivePidIndex][$gg_sv_aOpenedPids_ix_hProcess] = $hMem[0]
	$gg_sv_aOpenedPids[$gg_sv_iActivePidIndex][$gg_sv_aOpenedPids_ix_Ptr4Vars] = $pProcessVars
	$gg_sv_aOpenedPids[$gg_sv_iActivePidIndex][$gg_sv_aOpenedPids_ix_Ptr4VarsType] = $pProcessVarsType

EndFunc







; #FUNCTION# ====================================================================================================================
; Name ..........: _sv_write (Short name instead of _SharedVar_WriteValue)
; Description ...: Write Value in the *shared_variable
; Syntax ........: _sv_write($Var, $Value)
; Parameters ....: $Var                 - Output of _SharedVar_DeclareVar()
;                  $Value               - The value to write.
; Return values .: Failure: Set @error to line of the error
; Author ........: gil900
; Link ..........: https://www.autoitscript.com/forum/topic/180616-_sharedvar-declare-shared-variables-between-2-or-more-process-directly-on-memory/
; Example .......: YES
; ===============================================================================================================================
Func _sv_write($Var,$Value)
	Local $Out
	If Not IsArray($Var) Then
		; Write mode A: Write the value with DllStructSetData (Only when the varible stored in the memory of this process
		DllStructSetData(Eval($Var),1,$Value)
		If @error Then Return SetError(@ScriptLineNumber)
	Else
		; Write mode B: Write the value with WriteProcessMemory (Only when the varible stored in the memory another process
		DllStructSetData($Var[$gg_sv_aVar_ix_StructIn],1,$Value)
		If @error Then Return SetError(@ScriptLineNumber)
		DllCall($Var[$gg_sv_aVar_ix_hDll], 'int', 'WriteProcessMemory', 'int', $Var[$gg_sv_aVar_ix_hProcess], 'int', $Var[$gg_sv_aVar_ix_ptr], _
		'ptr', DllStructGetPtr($Var[$gg_sv_aVar_ix_StructIn]), 'int', DllStructGetSize($Var[$gg_sv_aVar_ix_StructIn]), 'int', '')
		If @error Then Return SetError(@ScriptLineNumber)
		If _WinAPI_GetLastError() = $gg_sv_ERROR_PARTIAL_COPY Then SetError(@ScriptLineNumber)
	EndIf
EndFunc



; #FUNCTION# ====================================================================================================================
; Name ..........: _sv_read (Short name instead of _SharedVar_ReadVar )
; Description ...: Read the *shared_variable
; Syntax ........: _sv_read($Var)
; Parameters ....: $Var                 - Variable that is output of _SharedVar_DeclareVar()
; Return values .: Success: The value of the Variable.
;				   Failure: Set @error and the return the last readed value
; Author ........: gil900
; Link ..........: https://www.autoitscript.com/forum/topic/180616-_sharedvar-declare-shared-variables-between-2-or-more-process-directly-on-memory/
; Example .......: YES
; ===============================================================================================================================
Func _sv_read($Var)
	If Not IsArray($Var) Then
		; Read mode A: Read the value with DllStructGetData (Only when the varible stored in the memory of this process
		Return DllStructGetData(Eval($Var),1)
	Else
		; Read mode B: Read the value with ReadProcessMemory (Only when the varible stored in the memory another process
		DllCall($Var[$gg_sv_aVar_ix_hDll], 'int', 'ReadProcessMemory', 'int', $Var[$gg_sv_aVar_ix_hProcess], 'int', $Var[$gg_sv_aVar_ix_ptr], 'ptr', _
		DllStructGetPtr($Var[$gg_sv_aVar_ix_StructIn]), 'int', DllStructGetSize($Var[$gg_sv_aVar_ix_StructIn]), 'int', '')
		If @error Then Return SetError(@ScriptLineNumber)
		If _WinAPI_GetLastError() = $gg_sv_ERROR_PARTIAL_COPY Then SetError(@ScriptLineNumber)
		Return DllStructGetData($Var[$gg_sv_aVar_ix_StructIn],1)
	EndIf
EndFunc



; #FUNCTION# ====================================================================================================================
; Name ..........: _sv_readlast
; Description ...: Get the last readed value from the *shared_variable.
;					It will return **non-updated value**. If the value was changed in the target
;					process/the process was closed and you read the value with this function,
;					you will get the old value and not the new one.
;
;					NOTE: if you read value that stored in the memory of this process, then the
;					returned value will be always updated and there is no difference in this case from
;					using _sv_read.
; Syntax ........: _sv_read($Var)
; Parameters ....: $Var                 - Variable that is output of _SharedVar_DeclareVar()
; Return values .: Success: The value of the Variable.
; Author ........: gil900
; Link ..........: https://www.autoitscript.com/forum/topic/180616-_sharedvar-declare-shared-variables-between-2-or-more-process-directly-on-memory/
; Example .......: YES
; ===============================================================================================================================
Func _sv_readlast($Var)
	If Not IsArray($Var) Then
		Return DllStructGetData(Eval($Var),1)
	Else
		Return DllStructGetData($Var[$gg_sv_aVar_ix_StructIn],1)
	EndIf
EndFunc



; #FUNCTION# ====================================================================================================================
; Name ..........: _SharedVar_DeclareVar
; Description ...: Declare the *shared_variable
;
;			 NOTE: You must first call to _SharedVar_SetTargetProcess or _SharedVar_SetNewTargetProcess before this
;					and enure that no error occurred.
;
;			 A) The value of the varible will be unique identifier. the unique identifier must be only number.
;			    * not x.x(for example 0.5 or 1.2). only x (for example: 1)
;			 	Example:: Correct: "$var = 1, $var2 = 2 ...". Wrong: "$var = 1, $var2 = 1 ...".
;				In this case $var2 can't have value 1 because it is the value of $var1.
;				$var2 can store any value except 1.
;				The variables must not contain values like 0.1,1.1 ... (x.*)
;			 B) The data type of the same variable will be EXACTLY the same in all processes.
;				Example::: Correct:: Inside "Process A": data type of $var is "char[20]". And Inside "Process B":
;				the data type of $var is "char[20]". Wrong:: Inside "Process A": data type of $var is "char[20]". And Inside "Process B":
;				the data type of $var is "char[19]".
;			 C) You will never change the varible normally. You do it only with  _SharedVar_Write(*)
;			 	declare the varibals
;			 D) The unique identifier of the variable will be the same in the other process.
;				Example::: Correct:: Inside "Process A": $var = 1. And Inside "Process B": $var = 1.
;				Wrong:: Inside "Process A": $var = 1. And Inside "Process B": $var = 2.
;			 E) If the value of the variable stored in C++ process,
;			 	make sure that no reallocation will occur!
;				If the value stored in Autoit process then it should be safe Because probably in autoit you don't
;				have option to paly with it enough to get reallocation.
;
;
; Syntax ........: _SharedVar_DeclareVar(Byref $Var[, $DataType = Default[, $Value = Default)
; Parameters ....: $Var                 - [in/out]
;                  $DataType            - [optional] The data type of the variable.
;
;				*** The data type must be EXACTLY the same in all processes (Read rule B )
;					If set to Default then it will be automatic according to the Value (If $Value set)
;
;                  $Value               - [optional] The Value to assign to the variable during the Declaration.
;										If set to Default then it will not assign any value
;
;
; Return values .: On Error: @Error set to the line number of the error.
; Author ........: gil900
; Link ..........: https://www.autoitscript.com/forum/topic/180616-_sharedvar-declare-shared-variables-between-2-or-more-process-directly-on-memory/
; Example .......: YES
; ===============================================================================================================================
Func _SharedVar_DeclareVar(ByRef $Var,$DataType = Default,$Value = Default)
	If $gg_sv_iActivePidIndex = -1 Then Return SetError(@ScriptLineNumber) ; You must first call to _SharedVar_SetTargetProcess or _SharedVar_SetNewTargetProcess before this
	If Not IsNumber($Var) Then Return SetError(@ScriptLineNumber) ; The Pointer identifier must be number only
	If $DataType = Default Then
		$DataType = 'int';VarGetType($Var)
		If $Value <> Default And IsString($Value) Then $DataType = 'char['&StringLen($Value)&']'
	EndIf

	If Not $gg_sv_iActivePidIndex Then

		; If the varible was not declared before then try to declare it (this check done only in Declaration Type A for a reason)
		If _ArraySearch($gg_Dec_vars,$var) >= 0 Then Return SetError(@ScriptLineNumber) ; The Pointer identifier already exist. You must use unique identifier.

		; Declaration Type A:


		; allocate memory -> get the pointer
		Assign($g_sv_stuctname&$Var,DllStructCreate($DataType),2)
		If @error Then Return SetError(@ScriptLineNumber)
		Local $pPointer = DllStructGetPtr(Eval($g_sv_stuctname&$Var))
		If @error Then Return SetError(@ScriptLineNumber)
		If $Value <> Default Then DllStructSetData(Eval($g_sv_stuctname&$Var),1,$Value)




		; Add the pointer and its pointer identifier to hidden GUI / memory address to make it readable from outside
		__SharedVar_DeclareVar_AddPointerData($Var,$pPointer)


		If $gg_sv_pPointer4vars_type Then
			DllStructSetData($gg_sv_pPointer4vars_struct,1,$gg_sv_sDeclaredVars) ; Write it in memory address
		Else ; $gg_sv_pPointer4vars_type = $SharedVar_PTR_MEM_ADDRESS_Mode
			_WinAPI_SetWindowText($gg_sv_pPointer4vars,$gg_sv_sDeclaredVars) ; Write it in hidden GUI
		EndIf

		; Add the var id for later processing
		_ArrayAdd($gg_Dec_vars,$var)

		; Rebuild the variable
		$Var = $g_sv_stuctname&$Var



	Else

		; Declaration Type B:

		Local $sTargetProVarData
		If $gg_sv_aOpenedPids[$gg_sv_iActivePidIndex][$gg_sv_aOpenedPids_ix_Ptr4VarsType] Then
			$sTargetProVarData = __SharedVar_GetInfoFromTargetProcess($gg_sv_iActivePidIndex)
		Else ; $gg_sv_aOpenedPids[$gg_sv_iActivePidIndex][$gg_sv_aOpenedPids_ix_Ptr4VarsType] = $SharedVar_PTR_MEM_ADDRESS_Mode
			; Get the *info from hidden gui
			$sTargetProVarData = _WinAPI_GetWindowText($gg_sv_aOpenedPids[$gg_sv_iActivePidIndex][$gg_sv_aOpenedPids_ix_Ptr4Vars])
		EndIf

		If @error Then Return SetError(@ScriptLineNumber)
		If Not $sTargetProVarData Or @error Then Return SetError(@ScriptLineNumber) ; The *target_process have no varibals so there is nothing to connect to
		$aTargetProVarData = __SharedVar_DeclareVar_GetInfoAsArray($sTargetProVarData)
		If @error Or Not $aTargetProVarData[0][0] Then Return SetError(@ScriptLineNumber) ; The *target_process have no varibals so there is nothing to connect to
		$Add = _ArraySearch($aTargetProVarData,$Var,1,$aTargetProVarData[0][0],0,0,1,$gg_sv_aPtrsA_ix_PtrId)
		If $Add <= 0 Then Return SetError(@ScriptLineNumber) ; The variable not found in *target_process -> *info

		; Rebuild the variable
		Local $aOutput[$gg_sv_aVar_imax]
		$aOutput[$gg_sv_aVar_ix_ptr] = $aTargetProVarData[$Add][$gg_sv_aPtrsA_ix_Ptr]
		$aOutput[$gg_sv_aVar_ix_DataType] = $DataType
		$aOutput[$gg_sv_aVar_ix_StructIn] = DllStructCreate($DataType)
		$aOutput[$gg_sv_aVar_ix_hDll] = $gg_sv_aOpenedPids[$gg_sv_iActivePidIndex][$gg_sv_aOpenedPids_ix_hDll]
		$aOutput[$gg_sv_aVar_ix_hProcess] = $gg_sv_aOpenedPids[$gg_sv_iActivePidIndex][$gg_sv_aOpenedPids_ix_hProcess]
		$Var = $aOutput
	EndIf
EndFunc





; #FUNCTION# ====================================================================================================================
; Name ..........: _SharedVar_CloseProcess
; Description ...: Close the memory handle of the process if memory handle create before.
;					(It create memory handle when you first use $haProcess in _SharedVar_SetDeclarationsInProcess )
;					English: When you should use this - you shluld use this when the *target_process is closed.
; Syntax ........: _SharedVar_CloseProcess($haProcess)
; Parameters ....: $haProcess           - A handle returned from _SharedVar_OpenProcess(*).
; Return values .: None
; Author ........: gil900
; ===============================================================================================================================
Func _SharedVar_CloseProcess($iPid)
	If Not $gg_sv_aOpenedPids[0][0] Then Return
	Local $iIndex = _ArraySearch($gg_sv_aOpenedPids,$iPid,1,$gg_sv_aOpenedPids[0][0],0,0,1,$gg_sv_aOpenedPids_ix_iPid)
	If $iIndex <= 0 Then Return
	DllCall($gg_sv_aOpenedPids[$iIndex][$gg_sv_aOpenedPids_ix_hDll], 'int', 'CloseHandle', 'int', $gg_sv_aOpenedPids[$iIndex][$gg_sv_aOpenedPids_ix_hProcess])
	DllClose($gg_sv_aOpenedPids[$iIndex][$gg_sv_aOpenedPids_ix_hDll])
	_ArrayDelete($gg_sv_aOpenedPids,$iIndex)
	$gg_sv_aOpenedPids[0][0] -= 1
	If $gg_sv_iActivePidIndex >= $iIndex Then $gg_sv_iActivePidIndex -= 1
EndFunc


#Region Internal Use

Func __SharedVar_DeclareVar_AddPointerData($PointerIdentifier,$Pointer)
	If Not $gg_sv_sDeclaredVars Then
		$gg_sv_sDeclaredVars = $PointerIdentifier & $gg_sv_sPlit_3 & '0x'&Hex($Pointer)
	Else
		$gg_sv_sDeclaredVars &= $gg_sv_sPlit_2 & $PointerIdentifier & $gg_sv_sPlit_3 & '0x'&Hex($Pointer)
	EndIf

EndFunc

Func __SharedVar_GetInfoFromTargetProcess($iIndex)
	Local $v_Buffer = DllStructCreate($gg_sv_pPointer4vars_struct_datatype)
	DllCall($gg_sv_aOpenedPids[$iIndex][$gg_sv_aOpenedPids_ix_hDll], 'int', 'ReadProcessMemory', 'int', _
			$gg_sv_aOpenedPids[$iIndex][$gg_sv_aOpenedPids_ix_hProcess], 'int', _
			$gg_sv_aOpenedPids[$iIndex][$gg_sv_aOpenedPids_ix_Ptr4Vars], 'ptr', _
			DllStructGetPtr($v_Buffer), 'int', DllStructGetSize($v_Buffer), 'int', '')
	If @Error Then Return SetError(@ScriptLineNumber)
	Local $sValue = DllStructGetData($v_Buffer, 1)
	If @Error Then Return SetError(@ScriptLineNumber)
	Return $sValue
EndFunc


Func __SharedVar_DeclareVar_GetInfoAsArray($sPointersData)
	$asPointersData = StringSplit($sPointersData,$gg_sv_sPlit_2,1)
	If Not $asPointersData[0] Then Return SetError(@ScriptLineNumber)
	Local $aOutput = __SharedVar_CreatePtrDataA($asPointersData[0]+1)
	Local $asPointersData2
	For $a = 1 To $asPointersData[0]
		$asPointersData2 = StringSplit($asPointersData[$a],$gg_sv_sPlit_3,1)
		If $asPointersData2[0] < 2 Then Return SetError(@ScriptLineNumber) ; Problem in reading the pointers data....
		$aOutput[$a][$gg_sv_aPtrsA_ix_PtrId] = $asPointersData2[1]
		$aOutput[$a][$gg_sv_aPtrsA_ix_Ptr] = $asPointersData2[2]
	Next
	Return $aOutput
EndFunc




Func __SharedVar_OnAutoItExit()
	If Not $gg_sv_aOpenedPids[0][0] Then Return
	For $a = 1 To $gg_sv_aOpenedPids[0][0]
		DllCall($gg_sv_aOpenedPids[$a][$gg_sv_aOpenedPids_ix_hDll], 'int', 'CloseHandle', 'int', $gg_sv_aOpenedPids[$a][$gg_sv_aOpenedPids_ix_hProcess])
		DllClose($gg_sv_aOpenedPids[$a][$gg_sv_aOpenedPids_ix_hDll])
	Next
EndFunc


Func __SharedVar_CreatePtrDataA($iSize = 1)
	Local $aOutput[$iSize][$gg_sv_aPtrsA_iMax] = [[$iSize-1]]
	Return $aOutput
EndFunc

#EndRegion
