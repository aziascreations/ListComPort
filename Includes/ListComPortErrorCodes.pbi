;{- Code Header
; ==- Basic Info -================================
;         Name: ListComPortErrorCodes.pbi
;      Version: N/A
;       Author: Herwin Bozet
; 
; ==- Links & License -===========================
;  License: Unlicense
;}

;- Compiler Directives

EnableExplicit


;- Error Codes

Enumeration LSCOM_ErrorCodes
	#LSCOM_ErrorCode_NoError = 0
	
	; Fatal errors (1-9)
	#LSCOM_ErrorCode_NoTerminal = 1
	#LSCOM_ErrorCode_NoRequiredWinApiFunction
	
	; Internal argument parser errors (10-19)
	#LSCOM_ErrorCode_Legacy1 = 10
	#LSCOM_ErrorCode_Legacy2
	#LSCOM_ErrorCode_Legacy3
	#LSCOM_ErrorCode_UnknownArgument = 13
	
	; External argument errors (20-29)
	#LSCOM_ErrorCode_NoPaddingValue = 20
	
	; Application & System errors (30-39)
	#LSCOM_ErrorCode_NoFriendlyNames = 30
	#LSCOM_ErrorCode_NoComPorts
EndEnumeration
