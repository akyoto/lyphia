
' TPopupMenu
Type TPopupMenu Extends TWidget
	' Init
	Method Init(nID:String, nAffectingWidget:TWidget, nX:Int, nY:Int, nWidth:Int, nHeight:Int)
		Self.InitWidget(nID, "", nX, nY, nWidth, nHeight) 
		Self.SetPosition(0, 0)
		Self.SetPositionAbs(0, 0) 
		Self.SetAffectingWidget(nAffectingWidget)
		Self.SetAlpha(1.0)
		Self.SetVisible(False)
	End Method
	
	' SetText
	Method SetText(nText:String)
		Self.text = nText
	End Method
	
	' Update
	Method Update() 
		If TInputSystem.GetMouseHit(1) Or TInputSystem.GetMouseHit(2)
			Self.SetVisible(False)
			
			' Erase mouse events
			TInputSystem.EraseMouseEvents()
			gui.eraseMouseEvents = True
		EndIf
	End Method
	
	' Draw
	Method Draw()
		' Alpha
		'.SetAlpha gui.alpha * Self.alpha
		
		'.SetColor Self.r, Self.g, Self.b
		'DrawRect Self.rX, Self.rY, Self.rWidth, Self.rHeight
		
		'.SetColor Self.textR, Self.textG, Self.textB
		'DrawText Self.text, Self.rX + 15, Self.rY + 0
	End Method
	
	' Popup
	Method Popup()
		Self.PopupAt(TInputSystem.GetMouseX(), TInputSystem.GetMouseY())
	End Method
	
	' PopupAt
	Method PopupAt(posX:Int, posY:Int)
		If posX + Self.rWidth > Self.gui.root.rWidth
			posX = Self.gui.root.rWidth - Self.rWidth
		End If
		If posY + Self.rHeight > Self.gui.root.rHeight
			posY = Self.gui.root.rHeight - Self.rHeight
		End If
		
		Self.MoveTo(posX, posY)
		Self.SetVisible(True)
		Self.Focus()
		
		' Erase mouse events
		TInputSystem.EraseMouseEvents()
	End Method
	
	' SetAffectingWidget
	Method SetAffectingWidget(widget:TWidget)
		Super.SetAffectingWidget(widget)
		
		For Local child:TWidget = EachIn Self.list
			child.SetAffectingWidget(widget)
		Next
	End Method
	
	' AddMenuItem
	Method AddMenuItem(nID:String, nText:String, nFunc(widget:TWidget), icon:TImage = Null, iconFrame:Int = 0) 
		' TODO: Change widget
		Local button:TMenuButton = TMenuButton.Create(nID, nText)
		button.SetAffectingWidget(button)
		button.onClick = nFunc
		button.SetSize(1.0, 0)
		button.SetSizeAbs(0, 24)
		button.SetAlpha(Self.alpha)
		button.SetPositionAbs(0, 24 * Self.list.Count())
		button.SetPadding(5, 5, 5, 5)
		button.GetLabel().Dock(TWidget.DOCK_LEFT)
		Self.Add(button)
		
		' Add icon
		If icon <> Null
			Self.SetMenuItemIcon(nID, icon, iconFrame)
		EndIf
		
		Self.SetSizeAbs(Max(button.GetLabel().textSizeX + button.padding.x1 + button.padding.x2, Self.rWidth), 24 * Self.list.Count())
	End Method
	
	' SetMenuItemIcon
	Method SetMenuItemIcon(nID:String, iconImage:TImage = Null, iconFrame:Int = 0)
		Local button:TButton = TMenuButton(Self.GetChild(nID))
		If button <> Null
			If button.GetChild(button.GetID() + "_icon")
				button.GetChild(button.GetID() + "_icon").Remove()
			EndIf
			
			Local icon:TImageBox = TImageBox.Create(nID + "_icon", iconImage, iconFrame)
			Local iconSize:Int = button.rHeight - (button.padding.y1 + button.padding.y2)
			icon.SetSizeAbs(iconSize, iconSize)
			icon.Dock(TWidget.DOCK_RIGHT)
			button.Add(icon)
		EndIf
	End Method
	
	' SetMenuItemText
	Method SetMenuItemText(nID:String, nText:String)
		Local button:TButton = TMenuButton(Self.GetChild(nID))
		If button <> Null
			button.SetText(nText)
			Self.OnFontChange()
		EndIf
	End Method
	
	' SetMenuItemVisibility
	Method SetMenuItemVisibility(nID:String, visible:Int)
		Local button:TButton = TMenuButton(Self.GetChild(nID))
		If button <> Null
			button.SetVisible(visible)
			Self.OnFontChange()
		EndIf
	End Method
	
	' SetMenuItemAffectingWidget
	Method SetMenuItemAffectingWidget(nID:String, nWidget:TWidget)
		Local button:TButton = TMenuButton(Self.GetChild(nID))
		If button <> Null
			button.SetAffectingWidget(nWidget)
		EndIf
	End Method
	
	' OnFontChange
	Method OnFontChange()
		Local count:Int = 0
		Local sizeX:Int = Self.rWidth - Self.rHeight
		Local sizeY:Int = 0
		
		' Find highest values (width + height)
		For Local button:TMenuButton = EachIn Self.list
			button.SetFont(Self.font)
			
			If button.GetLabel().textSizeX + button.padding.x1 + button.padding.x2 > sizeX
				sizeX = button.GetLabel().textSizeX + button.padding.x1 + button.padding.x2
			EndIf
			
			If button.GetLabel().textSizeY + button.padding.y1 + button.padding.y2 > sizeY
				sizeY = button.GetLabel().textSizeY + button.padding.y1 + button.padding.y2
			EndIf
			
			Local iconBox:TImageBox = TImageBox(button.GetChild(button.GetID() + "_icon"))
			If iconBox
				Local iconSize:Int = button.rHeight - (button.padding.y1 + button.padding.y2)
				iconBox.SetSizeAbs(iconSize, iconSize)
			EndIf
			
			count :+ 1
		Next
		
		' Set new size
		Self.SetSizeAbs(sizeX + sizeY, sizeY * count)	' Add sizeY because of icons
		
		count = 0
		For Local button:TMenuButton = EachIn Self.list
			If button.IsVisible()
				' TODO: Remove temporary bugfix for skin (sizeY - 1)
				button.SetPositionAbs(0, (sizeY - 1) * count)
				button.SetSizeAbs(0, sizeY)
				count :+ 1
			EndIf
		Next
	End Method
	
	' Create
	Function Create:TPopupMenu(nID:String, nAffectingWidget:TWidget = Null, nWidth:Int = 0, nHeight:Int = 0)
		Local widget:TPopupMenu = New TPopupMenu
		widget.Init(nID, nAffectingWidget, 0, 0, nWidth, nHeight)
		Return widget
	End Function
End Type

' TMenuBar
Type TMenuBar Extends TWidget
	' Init
	Method Init(nID:String, nText:String, nX:Int, nY:Int, nWidth:Int, nHeight:Int)
		Self.InitWidget(nID, nText, nX, nY, nWidth, nHeight)
	End Method
	
	' SetText
	Method SetText(nText:String)
		Self.text = nText
	End Method
	
	' Update
	Method Update() 
		
	End Method
	
	' Draw
	Method Draw()
		' Alpha
		.SetAlpha Self.GetRealAlpha()
		
		.SetColor Self.r, Self.g, Self.b
		DrawRect Self.rX, Self.rY, Self.rWidth, Self.rHeight
	End Method
	
	' AddMenu
	Method AddMenu(nText:String, popupMenu:TPopupMenu)
		' TODO: Change widget
		Local button:TMenuButton = TMenuButton.Create(Self.id + Self.list.Count(), nText)
		button.SetAffectingWidget(button) 
		popupMenu.SetAffectingWidget(button)
		button.SetPopupMenu(popupMenu)
		button.onClick = TMenuBar.PopupSubMenu
		button.SetSize(0, 1.0)
		button.SetSizeAbs(button.GetLabel().textSizeX + 16, 0)
		button.SetAlpha(Self.alpha)
		button.label.Dock(TWidget.DOCK_CENTER)
		Self.Add(button)
		
		' Adjust all buttons
		Self.OnFontChange()
	End Method
	
	' OnFontChange
	Method OnFontChange()
		Local currentPosX:Int = 0
		For Local button:TMenuButton = EachIn Self.list
			button.SetPositionAbs(currentPosX, 0)
			button.SetFont(Self.font)
			button.SetSizeAbs(button.GetLabel().textSizeX + 16, 0)
			
			' TODO: Remove temporary bugfix for skin (button.rWidth - 1)
			currentPosX :+ button.rWidth - 1
		Next
	End Method
	
	' PopupSubMenu
	Function PopupSubMenu(widget:TWidget)
		If widget.GetPopupMenu() <> Null
			widget.GetPopupMenu().PopupAt(widget.GetX(), widget.GetY2())
		EndIf
	End Function
	
	' Create
	Function Create:TMenuBar(nID:String, nText:String, nWidth:Int = 0, nHeight:Int = 24)
		Local widget:TMenuBar = New TMenuBar
		widget.Init(nID, nText, 0, 0, nWidth, nHeight)
		Return widget
	End Function
End Type
