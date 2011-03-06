' Strict
SuperStrict

' Modules
Import BRL.Math

' Sin/Cos caching
Const maxSinCosCache:Int = 720
Global CosFast:Float[maxSinCosCache]
Global SinFast:Float[maxSinCosCache]

For Local I:Int = 0 Until maxSinCosCache
	CosFast[I] = Cos(I)
	SinFast[i] = Sin(I)
Next

' CosFastSec
Function CosFastSec:Float(degree:Int)
	If degree < 0
		Return CosFast[-degree Mod maxSinCosCache]
	EndIf
	
	Return CosFast[degree Mod maxSinCosCache]
End Function

' SinFastSec
Function SinFastSec:Float(degree:Int)
	If degree < 0
		Return -SinFast[-degree Mod maxSinCosCache]
	EndIf
	
	Return SinFast[degree Mod maxSinCosCache]
End Function

' InRange
Function InRange:Int(value:Float, range:Float)
	Return value < range And value > -range
End Function

' PointInRect
Function PointInRect:Int(x:Int, y:Int, rX:Int, rY:Int, rWidth:Int, rHeight:Int)
	Return x >= rX And y >= rY And x <= rX + rWidth And y <= rY + rHeight
End Function

' RectInRect
Function RectInRect:Int(x:Int, y:Int, width:Int, height:Int, x2:Int, y2:Int, width2:Int, height2:Int)
	If x > x2 + width2 Or y > y2 + height2 Or y + height < y2 Or x + width < x2
		Return False
	EndIf
	
	Return True
End Function

' CircleInRect
Function CircleInRect:Int(cx:Int, cy:Int, cr:Int, x1:Int, y1:Int, w:Int, h:Int)
	Local cr2:Int = cr * cr
	
	If PointInRect(cx, cy, x1 - cr, y1 - cr, cr, cr) Then Return DistanceSq2(cx - x1, cy - y1) <= cr2
	If PointInRect(cx, cy, x1 - cr, y1 + h, cr, cr) Then Return DistanceSq2(cx - x1, cy - y1 - h) <= cr2
	If PointInRect(cx, cy, x1 + w, y1 - cr, cr, cr) Then Return DistanceSq2(cx - x1 - w, cy - y1) <= cr2
	If PointInRect(cx, cy, x1 + w, y1 + h, cr, cr) Then Return DistanceSq2(cx - x1 - w, cy - y1 - h) <= cr2
	
	Return PointInRect(cx, cy, x1 - cr, y1 - cr, w + 2 * cr, h + 2 * cr)
End Function

' FloatToReadableString
Function FloatToReadableString:String(val:Float, numbers:Int = 1)
	Local txt:String = val
	Local pointPosition:Int = txt.Find(".")
	
	' Return float
	For Local i:Int = 1 To numbers
		If pointPosition + i >= txt.length
			' Return integer
			Return txt[..pointPosition] 
		EndIf
		
		If txt[pointPosition + i] <> "0"[0]
			Return txt[..pointPosition + 1 + numbers]
		EndIf
	Next
	
	' Return integer
	Return txt[..pointPosition] 
End Function

' MSToSeconds
Function MSToSeconds:String(val:Int)
	Return FloatToReadableString(val / 1000.0, 1)
End Function

' BoolToYesNo
Function BoolToYesNo:String(bool:Int)
	If bool
		Return "Yes"
	EndIf
	
	Return "No"
End Function

' FloatNormalised
Function FloatNormalised:Int(val:Float)
	If val = 0
		Return 0
	EndIf
	If val > 0
		Return 1
	EndIf
	
	Return -1
End Function

' Round
Function Round:Int(val:Float)
	Local rest:Float = val - Int(val)
	
	If rest >= 0.5 Or rest <= -0.5
		Return Ceil(val)
	Else
		Return Floor(val)
	EndIf
End Function

' DistanceSq
Function DistanceSq:Float(x1:Float, y1:Float, x2:Float, y2:Float)
	Local dx:Float = x2 - x1
	Local dy:Float = y2 - y1
	Return dx * dx + dy * dy
End Function

' DistanceSq2
Function DistanceSq2:Float(dx:Float, dy:Float)
	Return dx * dx + dy * dy
End Function

' CompareStringsByNumericValue
Function CompareStringsByNumericValue:Int(a:Object, b:Object)
	Return Int(String(a)) > Int(String(b))
End Function

' DAR_Recursive
Function DAR_Recursive:Int(a:Int, b:Int)
	Local result:Int
	
	If b Mod a <= 0
		result = a
	Else
		result = DAR_Recursive(b, a Mod b)
	EndIf
	
	Return result
End Function

' GetGraphicsRatioString
Function GetGraphicsRatioString:String(width:Int, height:Int)
	Local div:Int = DAR_Recursive(width, height)
	Local ratio:String = (width / div) + ":" + (height / div)
	
	If ratio = "8:5"
		Return "16:10"
	EndIf
	
	Return ratio
End Function
