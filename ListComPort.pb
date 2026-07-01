;{- Code Header
; ==- Basic Info -================================
;     Name: ListComPort.pb
;  Version: 4.0.0
;   Author: Herwin Bozet (NibblePoker)
;
; ==- Compatibility -=============================
;  Compiler version:
;    * PureBasic 5.73 LTS (x86/x64)
;    * PureBasic 6.0 LTS (x64)
;    * PureBasic 6.0 LTS - C Backend (x64)
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

XIncludeFile "./Includes/ListComPortLocales.pbi"
XIncludeFile "./Includes/ListComPortErrorCodes.pbi"

XIncludeFile "./Includes/ComPortHelper.pbi"

XIncludeFile "./Includes/PB-Win32-GetConsoleProcessList/Includes/Win32_GetConsoleProcessList.pbi"


; ------------------------------------------------------------------------------
;- Constants

#Version$ = "4.0.0"



; ------------------------------------------------------------------------------
;- Globals
Global ExitCode.i = #LSCOM_ErrorCode_NoError

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
Procedure PrintUsageText(PrintFull.b = #False)
    Define UsageText$
    
;     Restore UsageText
;     
;     Read.s UsageText$
;     PrintN(UsageText$)
;     
;     If PrintFull
;         Read.s UsageText$
;         PrintN(UsageText$)
;     EndIf
EndProcedure

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
;- App's code

;-> Setup

If Not OpenConsole("lscom")
    End #LSCOM_ErrorCode_NoTerminal
EndIf


;-> Parsing launch arguments
; I dropped the original "PB-Arguments" include to reduce runtime memory allocations.

Define IParam.i
For IParam = 0 To CountProgramParameters()
    Define CurrentParam$ = ProgramParameter(IParam)
    
    If Len(CurrentParam$) = 0
        Continue  
    EndIf
    
    If (PeekC(@CurrentParam$) <> '/' And PeekC(@CurrentParam$) <> '-') Or Len(CurrentParam$) <= 0
        ConsoleError("Unknown argument: '" + CurrentParam$ + "'")
        ExitCode = #LSCOM_ErrorCode_UnknownArgument
        PrintUsageText()
        Goto LSCOM_End
    EndIf
    
    If PeekC(@CurrentParam$) = '/' Or Left(CurrentParam$, 2) = "--"
        CurrentParam$ = UCase(LTrim(LTrim(CurrentParam$, "/"), "-"))
        
        Select CurrentParam$
            Case "?", "HELP"
                PrintUsageText(#True)
                Goto LSCOM_End
                
            Case "A", "SHOW-ALL"
                ShouldPrintDeviceNames = #True
                ShouldPrintFriendlyNames = #True
                ShouldPrintRawNames = #True
                
            Case "D", "SHOW-DEVICE"
                ShouldPrintDeviceNames = #True
                
            Case "F", "SHOW-FRIENDLY"
                ShouldPrintFriendlyNames = #True
                
            Case "N", "SHOW-NAME"
                ShouldPrintRawNames = #True
                
            Case "P", "NO-PRETTY"
                PaddingString$ = " "
                
            Case "DIVIDER"
                SortingOrder = ComPortHelper::#Sort_Order_Ascending
                
            Case "T", "TAB-PADDING"
                PaddingString$ = #TAB$
                
            Case "S", "SORT"
                SortingOrder = ComPortHelper::#Sort_Order_Ascending
                
            Case "SR", "SORT-REVERSE"
                SortingOrder = ComPortHelper::#Sort_Order_Descending
                
            Case "V", "VERSION"
                PrintN(#Version$)
                Goto LSCOM_End
                
            Default
                ConsoleError("Unknown argument: '" + CurrentParam$ + "'")
                ExitCode = #LSCOM_ErrorCode_UnknownArgument
                PrintUsageText()
                Goto LSCOM_End
        EndSelect
        
    ElseIf PeekC(@CurrentParam$) = '-' And Len(CurrentParam$) > 1
        Define IParamMaxSubIndex = Len(CurrentParam$) - 1
        Define IParamSubIndex = 1
        
        Select PeekC(@CurrentParam$ + IParamSubIndex)
            Case 'h'
                PrintUsageText(#True)
                Goto LSCOM_End
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
            Case 'd'
            Case 't'
                PaddingString$ = #TAB$
            Case 's'
                SortingOrder = ComPortHelper::#Sort_Order_Ascending
            Case 'S'
                SortingOrder = ComPortHelper::#Sort_Order_Descending
            Case 'v'
                PrintN(#Version$)
                Goto LSCOM_End
            Default
                ConsoleError("Unknown argument: '" + CurrentParam$ + "'")
                ExitCode = #LSCOM_ErrorCode_UnknownArgument
                PrintUsageText()
                Goto LSCOM_End
        EndSelect
        
    Else
        ConsoleError("Unknown argument: '" + CurrentParam$ + "'")
        ExitCode = #LSCOM_ErrorCode_UnknownArgument
        PrintUsageText()
        Goto LSCOM_End
    EndIf
    
    
    
    
    ; 			
    ; 			If *NoPrettyAscOption\WasUsed
    ; 				PaddingString$ = " "
    ; 			EndIf
    ; 			
    ; 			If *DividerCharOption\WasUsed
    ; 				If ListSize(*DividerCharOption\Arguments()) = 0
    ; 					ConsoleError(#LSCOM_Locale_ErrorExplaination_NoPaddingValue$)
    ; 					ExitCode = #LSCOM_ErrorCode_NoPaddingValue
    ; 				Else
    ; 					FirstElement(*DividerCharOption\Arguments())
    ; 					PaddingString$ = *DividerCharOption\Arguments()
    ; 				EndIf
    ; 			EndIf
    ; 			
    ; 			If *NameTabPaddingOption\WasUsed
    ; 				PaddingString$ = #TAB$
    ; 			EndIf
    
    LSCOM_ArgsLoop_End:
Next


; Procedure VerifyOption(*Option, OptionName$, *HasRegisteredArgumentsCorrectly)
;     If Not Arguments::RegisterOption(*Option)
;         ConsoleError(ReplaceString(#LSCOM_Locale_Error_ArgumentDefinitionFailure$, "%0", OptionName$))
;         Arguments::FreeOption(*Option)
;         PokeB(*HasRegisteredArgumentsCorrectly, #False)
;     EndIf
; EndProcedure

; If Arguments::Init()
;     Define HasRegisteredArgumentsCorrectly.b = #True
;     ;{
;     
;     If HasRegisteredArgumentsCorrectly
;         If Not Arguments::ParseArguments(0, CountProgramParameters())
;            
;             If *DividerCharOption\WasUsed
;                 If ListSize(*DividerCharOption\Arguments()) = 0
;                     ConsoleError(#LSCOM_Locale_ErrorExplaination_NoPaddingValue$)
;                     ExitCode = #LSCOM_ErrorCode_NoPaddingValue
;                 Else
;                     FirstElement(*DividerCharOption\Arguments())
;                     PaddingString$ = *DividerCharOption\Arguments()
;                 EndIf
;             EndIf
;             
;             If *NameTabPaddingOption\WasUsed
;                 PaddingString$ = #TAB$
;             EndIf
;         Else
;             ConsoleError(#LSCOM_Locale_ErrorExplaination_ArgumentParsingFailure$)
;             ExitCode = #LSCOM_ErrorCode_ArgumentParsingFailure
;         EndIf
;     Else
;         ConsoleError(#LSCOM_Locale_ErrorExplaination_ArgumentDefinitionFailure$)
;         ExitCode = #LSCOM_ErrorCode_ArgumentDefinitionFailure
;     EndIf
;     
;     ; Clearing the memory for the argument parser...
;     Arguments::Finish()
; Else
;     ConsoleError(#LSCOM_Locale_ErrorExplaination_ArgumentInitFailure$)
;     ExitCode = #LSCOM_ErrorCode_ArgumentInitFailure
; EndIf


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

If ComPortHelper::GetComPortAndDeviceNameLists(ComPortDeviceNames(), ComPortRawNames()) <> -1
    If ShouldPrintFriendlyNames
        If ComPortHelper::GetComPortMappedFriendlyName(ComPortRawNames(), ComPortFriendlyNames(), #True) = -1
            ConsoleError(#LSCOM_Locale_ErrorExplaination_NoFriendlyNames$)
            IsDoingFine = #False
            ExitCode = #LSCOM_ErrorCode_NoFriendlyNames
        EndIf
    EndIf
Else
    ConsoleError(#LSCOM_Locale_ErrorExplaination_NoComPorts$)
    IsDoingFine = #False
    ExitCode = #LSCOM_ErrorCode_NoComPorts
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



;-> Cleanup and end
LSCOM_End:
FreeMap(ComPortFriendlyNames())
FreeList(ComPortRawNames())
FreeList(ComPortDeviceNames())

If IsProgramRunDirectly()
    PrintN("Press enter to exit...")
    Input()
EndIf

End ExitCode
