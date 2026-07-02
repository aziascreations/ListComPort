;{- Code Header
; ==- Basic Info -================================
;         Name: WinTypes.pbi
;      Version: 1.0.0
;       Author: Herwin Bozet
;
; ==- Compatibility -=============================
;  Compiler version: PureBasic 5.70 (x86/x64)
;  Operating system: Windows 10 21H1 (Previous versions untested)
;
; ==- Sources -===================================
;  https://docs.microsoft.com/en-us/windows/win32/winprog/windows-data-types
; 
; ==- Links & License -===========================
;  License: Unlicense
;}


; ------------------------------------------------------------------------------
;- Compiler Options

EnableExplicit



; ------------------------------------------------------------------------------
;- Module Declaration

DeclareModule WinTypes
	;-> Semver Data
	
	#Version_Major = 1
	#Version_Minor = 1
	#Version_Patch = 0
	#Version_Label$ = ""
	#Version$ = "1.1.0";+"-"+#Version_Label$
	
	
	;-> Macros
	
	Macro APIENTRY : WinTypes::WINAPI : EndMacro
	Macro ATOM : WinTypes::WORD : EndMacro
	
	Macro BOOL : l : EndMacro
	Macro BOOLEAN : WinTypes::BYTE : EndMacro
	Macro BYTE : a : EndMacro
	
	Macro CCHAR : b : EndMacro
	Macro CHAR : b : EndMacro
	Macro COLORREF : l : EndMacro
	
	Macro DWORD : l : EndMacro
	Macro DWORDLONG : q : EndMacro
	Macro DWORD_PTR : i : EndMacro
	Macro DWORD32 : l : EndMacro
	Macro DWORD64 : q : EndMacro
	
	Macro FLOAT : f : EndMacro
	
	Macro HACCEL : HANDLE : EndMacro
	
	CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
		Macro HALF_PTR : u : EndMacro
	CompilerElseIf  #PB_Compiler_Processor = #PB_Processor_x64
		Macro HALF_PTR : l : EndMacro
	CompilerEndIf
	
	Macro HANDLE : i : EndMacro
	Macro HBITMAP : WinTypes::HANDLE : EndMacro
	Macro HBRUSH : WinTypes::HANDLE : EndMacro
	Macro HCOLORSPACE : WinTypes::HANDLE : EndMacro
	Macro HCONV : WinTypes::HANDLE : EndMacro
	Macro HCONVLIST : WinTypes::HANDLE : EndMacro
	Macro HCURSOR : WinTypes::HICON : EndMacro
	Macro HDC : WinTypes::HANDLE : EndMacro
	Macro HDDEDATA : WinTypes::HANDLE : EndMacro
	Macro HDESK : WinTypes::HANDLE : EndMacro
	Macro HDROP : WinTypes::HANDLE : EndMacro
	Macro HDWP : WinTypes::HANDLE : EndMacro
	Macro HENHMETAFILE : WinTypes::HANDLE : EndMacro
	Macro HFILE : l : EndMacro
	Macro HFONT : WinTypes::HANDLE : EndMacro
	Macro HGDIOBJ : WinTypes::HANDLE : EndMacro
	Macro HGLOBAL : WinTypes::HANDLE : EndMacro
	Macro HHOOK : WinTypes::HANDLE : EndMacro
	Macro HICON : WinTypes::HANDLE : EndMacro
	Macro HINSTANCE : WinTypes::HANDLE : EndMacro
	Macro HKEY : WinTypes::HANDLE : EndMacro
	Macro HKL : WinTypes::HANDLE : EndMacro
	Macro HLOCAL : WinTypes::HANDLE : EndMacro
	Macro HMENU : WinTypes::HANDLE : EndMacro
	Macro HMETAFILE : WinTypes::HANDLE : EndMacro
	Macro HMODULE : WinTypes::HINSTANCE : EndMacro
	Macro HMONITOR : WinTypes::HANDLE : EndMacro ; if(WINVER >= 0x0500) typedef HANDLE HMONITOR;
	Macro HPALETTE : WinTypes::HANDLE : EndMacro
	Macro HPEN : WinTypes::HANDLE : EndMacro
	Macro HRESULT : WinTypes::LONG : EndMacro
	Macro HRGN : WinTypes::HANDLE : EndMacro
	Macro HRSRC : WinTypes::HANDLE : EndMacro
	Macro HSZ : WinTypes::HANDLE : EndMacro
	Macro HWINSTA : WinTypes::HANDLE : EndMacro
	Macro HWND : WinTypes::HANDLE : EndMacro
	
	Macro LANGID : WinTypes::WORD : EndMacro
	Macro LCID : WinTypes::DWORD : EndMacro
	Macro LCTYPE : WinTypes::DWORD : EndMacro
	Macro LGRPID : WinTypes::DWORD : EndMacro
	
	; Can be used somewhat interchangeably, but can cause issues with PB's compiler.
	;Macro LPCWSTR : s : EndMacro
	Macro LPCWSTR : i : EndMacro
	
	Macro LPDWORD : i : EndMacro
	Macro LONG : l : EndMacro
	Macro LONG32 : l : EndMacro
	Macro LONG64 : q : EndMacro
	; IDK what the fuck this is...
	Macro LPOVERLAPPED : i : EndMacro
	Macro LSTATUS : l : EndMacro
	
	Macro PCWSTR : s : EndMacro
	Macro PSTR : s : EndMacro
	Macro PDWORD : i : EndMacro
	Macro PVOID : i : EndMacro
	Macro PHANDLE : i : EndMacro
	Macro PULONG : i : EndMacro
	Macro PCHAR : i : EndMacro
	
	Macro UCHAR : a : EndMacro
	Macro ULONG : l : EndMacro
	Macro ULONGLONG : q : EndMacro
	Macro USHORT : u : EndMacro
	
	Macro WCHAR : u : EndMacro
	Macro WINAPI : q : EndMacro
	Macro WORD : w : EndMacro
EndDeclareModule



; ------------------------------------------------------------------------------
;- Module Definition

Module WinTypes
	; Nothing...
EndModule
