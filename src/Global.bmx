' Strict
SuperStrict

' Root
Global FS_ROOT:String = "../"

?Win32
	Global NEWLINE:String = "~r~n"
?Linux|MacOS
	Global NEWLINE:String = "~n"
?