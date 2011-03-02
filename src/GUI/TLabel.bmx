
' TLabel
Type TLabel Extends TWidget
	Field textSizeX:Int
	Field textSizeY:Int
	
	' Init
	Method Init(nID:String, nText:String, nX:Int, nY:Int, nWidth:Int, nHeight:Int)
		Self.InitWidget(nID, nText, nX, nY, nWidth, nHeight)
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
		Self.SetSizeAbs(Self.textSizeX, Self.textSizeY)
	End Method
	
	' Update
	Method Update()
		
	End Method
	
	' Draw
	Method Draw()
		If Self.text.length <> 0
			' Draw
			.SetAlpha Self.gui.alpha * Self.alpha
			.SetImageFont Self.font
			.SetColor Self.textR, Self.textG, Self.textB
			DrawText Self.text, Self.rX, Self.rY
		EndIf
	End Method
	
	' Create
	Function Create:TLabel(nID:String, nText:String, nX:Int = 0, nY:Int = 0, nWidth:Int = 0, nHeight:Int = 0)
		Local widget:TLabel = New TLabel
		widget.Init(nID, nText, nX, nY, nWidth, nHeight)
		Return widget
	End Function
End Type

