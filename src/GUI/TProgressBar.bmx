
' TProgressBar
Type TProgressBar Extends TWidget
	Field value:Float
	
	' Init
	Method Init(nID:String, nX:Int, nY:Int, nWidth:Int, nHeight:Int)
		Self.InitWidget(nID, "", nX, nY, nWidth, nHeight) 
		Self.value = 0.0
	End Method
	
	' SetText
	Method SetText(nText:String)
		Self.text = nText
	End Method
		
	' SetProgress
	Method SetProgress(nVal:Float) 
		Self.value = nVal
	End Method
		
	' GetProgress
	Method GetProgress:Float()
		Return Self.value
	End Method
		
	' Update
	Method Update()
		If PointInRect(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), Self.screenX, Self.screenY, Self.rWidth, Self.rHeight)
			gui.TryToSetHoverWidget(Self)
			
			If TInputSystem.GetMouseHit(1)
				' OnClick handler
				If Self.onClick <> Null
					Self.onClick(Self.GetAffectingWidget())
				EndIf
			EndIf
		EndIf
	End Method
	
	' Draw
	Method Draw()
		.SetAlpha Self.GetRealAlpha()
		.SetColor Self.r, Self.g, Self.b
		
		' Save variable values (as an optimization)
		Local sliderSkin:TProgressBarSkin = gui.skin.progressBar
		Local westWidth:Int = sliderSkin.w.width
		Local northHeight:Int = sliderSkin.n.height
		Local southHeight:Int = sliderSkin.s.height
		Local eastWidth:Int = sliderSkin.e.width
		Local northWestWidth:Int = sliderSkin.nw.width
		Local northEastWidth:Int = sliderSkin.ne.width
		Local southWestWidth:Int = sliderSkin.sw.width
		Local southEastWidth:Int = sliderSkin.se.width
		Local southWestHeight:Int = sliderSkin.sw.height
		Local southEastHeight:Int = sliderSkin.se.height
		
		' Draw center
		' TODO: Optimize by caching
		DrawImageRectTiled sliderSkin.c, Self.rX + westWidth, Self.rY + northHeight, Self.rWidth - westWidth - eastWidth, Self.rHeight - northHeight - southHeight
		DrawImageRectTiled sliderSkin.cProgress, Self.rX + westWidth, Self.rY + northHeight, (Self.rWidth - westWidth - eastWidth) * Self.value, Self.rHeight - northHeight - southHeight
		
		' Draw edges
		DrawImageRectTiled sliderSkin.n, Self.rX + northWestWidth, Self.rY, Self.rWidth - northWestWidth - northEastWidth, northHeight
		DrawImageRectTiled sliderSkin.s, Self.rX + southWestWidth, Self.rY + Self.rHeight - southHeight, Self.rWidth - southWestWidth - southEastWidth, southHeight
		DrawImageRectTiled sliderSkin.w, Self.rX, Self.rY + northHeight, westWidth, Self.rHeight - northHeight - southWestHeight
		DrawImageRectTiled sliderSkin.e, Self.rX + Self.rWidth - eastWidth, Self.rY + northHeight, eastWidth, Self.rHeight - northHeight - southEastHeight
		
		' Draw corners
		DrawImage sliderSkin.nw, Self.rX, Self.rY
		DrawImage sliderSkin.ne, Self.rX + Self.rWidth, Self.rY
		DrawImage sliderSkin.sw, Self.rX, Self.rY + Self.rHeight
		DrawImage sliderSkin.se, Self.rX + Self.rWidth, Self.rY + Self.rHeight
	End Method
		
	' Create
	Function Create:TProgressBar(nID:String, nX:Int = 0, nY:Int = 0, nWidth:Int = 0, nHeight:Int = 0)
		Local widget:TProgressBar = New TProgressBar
		widget.Init(nID, nX, nY, nWidth, nHeight)
		Return widget
	End Function
End Type

' TProgressBarSkin
Type TProgressBarSkin Extends TWidgetSkin
	Field c:TImage							' Center (fill)
	Field cProgress:TImage						' Center (progress)
	Field n:TImage, s:TImage, w:TImage, e:TImage		' North, South, West, East
	Field nw:TImage, ne:TImage					' North
	Field sw:TImage, se:TImage					' South
	
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
		
		Self.cProgress = Self.imageMgr.Get(Self.name + "-" + "Progress")
				
		' Adjust image handle
		SetImageHandle Self.ne, Self.ne.width, 0
		SetImageHandle Self.sw, 0, Self.sw.height
		SetImageHandle Self.se, Self.se.width, Self.se.height
		
		' Ini
		'If Self.ini.Load()
		'EndIf
	End Method
	
	' Create
	Function Create:TProgressBarSkin(nDir:String)
		Local widgetSkin:TProgressBarSkin = New TProgressBarSkin
		widgetSkin.Init("ProgressBar", nDir)
		Return widgetSkin
	End Function
End Type

