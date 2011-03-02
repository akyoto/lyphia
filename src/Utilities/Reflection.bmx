' Strict
SuperStrict

' Modules
Import BRL.Reflection

' Files
Import "../TLog.bmx"

' CreateObjectFromClass
Function CreateObjectFromClass:Object(className:String)
	Return TTypeId.ForName(className).NewObject()
End Function

' GetTypeName
Function GetTypeName:String(obj:Object)
	Return TTypeId.ForObject(obj).Name() 
End Function

' PrintTypeDebugStdio
Function PrintTypeDebugStdio(obj:Object)
	Local id:TTypeId = TTypeId.ForObject(obj)
	
	For Local f:TField = EachIn id.Fields()'list
		Print(id.Name() + "." + f.Name() + " = " + f.Get(obj).ToString())
	Next
End Function

' PrintTypeDebug
Function PrintTypeDebug(obj:Object, logFile:TLog)
	Local id:TTypeId = TTypeId.ForObject(obj)
	
	For Local f:TField = EachIn id.Fields()'list
		logFile.Write(id.Name() + "." + f.Name() + " = " + f.Get(obj).ToString())
	Next
End Function