' Strict
SuperStrict

' Modules
Import BRL.Max2D

' File formats
Import BRL.PNGLoader

' Files
Import "../Global.bmx"
Import "TResourceManager.bmx"

' TImageManager
Type TImageManager Extends TResourceManager
	Field logger:TLog
	Field flags:Int = -1
	
	' Init
	Method Init(nLogger:TLog)
		Super.InitManager(nLogger)
		Super.AddExtension("png")
		Self.resourceType = "image"
		
		Self.flags = -1
		Self.logger = nLogger
	End Method
	
	' SetFlags
	Method SetFlags(nFlags:Int)
		Self.flags = nFlags
	End Method
	
	' LoadFromFile
	Method LoadFromFile:Object(file:String)
		Return LoadImage(file, flags)
	End Method
	
	' Get
	Method Get:TImage(name:String)
		Return TImage(Self.resources.ValueForKey(name))
	End Method
	
	' Create
	Function Create:TImageManager(nLogger:TLog)
		Local imgMgr:TImageManager = New TImageManager
		imgMgr.Init(nLogger)
		Return imgMgr
	End Function
End Type
