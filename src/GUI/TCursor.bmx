
' TCursor
Type TCursor
	Global dir:String
	Global extension:String
	
	Field name:String
	Field img:TImage
	
	' Init
	Method Init(nName:String, nImg:TImage)
		Self.name = nName
		Self.img = nImg
	End Method
	
	' Draw
	Method Draw()
		DrawImage Self.img, TInputSystem.GetMouseX(), TInputSystem.GetMouseY()
	End Method
	
	' InitClass
	Function InitClass(cursorDir:String)
		TCursor.dir = cursorDir
	End Function
	
	' Create
	Function Create:TCursor(nName:String, nImg:TImage)
		Local cur:TCursor = New TCursor
		cur.Init(nName, nImg)
		Return cur
	End Function
End Type