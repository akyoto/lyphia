' Strict
'SuperStrict

' Modules
'Import BRL.Max2D

' Files
Include "TBox.bmx"

' TWidget
Type TWidget Abstract
	Const DOCK_NONE:Int = %00000000
	Const DOCK_LEFT:Int = %00000001
	Const DOCK_RIGHT:Int = %00000010
	Const DOCK_TOP:Int = %00000100
	Const DOCK_BOTTOM:Int = %00001000
	Const DOCK_CENTER:Int = %00010000
	
	Field list:TList
	Field link:TLink
	Field childs:TMap
	
	Field listReversed:TList
	
	Field id:String
	Field text:String
	
	Field cAbs:TBox
	Field cRel:TBoxFloat
	
	Field alpha:Float
	Field r:Byte, g:Byte, b:Byte
	Field textR:Byte, textG:Byte, textB:Byte
	Field visible:Int
	Field font:TImageFont
	
	Field padding:TBox
	Field skinPadding:TBox
	
	Field popupMenu:TPopupMenu
	
	Field dontUpdateChilds:Int
	
	Field metaData:Object
	
	' Parent
	Field gui:TGUI
	Field parent:TWidget
	
	Field canHaveScrollBars:Int
	Field needsScrollBar:Int
	Field scrollOffsetX:Float
	Field scrollOffsetY:Float
	Field scrollOffsetYMax:Int
	Field isDraggingScrollBar:Int
	Field dragScrollBarX:Int
	Field dragScrollBarY:Int
	
	' "Real" coordinates (padding, but still relative to the parent)
	Field rX:Int
	Field rY:Int
	Field rX2:Int
	Field rY2:Int
	Field rWidth:Int
	Field rHeight:Int
	
	' Screen coordinates
	Field screenX:Int
	Field screenY:Int
	
	' Dock
	Field dockType:Int
	
	' Event handlers
	Field affectingWidget:TWidget
	Field onEnter(widget:TWidget)
	Field onLeave(widget:TWidget)
	Field onClick(widget:TWidget)
	Field onVisible(widget:TWidget)
	
	' InitWidget
	Method InitWidget(nID:String, nText:String, nX:Int = 0, nY:Int = 0, nWidth:Int = 0, nHeight:Int = 0)
		Self.list = CreateList()
		Self.listReversed = CreateList()
		Self.childs = CreateMap()
		Self.id = nID
		
		Self.cAbs = TBox.Create()
		Self.cRel = TBoxFloat.Create()
		Self.padding = TBox.Create()
		Self.skinPadding = TBox.Create()
		
		Self.canHaveScrollBars = False
		Self.dontUpdateChilds = False
		
		Self.Dock(DOCK_NONE)
		'Self.Dock(DOCK_LEFT | DOCK_RIGHT)
		
		Self.SetPosition(0, 0)
		Self.SetPositionAbs(nX, nY)
		Self.SetSize(0, 0)
		Self.SetSizeAbs(nWidth, nHeight)
		
		Self.SetColor(255, 255, 255)
		Self.SetAlpha(1.0)
		Self.SetTextColor(0, 0, 0)
		Self.SetPadding(0, 0, 0, 0)
		Self.SetText(nText) 
		Self.SetVisible(True) 
		Self.SetAffectingWidget(Self)
		
		Self.SetMetaData(Null)
	End Method
	
	' SetPosition
	Method SetPosition(nX1:Float, nY1:Float) 
		' x2 and y2 will be set initially in SetSize and SetSizeAbs
		Self.cRel.x2 :+ nX1 - Self.cRel.x1
		Self.cRel.y2 :+ nY1 - Self.cRel.y1
		Self.cRel.x1 = nX1
		Self.cRel.y1 = nY1
		
		Self.UpdatePosition()
	End Method
	
	' SetPositionAbs
	Method SetPositionAbs(nX1:Int, nY1:Int) 
		' x2 and y2 will be set initially in SetSize and SetSizeAbs
		Self.cAbs.x2 :+ nX1 - Self.cAbs.x1
		Self.cAbs.y2 :+ nY1 - Self.cAbs.y1
		Self.cAbs.x1 = nX1
		Self.cAbs.y1 = nY1
		
		Self.UpdatePosition()
	End Method
	
	' SetSize
	Method SetSize(nWidth:Float = -1.0, nHeight:Float = -1.0)
		If nWidth <> -1.0
			Self.cRel.x2 = Self.cRel.x1 + nWidth
		EndIf
		
		If nHeight <> -1.0
			Self.cRel.y2 = Self.cRel.y1 + nHeight
		EndIf
		
		Self.UpdatePosition()
		Self.UpdateDock()
	End Method
	
	' SetSizeAbs
	Method SetSizeAbs(nWidth:Int, nHeight:Int)
		If nWidth <> -1
			Self.cAbs.x2 = Self.cAbs.x1 + nWidth
		EndIf
		
		If nHeight <> -1
			Self.cAbs.y2 = Self.cAbs.y1 + nHeight
		EndIf
		
		Self.UpdatePosition()
		Self.UpdateDock()
	End Method
	
	' SetScrollOffset
	Method SetScrollOffset(nOffsetX:Int, nOffsetY:Int = -1)
		If nOffsetX <> -1
			Self.scrollOffsetX = nOffsetX
		EndIf
		
		If nOffsetY <> -1
			Self.scrollOffsetY = nOffsetY
		EndIf
	End Method
	
	' SetColor
	Method SetColor(nR:Int, nG:Int, nB:Int)
		Self.r = nR
		Self.g = nG
		Self.b = nB
	End Method
	
	' SetTextColor
	Method SetTextColor(nR:Int, nG:Int, nB:Int)
		Self.textR = nR
		Self.textG = nG
		Self.textB = nB
	End Method
	
	' SetAlpha
	Method SetAlpha(nAlpha:Float)
		Self.alpha = nAlpha
	End Method
	
	' SetFont
	Method SetFont(nFont:TImageFont)
		Self.font = nFont
		Self.OnFontChange()
	End Method
	
	' SetFontAll
	Method SetFontAll(nFont:TImageFont)
		Self.SetFont(nFont)
		Self.OnFontChange()
		For Local widget:TWidget = EachIn Self.list
			widget.SetFontAll(nFont)
		Next
	End Method
	
	' SetPadding
	Method SetPadding(nPaddingLeft:Int, nPaddingTop:Int, nPaddingRight:Int, nPaddingBottom:Int)
		Self.padding.x1 = nPaddingLeft
		Self.padding.y1 = nPaddingTop
		Self.padding.x2 = nPaddingRight
		Self.padding.y2 = nPaddingBottom
	End Method
	
	' SetVisible
	Method SetVisible(show:Int)
		' OnVisible handler
		If Self.visible = False And show = True And Self.onVisible <> Null
			Self.onVisible(Self.GetAffectingWidget())
		EndIf
		
		Self.visible = show
	End Method
	
	' SetAffectingWidget
	Method SetAffectingWidget(widget:TWidget)
		Self.affectingWidget = widget
	End Method
	
	' SetPopupMenu
	Method SetPopupMenu(menu:TPopupMenu) 
		Self.popupMenu = menu
	End Method
	
	' SetMetaData
	Method SetMetaData(obj:Object)
		Self.metaData = obj
	End Method
	
	' ToggleVisibility
	Method ToggleVisibility()
		Self.SetVisible(1 - Self.IsVisible())
	End Method
	
	' IsVisible
	Method IsVisible:Int()
		Return Self.visible
	End Method
	
	' IsHovered
	Method IsHovered:Int()
		Return gui.hoverWidget = Self
	End Method
	
	' IsChildOf
	Method IsChildOf:Int(widget:TWidget)
		Return Self.parent = widget
	End Method
	
	' IsEmpty
	Method IsEmpty:Int()
		Return Self.list.IsEmpty()
	End Method
	
	' Contains
	Method Contains:Int(id:String)
		Return Self.childs.Contains(id)
	End Method
	
	' ContainsWidget
	Method ContainsWidget:Int(widget:TWidget)
		Return Self.childs.Contains(widget.GetID())
	End Method
	
	' GetAffectingWidget
	Method GetAffectingWidget:TWidget()
		Return Self.affectingWidget
	End Method
	
	' GetPopupMenu
	Method GetPopupMenu:TPopupMenu() 
		Return Self.popupMenu
	End Method
	
	' GetID
	Method GetID:String()
		Return Self.id
	End Method
	
	' GetParent
	Method GetParent:TWidget()
		Return Self.parent
	End Method
	
	' GetText
	Method GetText:String()
		Return Self.text
	End Method
	
	' GetX
	Method GetX:Int()
		Return Self.screenX
	End Method
	
	' GetY
	Method GetY:Int()
		Return Self.screenY
	End Method
	
	' GetX2
	Method GetX2:Int()
		Return Self.screenX + Self.rWidth
	End Method
	
	' GetY2
	Method GetY2:Int()
		Return Self.screenY + Self.rHeight
	End Method
	
	' GetWidth
	Method GetWidth:Int()
		Return Self.rWidth
	End Method
	
	' GetHeight
	Method GetHeight:Int()
		Return Self.rHeight
	End Method
	
	' GetRelOffsetX
	Method GetRelOffsetX:Int()
		Return Self.rX - Self.cAbs.x1
	End Method
	
	' GetRelOffsetY
	Method GetRelOffsetY:Int()
		Return Self.rY - Self.cAbs.y1
	End Method
	
	' GetAlpha
	Method GetAlpha:Float()
		Return Self.alpha
	End Method
	
	' GetMouseX
	Method GetMouseX:Int()
		Return TInputSystem.GetMouseX() - Self.screenX
	End Method
	
	' GetMouseY
	Method GetMouseY:Int()
		Return TInputSystem.GetMouseY() - Self.screenY
	End Method
	
	' GetRealAlpha
	Method GetRealAlpha:Float()
		Return Self.alpha * gui.alpha
	End Method
	
	' GetChild
	Method GetChild:TWidget(id:String)
		Return TWidget(Self.childs.ValueForKey(id))
	End Method
	
	' GetChildByIndex
	Method GetChildByIndex:TWidget(index:Int)
		Return TWidget(Self.list.ValueAtIndex(index))
	End Method
	
	' GetChildsList
	Method GetChildsList:TList()
		Return Self.list
	End Method
	
	' GetChildsMap
	Method GetChildsMap:TMap()
		Return Self.childs
	End Method
	
	' GetNumberOfChilds
	Method GetNumberOfChilds:Int()
		Return Self.list.Count()
	End Method
	
	' GetRealViewport
	Method GetRealViewport(x:Int Var, y:Int Var, width:Int Var, height:Int Var)
		' TODO: Implement GetRealViewport
	End Method
	
	' GetFont
	Method GetFont:TImageFont()
		Return Self.font
	End Method
	
	' GetMetaData
	Method GetMetaData:Object()
		Return Self.metaData
	End Method
	
	' HasChilds
	Method HasChilds:Int()
		Return Self.list.IsEmpty() = False
	End Method
	
	' CollidesWithMouse
	Method CollidesWithMouse:Int()
		Return PointInRect(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), Self.screenX, Self.screenY, Self.rWidth, Self.rHeight)
	End Method
	
	' Dock
	Method Dock(where:Int)
		Self.dockType = where
		Self.UpdateDock()
	End Method
	
	' UpdateDock
	Method UpdateDock()
		If Self.dockType = TWidget.DOCK_NONE
			Return
		EndIf
		
		Local xRel:Float = 0.5
		Local yRel:Float = 0.5
		
		' Bottom/Top
		If Self.dockType & TWidget.DOCK_BOTTOM
			yRel = 1.0
		ElseIf Self.dockType & TWidget.DOCK_TOP
			yRel = 0.0
		EndIf
		
		' Right/Left
		If Self.dockType & TWidget.DOCK_RIGHT
			xRel = 1.0
		ElseIf Self.dockType & TWidget.DOCK_LEFT
			xRel = 0.0
		EndIf
		
		' Center
		If Self.dockType & TWidget.DOCK_CENTER
			xRel = 0.5
			yRel = 0.5
		EndIf
		
		Self.SetPosition(xRel, yRel)
		Self.SetPositionAbs(-Self.rWidth * xRel, -Self.rHeight * yRel)
	End Method
	
	' UpdatePosition
	Method UpdatePosition()
		' TODO: Update
		If parent <> Null
			Self.rX = Self.cAbs.x1 + Self.cRel.x1 * (Self.parent.rWidth - Self.parent.skinPadding.x1 - Self.parent.skinPadding.x2 - Self.parent.padding.x1 - Self.parent.padding.x2)
			Self.rY = Self.cAbs.y1 + Self.cRel.y1 * (Self.parent.rHeight - Self.parent.skinPadding.y1 - Self.parent.skinPadding.y2 - Self.parent.padding.y1 - Self.parent.padding.y2)
			Self.rX2 = Self.cAbs.x2 + Self.cRel.x2 * (Self.parent.rWidth - Self.parent.skinPadding.x1 - Self.parent.skinPadding.x2 - Self.parent.padding.x1 - Self.parent.padding.x2)
			Self.rY2 = Self.cAbs.y2 + Self.cRel.y2 * (Self.parent.rHeight - Self.parent.skinPadding.y1 - Self.parent.skinPadding.y2 - Self.parent.padding.y1 - Self.parent.padding.y2) 
		Else
			Self.rX = Self.cAbs.x1 + Self.cRel.x1 * GraphicsWidth()
			Self.rY = Self.cAbs.y1 + Self.cRel.y1 * GraphicsHeight()
			Self.rX2 = Self.cAbs.x2 + Self.cRel.x2 * GraphicsWidth()
			Self.rY2 = Self.cAbs.y2 + Self.cRel.y2 * GraphicsHeight()
		EndIf
		
		Self.rWidth = Self.rX2 - Self.rX
		Self.rHeight = Self.rY2 - Self.rY
		
		Self.UpdateScreenPosition()
		
		' Check for scroll bar
		If Self.parent <> Null And Self.parent.canHaveScrollBars And (Self.rX2 > Self.parent.rX2 Or Self.rY2 > Self.parent.rY2)
			Self.parent.needsScrollBar = True
			Self.parent.scrollOffsetYMax = Max(Self.rY2 - Self.parent.rY2, Self.parent.scrollOffsetYMax)
		EndIf
		'DrawRect Self.rX1, Self.rY1, Self.rX2 - Self.rX, Self.rY2 - Self.rY
	End Method
	
	' UpdateScreenPosition
	Method UpdateScreenPosition()
		If Self.parent <> Null
			Self.screenX = Self.parent.screenX - Self.parent.scrollOffsetX + Self.parent.skinPadding.x1 + Self.parent.padding.x1 + Self.rX
			Self.screenY = Self.parent.screenY - Self.parent.scrollOffsetY + Self.parent.skinPadding.y1 + Self.parent.padding.y1 + Self.rY
		Else
			Self.screenX = Self.rX
			Self.screenY = Self.rY
		EndIf
		
		Self.needsScrollBar = False
		
		' Update childs
		For Local widget:TWidget = EachIn Self.list
			widget.UpdatePosition()
		Next
	End Method
	
	' UseCurrentAreaAsClientArea
	Method UseCurrentAreaAsClientArea()
		Self.cAbs.ExpandBox(Self.skinPadding)
		Self.UpdatePosition()
	End Method
	
	' MoveTo
	Method MoveTo(toX:Int, toY:Int)
		' Moves the window to the specified position, ignoring relative positioning
		Self.SetPositionAbs(toX - Self.GetRelOffsetX(), toY - Self.GetRelOffsetY())
	End Method
	
	' ScrollToMin
	Method ScrollToMin()
		Self.scrollOffsetY = 0
	End Method
	
	' ScrollToMax
	Method ScrollToMax()
		Self.scrollOffsetY = Self.scrollOffsetYMax
	End Method
	
	' DrawAll
	Method DrawAll() 
		If Self.visible = False
			Return
		EndIf
		
		ResetMax2D()
		If Self.font <> Null
			SetImageFont Self.font
		EndIf
		Self.Draw()
		
		' Calculate view port coords
		Local vpX:Int, vpY:Int, vpWidth:Int, vpHeight:Int
		Local oldX:Int, oldY:Int, oldWidth:Int, oldHeight:Int
		GetViewport(oldX, oldY, oldWidth, oldHeight)
		
		vpX = Self.screenX + Self.skinPadding.x1 + Self.padding.x1
		vpY = Self.screenY + Self.skinPadding.y1 + Self.padding.y1
		vpWidth = Self.rWidth - Self.skinPadding.x2 - Self.skinPadding.x1 - Self.padding.x2 - Self.padding.x1
		vpHeight = Self.rHeight - Self.skinPadding.y2 - Self.skinPadding.y1 - Self.padding.y2 - Self.padding.y1
		
		' Debug
		'Print Self.id
		'Print "[OLD] " + oldX + ", " + oldY + ", " + oldWidth + ", " + oldHeight
		'Print "[NEW] " + vpX + ", " + vpY + ", " + vpWidth + ", " + vpHeight
		
		SetViewportInViewport vpX, vpY, vpWidth, vpHeight, oldX, oldY, oldWidth, oldHeight
		
		' Draw childs
		For Local widget:TWidget = EachIn Self.list
			' TODO: Track scroll changes
			If Self.needsScrollBar
				widget.UpdateScreenPosition()
			EndIf
			
			ResetMax2D()
			.SetOrigin Self.screenX + Self.skinPadding.x1 + Self.padding.x1, Self.screenY + Self.skinPadding.y1 + Self.padding.y1
			widget.DrawAll()
		Next
		
		Self.DrawEnd()
		
		' Scroll bar
		' TODO: Remove hardcoded stuff
		If Self.needsScrollBar
			Local dragBarHeightRel:Float = Self.rHeight / Float(Self.rHeight + Self.scrollOffsetYMax)
			
			If Self.CollidesWithMouse() Or Self.isDraggingScrollBar
				.SetAlpha Self.GetRealAlpha()
			Else
				.SetAlpha Self.GetRealAlpha() * 0.1
			EndIf
			
			.SetOrigin Self.screenX + Self.skinPadding.x1 + Self.padding.x1, Self.screenY + Self.skinPadding.y1 + Self.padding.y1
			.SetColor 192, 192, 192
			DrawRect Self.rWidth - 16, 0, 16, Self.rHeight
			.SetColor 64, 64, 64
			DrawRect Self.rWidth - 16, Self.scrollOffsetY * dragBarHeightRel, 16, Self.rHeight * dragBarHeightRel
			.SetColor 0, 0, 0
			DrawRectOutline Self.rWidth - 16, 0, 16, Self.rHeight
			DrawRectOutline Self.rWidth - 16, Self.scrollOffsetY * dragBarHeightRel, 16, Self.rHeight * dragBarHeightRel
		EndIf
		
		.SetOrigin 0, 0
		.SetViewport oldX, oldY, oldWidth, oldHeight
	End Method
	
	' UpdateAll
	Method UpdateAll()
		If Self.visible = False
			Return
		EndIf
		
		' Scroll bar
		If Self.needsScrollBar
			Local dragBarHeightRel:Float = Self.rHeight / Float(Self.rHeight + Self.scrollOffsetYMax)
			
			If TInputSystem.GetMouseDown(1) = False
				Self.isDraggingScrollBar = False
			EndIf
			
			If Self.CollidesWithMouse()
				Self.scrollOffsetY :- TInputSystem.GetMouseZSpeed() * 20
				'TInputSystem.EraseMouseSpeed()
				
				If PointInRect(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), Self.screenX + Self.rWidth - 16, Self.screenY, 16, Self.rHeight)
					If PointInRect(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), Self.screenX + Self.rWidth - 16, Self.screenY + Self.scrollOffsetY * dragBarHeightRel, 16, Self.rHeight * dragBarHeightRel)
						If TInputSystem.GetMouseHit(1)
							Self.dragScrollBarY = TInputSystem.GetMouseY() - (Self.screenY + Self.scrollOffsetY * dragBarHeightRel)
							Self.isDraggingScrollBar = True
						EndIf
					ElseIf Self.isDraggingScrollBar = False
						If TInputSystem.GetMouseHit(1)
							If TInputSystem.GetMouseY() < Self.screenY + Self.scrollOffsetY * dragBarHeightRel
								Self.scrollOffsetY :- Self.rHeight
							Else
								Self.scrollOffsetY :+ Self.rHeight
							EndIf
						EndIf
					EndIf
					
					TInputSystem.EraseMouseEvents()
				EndIf
			EndIf
			
			If Self.isDraggingScrollBar
				'Self.scrollOffsetY = ((TInputSystem.GetMouseY() - Self.screenY) / Float(Self.rHeight)) * Self.scrollOffsetYMax
				Self.scrollOffsetY = (TInputSystem.GetMouseY() - Self.screenY - Self.dragScrollBarY) / dragBarHeightRel
				TInputSystem.EraseMouseEvents()
			EndIf
			
			If Self.scrollOffsetY < 0
				Self.scrollOffsetY = 0
			ElseIf Self.scrollOffsetY > Self.scrollOffsetYMax
				Self.scrollOffsetY = Self.scrollOffsetYMax
			EndIf
		EndIf
		
		' Update childs
		If Self.dontUpdateChilds = False
			For Local widget:TWidget = EachIn Self.listReversed
				' TODO: Track scroll changes
				If Self.needsScrollBar
					widget.UpdateScreenPosition()
				EndIf
				widget.UpdateAll()
			Next
		EndIf
		
		Self.Update()
	End Method
	
	' InitSkinPadding
	Method InitSkinPadding() 
		' override this method
	End Method
	
	' Add
	Method Add(widget:TWidget)
		widget.link = Self.list.AddLast(widget)
		widget.parent = Self
		widget.gui = Self.gui
		Self.listReversed.AddFirst(widget)
		Self.childs.Insert(widget.GetID(), widget) 
		
		If Self.gui <> Null And Self <> Self.gui.root And widget.popupMenu <> Null And widget.popupMenu.parent = Null
			Self.gui.AddMenu(widget.popupMenu) 
		EndIf
		
		' Widget childs (update every child -> widget.gui needs to be set manually)
		If widget.gui <> Null
			' TODO: Updating childs is needed ?
			widget.InvokeOnGUIAvailable()
		EndIf
		
		' Due to "late skin binding" padding has to be updated
		widget.InitSkinPadding() 
		widget.UpdatePosition()
		
		Self.UpdateScreenPosition()
	End Method
	
	' Remove
	Method Remove()
		Self.link.Remove()
		
		' Null
		Self.affectingWidget = Null
		
		' TODO: Optimize
		If Self.parent <> Null
			Self.parent.listReversed = Self.parent.list.Reversed() 
			Self.parent.childs.Remove(Self.GetID())
		EndIf
	End Method
	
	' Focus
	Method Focus()
		gui.newFocusWidget = Self
		TGUI.logger.Write("Focus: " + Self.text)
	End Method
	
	' UnFocus
	Method UnFocus()
		gui.newFocusWidget = Null
	End Method
	
	' HasFocus
	Method HasFocus:Int()
		Return gui.focusWidget = Self
	End Method
	
	' ApplyLayoutTable
	' DEPRECATED FUNCTION
	Method ApplyLayoutTable(rows:Int, columns:Int = 1, vertically:Int = False)
		Local cellWidth:Float = 1.0 / columns
		Local cellHeight:Float = 1.0 / rows
		Local iterX:Int = 0
		Local iterY:Int = 0
		
		For Local widget:TWidget = EachIn Self.list
			widget.SetPositionAbs(0, 0)
			widget.SetSizeAbs(0, 0)
			widget.SetPosition(iterX * cellWidth, iterY * cellHeight)
			widget.SetSize(cellWidth, cellHeight)
			
			If vertically
				iterY :+ 1
				If iterY >= rows
					iterY = 0
					iterX :+ 1
				EndIf
			Else
				iterX :+ 1
				If iterX >= columns
					iterX = 0
					iterY :+ 1
				EndIf
			EndIf
		Next
	End Method
	
	' PrintDebug
	Method PrintDebug()
		If Self.parent <> Null
			Print Self.id + ".parent: " + Self.parent.id
		EndIf
		Print Self.id + ".visible: " + Self.IsVisible()
		Print Self.id + ".cAbs: " + Self.cAbs.ToString()
		Print Self.id + ".cRel: " + Self.cRel.ToString() 
		Print Self.id + ".rPos: " + Self.rX + ", " + Self.rY + ", " + Self.rWidth + ", " + Self.rHeight
		Print Self.id + ".screenPos: " + Self.screenX + ", " + Self.screenY
		Print Self.id + ".padding: " + Self.padding.ToString()
		Print Self.id + ".skinPadding: " + Self.skinPadding.ToString()
	End Method
	
	' Clear
	Method Clear()
		For Local child:TWidget = EachIn Self.list
			child.Remove()
		Next
	End Method
	
	' InvokeOnGUIAvailable
	Method InvokeOnGUIAvailable()
		For Local child:TWidget = EachIn Self.list
			child.gui = Self.gui
			child.InvokeOnGUIAvailable()
		Next
		
		' Assign font
		If Self.font = Null
			If Self.parent <> Null And Self.parent.font <> Null
				Self.SetFont(Self.parent.font)
			ElseIf Self.gui.root <> Null And Self.gui.root.font <> Null
				Self.SetFont(Self.gui.root.font)
			EndIf
		EndIf
		
		Self.OnGUIAvailable()
		Self.UpdateDock()
	End Method
	
	' OnFontChange
	Method OnFontChange() 
		
	End Method
	
	' OnGUIAvailable
	Method OnGUIAvailable() 
		
	End Method
	
	' Update
	Method Update() Abstract
	
	' Draw
	Method Draw() Abstract
	
	' DrawEnd
	Method DrawEnd()
		
	End Method
	
	' SetText
	Method SetText(nText:String) Abstract
End Type
