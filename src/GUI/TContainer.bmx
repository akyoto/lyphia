
' TContainer
Type TContainer Extends TWidget
	' Init
	Method Init(nID:String)
		Self.InitWidget(nID, "")
		'Self.SetPosition(0, 0)
		'Self.SetSize(1, 1)
	End Method
	
	' SetText
	Method SetText(nText:String)
		Self.text = nText
	End Method
	
	' Update
	Method Update()
		If PointInRect(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), Self.screenX, Self.screenY, Self.rWidth, Self.rHeight)
			gui.TryToSetHoverWidget(Self)
			
			If TInputSystem.GetMouseHit(1)
				' TODO: Focus (for root container)
				'Self.Focus()
				
				' OnClick handler
				If Self.onClick <> Null
					Self.onClick(Self.GetAffectingWidget())
				EndIf
			EndIf
		EndIf
	End Method
	
	' Draw
	Method Draw()
		
	End Method
	
	' Create
	Function Create:TContainer(nID:String)
		Local widget:TContainer = New TContainer
		widget.Init(nID)
		Return widget
	End Function
End Type


