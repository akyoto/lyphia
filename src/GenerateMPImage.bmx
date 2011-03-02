SuperStrict

Import "Global.bmx"

Graphics 640, 480

Const SPLIT_PIXELS:Int = 1	' higher value than 1 DOES NOT WORK YET

Local n:TPixmap = LoadPixmap(FS_ROOT + "data/status/mp-full.png") 

' Yes, n.height is correct, but actually doesn't matter
Local width:Int = n.height
Local result:TPixmap = CreatePixmap(width * (width / SPLIT_PIXELS), SPLIT_PIXELS, n.format)

For Local I:Int = 0 Until width Step SPLIT_PIXELS
	CopyPixels n.PixelPtr(0, I), result.PixelPtr(I * width, 0), n.format, width
Next

SavePixmapPNG result, FS_ROOT + "data/status/mp.png"