' Strict
SuperStrict

' Modules
Import BRL.Max2D

' Files
Import "../Global.bmx"
Import "../TINILoader.bmx"
Import "TResourceManager.bmx"

' TFontManager
Type TFontManager Extends TResourceManager
	Field logger:TLog
	
	' Init
	Method Init(nLogger:TLog)
		Super.InitManager(nLogger)
		Super.AddExtension("ini")
		Self.resourceType = "font"
		
		Self.logger = nLogger
	End Method
	
	' LoadFromFile
	Method LoadFromFile:Object(file:String)
		Local ini:TINI = TINI.Create(file)
		ini.Load()
		
		Local style:Int = 0
		If Int(ini.Get("Font", "Bold"))
			style :& BOLDFONT
		EndIf
		If Int(ini.Get("Font", "Italic"))
			style :& ITALICFONT
		EndIf
		If Int(ini.Get("Font", "Smooth"))
			style :& SMOOTHFONT
		EndIf
		
		Return LoadImageFont(ExtractDir(file) + "/" + ini.Get("Font", "File"), Int(ini.Get("Font", "Size")), style)
	End Method
	
	' Get
	Method Get:TImageFont(name:String)
		Return TImageFont(Self.resources.ValueForKey(name))
	End Method
	
	' Create
	Function Create:TFontManager(nLogger:TLog)
		Local fontMgr:TFontManager = New TFontManager
		fontMgr.Init(nLogger)
		Return fontMgr
	End Function
End Type
