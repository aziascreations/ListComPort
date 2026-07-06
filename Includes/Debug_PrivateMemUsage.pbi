;{- Code Header
; ==- Basic Info -================================
;     Name: Debug_PrivateMemUsage.pbi
;  Version: 0.0.1
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
; 
; ==- Notes -=====================================
;  This include is more basic and unploished on purpose
;   since you should only be using it when debugging
;   memory-related issues.
;}

EnableExplicit


CompilerIf Not Defined(NP_PrivateMemPrintEnable, #PB_Constant)
    Debug "Defining #NP_PrivateMemPrintEnable as `0` !"
    #NP_PrivateMemPrintEnable = 0
CompilerEndIf

CompilerIf #NP_PrivateMemPrintEnable <> 0
    Global BaselinePrivateMem.i = 0
    
    Global HighestPrivateMem.i = 0
    
    CompilerIf SizeOf(Integer) > 4
        Global LowestPrivateMem.i = 9223372036854775807
    CompilerElse
        Global LowestPrivateMem.i = 2147483647
    CompilerEndIf
    
    ; Not working on PB 5.x, and I don't want to point to the Windows SDK
    ; ImportC "psapi.lib"
    ;     GetProcessMemoryInfo_(hProcess.i, *ppsmemCounters, cb.l) As "GetProcessMemoryInfo"
    ; EndImport
    
    Prototype.i pGetProcessMemoryInfo(hProcess.i, *ppsmemCounters, cb.l)

    Global LibPsApi = OpenLibrary(#PB_Any, "psapi.dll")
    If LibPsApi
        Global GetProcessMemoryInfo_.pGetProcessMemoryInfo = GetFunction(LibPsApi, "GetProcessMemoryInfo")
    Else
        DebuggerError("Unable to load `GetProcessMemoryInfo` from `psapi.dll` !")
        End 1
    EndIf
    
    ; Lower-level equivalent to MemorySize()
	ImportC "msvcrt.lib"
	    _msize(*ptr) As "_msize"
	EndImport
    
    CompilerIf Not Defined(PROCESS_MEMORY_COUNTERS_EX, #PB_Structure)
        Structure PROCESS_MEMORY_COUNTERS_EX
            cb.l
            PageFaultCount.l
            PeakWorkingSetSize.i
            WorkingSetSize.i
            QuotaPeakPagedPoolUsage.i
            QuotaPagedPoolUsage.i
            QuotaPeakNonPagedPoolUsage.i
            QuotaNonPagedPoolUsage.i
            PagefileUsage.i
            PeakPagefileUsage.i
            PrivateUsage.i
        EndStructure
    CompilerEndIf
    
    Procedure.i _GetPrivateBytes()
        Protected pmc.PROCESS_MEMORY_COUNTERS_EX
        pmc\cb = SizeOf(PROCESS_MEMORY_COUNTERS_EX)
        If GetProcessMemoryInfo_(GetCurrentProcess_(), @pmc, pmc\cb)
            ProcedureReturn pmc\PrivateUsage
        EndIf
        ProcedureReturn -1
    EndProcedure
    
    Procedure CheckPrivateBytes(DoPrint.b = #True)
        Protected CurrentPrivateMem.i = _GetPrivateBytes()
        
        If CurrentPrivateMem > HighestPrivateMem
            HighestPrivateMem = CurrentPrivateMem
        EndIf
        
        If CurrentPrivateMem < LowestPrivateMem
            LowestPrivateMem = CurrentPrivateMem
        EndIf
        
        If DoPrint
            Debug "  Private Bytes: " + Str((CurrentPrivateMem - BaselinePrivateMem) / 1024) + " KB"
            
            CompilerIf #PB_Compiler_ExecutableFormat = #PB_Compiler_Console
                PrintN("  Private Bytes: " + Str((CurrentPrivateMem - BaselinePrivateMem) / 1024) + " KB")
            CompilerEndIf
        EndIf
    EndProcedure
    
;     Procedure PreCheckPrivateBytesForHumans(OperationName$)
;         Protected CurrentPrivateMem.i = _GetPrivateBytes()
;         
;         CheckPrivateBytes(#False)
;         
;         Debug "----------"
;         Debug OperationName$
;         Debug "> Private Bytes: " + Str((CurrentPrivateMem - BaselinePrivateMem) / 1024) + " KB"
;         
;         CompilerIf #PB_Compiler_ExecutableFormat = #PB_Compiler_Console
;             PrintN("----------")
;             PrintN(OperationName$)
;             PrintN("> Private Bytes: " + Str((CurrentPrivateMem - BaselinePrivateMem) / 1024) + " KB")
;         CompilerEndIf
;     EndProcedure
;     
;     Procedure PostCheckPrivateBytesForHumans(OperationName$)
;         Protected CurrentPrivateMem.i = _GetPrivateBytes()
;         
;         Debug "----------"
;         Debug OperationName$
;         Debug "> Private Bytes: " + Str((CurrentPrivateMem - BaselinePrivateMem) / 1024) + " KB"
;         
;         CompilerIf #PB_Compiler_ExecutableFormat = #PB_Compiler_Console
;             PrintN("----------")
;             PrintN(OperationName$)
;             PrintN("> Private Bytes: " + Str((CurrentPrivateMem - BaselinePrivateMem) / 1024) + " KB")
;         CompilerEndIf
;         
;         CheckPrivateBytes(#False)
;     EndProcedure
    
    Procedure PrintPrivateBytesStats()
        Debug "Min: " + Str((LowestPrivateMem - BaselinePrivateMem) / 1024) + " KB"
        Debug "Max: " + Str((HighestPrivateMem - BaselinePrivateMem) / 1024) + " KB"
        
        CompilerIf #PB_Compiler_ExecutableFormat = #PB_Compiler_Console
            PrintN("Min: " + Str((LowestPrivateMem - BaselinePrivateMem) / 1024) + " KB")
            PrintN("Max: " + Str((HighestPrivateMem - BaselinePrivateMem) / 1024) + " KB")
        CompilerEndIf
    EndProcedure
    
    Procedure SetBaselinePrivateBytes()
        BaselinePrivateMem = _GetPrivateBytes()
    EndProcedure
    
CompilerElse
    Macro _GetPrivateBytes() : -1 : EndMacro
    Macro CheckPrivateBytes(DoPrint = #True) : : EndMacro
;     Macro PreCheckPrivateBytesForHumans(OperationName) : : EndMacro
;     Macro PostCheckPrivateBytesForHumans(OperationName) : : EndMacro
    Macro PrintPrivateBytesStats() : : EndMacro
    Macro SetBaselinePrivateBytes() : : EndMacro
CompilerEndIf


CompilerIf #PB_Compiler_IsMainFile
    Debug "Private Bytes: " + Str(_GetPrivateBytes() / 1024) + " KB"
    OpenConsole()
    PrintN("Private Bytes: " + Str(_GetPrivateBytes() / 1024) + " KB")
    Input()
CompilerEndIf
