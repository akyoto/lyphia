
' TCheckBox
Type TCheckBox Extends TWidget
	Field checked:Int
	Field textSizeX:Int
	Field textSizeY:Int
	
	' Init
	Method Init(nID:String, nText:String, nX:Int, nY:Int, nWidth:Int, nHeight:Int)
		Self.checked = 0
		Self.InitWidget(nID, nText, nX, nY, nWidth, nHeight)
	End Method
	
	' SetState
	Method SetState(nChecked:Int)
		Self.checked = nChecked
		
		' TODO: Change handler
		If Self.onClick
			Self.onClick(Self)
		EndIf
	End Method
	
	' GetState
	Method GetState:Int()
		Return Self.checked
	End Method
	
	' ToggleState
	Method ToggleState() 
		Self.SetState(1 - Self.checked)
	End Method
	
	' SetText
	Method SetText(nText:String)
		Self.text = nText
		Self.OnFontChange()
	End Method
	
	' OnFontChange
	Method OnFontChange()
		SetImageFont Self.font
		Self.textSizeX = TextWidth(Self.text)
		Self.textSizeY = TextHeight(Self.text)
		
		If gui <> Null
			Self.OnGUIAvailable()
		EndIf
	End Method
	
	' OnGUIAvailable
	Method OnGUIAvailable()
		If Self.textSizeX = 0
			Self.SetSizeAbs(gui.skin.checkbox.unchecked.width, gui.skin.checkbox.unchecked.height)
		Else
			Self.SetSizeAbs(gui.skin.checkbox.unchecked.width + Self.textSizeX + gui.skin.checkbox.textOffsetX, Max(gui.skin.checkbox.unchecked.height, Self.textSizeY))
		EndIf
	End Method
	
	' Update
	Method Update()
		If PointInRect(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), Self.screenX, Self.screenY, Self.rWidth, Self.rHeight)
			gui.TryToSetHoverWidget(Self)
			
			If TInputSystem.GetMouseHit(1)
				Self.ToggleState()
				
				' OnClick handler
				If Self.onClick <> Null
					Self.onClick(Self.GetAffectingWidget())
				EndIf
			EndIf
		EndIf
	End Method
	
	' Draw
	Method Draw()
		Local checkBoxImage:TImage = Null
		
		If Self.IsHovered()
			If Self.checked
				checkBoxImage = gui.skin.checkbox.checkedHover
			Else
				checkBoxImage = gui.skin.checkbox.uncheckedHover
			EndIf
		Else
			If Self.checked
				checkBoxImage = gui.skin.checkbox.checked
			Else
				checkBoxImage = gui.skin.checkbox.unchecked
			EndIf
		EndIf
		
		.SetAlpha Self.GetRealAlpha()
		.SetColor Self.r, Self.g, Self.b
		DrawImage checkBoxImage, Self.rX, Self.rY
		
		.SetColor Self.textR, Self.textG, Self.textB
		DrawText Self.text, Self.rX + checkBoxImage.width + gui.skin.checkbox.textOffsetX, Self.rY + checkBoxImage.height / 2 - Self.textSizeY / 2 + gui.skin.checkbox.textOffsetY
	End Method
	
	' Create
	Function Create:TCheckBox(nID:String, nText:String, nX:Int, nY:Int, nWidth:Int = 0, nHeight:Int = 0)
		Local widget:TCheckBox = New TCheckBox
		widget.Init(nID, nText, nX, nY, nWidth, nHeight)
		Return widget
	End Function
End Type

' TCheckBoxSkin
Type TCheckBoxSkin Extends TWidgetSkin
	Field unchecked:TImage
	Field uncheckedHover:TImage
	Field checked:TImage
	Field checkedHover:TImage
	
	Field textOffsetX:Int
	Field textOffsetY:Int
	
	' Load
	Method Load()
		Self.unchecked = Self.imageMgr.Get(Self.name + "-" + "Unchecked")
		Self.uncheckedHover = Self.imageMgr.Get(Self.name + "-" + "Unchecked-Hover")
		Self.checked = Self.imageMgr.Get(Self.name + "-" + "Checked")
		Self.checkedHover = Self.imageMgr.Get(Self.name + "-" + "Checked-Hover")
		
		' Ini
		If Self.ini.Load()
			Self.textOffsetX = Int(Self.ini.Get("Widget", "TextOffsetX"))
			Self.textOffsetY = Int(Self.ini.Get("Widget", "TextOffsetY"))
		EndIf
	End Method
	
	' Create
	Function Create:TCheckBoxSkin(nDir:String)
		Local widgetSkin:TCheckBoxSkin = New TCheckBoxSkin
		widgetSkin.Init("CheckBox", nDir)
		Return widgetSkin
	End Function
End Type
