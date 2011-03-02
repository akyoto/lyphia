' Strict
SuperStrict

' Modules
Import BRL.Map
Import BRL.FileSystem

' Files
Import "../Global.bmx"
Import "../TLog.bmx"

' TResourceManager
Type TResourceManager
	Field resources:TMap
	Field resLogger:TLog
	Field extensions:TList
	Field resourceType:String
	
	' InitManager
	Method InitManager(nLogger:TLog)
		Self.resources = CreateMap()
		Self.resourceType = "resource"
		
		Self.extensions = CreateList()
		
		Self.resLogger = nLogger
		Self.resLogger.Write("Resource manager initialized")
	End Method
	
	' AddObject
	Method AddObject(name:String, obj:Object)
		Self.resLogger.Write("Adding object '" + name + "'")
		Self.resources.Insert(name, obj)
	End Method
	
	' AddResource
	Method AddResource(fileName:String)
		Local name:String = StripAll(fileName)
		If Self.resources.Contains(name) = False
			Self.resLogger.Write("Loading " + Self.resourceType + " '" + name + "' from '" + fileName + "'")
			Self.resources.Insert(name, Self.LoadFromFile(fileName))
		EndIf
	End Method
	
	' AddExtension
	Method AddExtension(ext:String)
		Self.extensions.AddLast(ext.ToLower())
	End Method
	
	' LoadFromFile
	Method LoadFromFile:Object(file:String)
		Return Null
	End Method
	
	' AddResourcesFromDirectory
	' TODO: Recursive option
	Method AddResourcesFromDirectory(dir:String)
		' Add slash if needed
		If dir[dir.length-1] <> "/"[0]
			dir :+ "/"
		EndIf
		
		Self.resLogger.Write("Loading directory: " + dir)
		
		Local files:String[] = LoadDir(dir)
		For Local file:String = EachIn files
			If Self.extensions.Contains(ExtractExt(file).ToLower())
				Self.AddResource(dir + file)
			EndIf
		Next
	End Method
	
	' GetObjectByName
	Method GetObjectByName:Object(name:String)
		Return Self.resources.ValueForKey(name)
	End Method
	
	' Create
'	Function Create:TResourceManager(nLogger:TLog)
'		Local mgr:TResourceManager = New TResourceManager
'		mgr.InitManager(nLogger)
'		Return mgr
'	End Function
End Type