' Strict
SuperStrict

' Files
Import "../Global.bmx"
Import "../TLua.bmx"
Import "TResourceManager.bmx"

' TScriptManager
Type TScriptManager Extends TResourceManager
	Field logger:TLog
	
	' Init
	Method Init(nLogger:TLog)
		Super.InitManager(nLogger)
		Super.AddExtension("lua")
		Self.resourceType = "script"
		
		Self.logger = nLogger
	End Method
	
	' LoadFromFile
	Method LoadFromFile:Object(file:String)
		Return TLuaScript.Create(file)
	End Method
	
	' Get
	Method Get:TLuaScript(name:String)
		Return TLuaScript(Self.resources.ValueForKey(name))
	End Method
	
	' Create
	Function Create:TScriptManager(nLogger:TLog)
		Local scriptMgr:TScriptManager = New TScriptManager
		scriptMgr.Init(nLogger)
		Return scriptMgr
	End Function
End Type

