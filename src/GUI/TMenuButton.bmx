
' TMenuButton
Type TMenuButton Extends TButton
		
	' Update
	Method Update()
		Self.pressed = False
		
		If PointInRect(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), Self.screenX, Self.screenY, Self.rWidth, Self.rHeight)
			gui.TryToSetHoverWidget(Self)
			
			If TInputSystem.GetMouseHit(1)
				Self.pressed = True
				
				' OnClick handler
				If Self.onClick <> Null
					Self.onClick(Self.GetAffectingWidget())
				EndIf
				
				' Erase mouse events until mouse button is not pressed anymore
				gui.eraseMouseEvents = True
			Else
				' Erase mouse events
				TInputSystem.EraseMouseEvents()
			EndIf
		EndIf
	End Method
	
	' Draw
	Method Draw()
		.SetAlpha Self.GetRealAlpha()
		
		.SetColor Self.r, Self.g, Self.b
		DrawRect Self.rX, Self.rY, Self.rWidth, Self.rHeight
		
		.SetColor 128, 128, 128
		DrawRectOutline Self.rX, Self.rY, Self.rWidth, Self.rHeight
		
		If Self.IsHovered()
			.SetAlpha 0.5 * Self.GetRealAlpha()
			.SetColor 255, 255, 255
			DrawRect Self.rX, Self.rY, Self.rWidth, Self.rHeight
		EndIf
	End Method
		
	' Create
	Function Create:TMenuButton(nID:String, nText:String, nX:Int = 0, nY:Int = 0, nWidth:Int = 0, nHeight:Int = 0)
		Local widget:TMenuButton = New TMenuButton
		widget.Init(nID, nText, nX, nY, nWidth, nHeight)
		Return widget
	End Function
End Type
