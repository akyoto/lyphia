
' Files
Include "TCursor.bmx"

' TWidgetSkin
Type TWidgetSkin
	Field dir:String
	Field name:String
	
	Field ini:TINI
	Field imageMgr:TImageManager
	
	Rem
	' Window
	Field c:TImage								' Center (fill)
	Field n:TImage, s:TImage, w:TImage, e:TImage		' North, South, West, East
	Field nw:TImage, ne:TImage					' North
	Field sw:TImage, se:TImage					' South
	End Rem
	
	Rem
	' Buttons
	Field btnClose:TImage
	
	Field textOffsetX:Int
	Field textOffsetY:Int
	End Rem
	
	' Init
	Method Init(nName:String, nDir:String)
		Self.name = nName
		Self.dir = nDir
		
		TGUI.logger.Write("Loading widget skin '" + Self.name + "' from '" + Self.dir + "'")
		
		Self.imageMgr = TImageManager.Create(TGUI.logger)
		Self.imageMgr.SetFlags(0)
		
		' TODO: Remove hardcoded stuff
		SetMaskColor(255, 0, 255)
		
		' Add image resources
		Self.imageMgr.AddResourcesFromDirectory(nDir + nName)
		
		' Create INI object
		Self.ini = TINI.Create(nDir + nName + "/" + nName + ".ini")
		
		' Setup variables
		Self.Load()
	End Method
	
	' ToString
	Method ToString:String()
		Return Self.name
	End Method
	
	' Load
	Method Load() Abstract
End Type

' TSkin
Type TSkin
	Global dir:String
	Global extension:String
	
	' Skin name
	Field name:String
	Field localDir:String
	
	' Cursors
	Field cursors:TMap
	
	' Widgets
	Field window:TWindowSkin
	Field checkBox:TCheckBoxSkin
	Field slider:TSliderSkin
	Field progressBar:TProgressBarSkin
	
	' Init
	Method Init(nName:String)
		TGUI.logger.Write("Initializing skin '" + nName + "'")
		
		Self.cursors = CreateMap()
		Self.name = nName
		
		Self.localDir = TSkin.dir + Self.name + "/"
		Self.window = TWindowSkin.Create(Self.localDir)
		Self.checkBox = TCheckBoxSkin.Create(Self.localDir)
		Self.slider = TSliderSkin.Create(Self.localDir)
		Self.progressBar = TProgressBarSkin.Create(Self.localDir)
		
		Self.LoadCursors()
	End Method
	
	' LoadCursors
	Method LoadCursors()
		TGUI.logger.Write("Loading cursors")
		
		Local files:String[]
		Local file:String
		
		files = LoadDir(Self.localDir + TCursor.dir)
		For file = EachIn files
			If ExtractExt(file).ToLower() = TSkin.extension
				' Load cursor
				Self.AddCursor(StripExt(file))
			EndIf
		Next
	End Method
	
	' AddCursor
	Method AddCursor(nName:String)
		Self.cursors.Insert(nName, TCursor.Create(nName, Log_LoadImage(TGUI.logger, Self.localDir + TCursor.dir + nName + "." + TSkin.extension)))
	End Method
	
	' GetCursor
	Method GetCursor:TCursor(name:String)
		Return TCursor(cursors.ValueForKey(name))
	End Method
	
	' ToString
	Method ToString:String()
		Return Self.name
	End Method
	
	' InitClass
	Function InitClass(skinsDir:String, skinsExt:String = "png")
		TSkin.dir = skinsDir
		TSkin.extension = skinsExt
		
		TCursor.InitClass("Cursors/")
	End Function
	
	' Create
	Function Create:TSkin(nName:String)
		Local skin:TSkin = New TSkin
		skin.Init(nName)
		Return skin
	End Function
End Type
