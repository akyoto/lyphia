' Strict
SuperStrict

' Modules
Import BRL.Max2D
'Import BtbN.GLDraw2D

' Files
Import "Math.bmx"

' Stack vars for Push/PopViewport
Global viewportStack:Int[256, 4]
Global viewportStackIndex:Int = -1

' DrawCircle
Function DrawCircle(x:Float, y:Float, radius:Float)
	DrawOval x - radius, y - radius, radius * 2, radius * 2
End Function

' DrawRectOutline
Function DrawRectOutline(x:Float, y:Float, width:Float, height:Float, border:Int = 1)
	DrawRect x, y, width, border
	DrawRect x, y, border, height
	DrawRect x + width - border, y, border, height
	DrawRect x, y + height - border, width, border
End Function

' DrawImageRectTiled
Function DrawImageRectTiled(img:TImage, x:Float, y:Float, width:Int, height:Int, frame:Int = 0)
	Local i:Int
	Local h:Int
	Local imgWidth:Int = img.width
	Local imgHeight:Int = img.height
	
	x = Round(x)
	y = Round(y)
	
	' Save viewport
	Local oldX:Int
	Local oldY:Int
	Local oldWidth:Int
	Local oldHeight:Int
	GetViewport oldX, oldY, oldWidth, oldHeight
	
	' Set viewport
	Local originX:Float, originY:Float
	GetOrigin(originX, originY)
	Local vpX:Int = Ceil(x) + originX
	Local vpY:Int = Ceil(y) + originY
	
	SetViewportInViewport vpX, vpY, width, height, oldX, oldY, oldWidth, oldHeight
	
	For i = 0 To width / imgWidth
		For h = 0 To height / imgHeight
			DrawImage img, x + i * imgWidth, y + h * imgHeight, frame
		Next
	Next
	
	' Reset viewport
	SetViewport oldX, oldY, oldWidth, oldHeight
End Function

' SetViewportInViewport
Function SetViewportInViewport(vpX:Int, vpY:Int, vpWidth:Int, vpHeight:Int, oldX:Int, oldY:Int, oldWidth:Int, oldHeight:Int)
	SetViewport Max(vpX, oldX), Max(vpY, oldY), Min(vpWidth + Min(vpX - oldX, 0), oldWidth - Max(vpX - oldX, 0)), Min(vpHeight + Min(vpY - oldY, 0), oldHeight - Max(vpY - oldY, 0))
End Function

' PushViewport
Function PushViewport()
	Local oldX:Int
	Local oldY:Int
	Local oldWidth:Int
	Local oldHeight:Int
	
	GetViewport oldX, oldY, oldWidth, oldHeight
	
	viewportStackIndex :+ 1
	viewportStack[viewportStackIndex, 0] = oldX
	viewportStack[viewportStackIndex, 1] = oldY
	viewportStack[viewportStackIndex, 2] = oldWidth
	viewportStack[viewportStackIndex, 3] = oldHeight
End Function

' PopViewport
Function PopViewport()
	SetViewport viewportStack[viewportStackIndex, 0], viewportStack[viewportStackIndex, 1], viewportStack[viewportStackIndex, 2], viewportStack[viewportStackIndex, 3]
	viewportStackIndex :- 1
End Function

' DrawTextCentered
Function DrawTextCentered(txt:String, x:Float, y:Float)
	Local scaleX:Float, scaleY:Float
	GetScale(scaleX, scaleY)
	DrawText txt, x - TextWidth(txt) * scaleX / 2, y - TextHeight(txt) * scaleY / 2
End Function

' MidHandleImageX
Function MidHandleImageX(img:TImage)
	SetImageHandle img, img.width / 2, img.handle_y
End Function

' MidHandleImageY
Function MidHandleImageY(img:TImage)
	SetImageHandle img, img.handle_x, img.height / 2
End Function

' ResetMax2D
Function ResetMax2D()
	SetTransform
	SetAlpha 1
	SetColor 255, 255, 255
End Function
