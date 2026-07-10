;{- Code Header
; ==- Basic Info -================================
;         Name: ListComPort.pbi
;      Version: 3.0.0
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

CompilerIf Not #PB_Compiler_OS = #PB_OS_Windows
	CompilerError "Includes is intended to be used on Windows platforms only !"
CompilerEndIf

XIncludeFile "./Debug_PrivateMemUsage.pbi"



; ------------------------------------------------------------------------------
;- Module Declaration

DeclareModule ListComPort
	;-> Semver Data
	
	#Version_Major = 3
	#Version_Minor = 0
	#Version_Patch = 0
	#Version_Label$ = ""
	#Version$ = "3.0.0";+"-"+#Version_Label$
	
	
	;-> Constants
	
	#Sort_Order_Descending = -1
	#Sort_Order_None = 0
	#Sort_Order_Ascending = 1
	
	
	;-> Enumeration
	
	Macro LSCOMOption : l : EndMacro
	
	EnumerationBinary ListComPort_Options
		; Port types
		#LSCOM_Option_IncludeCom      = %00000000000000000000000000000001
		#LSCOM_Option_IncludeLpt      = %00000000000000000000000000000010
		
		; Desired data
		#LSCOM_Option_GetPortName     = %00000000000000000000000100000000
		#LSCOM_Option_GetFriendlyName = %00000000000000000000001000000000
		#LSCOM_Option_GetDeviceName   = %00000000000000000000010000000000
		
		; Other behaviour
		;#LSCOM_Option_GetConnected    = %00000001000000000000000000000000
		#LSCOM_Option_GetDisconnected = %00000010000000000000000000000000
	EndEnumeration
	
	#LSCOM_Option_LegacyDefaults = #LSCOM_Option_IncludeCom | #LSCOM_Option_GetPortName | #LSCOM_Option_GetDeviceName
	
	#LSCOM_Option_Everything = #LSCOM_Option_IncludeCom | #LSCOM_Option_IncludeLpt | 
	                           #LSCOM_Option_GetPortName | #LSCOM_Option_GetFriendlyName | #LSCOM_Option_GetDeviceName |
	                           #LSCOM_Option_GetDisconnected
	
	
	;-> Structures
	
	Structure PortInfo
		PortName$
		FriendlyName$
		DeviceName$
	EndStructure
	
	
	;-> Procedure Declaration
	
	Declare.i CountPorts(OnlyPresent.b = #True)
	Declare.i GetPortsInfo(List PortsInfo.PortInfo(), Options.ListComPort::LSCOMOption = ListComPort::#LSCOM_Option_LegacyDefaults)
	Declare SortDeviceAndRawNameLists(List PortsInfo.PortInfo(), SortingMode.b = ListComPort::#Sort_Order_None)
EndDeclareModule



; ------------------------------------------------------------------------------
;- Module Definition

Module ListComPort
	;-> Compiler Directives
	
	EnableExplicit
	
	; Doesn't share baselines !!!
	IncludeFile "./Debug_PrivateMemUsage.pbi"
	SetBaselinePrivateBytes()
	
	
	;-> Private Constants
	;#DIGCF_PRESENT = $2
	#DICS_FLAG_GLOBAL = $1
	#DIREG_DEV = $1
	#SPDRP_FRIENDLYNAME = $C
	#SPDRP_DEVICEDESC = $0
	;#KEY_READ = $20019
	
	#LSCOM_StrBufferCharSize = 255
	
	
	;-> Private Macros
	
	Macro HANDLE : i : EndMacro
	Macro HDEVINFO : HANDLE : EndMacro
	
	
	;-> Private Structures
	
	CompilerIf Not(Defined(SP_DEVINFO_DATA, #PB_Structure))
		Structure SP_DEVINFO_DATA
			cbSize.l
			ClassGuid.GUID
			DevInst.l
			Reserved.i
		EndStructure
	CompilerEndIf
	
	
	;-> Private Globals
	
	Global GuidPortsComLpt.GUID
	GuidPortsComLpt\Data1 = $4D36E978
	GuidPortsComLpt\Data2 = $E325
	GuidPortsComLpt\Data3 = $11CE
	GuidPortsComLpt\Data4[0] = $BF : GuidPortsComLpt\Data4[1] = $C1
	GuidPortsComLpt\Data4[2] = $08 : GuidPortsComLpt\Data4[3] = $00
	GuidPortsComLpt\Data4[4] = $2B : GuidPortsComLpt\Data4[5] = $E1
	GuidPortsComLpt\Data4[6] = $03 : GuidPortsComLpt\Data4[7] = $18
	
	
	; com0com: {DF799E12-3C56-421B-B298-B6D3642BC878}
	; default: {4D36E978-E325-11CE-BFC1-08002BE10318}
	
	
	;-> Public Procedures
	
	Procedure.i CountPorts(OnlyPresent.b = #True)
		Protected PortCount.i = 0
		
		Protected hDevInfo.HDEVINFO
		If OnlyPresent
			hDevInfo = SetupDiGetClassDevs_(@GuidPortsComLpt, #Null, #Null, 0)
		Else
			hDevInfo = SetupDiGetClassDevs_(@GuidPortsComLpt, #Null, #Null, #DIGCF_PRESENT)
		EndIf
		
		If hDevInfo <> #INVALID_HANDLE_VALUE
			Protected devData.SP_DEVINFO_DATA
			devData\cbSize = SizeOf(SP_DEVINFO_DATA)
			
			While SetupDiEnumDeviceInfo_(hDevInfo, PortCount, @devData)
				!INC PortCount
				;PortCount = PortCount + 1
			Wend
			
			SetupDiDestroyDeviceInfoList_(hDevInfo)
		EndIf
		
		ProcedureReturn PortCount
	EndProcedure
	
	Procedure.i GetPortsInfo(List PortsInfo.PortInfo(), Options.ListComPort::LSCOMOption = ListComPort::#LSCOM_Option_LegacyDefaults)
		PrintN("ListComPort::GetPortsInfo - Start")
	    Debug "ListComPort::GetPortsInfo - Start"
	    CheckPrivateBytes()
	    
	    
		; Getting all connected, or all ever connected ports
		Protected hDevInfo.HDEVINFO
		If (Options & ListComPort::#LSCOM_Option_GetDisconnected) <> 0
			hDevInfo = SetupDiGetClassDevs_(@GuidPortsComLpt, #Null, #Null, 0)
		Else
			hDevInfo = SetupDiGetClassDevs_(@GuidPortsComLpt, #Null, #Null, #DIGCF_PRESENT)
		EndIf
		
		PrintN("ListComPort::GetPortsInfo - Post-Setup")
	    Debug "ListComPort::GetPortsInfo - Post-Setup"
	    CheckPrivateBytes()
		
		
		If hDevInfo <> #INVALID_HANDLE_VALUE
			Protected *StringBuffer = AllocateMemory(#LSCOM_StrBufferCharSize * SizeOf(Character))
			
			If *StringBuffer <> #Null
				Protected devData.SP_DEVINFO_DATA
				devData\cbSize = SizeOf(SP_DEVINFO_DATA)
				
				PrintN("ListComPort::GetPortsInfo - Post-Allocs, Pre-Looping")
			    Debug "ListComPort::GetPortsInfo - Post-Allocs, Pre-Looping"
			    CheckPrivateBytes()
			    
			    ; Iterating over all ports
				Define DeviceIndex = 0
				While SetupDiEnumDeviceInfo_(hDevInfo, DeviceIndex, @devData)
					Debug "Port found:"
					
					AddElement(PortsInfo())
					
					; Retrieving the port name -> COM5
					; We have to get it from the registry since this isn't a generic field
					If (Options & ListComPort::#LSCOM_Option_GetPortName) <> 0
						Define hKeyPortDev = SetupDiOpenDevRegKey_(hDevInfo, @devData, #DICS_FLAG_GLOBAL, 0, #DIREG_DEV, #KEY_READ)
						
						If hKeyPortDev <> #Null And hKeyPortDev <> #INVALID_HANDLE_VALUE
							Protected BufferSize = MemorySize(*StringBuffer)
							RegQueryValueEx_(hKeyPortDev, "PortName", #Null, #Null, *StringBuffer, @BufferSize)
							RegCloseKey_(hKeyPortDev)
							PortsInfo()\PortName$ = PeekS(*StringBuffer, #LSCOM_StrBufferCharSize)
							FillMemory(*StringBuffer, MemorySize(*StringBuffer))
						EndIf
						
						Debug "> PortName$: " + PortsInfo()\PortName$
					EndIf
					
					; Retrieving the friendly name -> com0com - serial port emulator (COM5)
					If (Options & ListComPort::#LSCOM_Option_GetFriendlyName) <> 0
						Debug "2"
						SetupDiGetDeviceRegistryProperty_(hDevInfo, @devData, #SPDRP_FRIENDLYNAME, #Null, *StringBuffer, MemorySize(*StringBuffer), #Null)
						PortsInfo()\FriendlyName$ = PeekS(*StringBuffer, #LSCOM_StrBufferCharSize)
						FillMemory(*StringBuffer, MemorySize(*StringBuffer))
						
						Debug "> FriendlyName$: " + PortsInfo()\FriendlyName$
					EndIf
					
					; Retrieving the device name -> \Device\com0com15
					If (Options & ListComPort::#LSCOM_Option_GetDeviceName) <> 0
						SetupDiGetDeviceRegistryProperty_(hDevInfo, @devData, #SPDRP_DEVICEDESC, #Null, *StringBuffer, MemorySize(*StringBuffer), #Null)
						PortsInfo()\DeviceName$ = PeekS(*StringBuffer, #LSCOM_StrBufferCharSize)
						FillMemory(*StringBuffer, MemorySize(*StringBuffer))
						
						Debug "> DeviceName$: " + PortsInfo()\DeviceName$
					EndIf
					
					;!INC DeviceIndex
					DeviceIndex = DeviceIndex + 1
				
					PrintN("ListComPort::GetPortsInfo - Iter #" + Str(DeviceIndex))
				    Debug "ListComPort::GetPortsInfo - Iter #" + Str(DeviceIndex)
				    CheckPrivateBytes()
				Wend
				
				FreeMemory(*StringBuffer)
			EndIf
			
			SetupDiDestroyDeviceInfoList_(hDevInfo)
		EndIf
		
		PrintN("ListComPort::GetPortsInfo - End")
	    Debug "ListComPort::GetPortsInfo - End"
	    CheckPrivateBytes()
	    
		ProcedureReturn 0
	EndProcedure
	
	
	; This is a quick fix, it may or may not be changed later on.
	Procedure SortDeviceAndRawNameLists(List PortsInfo.PortInfo(), SortingMode.b = ListComPort::#Sort_Order_None)
; 		If SortingMode = #Sort_Order_Ascending Or SortingMode = #Sort_Order_Descending
; 			Protected NewMap ComToDeviceMapping.s()
; 			
; 			ForEach(ComPortNames())
; 				SelectElement(DeviceNames(), ListIndex(ComPortNames()))
; 				ComToDeviceMapping(ComPortNames()) = DeviceNames()
; 			Next
; 			
; 			ClearList(DeviceNames())
; 			
; 			If SortingMode = #Sort_Order_Ascending
; 				SortStructuredList(PortsInfo(), #PB_Sort_Ascending | #PB_Sort_NoCase, OffsetOf(PortInfo\PortName$))
; 			ElseIf SortingMode = #Sort_Order_Descending
; 				SortStructuredList(PortsInfo(), #PB_Sort_Descending | #PB_Sort_NoCase, OffsetOf(PortInfo\PortName$))
; 			EndIf
; 		EndIf
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
    
    NewList PortsInfo.ListComPort::PortInfo()
    PrintN("Allocated Linked List")
    Debug "Allocated Linked List"
    CheckPrivateBytes()
    
    Debug "Listing COM Ports"
    ;If ListComPort::GetPortsInfo(PortsInfo(), ) <> -1
    If ListComPort::GetPortsInfo(PortsInfo(), ListComPort::#LSCOM_Option_Everything) <> -1
        CheckPrivateBytes()
        
        Debug "Found " + Str(ListSize(PortsInfo())) + " port(s)"
        If ShouldPrintFriendlyNames
            
            Debug "Listing Friendly names"
            
            ;If ListComPort::GetComPortMappedFriendlyName(ComPortRawNames(), ComPortFriendlyNames(), #True) = -1
            ;    CheckPrivateBytes()
            ;    Debug "#LSCOM_Locale_Error_NoFriendlyNames"
            ;    PrintN("#LSCOM_Locale_Error_NoFriendlyNames")
            ;    Goto ListComPort_End
            ;EndIf
    	EndIf
    Else
        CheckPrivateBytes()
        
        Debug "#LSCOM_Locale_Error_NoComPorts"
        PrintN("#LSCOM_Locale_Error_NoComPorts")
        Goto ListComPort_End
    EndIf
    
    Debug "Exited COM Ports Listing If/Else block"
    CheckPrivateBytes()
    
    Debug "Cleaning lists and maps"
	FreeMap(ComPortFriendlyNames())
	FreeList(ComPortRawNames())
	FreeList(ComPortDeviceNames())
    CheckPrivateBytes()
    
    
	ListComPort_End:
    Debug "Exiting"
	CheckPrivateBytes()
	PrintPrivateBytesStats()
	
    Input()
CompilerEndIf
