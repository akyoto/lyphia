
' TImageBox
Type TImageBox Extends TWidget
	Field img:TImage
	Field frame:Int
	Field border:Int
	
	' Init
	Method Init(nID:String, nImage:TImage, nFrame:Int, nX:Int, nY:Int, nWidth:Int, nHeight:Int)
		Self.InitWidget(nID, "", nX, nY, nWidth, nHeight)
		Self.SetImage(nImage, nFrame)
		Self.SetBorderWidth(0)
	End Method
	
	' SetText
	Method SetText(nText:String)
		Self.text = nText
	End Method
	
	' SetImage
	Method SetImage(nImage:TImage, nFrame:Int = 0, applySizeAbs:Int = False)
		Self.img = nImage
		Self.SetFrame(nFrame)
		
		If Self.img <> Null And applySizeAbs = True
			' TODO: Image frame size (?)
			Self.SetSizeAbs(Self.img.width, Self.img.height)
		EndIf
	End Method
	
	' SetFrame
	Method SetFrame(nFrame:Int)
		Self.frame = nFrame
	End Method
	
	' SetBorderWidth
	Method SetBorderWidth(nBorder:Int)
		Self.border = nBorder
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
		If Self.img
			' Alpha
			.SetAlpha Self.GetRealAlpha()
			
			.SetScale Self.rWidth / Float(Self.img.width), Self.rHeight / Float(Self.img.height)
			DrawImage Self.img, Self.rX, Self.rY, Self.frame
			
			If Self.border
				.SetScale 1, 1
				.SetColor 0, 0, 0
				DrawRectOutline Self.rX, Self.rY, Self.rWidth, Self.rHeight, Self.border
			EndIf
			
			' TODO: Remove hardcoded
			If 0'Self.IsHovered()
				'.SetAlpha 0.5
				
				.SetColor 255, 0, 0
				DrawRectOutline Self.rX, Self.rY, Self.rWidth, Self.rHeight
			EndIf
		EndIf
	End Method
	
	' Create
	Function Create:TImageBox(nID:String, nImage:TImage, nFrame:Int = 0, nX:Int = 0, nY:Int = 0, nWidth:Int = 0, nHeight:Int = 0)
		Local widget:TImageBox = New TImageBox
		widget.Init(nID, nImage, nFrame, nX, nY, nWidth, nHeight)
		Return widget
	End Function
End Type
