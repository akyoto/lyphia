
' TBox
Type TBox
	Field x1:Int
	Field y1:Int
	Field x2:Int
	Field y2:Int
	
	' Init
	Method Init(nX:Int = 0, nY:Int = 0, nX2:Int = 0, nY2:Int = 0)
		Self.x1 = nX
		Self.y1 = nY
		Self.x2 = nX2
		Self.y2 = nY2
	End Method
	
	' ExpandBox
	Method ExpandBox(box:TBox)
		Self.x1 :- box.x1
		Self.y1 :- box.y1
		Self.x2 :+ box.x2
		Self.y2 :+ box.y2
	End Method
	
	' ShrinkBox
	Method ShrinkBox(box:TBox)
		Self.x1 :+ box.x1
		Self.y1 :+ box.y1
		Self.x2 :- box.x2
		Self.y2 :- box.y2
	End Method
	
	' ToString
	Method ToString:String()
		Return Self.x1 + ", " + Self.y1 + ", " + Self.x2 + ", " + Self.y2
	End Method
	
	' Create
	Function Create:TBox(nX:Int = 0, nY:Int = 0, nX2:Int = 0, nY2:Int = 0)
		Local box:TBox = New TBox
		box.Init(nX, nY, nX2, nY2)
		Return box
	End Function
End Type

' TBoxFloat
Type TBoxFloat
	Field x1:Float
	Field y1:Float
	Field x2:Float
	Field y2:Float
	
	' Init
	Method Init(nX:Float = 0, nY:Float = 0, nX2:Float = 0, nY2:Float = 0)
		Self.x1 = nX
		Self.y1 = nY
		Self.x2 = nX2
		Self.y2 = nY2
	End Method
	
	' ExpandBox
	Method ExpandBox(box:TBoxFloat)
		Self.x1 :- box.x1
		Self.y1 :- box.y1
		Self.x2 :+ box.x2
		Self.y2 :+ box.y2
	End Method
	
	' ShrinkBox
	Method ShrinkBox(box:TBoxFloat)
		Self.x1 :+ box.x1
		Self.y1 :+ box.y1
		Self.x2 :- box.x2
		Self.y2 :- box.y2
	End Method
	
	' ToString
	Method ToString:String()
		Return String(Self.x1)[0..4] + ", " + String(Self.y1)[0..4] + ", " + String(Self.x2)[0..4] + ", " + String(Self.y2)[0..4]
	End Method
	
	' Create
	Function Create:TBoxFloat(nX:Float = 0, nY:Float = 0, nX2:Float = 0, nY2:Float = 0)
		Local box:TBoxFloat = New TBoxFloat
		box.Init(nX, nY, nX2, nY2)
		Return box
	End Function
End Type
