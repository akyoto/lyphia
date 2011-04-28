' TTextField
Type TTextField Extends TWidget
	Field onEdit(widget:TWidget)
	Field textSizeY:Int
	Field cursorStart:Int
	Field cursorEnd:Int
	Field cursorX:Int
	Field cursorWidth:Int
	Field cursorLastBlink:Int
	Field savedPosition:Int
	Field onEnterKey(widget:TWidget)
	Field displayCharacter:String
	Field displayText:String
	
	' Virtual Whitespace
	Field virtualWhitespaces:Int
	
	' Init
	Method Init(nID:String, nText:String, nX:Int, nY:Int, nWidth:Int, nHeight:Int)
		Super.InitWidget(nID, nText, nX, nY, nWidth, nHeight)
		Self.SetPadding(5, 5, 5, 5)
		Self.EnableVirtualWhitespaces(False)
		Self.onEnterKey = Null
	End Method
	
	' SetText
	Method SetText(nText:String) 
		Self.text = nText
		Self.textSizeY = TextHeight(nText)
		If Self.cursorStart > Self.text.length
			Self.SetCursorPosition(Self.text.length - 1)
		EndIf
		
		If Self.displayCharacter
			Self.displayText = ""
			For Local I:Int = 1 To Self.text.length
				Self.displayText :+ Self.displayCharacter
			Next
		Else
			Self.displayText = Self.text
		EndIf
	End Method
	
	' SetDisplayCharacter
	Method SetDisplayCharacter(char:String)
		Self.displayCharacter = char
		Self.SetText(Self.GetText())
	End Method
	
	' SetCursorPosition
	Method SetCursorPosition(start:Int, length:Int = 0)
		If start < 0
			start = 0
		ElseIf start > Self.text.Length And Self.virtualWhitespaces = False
			start = Self.text.Length
		End If
		
		Self.cursorStart = start
		
		If length > 0
			Self.cursorEnd = Self.cursorStart + length
		Else
			Self.cursorEnd = Self.cursorStart
			Self.cursorStart:+length
		End If
		
		Self.cursorX = TextWidth(Self.displayText[..Self.cursorStart])
		Self.cursorWidth = TextWidth(Self.displayText[Self.cursorStart..Self.cursorEnd])
		Self.cursorLastBlink = MilliSecs()
	End Method
	
	' EnableVirtualWhitespaces
	Method EnableVirtualWhitespaces(value:Int = True)
		Self.virtualWhitespaces = value
	End Method
	
	' MoveCursorPosition
	Method MoveCursorPosition(offset:Int)
		Self.SetCursorPosition(Self.cursorStart + offset)
	End Method
	
	' GetCursorPositionByPixel
	Method GetCursorPositionByPixel:Int(px:Int)
		Local offset:Int = px - Self.screenX
		
		If offset < 0
			Return 0
		ElseIf offset > TextWidth(Self.displayText)
			Return Self.text.Length
		End If
		
		For Local I:Int = 0 To Self.displayText.Length
			If TextWidth(Self.displayText[..I]) > offset
				Return I - 1
			End If
		Next
		
		Return Self.text.Length - 1
	End Method
	
	' SetCursorPositionByPixel
	Method SetCursorPositionByPixel(px:Int, length:Int = 0)
		Self.SetCursorPosition(Self.GetCursorPositionByPixel(px), length)
	End Method
	
	' Update
	Method Update()
		If PointInRect(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), Self.screenX, Self.screenY, Self.rWidth, Self.rHeight)
			gui.TryToSetHoverWidget(Self)
			
			If TInputSystem.GetMouseHit(1)
				TInputSystem.ResetCharacterQueue()
				Self.Focus()
				
				' Cursor position
				Self.SetCursorPositionByPixel(TInputSystem.GetMouseX())
				Self.savedPosition = Self.cursorStart
				
				' Prevent other gadgets from gaining focus
				TInputSystem.EraseMouseEvents()
				
				' OnClick handler
				If Self.onClick <> Null
					Self.onClick(Self.GetAffectingWidget())
				EndIf
				
				' Erase mouse events until mouse button is not pressed anymore
				'gui.eraseMouseEvents = True
			ElseIf TInputSystem.GetMouseDown(1)
				Local newCurPos:Int = Self.GetCursorPositionByPixel(TInputSystem.GetMouseX())
				Local newLen:Int = newCurPos - Self.savedPosition
				
				Self.SetCursorPosition(Self.savedPosition, newLen)
				
				' Erase mouse events
				'TInputSystem.EraseMouseEvents()
			EndIf
		EndIf
		
		If Self.HasFocus()
			' Delete
			If TInputSystem.GetKeyHit(KEY_DELETE)
				If Self.cursorEnd = Self.cursorStart
					Self.cursorEnd:+1
				End If
				Self.SetText(Self.text[..Self.cursorStart] + Self.text[Self.cursorEnd..])
				Self.cursorEnd = Self.cursorStart
			EndIf
			
			' Left
			If TInputSystem.GetKeyHit(KEY_LEFT)
				Self.MoveCursorPosition(-1)
			EndIf
			
			' Right
			If TInputSystem.GetKeyHit(KEY_RIGHT)
				Self.MoveCursorPosition(1)
			EndIf
			
			' TODO: Copy with Ctrl + C
			
			' Input
			Local char:Int = TInputSystem.GetNextChar()
			Select char
				Case 0
					' Nothing
					
				Case KEY_TAB
					For Local widget:TWidget = EachIn Self.parent.GetChildsList()
						If TTextField(widget) And widget <> Self
							widget.Focus()
							Exit
						EndIf
					Next
					
				Case KEY_ESCAPE
					Self.UnFocus()
					
				Case KEY_ENTER
					If Self.onEnterKey <> Null
						' TODO: Remove this temporary bugfix
						Self.SetAffectingWidget(Self)
						
						Self.onEnterKey(Self.GetAffectingWidget())
					EndIf
					
				Case KEY_BACKSPACE
					If Self.cursorStart = Self.cursorEnd
						Self.cursorStart:-1
					EndIf
					If Self.cursorStart >= 0
						Self.SetText(Self.text[..Self.cursorStart] + Self.text[Self.cursorEnd..])
						Self.SetCursorPosition(Self.cursorStart)
					Else
						Self.cursorStart:+1
					EndIf
					Self.cursorLastBlink = MilliSecs()
					
				Default
					' Ctrl + V
					If TInputSystem.GetKeyDown(KEY_LCONTROL) And TInputSystem.GetKeyDown(KEY_V)
						Local tmpWindow:TGadget = CreateWindow("", 0, 0, 100, 24, Null, WINDOW_HIDDEN)
						Local tmpGadget:TGadget = CreateTextField(0, 0, 100, 24, tmpWindow)
						
						GadgetPaste tmpGadget
						Self.InsertText(GadgetText(tmpGadget))
						
						FreeGadget tmpGadget
						FreeGadget tmpWindow
					EndIf
					
					Self.InsertText(Chr(char))
			End Select
			
			If char <> 0 And char <> KEY_ESCAPE And char <> KEY_ENTER
				' OnEdit handler
				If Self.onEdit <> Null
					' TODO: Remove this temporary bugfix
					Self.SetAffectingWidget(Self)
					
					Self.onEdit(Self.GetAffectingWidget())
				EndIf
			EndIf
			
			TInputSystem.EraseKeyEvents()
		EndIf
	End Method
	
	' InsertText
	Method InsertText(stri:String)
		Self.SetText(Self.text[..Self.cursorStart] + stri + Self.text[Self.cursorEnd..])
		Self.SetCursorPosition(Self.cursorStart + stri.Length)
	End Method
	
	' Draw
	Method Draw()
		.SetAlpha Self.GetRealAlpha()
		
		.SetColor Self.r, Self.g, Self.b
		DrawRect Self.rX, Self.rY, Self.rWidth, Self.rHeight
		
		.SetColor Self.textR, Self.textG, Self.textB
		DrawText Self.displayText, Self.rX + Self.padding.x1, Self.rY + Self.rHeight / 2 - Self.textSizeY / 2
		
		If Self.HasFocus()
			' Cursor
			If MilliSecs() - Self.cursorLastBlink < 500
				DrawRect Self.rX + Self.padding.x1 + Self.cursorX, Self.rY + Self.rHeight / 2 - Self.textSizeY / 2, 1, Self.textSizeY
			ElseIf MilliSecs() - Self.cursorLastBlink > 1000
				Self.cursorLastBlink = MilliSecs()
			EndIf
			
			' Selection
			.SetColor 0, 0, 255
			DrawRect Self.rX + Self.padding.x1 + Self.cursorX, Self.rY + Self.rHeight / 2 - Self.textSizeY / 2, Self.cursorWidth, Self.textSizeY
			
			.SetColor 255, 255, 255
			DrawText Self.text[Self.cursorStart..Self.cursorEnd], Self.rX + Self.padding.x1 + Self.cursorX, Self.rY + Self.rHeight / 2 - Self.textSizeY / 2
		EndIf
		
		.SetColor 0, 0, 0
		DrawRectOutline Self.rX, Self.rY, Self.rWidth, Self.rHeight
		
		If Self.IsHovered()
			.SetAlpha 0.25
			.SetColor 255, 255, 255
			DrawRect Self.rX + 1, Self.rY + 1, Self.rWidth - 2, Self.rHeight - 2
		EndIf
	End Method
	
	' Create
	Function Create:TTextField(nID:String, nText:String = "", nX:Int = 0, nY:Int = 0, nWidth:Int = 0, nHeight:Int = 0)
		Local widget:TTextField = New TTextField
		widget.Init(nID, nText, nX, nY, nWidth, nHeight)
		Return widget
	End Function
End Type