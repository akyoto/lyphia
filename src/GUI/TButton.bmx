
' TButton
Type TButton Extends TWidget
	Field pressed:Int
	Field label:TLabel
	
	' Init
	Method Init(nID:String, nText:String, nX:Int, nY:Int, nWidth:Int, nHeight:Int)
		Super.InitWidget(nID, nText, nX, nY, nWidth, nHeight)
		Self.pressed = 0
		Self.SetPadding(5, 5, 5, 5)
		
		Self.label = TLabel.Create(nID + "_label", nText, 0, 0)
		Self.label.Dock(TWidget.DOCK_CENTER)
		Self.Add(label)
	End Method
	
	' SetText
	Method SetText(nText:String)
		Self.text = nText
		
		If Self.label <> Null
			Self.label.SetText(nText)
		EndIf
	End Method
	
	' GetLabel
	Method GetLabel:TLabel()
		Return Self.label
	End Method
	
	' OnFontChange
	Method OnFontChange()
		Self.label.SetFont(Self.font)
	End Method
	
	' Update
	Method Update()
		If PointInRect(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), Self.screenX, Self.screenY, Self.rWidth, Self.rHeight)
			gui.TryToSetHoverWidget(Self)
			
			If TInputSystem.GetMouseDown(1) = False And Self.pressed = True
				' OnClick handler
				If Self.onClick <> Null
					Self.onClick(Self.GetAffectingWidget())
				EndIf
			EndIf
			
			If TInputSystem.GetMouseHit(1)
				Self.pressed = True
			EndIf
		EndIf
		
		If TInputSystem.GetMouseDown(1) = False
			Self.pressed = False
		EndIf
		
		If Self.pressed
			TInputSystem.EraseMouseEvents()
		EndIf
	End Method
	
	' Draw
	Method Draw()
		.SetAlpha Self.GetRealAlpha()
		
		.SetColor Self.r, Self.g, Self.b
		DrawRect Self.rX, Self.rY, Self.rWidth, Self.rHeight
		
		'.SetColor Self.textR, Self.textG, Self.textB
		'DrawText Self.text, Self.rX + Self.rWidth / 2 - Self.textSizeX / 2, Self.rY + Self.rHeight / 2 - Self.textSizeY / 2
		
		.SetColor 0, 0, 0
		DrawRectOutline Self.rX, Self.rY, Self.rWidth, Self.rHeight
		
		If Self.IsHovered()
			.SetAlpha 0.5 * Self.GetRealAlpha()
			.SetColor 255, 255, 255
			DrawRect Self.rX, Self.rY, Self.rWidth, Self.rHeight
		EndIf
		
		If Self.pressed
			.SetAlpha 0.5 * Self.GetRealAlpha()
			.SetColor 0, 0, 0
			DrawRect Self.rX, Self.rY, Self.rWidth, Self.rHeight
		EndIf
	End Method
	
	' OnGUIAvailable
	Method OnGUIAvailable() 
		Self.label.gui = Self.gui
	End Method
	
	' Create
	Function Create:TButton(nID:String, nText:String, nX:Int = 0, nY:Int = 0, nWidth:Int = 0, nHeight:Int = 0)
		Local widget:TButton = New TButton
		widget.Init(nID, nText, nX, nY, nWidth, nHeight)
		Return widget
	End Function
End Type
