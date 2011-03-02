
' TListBox
Type TListBox Extends TWidget
	Const ITEM_NONE:Int = -1
	
	Field itemHeight:Int
	Field selectedItemIndex:Int
	Field onItemChange(widget:TWidget)
	
	' Init
	Method Init(nID:String, nX:Int, nY:Int, nWidth:Int, nHeight:Int)
		Self.InitWidget(nID, "", nX, nY, nWidth, nHeight)
		Self.canHaveScrollBars = True
		Self.itemHeight = 20
		Self.selectedItemIndex = TListBox.ITEM_NONE
	End Method
	
	' SetText
	Method SetText(nText:String)
		
	End Method
	
	' GetText
	Method GetText:String()
		Return Self.GetItemText()
	End Method
	
	' AddItem
	Method AddItem(nText:String, nIcon:TImage = Null, nIconFrame:Int = 0, nTip:String = "")
		Local item:TContainer = TContainer.Create(Self.id + "_item" + Self.list.Count())
		item.SetAffectingWidget(Self.GetAffectingWidget())
		item.SetSize(1.0, 0)
		item.SetSizeAbs(0, Self.itemHeight)
		item.SetPadding(5, 0, 5, 0)
		
		Local label:TLabel = TLabel.Create(item.id + "_label", nText, 0, 0)
		label.Dock(TWidget.DOCK_LEFT)
		item.Add(label)
		
		' TODO: Icon + Tooltip
		Rem
		' Add icon
		If icon <> Null
			Self.SetItemIcon(nID, icon, iconFrame)
		EndIf
		End Rem
		
		Self.Add(item)
		Self.Rearrange()
	End Method
	
	' GetSelectedItem
	Method GetSelectedItem:Int()
		Return Self.selectedItemIndex
	End Method
	
	' SelectItem
	Method SelectItem(newIndex:Int)
		If newIndex < 0 Or newIndex >= Self.GetNumberOfChilds()
			newIndex = TListBox.ITEM_NONE
		EndIf
		If newIndex <> Self.selectedItemIndex
			Self.selectedItemIndex = newIndex
			If Self.onItemChange <> Null
				Self.onItemChange(Self.GetAffectingWidget())
			EndIf
		EndIf
	End Method
	
	' SetItemText
	Method SetItemText(nIndex:Int = -2, nText:String)
		If nIndex = -2
			nIndex = Self.selectedItemIndex
		EndIf
		
		If nIndex = TListBox.ITEM_NONE
			Return
		EndIf
		
		Local widget:TWidget = TWidget(Self.GetChildsList().ValueAtIndex(nIndex))
		widget.GetChild(widget.GetID() + "_label").SetText(nText)
	End Method
	
	' GetItemText
	Method GetItemText:String(nIndex:Int = -2)
		If nIndex = -2
			nIndex = Self.selectedItemIndex
		EndIf
		
		If nIndex = TListBox.ITEM_NONE
			Return ""
		EndIf
		
		Local widget:TWidget = TWidget(Self.GetChildsList().ValueAtIndex(nIndex))
		Return widget.GetChild(widget.GetID() + "_label").GetText()
	End Method
	
	' RemoveItemByText
	Method RemoveItemByText:Int(txt:String)
		For Local widget:TWidget = EachIn Self.GetChildsList()
			If widget.GetChild(widget.GetID() + "_label").GetText() = txt
				widget.Remove()
				Self.Rearrange()
				Return True
			EndIf
		Next
		Return False
	End Method
	
	' Update
	Method Update() 
		If PointInRect(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), Self.screenX, Self.screenY, Self.rWidth, Self.rHeight)
			gui.TryToSetHoverWidget(Self)
			
			If TInputSystem.GetMouseHit(1)
				Self.Focus()
				
				' OnItemChange handler
				If Self.HasChilds()
					Local newIndex:Int = Self.GetChildByIndex(0).GetMouseY() / Self.itemHeight
					Self.SelectItem(newIndex)
				EndIf
				
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
		' Alpha
		.SetAlpha Self.GetRealAlpha()
		
		.SetColor Self.r, Self.g, Self.b
		DrawRect Self.rX, Self.rY, Self.rWidth, Self.rHeight
		
		.SetColor Self.textR, Self.textG, Self.textB
		'DrawText Self.text, Self.rX + 15, Self.rY + 0
		DrawRectOutline Self.rX, Self.rY, Self.rWidth, Self.rHeight
		
		.SetAlpha 0.5 * Self.GetRealAlpha()
		.SetColor 0, 128, 255
		If Self.selectedItemIndex <> TListBox.ITEM_NONE And Self.HasChilds()
			DrawRect Self.rX - Self.scrollOffsetX, Self.rY - Self.scrollOffsetY + Self.selectedItemIndex * Self.itemHeight, Self.rWidth, Self.itemHeight
		EndIf
	End Method
	
	Rem
	' SetAffectingWidget
	Method SetAffectingWidget(widget:TWidget)
		Super.SetAffectingWidget(widget)
		
		For Local child:TWidget = EachIn Self.list
			child.SetAffectingWidget(widget)
		Next
	End Method
	End Rem
	
	Rem
	' SetItemIcon
	Method SetItemIcon(nIndex:Int, icon:TImage = Null, iconFrame:Int = 0)
		Local button:TButton = TButton(Self.GetChild(Self.id + "_item" + nIndex))
		If button <> Null
			Local icon:TImageBox = TImageBox.Create(nID + "_icon", icon, iconFrame)
			Local iconSize:Int = button.rHeight - (button.padding.y1 + button.padding.y2)
			icon.SetSizeAbs(iconSize, iconSize)
			icon.Dock(TWidget.DOCK_RIGHT)
			button.Add(icon)
		EndIf
	End Method
	
	' SetItemText
	Method SetItemText(nIndex:Int, nText:String)
		Local button:TButton = TButton(Self.GetChild(Self.id + "_item_label" + nIndex))
		If button <> Null
			button.SetText(nText)
			Self.OnFontChange()
		EndIf
	End Method
	
	' OnFontChange
	Method OnFontChange()
		Local count:Int = 0
		Local sizeX:Int = Self.rWidth
		Local sizeY:Int = 0
		
		' Find highest values (width + height)
		For Local button:TButton = EachIn Self.list
			button.SetFont(Self.font)
			
			If button.GetLabel().textSizeX + button.padding.x1 + button.padding.x2 > sizeX
				sizeX = button.GetLabel().textSizeX + button.padding.x1 + button.padding.x2
			EndIf
			
			If button.GetLabel().textSizeY + button.padding.y1 + button.padding.y2 > sizeY
				sizeY = button.GetLabel().textSizeY + button.padding.y1 + button.padding.y2
			EndIf
			
			count :+ 1
		Next
		
		' Set new size
		Self.SetSizeAbs(sizeX, sizeY * count)
		
		count = 0
		For Local button:TButton = EachIn Self.list
			button.SetPositionAbs(0, sizeY * count)
			button.SetSizeAbs(0, sizeY)
			count :+ 1
		Next
	End Method
	End Rem
	
	' Rearrange
	Method Rearrange()
		Local count:Int = 0
		
		For Local item:TWidget = EachIn Self.list
			item.SetPositionAbs(0, Self.itemHeight * count)
			count :+ 1
		Next
	End Method
	
	' Create
	Function Create:TListBox(nID:String, nX:Int = 0, nY:Int = 0, nWidth:Int = 0, nHeight:Int = 0)
		Local widget:TListBox = New TListBox
		widget.Init(nID, nX, nY, nWidth, nHeight)
		Return widget
	End Function
End Type
