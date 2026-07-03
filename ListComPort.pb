;{- Code Header
; ==- Basic Info -================================
;     Name: ListComPort.pb
;  Version: 4.0.0
;   Author: Herwin Bozet (NibblePoker)
;
; ==- Compatibility -=============================
;  Compiler version:
;    * PureBasic 5.73 LTS (x86/x64)
;    * PureBasic 6.0 LTS - C Backend (x64)
;    * PureBasic 6.21 (x86/x64)
;    * PureBasic 6.41 beta 2 (x64)
; 
; ==- Links & License -===========================
;  License: CC0 1.0 Universal (Public Domain)
;  GitHub: https://github.com/aziascreations/ListComPort
;}


; ------------------------------------------------------------------------------
;- Notes

; No notes currently available.


; ------------------------------------------------------------------------------
;- Compiler directive

EnableExplicit

CompilerIf #PB_Compiler_ExecutableFormat <> #PB_Compiler_Console
	CompilerError("this program needs to be compiled as a console application !")
CompilerEndIf

CompilerIf #PB_Compiler_OS <> #PB_OS_Windows
	CompilerError "This program can only be compiled for Windows !"
CompilerEndIf

XIncludeFile "./Includes/ComPortHelper.pbi"

XIncludeFile "./Includes/PB-Win32-GetConsoleProcessList/Includes/Win32_GetConsoleProcessList.pbi"



; ------------------------------------------------------------------------------
;- Constants

#Version$ = "4.0.0"



; ------------------------------------------------------------------------------
;- Enumerations

;-> Error Codes
Enumeration LSCOM_ErrorCodes
	#LSCOM_ErrorCode_NoError = 0
	
	; Fatal errors (1-9)
	#LSCOM_ErrorCode_NoTerminal = 1
	; 2 - NoRequiredWinApiFunction (Legacy Win32 API Import)
	
	; Arguments - Generalized errors (10-19)
	; 10 - ArgumentParsingFailure (Legacy PB-Arguments module)
	; 11 - DefinitionFailure      (Legacy PB-Arguments module)
	; 12 - ArgumentInitFailure    (Legacy PB-Arguments module)
	#LSCOM_ErrorCode_MalformedArgument = 13
	#LSCOM_ErrorCode_UnknownArgument = 14
	#LSCOM_ErrorCode_ArgumentWithValueNotTrailling = 15
	
	; Arguments - Specific errors (20-29)
	#LSCOM_ErrorCode_NoPaddingValue = 20
	
	; Application & System errors (30-39)
	#LSCOM_ErrorCode_NoFriendlyNames = 30
	#LSCOM_ErrorCode_NoComPorts = 31
EndEnumeration


;-> Localized strings IDs
Enumeration LSCOM_StringIds
	#LSCOM_Locale_Usage_Text = 1000
	#LSCOM_Locale_Usage_Remarks = 1010
	#LSCOM_Locale_Usage_Fornatting_0 = 1020
	#LSCOM_Locale_Usage_Fornatting_1 = 1021
	#LSCOM_Locale_Usage_Fornatting_2 = 1022
	#LSCOM_Locale_Usage_Fornatting_3 = 1023
	#LSCOM_Locale_Usage_Fornatting_4 = 1024
	
	#LSCOM_Locale_Text_PressAnyKeyToContinue = 2000
	
	#LSCOM_Locale_Error_MalformedArgument = 5000
	#LSCOM_Locale_Error_UnknownArgument = 5001
	#LSCOM_Locale_Error_NoComPorts = 5002
	#LSCOM_Locale_Error_NoFriendlyNames = 5003
	#LSCOM_Locale_Error_NoPaddingValue = 5004
	#LSCOM_Locale_Error_ArgumentWithValueNotTrailling = 5005
EndEnumeration


; ------------------------------------------------------------------------------
;- Globals
Global ErrorCode.i = #LSCOM_ErrorCode_NoError

; Arguments
Global ShouldPrintRawNames.b = #False
Global ShouldPrintDeviceNames.b = #False
Global ShouldPrintFriendlyNames.b = #False
Global SortingOrder.b = ComPortHelper::#Sort_Order_None
Global PaddingString$ = #Null$

; Main loop globals
Global IsDoingFine.b = #True
Global RawToFriendlySeparator$ = " - "
Global UseDeviceBrackets.b = #True

Global NewList ComPortDeviceNames.s()
Global NewList ComPortRawNames.s()

; May not be used depending on the options used.
Global NewMap ComPortFriendlyNames.s()



; ------------------------------------------------------------------------------
;- Procedures

; Checks if the current process was started via another process (CMD), or not.
Procedure.b IsProgramRunDirectly()
	; Will act as a DWORD[2]
	Define ProcessListBuffer.q
	ProcedureReturn Bool(GetConsoleProcessList_(@ProcessListBuffer, 2) <= 1)
EndProcedure

Procedure.s LoadString(StringId.i, MaxLength.i = 4098)
	; Resource strings are limited to a maximum of 4097 characters
	; See: https://learn.microsoft.com/en-us/windows/win32/menurc/stringtable-resource
	; Source: https://github.com/aziascreations/PB-Win32-Internationalization
	If MaxLength > 4098
		DebuggerWarning("LoadString was given a MaxLength bigger than 4098 !")
		MaxLength = 4098
	EndIf
	
	Protected *Buffer = AllocateMemory((MaxLength + 1) * SizeOf(Character))
	Protected Result$ = #Null$
	
	If *Buffer
		If LoadString_(GetModuleHandle_(#Null), StringId, *Buffer, MaxLength)
			Result$ = PeekS(*Buffer, MaxLength, #PB_Unicode)
		Else
			; See: https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes
			DebuggerWarning("LoadString failed for " + Str(StringId) + " - Error " + Str(GetLastError_()))
		EndIf
		FreeMemory(*Buffer)
	Else
		DebuggerWarning("LoadString failed to allocate memory for its internal buffer !")
	EndIf
	
	ProcedureReturn Result$
EndProcedure



; ------------------------------------------------------------------------------
;- SubRoutines

Procedure ExitProgram()
	FreeMap(ComPortFriendlyNames())
	FreeList(ComPortRawNames())
	FreeList(ComPortDeviceNames())
	
	If IsProgramRunDirectly()
		PrintN(LoadString(#LSCOM_Locale_Text_PressAnyKeyToContinue))
		Input()
	EndIf
	
	End ErrorCode
EndProcedure

Procedure PrintUsageText(PrintFull.b = #False)
	PrintN(LoadString(#LSCOM_Locale_Usage_Text))
	
	If PrintFull
		PrintN(LoadString(#LSCOM_Locale_Usage_Remarks))
		
		PrintN(LoadString(#LSCOM_Locale_Usage_Fornatting_0))
		PrintN(LoadString(#LSCOM_Locale_Usage_Fornatting_1))
		PrintN(LoadString(#LSCOM_Locale_Usage_Fornatting_2))
		PrintN(LoadString(#LSCOM_Locale_Usage_Fornatting_3))
		PrintN(LoadString(#LSCOM_Locale_Usage_Fornatting_4))
	EndIf
EndProcedure



; ------------------------------------------------------------------------------
;- App's code

;-> Setup

If Not OpenConsole("lscom")
	End #LSCOM_ErrorCode_NoTerminal
EndIf


;-> Parsing launch arguments
; I dropped the original "PB-Arguments" include to reduce runtime memory allocations.

Debug "Parsing launch arguments..."

Define IParamMax.i = CountProgramParameters() - 1
Debug "IParamMax: " + Str(IParamMax)

Define IParam.i
For IParam = 0 To CountProgramParameters()
	Define CurrentParam$ = ProgramParameter(IParam)
	
	Debug "-> CurrentParam$: `" + CurrentParam$ + "`"
	Debug "--> IParam: " + Str(IParam)
	Debug "--> Len: " + Str(Len(CurrentParam$))
	
	If Len(CurrentParam$) = 0
		Continue  
	EndIf
	
	Debug "--> PeekC: " + Chr(PeekC(@CurrentParam$))
	
	If (PeekC(@CurrentParam$) <> '/' And PeekC(@CurrentParam$) <> '-') Or Len(CurrentParam$) <= 0
		Debug "--> Its malformed"
		ConsoleError(ReplaceString(LoadString(#LSCOM_Locale_Error_MalformedArgument), "{0}", CurrentParam$))
		ErrorCode = #LSCOM_ErrorCode_MalformedArgument
		PrintUsageText()
		ExitProgram()
	EndIf
	
	If PeekC(@CurrentParam$) = '/' Or Left(CurrentParam$, 2) = "--"
		Debug "--> Long argument"
		
		CurrentParam$ = UCase(LTrim(LTrim(CurrentParam$, "/"), "-"))
		
		Select CurrentParam$
			Case "?", "HELP"
				PrintUsageText(#True)
				ExitProgram()
				
			Case "SHOW-ALL", "SHOWALL"
				ShouldPrintDeviceNames = #True
				ShouldPrintFriendlyNames = #True
				ShouldPrintRawNames = #True
				
			Case "SHOW-DEVICE", "SHOWDEVICE"
				ShouldPrintDeviceNames = #True
				
			Case "SHOW-FRIENDLY", "SHOWFRIENDLY"
				ShouldPrintFriendlyNames = #True
				
			Case "SHOW-NAME", "SHOWNAME"
				ShouldPrintRawNames = #True
				
			Case "NO-PRETTY", "NOPRETTY"
				PaddingString$ = " "
				
			Case "DIVIDER"
				; #LSCOM_ErrorCode_ArgumentWithValueNotTrailling
				If IParam >= IParamMax
					Debug "--> Last argument requires an OOB value"
					ConsoleError(LoadString(#LSCOM_Locale_Error_NoPaddingValue))
					ErrorCode = #LSCOM_ErrorCode_NoPaddingValue
					PrintUsageText()
					ExitProgram()
				EndIf
				
				IParam = IParam + 1
				PaddingString$ = ProgramParameter(IParam)
				Continue
				
			Case "TAB-PADDING", "TABPADDING"
				PaddingString$ = #TAB$
				
			Case "SORT"
				SortingOrder = ComPortHelper::#Sort_Order_Ascending
				
			Case "SORT-REVERSE", "SORTREVERSE"
				SortingOrder = ComPortHelper::#Sort_Order_Descending
				
			Case "V", "VERSION"
				PrintN(#Version$)
				ExitProgram()
				
			Default
				Debug "--> Its unknown"
				ConsoleError(ReplaceString(LoadString(#LSCOM_Locale_Error_UnknownArgument), "{0}", CurrentParam$))
				ErrorCode = #LSCOM_ErrorCode_UnknownArgument
				PrintUsageText()
				ExitProgram()
		EndSelect
		
	ElseIf PeekC(@CurrentParam$) = '-' And Len(CurrentParam$) > 1
		Debug "--> Short argument(s)"
		
		Define IParamMaxSubIndex = Len(CurrentParam$) - 1
		Define IParamSubIndex = 1
		
		Debug "---> IParamMaxSubIndex: " + Str(IParamMaxSubIndex)
		
		While IParamSubIndex < Len(CurrentParam$)
			Debug "---> CurrentParam$[" + Str(IParamSubIndex) + "]: " + Chr(PeekC(@CurrentParam$ + (IParamSubIndex * SizeOf(Character))))
			
			Select PeekC(@CurrentParam$ + (IParamSubIndex * SizeOf(Character)))
				Case 'h'
					PrintUsageText(#True)
					ExitProgram()
				Case 'a'
					ShouldPrintDeviceNames = #True
					ShouldPrintFriendlyNames = #True
					ShouldPrintRawNames = #True
				Case 'd'
					ShouldPrintDeviceNames = #True
				Case 'f'
					ShouldPrintFriendlyNames = #True
				Case 'n'
					ShouldPrintFriendlyNames = #True
				Case 'P'
					PaddingString$ = " "
				Case 'D'
					If IParamSubIndex <> IParamMaxSubIndex
						Debug "-----> The `-D` short option isn't at the end !"
						ConsoleError(ReplaceString(LoadString(#LSCOM_Locale_Error_ArgumentWithValueNotTrailling),
						                           "{0}",
						                           Chr(PeekC(@CurrentParam$ + (IParamSubIndex * SizeOf(Character))))))
						ErrorCode = #LSCOM_ErrorCode_ArgumentWithValueNotTrailling
						ExitProgram()
					EndIf
					
					If IParam >= IParamMax
						Debug "--> Last argument requires an OOB value"
						ConsoleError(LoadString(#LSCOM_Locale_Error_NoPaddingValue))
						ErrorCode = #LSCOM_ErrorCode_NoPaddingValue
						PrintUsageText()
						ExitProgram()
					EndIf
				
					IParam = IParam + 1
					PaddingString$ = ProgramParameter(IParam)
					Break
					
				Case 't'
					PaddingString$ = #TAB$
				Case 's'
					SortingOrder = ComPortHelper::#Sort_Order_Ascending
				Case 'S'
					SortingOrder = ComPortHelper::#Sort_Order_Descending
				Case 'v'
					PrintN(#Version$)
					ExitProgram()
				Default
					Debug "--> Its unknown"
					ConsoleError(ReplaceString(LoadString(#LSCOM_Locale_Error_UnknownArgument), "{0}", CurrentParam$))
					ErrorCode = #LSCOM_ErrorCode_UnknownArgument
					PrintUsageText()
					ExitProgram()
			EndSelect
			IParamSubIndex = IParamSubIndex + 1
		Wend
	Else
		Debug "--> Its unknown"
		ConsoleError(ReplaceString(LoadString(#LSCOM_Locale_Error_UnknownArgument), "{0}", CurrentParam$))
		ErrorCode = #LSCOM_ErrorCode_UnknownArgument
		PrintUsageText()
		ExitProgram()
	EndIf
Next


;-> Post-processing launch arguments

If  ShouldPrintRawNames = #False And ShouldPrintDeviceNames.b = #False And ShouldPrintFriendlyNames.b = #False
	ShouldPrintRawNames = #True
EndIf

If PaddingString$ = #Null$
	; No custom padding char was used
	PaddingString$ = " "
Else
	; Custom padding char was used
	RawToFriendlySeparator$ = PaddingString$
	UseDeviceBrackets = #False
EndIf


;-> Listing ports
; FIXME: Consumes a full megabyte for 3 ports !!! - WTF
If ComPortHelper::GetComPortAndDeviceNameLists(ComPortDeviceNames(), ComPortRawNames()) <> -1
	If ShouldPrintFriendlyNames
		If ComPortHelper::GetComPortMappedFriendlyName(ComPortRawNames(), ComPortFriendlyNames(), #True) = -1
			ConsoleError(LoadString(#LSCOM_Locale_Error_NoFriendlyNames))
			IsDoingFine = #False
			ErrorCode = #LSCOM_ErrorCode_NoFriendlyNames
		EndIf
	EndIf
Else
	ConsoleError(LoadString(#LSCOM_Locale_Error_NoComPorts))
	IsDoingFine = #False
	ErrorCode = #LSCOM_ErrorCode_NoComPorts
EndIf


If IsDoingFine
	ComPortHelper::SortDeviceAndRawNameLists(ComPortDeviceNames(), ComPortRawNames(), SortingOrder)
	
	ForEach ComPortRawNames()
		If ShouldPrintRawNames
			Print(ComPortRawNames())
			
			If ShouldPrintFriendlyNames
				Print(RawToFriendlySeparator$+ComPortFriendlyNames(ComPortRawNames()))
			EndIf
			
			If ShouldPrintDeviceNames
				SelectElement(ComPortDeviceNames(), ListIndex(ComPortRawNames()))
				
				If UseDeviceBrackets
					PrintN(PaddingString$+"["+ComPortDeviceNames()+"]")
				Else
					PrintN(PaddingString$+ComPortDeviceNames())
				EndIf
			Else
				Print(#CRLF$)
			EndIf
		Else
			If ShouldPrintFriendlyNames
				Print(ComPortFriendlyNames(ComPortRawNames()))
				If ShouldPrintDeviceNames
					SelectElement(ComPortDeviceNames(), ListIndex(ComPortRawNames()))
					
					If UseDeviceBrackets
						PrintN(PaddingString$+"["+ComPortDeviceNames()+"]")
					Else
						PrintN(PaddingString$+ComPortDeviceNames())
					EndIf
				Else
					Print(#CRLF$)
				EndIf
			Else
				SelectElement(ComPortDeviceNames(), ListIndex(ComPortRawNames()))
				PrintN(ComPortDeviceNames())
			EndIf
		EndIf
	Next
EndIf


;-> Exit
ExitProgram()
