' Strict
'SuperStrict

' Files
'Import "BPR.Widget.bmx"

' TWindow
Type TWindow Extends TWidget
	Field textSizeX:Int
	Field textSizeY:Int
	
	Field dragging:Int
	Field dragDistX:Int, dragDistY:Int
	
	' Init
	Method Init(nID:String, nText:String, nX:Int, nY:Int, nWidth:Int, nHeight:Int)
		Self.InitWidget(nID, nText, nX, nY, nWidth, nHeight)
		Self.dragDistX = 0
		Self.dragDistY = 0
	End Method
	
	' InitSkinPadding
	Method InitSkinPadding() 
		Self.skinPadding.x1 = gui.skin.window.w.width
		Self.skinPadding.x2 = gui.skin.window.e.width
		Self.skinPadding.y1 = gui.skin.window.n.height
		Self.skinPadding.y2 = gui.skin.window.s.height
		'Self.UpdateScreenPosition()
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
	End Method
	
	' Update
	Method Update()
		If PointInRect(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), Self.screenX, Self.screenY, Self.rWidth, Self.rHeight)
			' Drag
			If TInputSystem.GetMouseDown(1)
				If TInputSystem.GetMouseHit(1)
					Self.Focus()
					
					' TODO: Optimise
					If Self.dragging = 0 And (PointInRect(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), Self.screenX, Self.screenY, Self.rWidth, Self.skinPadding.y1) Or TInputSystem.GetKeyDown(KEY_LALT))
						Self.dragDistX = Self.GetMouseX()
						Self.dragDistY = Self.GetMouseY()
						Self.dragging = True
						Self.dontUpdateChilds = True
					EndIf
				EndIf
			Else
				Self.dragging = False
				Self.dontUpdateChilds = False
			EndIf
			
			' Main application won't get any mouse events
			If Self.HasFocus()
				TInputSystem.EraseMouseEvents()
				gui.TryToSetHoverWidget(Self)
			Else
				gui.eraseEvents = True
			EndIf
		EndIf
		
		If Self.dragging
			Self.SetPositionAbs((TInputSystem.GetMouseX() - Self.GetRelOffsetX()) - Self.dragDistX, (TInputSystem.GetMouseY() - Self.GetRelOffsetY()) - Self.dragDistY)
			
			' Main application won't get any mouse events
			'gui.eraseMouseEvents = True
			TInputSystem.EraseMouseEvents()
		EndIf
	End Method
	
	' Draw
	Method Draw()
		' This needs to modify gui.alpha directly for all child nodes (will be reset in ->DrawEnd())
		If Self.HasFocus() = 0 Then
			gui.alpha = gui.alpha * gui.noFocusAlpha
		EndIf
		
		' Alpha
		Local nAlpha:Float = Self.GetRealAlpha()
		
		' Save variable values (as an optimization)
		Local windowSkin:TWindowSkin = gui.skin.window
		Local westWidth:Int = windowSkin.w.width
		Local northHeight:Int = windowSkin.n.height
		Local southHeight:Int = windowSkin.s.height
		Local eastWidth:Int = windowSkin.e.width
		Local northWestWidth:Int = windowSkin.nw.width
		Local northEastWidth:Int = windowSkin.ne.width
		Local southWestWidth:Int = windowSkin.sw.width
		Local southEastWidth:Int = windowSkin.se.width
		Local southWestHeight:Int = windowSkin.sw.height
		Local southEastHeight:Int = windowSkin.se.height
		
		' Draw shadow
		If nAlpha = 1.0
			PushViewport()
			
			.SetColor 0, 0, 0
			.SetAlpha gui.shadowIntensity
			
			SetViewport Self.screenX + Self.rWidth, Self.screenY + gui.shadowOffsetY, gui.shadowOffsetX, Self.rHeight
			DrawImageRectTiled windowSkin.e, gui.shadowOffsetX + Self.rX + Self.rWidth - eastWidth, gui.shadowOffsetY + Self.rY + northHeight, eastWidth, Self.rHeight - northHeight - southEastHeight
			DrawImage windowSkin.ne, gui.shadowOffsetX + Self.rX + Self.rWidth, gui.shadowOffsetY + Self.rY
			
			SetViewport Self.screenX + gui.shadowOffsetX, Self.screenY + Self.rHeight, Self.rWidth, gui.shadowOffsetY
			DrawImageRectTiled windowSkin.s, gui.shadowOffsetX + Self.rX + southWestWidth, gui.shadowOffsetY + Self.rY + Self.rHeight - southHeight, Self.rWidth - southWestWidth - southEastWidth, southHeight
			DrawImage windowSkin.sw, gui.shadowOffsetX + Self.rX, gui.shadowOffsetY + Self.rY + Self.rHeight
			
			PopViewport()
			DrawImage windowSkin.se, gui.shadowOffsetX + Self.rX + Self.rWidth, gui.shadowOffsetY + Self.rY + Self.rHeight
		EndIf
		
		' Draw center
		.SetAlpha nAlpha * windowSkin.centerAlpha
		.SetColor Self.r, Self.g, Self.b
		DrawImageRectTiled windowSkin.c, Self.rX + westWidth, Self.rY + northHeight, Self.rWidth - westWidth - eastWidth, Self.rHeight - northHeight - southHeight
		
		' Draw edges
		.SetAlpha nAlpha * windowSkin.borderAlpha
		DrawImageRectTiled windowSkin.n, Self.rX + northWestWidth, Self.rY, Self.rWidth - northWestWidth - northEastWidth, northHeight
		DrawImageRectTiled windowSkin.s, Self.rX + southWestWidth, Self.rY + Self.rHeight - southHeight, Self.rWidth - southWestWidth - southEastWidth, southHeight
		DrawImageRectTiled windowSkin.w, Self.rX, Self.rY + northHeight, westWidth, Self.rHeight - northHeight - southWestHeight
		DrawImageRectTiled windowSkin.e, Self.rX + Self.rWidth - eastWidth, Self.rY + northHeight, eastWidth, Self.rHeight - northHeight - southEastHeight
		
		' Draw corners
		DrawImage windowSkin.nw, Self.rX, Self.rY
		DrawImage windowSkin.ne, Self.rX + Self.rWidth, Self.rY
		DrawImage windowSkin.sw, Self.rX, Self.rY + Self.rHeight
		DrawImage windowSkin.se, Self.rX + Self.rWidth, Self.rY + Self.rHeight
		
		' Draw text
		.SetAlpha nAlpha
		.SetColor Self.textR, Self.textG, Self.textB
		
		Local textOffsetX:Int = windowSkin.textOffsetX
		Local textOffsetY:Int = windowSkin.textOffsetY
		
		If textOffsetX = -1
			textOffsetX = Self.rWidth / 2 - Self.textSizeX / 2
		EndIf
		If textOffsetY = -1
			textOffsetY = Self.skinPadding.y1 / 2 - Self.textSizeY / 2
		EndIf
		
		DrawText Self.text, Self.rX + textOffsetX, Self.rY + textOffsetY
		
		' Debug
		'If Self.dragging
		'	.SetAlpha 0.25
		'	DrawRect Self.rX, Self.rY, Self.rWidth, Self.rHeight
		'EndIf
	End Method
	
	' DrawEnd
	Method DrawEnd()
		If Self.HasFocus() = 0 Then
			gui.alpha = gui.alpha / gui.noFocusAlpha
		EndIf
	End Method
	
	' Create
	Function Create:TWindow(nID:String, nText:String = "", nX:Int = 0, nY:Int = 0, nWidth:Int = 0, nHeight:Int = 0)
		Local widget:TWindow = New TWindow
		widget.Init(nID, nText, nX, nY, nWidth, nHeight)
		Return widget
	End Function
End Type

' TWindowSkin
Type TWindowSkin Extends TWidgetSkin
	Field c:TImage							' Center (fill)
	Field n:TImage, s:TImage, w:TImage, e:TImage		' North, South, West, East
	Field nw:TImage, ne:TImage					' North
	Field sw:TImage, se:TImage					' South
	
	Field borderAlpha:Float
	Field centerAlpha:Float
	Field textOffsetX:Int
	Field textOffsetY:Int
	
	' Load
	Method Load()
		Self.c = Self.imageMgr.Get(Self.name + "-" + "C")
		Self.n = Self.imageMgr.Get(Self.name + "-" + "N")
		Self.s = Self.imageMgr.Get(Self.name + "-" + "S")
		Self.w = Self.imageMgr.Get(Self.name + "-" + "W")
		Self.e = Self.imageMgr.Get(Self.name + "-" + "E")
		Self.nw = Self.imageMgr.Get(Self.name + "-" + "NW")
		Self.ne = Self.imageMgr.Get(Self.name + "-" + "NE")
		Self.sw = Self.imageMgr.Get(Self.name + "-" + "SW")
		Self.se = Self.imageMgr.Get(Self.name + "-" + "SE")
		
		' Adjust image handle
		If Self.ne
			SetImageHandle Self.ne, Self.ne.width, 0
		EndIf
		If Self.sw
			SetImageHandle Self.sw, 0, Self.sw.height
		EndIf
		If Self.se
			SetImageHandle Self.se, Self.se.width, Self.se.height
		EndIf
		
		' Ini
		If Self.ini.Load()
			Self.borderAlpha = Float(Self.ini.Get("Widget", "BorderAlpha"))
			Self.centerAlpha = Float(Self.ini.Get("Widget", "CenterAlpha"))
			Self.textOffsetX = Int(Self.ini.Get("Widget", "TextOffsetX"))
			Self.textOffsetY = Int(Self.ini.Get("Widget", "TextOffsetY"))
		EndIf
	End Method
	
	' Create
	Function Create:TWindowSkin(nDir:String)
		Local widgetSkin:TWindowSkin = New TWindowSkin
		widgetSkin.Init("Window", nDir)
		Return widgetSkin
	End Function
End Type
