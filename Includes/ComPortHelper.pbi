;{- Code Header
; ==- Basic Info -================================
;         Name: ComPortHelper.pbi
;      Version: 2.0.0
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

XIncludeFile "./RegistryHelper.pbi"

CompilerIf Not #PB_Compiler_OS = #PB_OS_Windows
	CompilerError "Includes is intended to be used on Windows platforms only !"
CompilerEndIf

XIncludeFile "./Debug_PrivateMemUsage.pbi"



; ------------------------------------------------------------------------------
;- Module Declaration

DeclareModule ComPortHelper
	;-> Semver Data
	
	#Version_Major = 2
	#Version_Minor = 0
	#Version_Patch = 0
	#Version_Label$ = ""
	#Version$ = "2.0.0";+"-"+#Version_Label$
	
	
	;-> Constants
	
	#RegistryKeyFull_DeviceMap_SerialCom$ = "HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM"
	#RegistryKeyFull_DeviceMap_ParallelPorts$ = "HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\PARALLEL PORTS"
	#RegistryKeyFull_DeviceEnum$ = "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Enum"
	
	#RegistryValueName_FriendlyName$ = "FriendlyName"
	
	#Sort_Order_Descending = -1
	#Sort_Order_None = 0
	#Sort_Order_Ascending = 1
	
	
	;-> Macro Definition
	
	Macro GetComPortAndDeviceNameLists(DeviceNames, ComPortNames)
		RegistryHelper::GetKeyValuePairAsLists(ComPortHelper::#RegistryKeyFull_DeviceMap_SerialCom$, DeviceNames, ComPortNames)
	EndMacro
	
	Macro GetComDeviceNameList(DeviceNames)
		RegistryHelper::GetKeyValueNames(ComPortHelper::#RegistryKeyFull_DeviceMap_SerialCom$, DeviceNames)
	EndMacro
	
	Macro GetComPortList(ComPortNames)
		RegistryHelper::GetKeyValues(ComPortHelper::#RegistryKeyFull_DeviceMap_SerialCom$, ComPortNames)
	EndMacro
	
	Macro GetParallelPortAndDeviceNameLists(DeviceNames, ParallelPortNames)
		RegistryHelper::GetKeyValuePairAsLists(ComPortHelper::#RegistryKeyFull_DeviceMap_ParallelPorts$, DeviceNames, ParallelPortNames)
	EndMacro
	
	Macro GetParallelDeviceNameList(DeviceNames)
		RegistryHelper::GetKeyValueNames(ComPortHelper::#RegistryKeyFull_DeviceMap_ParallelPorts$, DeviceNames)
	EndMacro
	
	Macro GetParallelPortList(ParallelPortNames)
		RegistryHelper::GetKeyValues(ComPortHelper::#RegistryKeyFull_DeviceMap_ParallelPorts$, ParallelPortNames)
	EndMacro
	
	
	;-> Procedure Declaration
	
	Declare.i GetComPortMappedFriendlyName(List ComPortList.s(), Map ComPortFriendlyNames.s(), FixMissing.b = #True)
	Declare SortDeviceAndRawNameLists(List DeviceNames.s(), List ComPortNames.s(), SortingMode.b = ComPortHelper::#Sort_Order_None)
EndDeclareModule



; ------------------------------------------------------------------------------
;- Module Definition

Module ComPortHelper
	;-> Compiler Directives
	
	EnableExplicit
	
	
	;-> Procedure Definition
	
	Procedure.i GetComPortMappedFriendlyName(List ComPortList.s(), Map ComPortFriendlyNames.s(), FixMissing.b = #True)
		If ListSize(ComPortList()) > 0
			Protected NewList RootSubKeyEnum.s()
			
			If RegistryHelper::GetSubKeys(#RegistryKeyFull_DeviceEnum$, RootSubKeyEnum()) = -1
				Debug "Unable to list main subkeys in '"+#RegistryKeyFull_DeviceEnum$+"'"
				FreeList(RootSubKeyEnum())
				ProcedureReturn -1
			EndIf
			
			Protected NewList SubSubKeyEnum.s()
			
			ForEach(RootSubKeyEnum())
				If RootSubKeyEnum() = "ACPI" Or
				   RootSubKeyEnum() = "ACPI_HAL" Or
				   RootSubKeyEnum() = "HDAUDIO" Or
				   RootSubKeyEnum() = "SCSI" Or
				   RootSubKeyEnum() = "STORAGE" Or
				   RootSubKeyEnum() = "SW" Or
				   RootSubKeyEnum() = "SWD" Or
				   RootSubKeyEnum() = "UEFI"
					Continue
				EndIf
				
				If RegistryHelper::GetSubKeys(#RegistryKeyFull_DeviceEnum$+"\"+RootSubKeyEnum(), SubSubKeyEnum(), #True, #True) = -1
					Debug "Unable to list main subkeys in '"+#RegistryKeyFull_DeviceEnum$+"'"
					Continue
				EndIf
			Next
			
			FreeList(RootSubKeyEnum())
			
			If ListSize(SubSubKeyEnum()) = 0
				Debug "No subsub keys found !"
				FreeList(SubSubKeyEnum())
				ProcedureReturn -1
			EndIf
			
			Protected NewList SubSubSubKeyEnum.s()
			
			ForEach(SubSubKeyEnum())
				If RegistryHelper::GetSubKeys(SubSubKeyEnum(), SubSubSubKeyEnum(), #True, #True) = -1
					Debug "Unable to list main subsubkeys in '"+#RegistryKeyFull_DeviceEnum$+"'"
				EndIf
			Next
			
			FreeList(SubSubKeyEnum())
			
			Protected NewList FriendlyNames.s()
			
			ForEach(SubSubSubKeyEnum())
				Protected Value$ = RegistryHelper::GetValue(SubSubSubKeyEnum(), #RegistryValueName_FriendlyName$)
				
				If Value$ <> #Null$
					AddElement(FriendlyNames())
					FriendlyNames() = Value$
				EndIf
			Next
			
			FreeList(SubSubSubKeyEnum())
			
			ForEach(ComPortList())
				Protected HasFoundName.b = #False
				
				ForEach(FriendlyNames())
					If FindString(FriendlyNames(), "("+ComPortList()+")") <> 0
						ComPortFriendlyNames(ComPortList()) = FriendlyNames()
						HasFoundName = #True
						Break
					EndIf
					
					If Not HasFoundName
						If FixMissing
							ComPortFriendlyNames(ComPortList()) = "No friendly name found ("+ComPortList()+")"
						Else
							ComPortFriendlyNames(ComPortList()) = ""
						EndIf
					EndIf
				Next
			Next
			
			FreeList(FriendlyNames())
		EndIf
		
		ProcedureReturn ListSize(ComPortList())
	EndProcedure
	
	; This is a quick fix, it may or may not be changed later on.
	Procedure SortDeviceAndRawNameLists(List DeviceNames.s(), List ComPortNames.s(), SortingMode.b = ComPortHelper::#Sort_Order_None)
		If SortingMode = #Sort_Order_Ascending Or SortingMode = #Sort_Order_Descending
			Protected NewMap ComToDeviceMapping.s()
			
			ForEach(ComPortNames())
				SelectElement(DeviceNames(), ListIndex(ComPortNames()))
				ComToDeviceMapping(ComPortNames()) = DeviceNames()
			Next
			
			ClearList(DeviceNames())
			
			If SortingMode = #Sort_Order_Ascending
				SortList(ComPortNames(), #PB_Sort_Ascending | #PB_Sort_NoCase)
			ElseIf SortingMode = #Sort_Order_Descending
				SortList(ComPortNames(), #PB_Sort_Descending | #PB_Sort_NoCase)
			EndIf
			
			ForEach ComPortNames()
				AddElement(DeviceNames())
				DeviceNames() = ComToDeviceMapping(ComPortNames())
			Next
			
			FreeMap(ComToDeviceMapping())
		EndIf
	EndProcedure
EndModule



; ------------------------------------------------------------------------------
;- Tests
CompilerIf #PB_Compiler_IsMainFile
    EnableExplicit
    
    Global NewList ComPortDeviceNames.s()
    Global NewList ComPortRawNames.s()
    Global NewMap ComPortFriendlyNames.s()
    
    Global ShouldPrintFriendlyNames = #False
    
    OpenConsole()
    
    Debug "Pre-baseline"
    CheckPrivateBytes()
    
    SetBaselinePrivateBytes()
    
    Debug "Post-Baseline"
    CheckPrivateBytes()
    
    
    Debug "Listing COM Ports"
    If ComPortHelper::GetComPortAndDeviceNameLists(ComPortDeviceNames(), ComPortRawNames()) <> -1
        CheckPrivateBytes()
        
        If ShouldPrintFriendlyNames
            
            Debug "Listing Friendly names"
            
            If ComPortHelper::GetComPortMappedFriendlyName(ComPortRawNames(), ComPortFriendlyNames(), #True) = -1
                CheckPrivateBytes()
                Debug "#LSCOM_Locale_Error_NoFriendlyNames"
                PrintN("#LSCOM_Locale_Error_NoFriendlyNames")
                Goto ComPortHelper_End
            EndIf
    	EndIf
    Else
        CheckPrivateBytes()
        
        Debug "#LSCOM_Locale_Error_NoComPorts"
        PrintN("#LSCOM_Locale_Error_NoComPorts")
        Goto ComPortHelper_End
    EndIf
    
    Debug "Exited COM Ports Listing If/Else block"
    CheckPrivateBytes()
    
    Debug "Cleaning lists and maps"
	FreeMap(ComPortFriendlyNames())
	FreeList(ComPortRawNames())
	FreeList(ComPortDeviceNames())
    CheckPrivateBytes()
    
    
	ComPortHelper_End:
    Debug "Exiting"
	CheckPrivateBytes()
	PrintPrivateBytesStats()
	
    Input()
CompilerEndIf
