' Strict
SuperStrict

' Root
Global FS_ROOT:String = "../"

' Host
Global HOST_ROOT:String = "http::blitzprog.com/scripts/"

?Win32
	Global NEWLINE:String = "~r~n"
?Linux|MacOS
	Global NEWLINE:String = "~n"
?