' Strict
SuperStrict

' Windows
?Win32
	' SYSTEM_INFO
	Type TSYSTEM_INFO
		Field wProcessorArchitecture:Short
		Field wReserved:Short
		Field dwPageSize:Int
		Field lpMinimumApplicationAddress:Byte Ptr
		Field lpMaximumApplicationAddress:Byte Ptr
		Field dwActiveProcessorMask:Int
		Field dwNumberOfProcessors:Int
		Field dwProcessorType:Int
		Field dwAllocationGranularity:Int
		Field wProcessorLevel:Short
		Field wProcessorRevision:Short
	End Type
	
	Rem
	' OSVERSIONINFO
	Type TOSVERSIONINFO
		Field dwOSVersionInfoSize:Int
		Field dwMajorVersion:Int
		Field dwMinorVersion:Int
		Field dwBuildNumber:Int
		Field dwPlatformId:Int
		Field szCSDVersion:Byte[128]
	End Type
	End Rem
	
	Extern "win32"
		Function GetSystemInfo(si:Byte Ptr)
		Function GetVersion:Int()
	End Extern
	
	Private
	
	' Vars
	Const LOBYTE:Int = %0000000011111111
	Const HIBYTE:Int = %1111111100000000
	Global systemInfo:TSYSTEM_INFO = New TSYSTEM_INFO
	'Global osVersionInfo:TOSVERSIONINFO = New TOSVERSIONINFO
	
	' Get info
	GetSystemInfo(systemInfo)
	
	Public
	
	' GetProcessorCount
	Function GetProcessorCount:Int()
		Return systemInfo.dwNumberOfProcessors
	End Function
	
	' GetProcessorArchitecture
	Function GetProcessorArchitecture:String()
		Select systemInfo.wProcessorArchitecture
			Case 9
				Return "x64"
			Case 6
				Return "ia64"
			Case 0
				Return "x86"
			Default
				Return "Unknown"
		End Select
	End Function
	
	' GetOSVersion
	Function GetOSVersion:String()
		Local version:Int = GetVersion() & Int(2^16 - 1)
		Return (version & LOBYTE) + "." + ((version & HIBYTE) Shr 8)
	End Function
?
