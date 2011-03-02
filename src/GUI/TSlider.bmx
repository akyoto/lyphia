
' TSlider
Type TSlider Extends TWidget
	' Menu
	Global stdPopupMenu:TPopupMenu
	
	Field value:Float
	Field defaultValue:Float
	Field onSlide(widget:TWidget) 
	Field sliding:Int
	Field textSizeX:Int
	Field textSizeY:Int
	
	Field valMin:Float
	Field valMax:Float
	
	' Init
	Method Init(nID:String, nText:String, nX:Int, nY:Int, nWidth:Int, nHeight:Int)
		Self.InitWidget(nID, nText, nX, nY, nWidth, nHeight) 
		Self.SetMinMax(0.0, 1.0)
		Self.value = Self.GetMaxValue()
		Self.defaultValue = Self.value
		Self.onSlide = Null
		
		Self.SetPopupMenu(TSlider.stdPopupMenu)
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
	
	' SetMinMax
	Method SetMinMax(nMin:Float, nMax:Float)
		Self.valMin = nMin
		Self.valMax = nMax
	End Method
	
	' GetMinValue
	Method GetMinValue:Float()
		Return Self.valMin
	End Method
	
	' GetMaxValue
	Method GetMaxValue:Float()
		Return Self.valMax
	End Method
	
	' SetDefaultValue
	Method SetDefaultValue(nVal:Float, apply:Int = True) 
		If apply
			Self.SetValue(nVal)
			Self.defaultValue = Self.value
		Else
			Self.defaultValue = (nVal - Self.valMin) / (Self.valMax - Self.valMin)
		EndIf
	End Method
	
	' SetValue
	Method SetValue(nVal:Float) 
		Self.SetValueRel((nVal - Self.valMin) / (Self.valMax - Self.valMin))
	End Method
	
	' SetValueRel
	Method SetValueRel(nVal:Float) 
		If nVal < 0
			nVal = 0
		EndIf
		If nVal > 1
			nVal = 1
		EndIf
		
		' OnSlide handler
		If Self.onSlide <> Null And nVal <> Self.value
			Self.value = nVal
			Self.onSlide(Self.GetAffectingWidget())
		Else
			Self.value = nVal
		EndIf
	End Method
	
	' GetValue
	Method GetValue:Float() 
		Return Self.valMin + (Self.value * (Self.valMax - Self.valMin))
	End Method
	
	' GetValueRel
	Method GetValueRel:Float()
		Return Self.value
	End Method
	
	' GetDefaultValue
	Method GetdefaultValue:Float() 
		Return Self.valMin + (Self.defaultValue * (Self.valMax - Self.valMin))
	End Method
	
	' GetDefaultValueRel
	Method GetdefaultValueRel:Float() 
		Return Self.defaultValue
	End Method
	
	' Update
	Method Update()
		Self.sliding = False
		
		If PointInRect(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), Self.screenX, Self.screenY, Self.rWidth, Self.rHeight)
			gui.TryToSetHoverWidget(Self)
			
			If TInputSystem.GetMouseHit(1)
				' OnClick handler
				If Self.onClick <> Null
					Self.onClick(Self.GetAffectingWidget())
				EndIf
			EndIf
			
			If TInputSystem.GetMouseHit(2) 
				' Popup
				If Self.popupMenu <> Null
					Self.popupMenu.SetAffectingWidget(Self)
					Self.popupMenu.Popup()
				EndIf
			EndIf
			
			If TInputSystem.GetMouseDown(1)
				Local nValue:Float = (TInputSystem.GetMouseX() - Self.screenX) / Float(Self.rWidth)
				
				If nValue <> Self.value
					Self.sliding = True
					Self.value = nValue
					
					' OnSlide handler
					If Self.onSlide <> Null
						Self.onSlide(Self.GetAffectingWidget())
					EndIf
				EndIf
				
				TInputSystem.EraseMouseEvents()
			EndIf
		EndIf
	End Method
	
	' Draw
	Method Draw()
		.SetAlpha Self.GetRealAlpha()
		.SetColor Self.r, Self.g, Self.b
		
		' Save variable values (as an optimization)
		Local sliderSkin:TSliderSkin = gui.skin.slider
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
		DrawImageRectTiled sliderSkin.c, Self.rX + westWidth, Self.rY + northHeight, Self.rWidth - westWidth - eastWidth, Self.rHeight - northHeight - southHeight
		
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
		
		' Draw slider
		Local sliderPosX:Float = Self.rX + Self.value * Self.rWidth
		Local sliderOffsetY:Int = sliderSkin.sliderOffsetY.GetValueFor(Self)
		
		DrawImageRectTiled sliderSkin.sliderMid, sliderPosX - (sliderSkin.sliderMid.width / 2), Self.rY + sliderOffsetY + sliderSkin.sliderTop.height, sliderSkin.sliderMid.width, Self.rHeight - sliderOffsetY * 2 - sliderSkin.sliderBottom.height - sliderSkin.sliderTop.height
		DrawImage sliderSkin.sliderTop, sliderPosX, Self.rY + sliderOffsetY
		DrawImage sliderSkin.sliderBottom, sliderPosX, Self.rY + Self.rHeight - sliderOffsetY
		
		' Draw text
		.SetColor Self.textR, Self.textG, Self.textB
		DrawText Self.text, Self.rX + Self.rWidth / 2 - Self.textSizeX / 2, Self.rY + Self.rHeight / 2 - Self.textSizeY / 2
	End Method
	
	' Reset
	Method Reset() 
		Self.SetValueRel(Self.defaultValue)
	End Method
	
	' SetToMinimum
	Method SetToMinimum() 
		Self.SetValueRel(0.0)
	End Method
	
	' SetToMaximum
	Method SetToMaximum() 
		Self.SetValueRel(1.0)
	End Method
	
	' ResetFunc
	Function ResetFunc(widget:TWidget) 
		TSlider(widget).Reset()
	End Function
	
	' SetToMinimumFunc
	Function SetToMinimumFunc(widget:TWidget) 
		TSlider(widget).SetToMinimum()
	End Function
	
	' SetToMaximumFunc
	Function SetToMaximumFunc(widget:TWidget)
		TSlider(widget).SetToMaximum()
	End Function
	
	' SliderPopupMenuFunc
	Function SliderPopupMenuFunc(widget:TWidget)
		TSlider.stdPopupMenu.SetMenuItemText("_sliderReset", "Reset (" + FloatToReadableString(TSlider(widget).GetDefaultValue()) + ")")
		TSlider.stdPopupMenu.SetMenuItemText("_sliderSetMin", "Set to minimum (" + FloatToReadableString(TSlider(widget).GetMinValue()) + ")")
		TSlider.stdPopupMenu.SetMenuItemText("_sliderSetMax", "Set to maximum (" + FloatToReadableString(TSlider(widget).GetMaxValue()) + ")")
	End Function
	
	' InitClass
	Function InitClass() 
		TSlider.stdPopupMenu = TPopupMenu.Create("_sliderPopUp")
		TSlider.stdPopupMenu.AddMenuItem("_sliderReset", "Reset", TSlider.ResetFunc)
		TSlider.stdPopupMenu.AddMenuItem("_sliderSetMin", "Set to minimum", TSlider.SetToMinimumFunc) 
		TSlider.stdPopupMenu.AddMenuItem("_sliderSetMax", "Set to maximum", TSlider.SetToMaximumFunc)
		TSlider.stdPopupMenu.onVisible = TSlider.SliderPopupMenuFunc
	End Function
	
	' Create
	Function Create:TSlider(nID:String, nText:String, nX:Int = 0, nY:Int = 0, nWidth:Int = 0, nHeight:Int = 0)
		Local widget:TSlider = New TSlider
		widget.Init(nID, nText, nX, nY, nWidth, nHeight)
		Return widget
	End Function
End Type

' TSliderSkin
Type TSliderSkin Extends TWidgetSkin
	Field c:TImage							' Center (fill)
	Field n:TImage, s:TImage, w:TImage, e:TImage		' North, South, West, East
	Field nw:TImage, ne:TImage					' North
	Field sw:TImage, se:TImage					' South
	
	Field sliderTop:TImage
	Field sliderMid:TImage
	Field sliderBottom:TImage
	
	Field sliderOffsetY:TWidgetParam
	
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
		
		Self.sliderTop = Self.imageMgr.Get(Self.name + "-" + "Slider-Top")
		Self.sliderMid = Self.imageMgr.Get(Self.name + "-" + "Slider-Mid")
		Self.sliderBottom = Self.imageMgr.Get(Self.name + "-" + "Slider-Bottom")
		
		' Adjust image handle
		SetImageHandle Self.ne, Self.ne.width, 0
		SetImageHandle Self.sw, 0, Self.sw.height
		SetImageHandle Self.se, Self.se.width, Self.se.height
		MidHandleImageX Self.sliderTop
		MidHandleImageX Self.sliderBottom
		SetImageHandle Self.sliderBottom, Self.sliderBottom.handle_x, Self.sliderBottom.height
		
		' Ini
		If Self.ini.Load()
			Self.sliderOffsetY = TWidgetParam.Create(Self.ini, "Widget", "SliderOffsetY")
		EndIf
	End Method
	
	' Create
	Function Create:TSliderSkin(nDir:String)
		Local widgetSkin:TSliderSkin = New TSliderSkin
		widgetSkin.Init("Slider", nDir)
		Return widgetSkin
	End Function
End Type
