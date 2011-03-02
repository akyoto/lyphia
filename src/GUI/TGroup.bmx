
' TGroup
Type TGroup Extends TWidget
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
		.SetAlpha gui.alpha * Self.alpha
		
		.SetColor Self.r, Self.g, Self.b
		DrawRect Self.rX, Self.rY, Self.rWidth, Self.rHeight
		
		.SetColor 0, 0, 0
		DrawRectOutline Self.rX, Self.rY, Self.rWidth, Self.rHeight
		
		'.SetColor Self.textR, Self.textG, Self.textB
		'DrawText Self.text, Self.rX + 15, Self.rY + 0
	End Method
	
	' Create
	Function Create:TGroup(nID:String, nText:String = "", nX:Int = 0, nY:Int = 0, nWidth:Int = 0, nHeight:Int = 0)
		Local widget:TGroup = New TGroup
		widget.Init(nID, nText, nX, nY, nWidth, nHeight)
		Return widget
	End Function
End Type
