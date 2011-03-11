' Strict
SuperStrict

' Modules
Import BRL.Basic

' URLString
Function URLString:String(inp:String)
	Return inp.Replace(" ", "%20")
End Function