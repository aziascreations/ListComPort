;{- Code Header
; ==- Basic Info -================================
;         Name: RegistryHelper.pbi
;      Version: 1.0.1
;       Author: Herwin Bozet
;
; ==- Compatibility -=============================
;  Compiler version: PureBasic 5.70 (x86/x64)
;  Operating system: Windows 10 21H1 (Previous versions untested)
; 
; ==- Links & License -===========================
;  License: Unlicense
;}


; ------------------------------------------------------------------------------
;- Compiler Directives

EnableExplicit

XIncludeFile "./WinTypes.pbi"

CompilerIf Not #PB_Compiler_OS = #PB_OS_Windows
	CompilerError "Includes is intended to be used on Windows platforms only !"
CompilerEndIf



; ------------------------------------------------------------------------------
;- Module Declaration

DeclareModule RegistryHelper
	;-> Semver Data
	
	#Version_Major = 1
	#Version_Minor = 0
	#Version_Patch = 1
	#Version_Label$ = ""
	#Version$ = "1.0.1";+"-"+#Version_Label$
	
	
	;-> Constants
	
	CompilerIf Not Defined(HKEY_PERFORMANCE_TEXT, #PB_Constant)
		#HKEY_PERFORMANCE_TEXT = $80000050
	CompilerEndIf
	
	; Not used
	CompilerIf Not Defined(HKEY_PERFORMANCE_NLSTEXT, #PB_Constant)
		#HKEY_PERFORMANCE_NLSTEXT = $80000060
	CompilerEndIf
	
	; https://docs.microsoft.com/en-us/windows/win32/sysinfo/registry-element-size-limits
	#Size_KeyName = 255
	#Size_ValueName = 16383
	#Size_ValueData_Standard = 1048576
	
	; Used to prevent infinite loops
	#Failsafe_MaxValueCount = 65536
	
	
	;-> Procedure Declaration
	
	Declare.WinTypes::HKEY DetectRootKey(RegistryKey$)
	Declare.s GetRootKeyName(RootKey.WinTypes::HKEY)
	Declare.s TrimRootKey(RegistryKey$)
	
	Declare.WinTypes::HKEY _OpenReadingKey(RootKey, SubKey$)
	Declare.WinTypes::HKEY OpenReadingKey(SubKey$)
	Declare.b CloseReadingKey(Key.WinTypes::HKEY)
	
	Declare.b _KeyExists(RootKey.WinTypes::HKEY, SubKey$)
	Declare.b KeyExists(SubKey$)
	
	; TODO: Value exists
	
	Declare.i _GetSubKeys(RootKey, SubKey$, List SubKeys.s(), PrependRootKey.b = #False, PrependSubKey.b = #False)
	Declare.i GetSubKeys(SubKey$, List SubKeys.s(), PrependRootKey.b = #False, PrependSubKey.b = #False)
	
	Declare.i _GetKeyValuePairAsLists(RootKey, SubKey$, List ValueNames.s(), List Values.s())
	Declare.i GetKeyValuePairAsLists(SubKey$, List ValueNames.s(), List Values.s())
	
	Declare.i _GetKeyValuePairAsMap(RootKey, SubKey$, Map ValueNamePair.s())
	Declare.i GetKeyValuePairAsMap(SubKey$, Map ValueNamePair.s())
	
	Declare.i _GetKeyValueNames(RootKey, SubKey$, List ValueNames.s())
	Declare.i GetKeyValueNames(SubKey$, List ValueNames.s())
	
	Declare.i _GetKeyValues(RootKey, SubKey$, List Values.s())
	Declare.i GetKeyValues(SubKey$, List Values.s())
	
	Declare.s _GetValue(RootKey, SubKey$, ValueName$, DataType.WinTypes::DWORD = #Null)
	Declare.s GetValue(SubKey$, ValueName$, DataType.WinTypes::DWORD = #Null)
	
	Declare.b _ValueExists(RootKey, SubKey$, ValueName$, DataType.WinTypes::DWORD = #Null)
	Declare.b ValueExists(SubKey$, ValueName$, DataType.WinTypes::DWORD = #Null)
EndDeclareModule



; ------------------------------------------------------------------------------
;- Module Definition

Module RegistryHelper
	;-> Compiler Directives
	
	EnableExplicit
	
	
	;-> Procedure Definition
	
	Procedure.WinTypes::HKEY DetectRootKey(RegistryKey$)
		Protected KeyRootElement$ = UCase(StringField(RegistryKey$, 1, "\"))
		
		Select KeyRootElement$
			Case "HKEY_CLASSES_ROOT"
				ProcedureReturn #HKEY_CLASSES_ROOT
			Case "HKEY_CURRENT_CONFIG"
				ProcedureReturn #HKEY_CURRENT_CONFIG
			Case "HKEY_CURRENT_USER"
				ProcedureReturn #HKEY_CURRENT_USER
			Case "HKEY_LOCAL_MACHINE"
				ProcedureReturn #HKEY_LOCAL_MACHINE
			Case "HKEY_USERS"
				ProcedureReturn #HKEY_USERS
		EndSelect
		
		ProcedureReturn #Null
	EndProcedure
	
	Procedure.s GetRootKeyName(RootKey.WinTypes::HKEY)
		Select RootKey
			Case #HKEY_CLASSES_ROOT
				ProcedureReturn "HKEY_CLASSES_ROOT"
			Case #HKEY_CURRENT_CONFIG
				ProcedureReturn "HKEY_CURRENT_CONFIG"
			Case #HKEY_CURRENT_USER
				ProcedureReturn "HKEY_CURRENT_USER"
			Case #HKEY_LOCAL_MACHINE
				ProcedureReturn "HKEY_LOCAL_MACHINE"
			Case #HKEY_USERS
				ProcedureReturn "HKEY_USERS"
		EndSelect
		
		ProcedureReturn #Null$
	EndProcedure
	
	Procedure.s TrimRootKey(RegistryKey$)
		ProcedureReturn Mid(RegistryKey$, FindString(RegistryKey$, "\", 2) + 1)
	EndProcedure
	
	Procedure.WinTypes::HKEY _OpenReadingKey(RootKey, SubKey$)
		Protected RegistryHandle.WinTypes::HKEY = #Null
		
		If RootKey <> #Null
			If RegOpenKeyEx_(RootKey, SubKey$, 0, #KEY_READ, @RegistryHandle) <> #ERROR_SUCCESS
				Debug "Failed to find or open '"+SubKey$+"' !"
			EndIf
		EndIf
		
		ProcedureReturn RegistryHandle
	EndProcedure
	
	Procedure.WinTypes::HKEY OpenReadingKey(SubKey$)
		ProcedureReturn _OpenReadingKey(DetectRootKey(SubKey$), TrimRootKey(SubKey$))
	EndProcedure
	
	Procedure.b CloseReadingKey(Key.WinTypes::HKEY)
		CloseHandle_(Key)
	EndProcedure
	
	Procedure.b _KeyExists(RootKey.WinTypes::HKEY, SubKey$)
		Protected RegistryHandle.WinTypes::HKEY
		
		If RootKey <> #Null
			If RegOpenKeyEx_(RootKey, SubKey$, 0, #KEY_READ, @RegistryHandle) = #ERROR_SUCCESS
				CloseHandle_(RegistryHandle)
				ProcedureReturn #True
			EndIf
		EndIf
		
		ProcedureReturn #False
	EndProcedure
	
	Procedure.b KeyExists(SubKey$)
		ProcedureReturn _KeyExists(DetectRootKey(SubKey$), TrimRootKey(SubKey$))
	EndProcedure
	
	Procedure.i _GetSubKeys(RootKey, SubKey$, List SubKeys.s(), PrependRootKey.b = #False, PrependSubKey.b = #False)
		Protected RegistryHandle.WinTypes::HKEY
		
		If RootKey = #Null
			Debug "Null 'RootKey' was given in '_GetSubKeys()' !"
			ProcedureReturn -1
		EndIf
		
		If RegOpenKeyEx_(RootKey, SubKey$, 0, #KEY_READ, @RegistryHandle) <> #ERROR_SUCCESS
			Debug "Failed to find or open the '"+SubKey$+"' subkey !"
			ProcedureReturn -1
		EndIf
		
		Protected *KeyStringBuffer = AllocateMemory(#Size_KeyName + 1)
		Protected KeyStringSize.i = #Size_KeyName
		
		If Not *KeyStringBuffer
			DebuggerError("Failed to allocate memory !")
			RegCloseKey_(RegistryHandle)
			ProcedureReturn -1
		EndIf
		
		Protected ReturnedValue.i = 0
		Protected i.i = 0
		
		Repeat
			If i > 0
				KeyStringSize = #Size_KeyName
				FillMemory(*KeyStringBuffer, #Size_KeyName + 1)
			EndIf
			
			ReturnedValue = RegEnumKeyEx_(RegistryHandle, i, *KeyStringBuffer, @KeyStringSize, #Null, #Null, #Null, #Null)
			
			If ReturnedValue = #ERROR_SUCCESS
				Protected FinalValue.s = PeekS(*KeyStringBuffer, #Size_KeyName)
				
				If PrependRootKey
					FinalValue = GetRootKeyName(RootKey) + "\" + SubKey$ + "\" + FinalValue
				ElseIf PrependSubKey
					FinalValue = SubKey$ + "\" + FinalValue
				EndIf
				
				AddElement(SubKeys())
				SubKeys() = FinalValue
			ElseIf ReturnedValue = #ERROR_MORE_DATA
				Debug "Not enough space error !"
			EndIf
			
			i = i + 1
		Until ReturnedValue = #ERROR_NO_MORE_ITEMS
		
		FreeMemory(*KeyStringBuffer)
		RegCloseKey_(RegistryHandle)
		
		ProcedureReturn ListSize(SubKeys())
	EndProcedure
	
	Procedure.i GetSubKeys(SubKey$, List SubKeys.s(), PrependRootKey.b = #False, PrependSubKey.b = #False)
		ProcedureReturn _GetSubKeys(DetectRootKey(SubKey$), TrimRootKey(SubKey$), SubKeys(), PrependRootKey, PrependSubKey)
	EndProcedure
	
	
	Procedure.i _GetKeyValuePairAsLists(RootKey, SubKey$, List ValueNames.s(), List Values.s())
		Protected RegistryHandle.WinTypes::HKEY = _OpenReadingKey(RootKey, SubKey$)
		
		If Not RegistryHandle
			Debug "Failed to open '"+SubKey$+"' !"
			ProcedureReturn -1
		EndIf
		
		Protected *ValueNameBuffer = AllocateMemory(#Size_ValueName+1)
		Protected ValueNameSize.i = #Size_ValueName
		
		If Not *ValueNameBuffer
			DebuggerError("Failed to allocate memory !")
			CloseReadingKey(RegistryHandle)
			ProcedureReturn -1
		EndIf
		
		; NOTE: Allocates a lot of RAM, but it only does so once !
		Protected *ValueDataBuffer = AllocateMemory(#Size_ValueData_Standard)
		Protected ValueDataSize.i = #Size_ValueData_Standard
		
		If Not *ValueDataBuffer
			DebuggerError("Failed to allocate memory !")
			FreeMemory(*ValueNameBuffer)
			CloseReadingKey(RegistryHandle)
			ProcedureReturn -1
		EndIf
		
		Protected i.i
		
		For i=0 To #Failsafe_MaxValueCount
			Protected ReturnedValue.i = 0
			
			If i > 0
				FillMemory(*ValueNameBuffer, #Size_ValueName+1)
				FillMemory(*ValueDataBuffer, #Size_ValueData_Standard)
			EndIf
			
			ValueNameSize = #Size_ValueName
			ValueDataSize = #Size_ValueData_Standard
			ReturnedValue = RegEnumValue_(RegistryHandle, i, *ValueNameBuffer, @ValueNameSize,
			                              #Null, #Null, *ValueDataBuffer, @ValueDataSize)
			
			If ReturnedValue = #ERROR_NO_MORE_ITEMS
				Break
			Else ; Implies #ERROR_SUCCESS or #ERROR_MORE_DATA
				Debug "> "+PeekS(*ValueNameBuffer, #Size_ValueName)+" #> "+PeekS(*ValueDataBuffer, #Size_ValueData_Standard)
				
				AddElement(ValueNames())
				ValueNames() = PeekS(*ValueNameBuffer, #Size_ValueName)
				
				AddElement(Values())
				Values() = PeekS(*ValueDataBuffer, #Size_ValueData_Standard)
				;ComPortDeviceNames(PeekS(*ValueStringBuffer, #Data_Buffer_Size)) = PeekS(*KeyStringBuffer, #Name_Buffer_Size)
			EndIf
		Next
		
		FreeMemory(*ValueDataBuffer)
		FreeMemory(*ValueNameBuffer)
		CloseReadingKey(RegistryHandle)
		ProcedureReturn ListSize(ValueNames())
	EndProcedure
	
	Procedure.i GetKeyValuePairAsLists(SubKey$, List ValueNames.s(), List Values.s())
		ProcedureReturn _GetKeyValuePairAsLists(DetectRootKey(SubKey$), TrimRootKey(SubKey$), ValueNames(), Values())
	EndProcedure
	
	
	Procedure.i _GetKeyValuePairAsMap(RootKey, SubKey$, Map ValueNamePair.s())
		Protected RegistryHandle.WinTypes::HKEY = _OpenReadingKey(RootKey, SubKey$)
		
		If Not RegistryHandle
			Debug "Failed to open '"+SubKey$+"' !"
			ProcedureReturn -1
		EndIf
		
		Protected *ValueNameBuffer = AllocateMemory(#Size_ValueName+1)
		Protected ValueNameSize.i = #Size_ValueName
		
		If Not *ValueNameBuffer
			DebuggerError("Failed to allocate memory !")
			CloseReadingKey(RegistryHandle)
			ProcedureReturn -1
		EndIf
		
		; NOTE: Allocates a lot of RAM, but it only does so once !
		Protected *ValueDataBuffer = AllocateMemory(#Size_ValueData_Standard)
		Protected ValueDataSize.i = #Size_ValueData_Standard
		
		If Not *ValueDataBuffer
			DebuggerError("Failed to allocate memory !")
			FreeMemory(*ValueNameBuffer)
			CloseReadingKey(RegistryHandle)
			ProcedureReturn -1
		EndIf
		
		Protected i.i
		
		For i=0 To #Failsafe_MaxValueCount
			Protected ReturnedValue.i = 0
			
			If i > 0
				FillMemory(*ValueNameBuffer, #Size_ValueName+1)
				FillMemory(*ValueDataBuffer, #Size_ValueData_Standard)
			EndIf
			
			ValueNameSize = #Size_ValueName
			ValueDataSize = #Size_ValueData_Standard
			ReturnedValue = RegEnumValue_(RegistryHandle, i, *ValueNameBuffer, @ValueNameSize,
			                              #Null, #Null, *ValueDataBuffer, @ValueDataSize)
			
			If ReturnedValue = #ERROR_NO_MORE_ITEMS
				Break
			Else ; Implies #ERROR_SUCCESS or #ERROR_MORE_DATA
				Debug "> "+PeekS(*ValueNameBuffer, #Size_ValueName)+" #> "+PeekS(*ValueDataBuffer, #Size_ValueData_Standard)
				
				ValueNamePair(PeekS(*ValueNameBuffer, #Size_ValueName)) = PeekS(*ValueDataBuffer, #Size_ValueData_Standard)
			EndIf
		Next
		
		FreeMemory(*ValueDataBuffer)
		FreeMemory(*ValueNameBuffer)
		CloseReadingKey(RegistryHandle)
		ProcedureReturn MapSize(ValueNamePair())
	EndProcedure
	
	Procedure.i GetKeyValuePairAsMap(SubKey$, Map ValueNamePair.s())
		ProcedureReturn _GetKeyValuePairAsMap(DetectRootKey(SubKey$), TrimRootKey(SubKey$), ValueNamePair())
	EndProcedure
	
	Procedure.i _GetKeyValueNames(RootKey, SubKey$, List ValueNames.s())
		Protected NewList TemporaryValueData.s()
		Protected ReturnedValue.i
		
		ReturnedValue = _GetKeyValuePairAsLists(RootKey, SubKey$, ValueNames(), TemporaryValueData())
		FreeList(TemporaryValueData())
		
		ProcedureReturn ReturnedValue
	EndProcedure
	
	Procedure.i GetKeyValueNames(SubKey$, List ValueNames.s())
		ProcedureReturn _GetKeyValueNames(DetectRootKey(SubKey$), TrimRootKey(SubKey$), ValueNames())
	EndProcedure
	
	Procedure.i _GetKeyValues(RootKey, SubKey$, List Values.s())
		Protected NewList TemporaryValueNames.s()
		Protected ReturnedValue.i
		
		ReturnedValue = _GetKeyValuePairAsLists(RootKey, SubKey$, TemporaryValueNames(), Values())
		FreeList(TemporaryValueNames())
		
		ProcedureReturn ReturnedValue
	EndProcedure
	
	Procedure.i GetKeyValues(SubKey$, List Values.s())
		ProcedureReturn _GetKeyValues(DetectRootKey(SubKey$), TrimRootKey(SubKey$), Values())
	EndProcedure
	
	Procedure.s _GetValue(RootKey, SubKey$, ValueName$, DataType.WinTypes::DWORD = #Null)
		Protected RegistryHandle.WinTypes::HKEY = _OpenReadingKey(RootKey, SubKey$)
		Protected ReturnValue.s = #Null$
		
		If Not RegistryHandle
			Debug "Failed to open '"+SubKey$+"' !"
			ProcedureReturn #Null$
		EndIf
		
		; Getting the actual size instead of allocating 1M directly (#Size_ValueData_Standard)
		Protected NeededSize.i = 0
		RegQueryValueEx_(RegistryHandle, ValueName$, #Null, @DataType, #Null, @NeededSize)
		
		Protected *ValueDataBuffer = AllocateMemory(NeededSize + 1)
		
		If Not *ValueDataBuffer
			DebuggerError("Failed to allocate memory !")
			FreeMemory(*ValueDataBuffer)
			CloseReadingKey(RegistryHandle)
			ProcedureReturn #Null$
		EndIf
		
		If RegQueryValueEx_(RegistryHandle, ValueName$, #Null, @DataType, *ValueDataBuffer, @NeededSize) = #ERROR_SUCCESS
			ReturnValue = PeekS(*ValueDataBuffer, NeededSize + 1)
		EndIf
		
		FreeMemory(*ValueDataBuffer)
		CloseReadingKey(RegistryHandle)
		
		ProcedureReturn ReturnValue
	EndProcedure
	
	Procedure.s GetValue(SubKey$, ValueName$, DataType.WinTypes::DWORD = #Null)
		ProcedureReturn _GetValue(DetectRootKey(SubKey$), TrimRootKey(SubKey$), ValueName$, DataType)
	EndProcedure
	
	Procedure.b _ValueExists(RootKey, SubKey$, ValueName$, DataType.WinTypes::DWORD = #Null)
		ProcedureReturn Bool(_GetValue(RootKey, SubKey$, ValueName$, DataType) <> #Null$)
	EndProcedure
	
	Procedure.b ValueExists(SubKey$, ValueName$, DataType.WinTypes::DWORD = #Null)
		ProcedureReturn _ValueExists(DetectRootKey(SubKey$), TrimRootKey(SubKey$), ValueName$, DataType)
	EndProcedure
EndModule
