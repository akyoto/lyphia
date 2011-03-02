SuperStrict

Import "Global.bmx"

Graphics 640, 480

Global n:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "N.png") 
Global e:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "E.png") 
Global s:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "S.png") 
Global w:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "W.png") 
Global ne:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "NE.png") 
Global nw:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "NW.png") 
Global se:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "SE.png") 
Global sw:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "SW.png")
Global nei:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "NEI.png") 
Global nwi:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "NWI.png") 
Global sei:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "SEI.png") 
Global swi:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "SWI.png") 
Global ned:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "NED.png")
Global nwd:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "NWD.png")
Global sed:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "SED.png")
Global swd:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/masks/" + "SWD.png")

' Layer 1
Local dir:String[] = LoadDir(FS_ROOT + "data/layers/layer-1/") 
For Local file:String = EachIn dir
	If ExtractExt(file) = "png" And Byte(file) <> 0
		Print "Processing " + file
		CreateAutoTile(file)
	EndIf
Next

' CreateAutoTile
Function CreateAutoTile(file:String)
	Local pixmap:TPixmap = LoadPixmap(FS_ROOT + "data/layers/layer-1/" + file) 
	
	Local result:TPixmap = CreatePixmap(32 * 16, 32, PF_RGBA8888) 
	result.ClearPixels(0)
	
	Blend(pixmap, n, result, 32 * 0) 
	Blend(pixmap, e, result, 32 * 1) 
	Blend(pixmap, s, result, 32 * 2) 
	Blend(pixmap, w, result, 32 * 3) 
	Blend(pixmap, ne, result, 32 * 4) 
	Blend(pixmap, nw, result, 32 * 5) 
	Blend(pixmap, se, result, 32 * 6) 
	Blend(pixmap, sw, result, 32 * 7)
	Blend(pixmap, nei, result, 32 * 8) 
	Blend(pixmap, nwi, result, 32 * 9) 
	Blend(pixmap, sei, result, 32 * 10) 
	Blend(pixmap, swi, result, 32 * 11) 
	Blend(pixmap, ned, result, 32 * 12) 
	Blend(pixmap, nwd, result, 32 * 13) 
	Blend(pixmap, sed, result, 32 * 14) 
	Blend(pixmap, swd, result, 32 * 15)
	
	Cls
	DrawPixmap result, 0, 0
	Flip
	
	SavePixmapPNG result, FS_ROOT + "data/layers/layer-1/autotiles/" + StripAll(file) + ".png"
End Function

' Blend
Function Blend(pixmap:TPixmap, bw:TPixmap, result:TPixmap, offset:Int = 0)
	Local val:Byte
	Local alpha:Float
	Local bytes:Byte[]
	For Local I:Int = 0 To 31
		For Local H:Int = 0 To 31
			val = IntToBytes(ReadPixel(bw, I, H))[2]
			If val
				alpha = val / 255.0
				bytes = IntToBytes(ReadPixel(pixmap, I, H))
				WritePixel result, offset + I, H, bytes[0] + bytes[1] Shl 8 + bytes[2] Shl 16 + val Shl 24
			EndIf
		Next
	Next
End Function

'Pointer
Function IntToBytes:Byte[](num:Int)
	Local p:Byte Ptr=Varptr num
	Local arr:Byte[4]
	arr[0]=p[0]
	arr[1]=p[1]
	arr[2]=p[2]
	arr[3]=p[3]
	p=Null
	Return arr
End Function
