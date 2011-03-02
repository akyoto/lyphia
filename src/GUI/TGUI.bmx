' Strict
SuperStrict

' Modules
Import BRL.Max2D
Import MaxGUI.Drivers
'Import BtbN.GLDraw2D

' Files
Import "../Global.bmx"
Import "../TLog.bmx"
Import "../TINILoader.bmx"
Import "../TInputSystem.bmx"
Import "../Managers/TImageManager.bmx"
Import "../Utilities/Log.bmx"
Import "../Utilities/Math.bmx"
Import "../Utilities/Graphics.bmx"

' Widgets
Include "TSkin.bmx"
Include "TWidget.bmx"
Include "TWidgetParam.bmx"
Include "TContainer.bmx"
Include "TWindow.bmx"
Include "TLabel.bmx"
Include "TImageBox.bmx"
Include "TCheckBox.bmx"
Include "TListBox.bmx"
Include "TProgressBar.bmx"
Include "TSlider.bmx"
Include "TButton.bmx"
Include "TMenuButton.bmx"
Include "TGroup.bmx"
Include "TPopupMenu.bmx"
Include "TTextField.bmx"

' TGUI
Type TGUI
	Global initializedClass:Int = 0
	Global logger:TLog
	
	Field root:TWidget
	Field popupMenuContainer:TWidget
	Field alpha:Float
	Field cursor:TCursor
	Field skin:TSkin
	
	Field eraseEvents:Int
	Field eraseMouseEvents:Int
	Field oldEraseMouseEvents:Int
	
	Field hoverWidget:TWidget
	Field oldHoverWidget:TWidget
	Field focusWidget:TWidget
	Field newFocusWidget:TWidget
	
	Field noFocusAlpha:Float
	Field shadowOffsetX:Int
	Field shadowOffsetY:Int
	Field shadowIntensity:Float
	
	Field shutdownOnIdle:Int
	Field displayDebugInfo:Int
	Field displayIdleMode:Int
	Field showCursorFlag:Int
	Field idle:Int
	
	' Init
	Method Init()
		If initializedClass = False
			TGUI.InitClass()
		EndIf
		
		TGUI.logger.Write("Initializing GUI")
		
		Self.root = TContainer.Create("root")
		Self.root.SetSize(1.0, 1.0)
		Self.root.gui = Self
		
		Self.popupMenuContainer = TContainer.Create("_popupMenuContainer")
		Self.popupMenuContainer.SetSize(1.0, 1.0)
		Self.popupMenuContainer.gui = Self
		
		' Load ini
		Local ini:TINI = TINI.Create(FS_ROOT + "data/gui/gui.ini")
		
		If ini.Load()
			Self.skin = TSkin.Create(ini.Get("GUI", "Skin"))
			Self.shutdownOnIdle = Int(ini.Get("GUI", "ShutdownOnIdle"))
			
			Self.alpha = Float(ini.Get("Transparency", "Alpha"))
			Self.noFocusAlpha = Float(ini.Get("Transparency", "NoFocusAlpha"))
			
			Self.shadowOffsetX = Int(ini.Get("Shadow", "ShadowOffsetX"))
			Self.shadowOffsetY = Int(ini.Get("Shadow", "ShadowOffsetY"))
			Self.shadowIntensity = Float(ini.Get("Shadow", "ShadowIntensity"))
			
			Self.displayDebugInfo = Int(ini.Get("Debug", "ShowDebugInfo"))
			Self.displayIdleMode = Int(ini.Get("Debug", "ShowIdleMode"))
		EndIf
		
		Self.eraseEvents = False
		Self.eraseMouseEvents = False
		Self.focusWidget = Null
		Self.newFocusWidget = Self.root
		
		Self.ShowCursor()
	End Method
	
	' Add
	Method Add(widget:TWidget)
		Self.root.Add(widget)
	End Method
	
	' AddMenu
	Method AddMenu(widget:TWidget)
		Self.popupMenuContainer.Add(widget)
	End Method
	
	' Update
	Method Update()
		' Don't do anything if mouse/keyboard has not been used
		If Self.shutdownOnIdle And TInputSystem.SomethingHappened() = False
			Self.idle = True
			Return
		Else
			Self.idle = False
		EndIf
		
		' Reset hover widget
		Self.hoverWidget = Null
		
		' Update menu first
		Self.popupMenuContainer.UpdateAll()
		
		' Reset hover widget if it was the popup menu container
		If Self.hoverWidget = Self.popupMenuContainer
			Self.hoverWidget = Null
		EndIf
		
		' Erase mouse events until mouse is not pressed anymore
		If Self.eraseMouseEvents
			If Self.oldEraseMouseEvents = Self.eraseMouseEvents And TInputSystem.GetMouseDown(1) = 0 And TInputSystem.GetMouseDown(2) = 0 And TInputSystem.GetMouseDown(3) = 0
				Self.eraseMouseEvents = False
			Else
				TInputSystem.EraseMouseEvents()
			EndIf
		EndIf
		Self.oldEraseMouseEvents = Self.eraseMouseEvents
		
		' Update all widgets
		Self.root.UpdateAll()
		
		If Self.eraseEvents
			TInputSystem.EraseAllEvents()
			Self.eraseEvents = False
		EndIf
		
		If Self.focusWidget <> Self.newFocusWidget
			Self.focusWidget = Self.newFocusWidget
			If Self.focusWidget <> Null And Self.focusWidget.parent <> Null
				Self.focusWidget.Remove()
				
				' Will be the last in the list (drawn last)
				Self.focusWidget.parent.Add(Self.focusWidget)
			EndIf
		EndIf
	End Method
	
	' Draw
	Method Draw()
		SetBlend ALPHABLEND
		
		Self.root.DrawAll() 
		Self.popupMenuContainer.DrawAll()
		
		ResetMax2D()
		SetViewport 0, 0, GraphicsWidth(), GraphicsHeight()
		
		If Self.displayIdleMode And Self.idle
			.SetAlpha 0.5
			.SetColor 0, 0, 0
			DrawRect Self.root.screenX, Self.root.screenY, Self.root.rWidth, Self.root.rHeight
			.SetAlpha 1.0
		EndIf
		
		If Self.displayDebugInfo
			Self.DrawDebug()
		EndIf
		
		If Self.cursor <> Null And Self.CursorVisible()
			Self.cursor.Draw()
		EndIf
	End Method
	
	' DrawDebug
	Method DrawDebug()
		If Self.focusWidget <> Null
			SetColor 255, 255, 0
			DrawRectOutline Self.focusWidget.screenX, Self.focusWidget.screenY, Self.focusWidget.rWidth, Self.focusWidget.rHeight
		EndIf
		
		If Self.hoverWidget <> Null
			SetColor 255, 0, 0
			DrawRectOutline Self.hoverWidget.screenX, Self.hoverWidget.screenY, Self.hoverWidget.rWidth, Self.hoverWidget.rHeight
			
			SetColor 255, 255, 255
			Local offX:Int = TInputSystem.GetMouseX() + Self.cursor.img.width
			Local offY:Int = TInputSystem.GetMouseY() + Self.cursor.img.height
			DrawRect offX, offY, 180, 130
			
			' Info
			Local widget:TWidget = Self.hoverWidget
			
			SetColor 0, 0, 0
			DrawRectOutline offX, offY, 180, 130
			
			DrawText "ID: " + widget.id, offX + 5, offY + 5
			DrawText "Text: " + widget.text, offX + 5, offY + 20
			DrawText "Size: " + widget.GetWidth() + ", " + widget.GetHeight(), offX + 5, offY + 35
			DrawText "Pos.Rel: " + widget.cRel.ToString(), offX + 5, offY + 50
			DrawText "Pos.Abs: " + widget.cAbs.ToString(), offX + 5, offY + 65
			DrawText "Padding: " + widget.padding.ToString(), offX + 5, offY + 80
			DrawText "Padding.Skin: " + widget.skinPadding.ToString(), offX + 5, offY + 95
			
			If widget.GetParent()
				DrawText "Parent: " + widget.GetParent().GetID(), offX + 5, offY + 110
			Else
				DrawText "Parent: " + "None", offX + 5, offY + 110
			EndIf
		EndIf
		
		SetColor 255, 255, 255
	End Method
	
	' SetAlpha
	Method SetAlpha(nAlpha:Float)
		Self.alpha = nAlpha
	End Method
	
	' SetFont
	Method SetFont(font:TImageFont)
		Self.root.SetFontAll(font)
		Self.popupMenuContainer.SetFontAll(font)
	End Method
	
	' SetCursor
	Method SetCursor(name:String)
		Self.cursor = Self.skin.GetCursor(name)
	End Method
	
	' ShowCursor
	Method ShowCursor()
		Self.showCursorFlag = True
	End Method
	
	' HideCursor
	Method HideCursor()
		Self.showCursorFlag = False
	End Method
	
	' CursorVisible
	Method CursorVisible:Int()
		Return Self.showCursorFlag
	End Method
	
	' GetRoot
	Method GetRoot:TWidget()
		Return Self.root
	End Method
	
	' GetAlpha
	Method GetAlpha:Float()
		Return Self.alpha
	End Method
	
	' TryToSetHoverWidget
	Method TryToSetHoverWidget(widget:TWidget)
		If Self.hoverWidget = Null And widget <> Null
			Self.hoverWidget = widget
			
			' onEnter / onLeave
			If Self.hoverWidget <> Self.oldHoverWidget
				If Self.hoverWidget.onEnter <> Null
					Self.hoverWidget.onEnter(Self.hoverWidget.GetAffectingWidget())
				EndIf
				If Self.oldHoverWidget <> Null And Self.oldHoverWidget.onLeave <> Null
					Self.oldHoverWidget.onLeave(Self.oldHoverWidget.GetAffectingWidget())
				EndIf
			EndIf
			
			Self.oldHoverWidget = Self.hoverWidget
			'Print widget.id + " got Hover"
			Return
		EndIf
		'Print widget.id + " claimed Hover but didn't get it"
	End Method
	
	' GetHoveredWidget
	Method GetHoveredWidget:TWidget()
		Return Self.hoverWidget
	End Method
	
	' InitClass
	Function InitClass()
		TSkin.InitClass(FS_ROOT + "data/gui/") 
		TSlider.InitClass()
		
		?Debug
			TGUI.logger = TLog.Create(StandardIOStream)
		?Not Debug
			TGUI.logger = TLog.Create(WriteFile(FS_ROOT + "logs/gui.txt"))
		?
		
		TGUI.initializedClass = True
	End Function
	
	' Create
	Function Create:TGUI()
		Local lgui:TGUI = New TGUI
		lgui.Init()
		Return lgui
	End Function
End Type
