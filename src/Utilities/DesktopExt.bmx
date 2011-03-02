Rem
bbdoc:	Extended commandset for dealing with the desktop.

Module chaos.desktopext
ModuleInfo "Version: 1.18"
ModuleInfo "Author: hamZta, Suco-X, d-bug"
ModuleInfo "License: Public Domain"

ModuleInfo "History: 1.18 renamed functions to fix compiling bugs with 1.39 (added suffix 'Multi')"
ModuleInfo "History: 1.17 added DesktopMouseX and DesktopMouseY for OSX"
ModuleInfo "History: 1.16 Linux support skipped / fixed documentation"
ModuleInfo "History: 1.15 added multi-desktop-support for DesktopPixmap"
ModuleInfo "History: 1.14 added DesktopWallpaper"
ModuleInfo "History: 1.13 added DesktopRatio"
ModuleInfo "History: 1.12 fixed 'identifier screen not found' bug on OSX"
ModuleInfo "History: 1.11 fixed multi-desktop-support for Windows"
ModuleInfo "History: 1.10 added multi-desktop-support for Windows"
ModuleInfo "History: 1.09 added pixmap convertion to PF_BGR888 to DesktopPixmap"
ModuleInfo "History: 1.08 added optional flip-mode to DesktopPixmap"
ModuleInfo "History: 1.07 added multi-desktop-support for OSX"
ModuleInfo "History: 1.06 fixed 'TPixmap not found'"
ModuleInfo "History: 1.05 added DesktopMouseX and DesktopMouseY for Windows"
ModuleInfo "History: 1.04 added DesktopPixmap for Windows"
ModuleInfo "History: 1.03 changed documentation to german"
ModuleInfo "History: 1.02 changed module scope to chaos"
ModuleInfo "History: 1.01 fixed missing ReleaseDC"
ModuleInfo "History: 1.00 initial release 2006-05-16"
EndRem

SuperStrict

Import brl.standardio
Import brl.pixmap
Import brl.linkedlist
Import brl.bank


?Win32 

	Import pub.win32

	Private 

		Const SM_CXVIRTUALSCREEN:Int = 78
		Const SM_CYVIRTUALSCREEN:Int = 79
		Const SM_CMONITORS:Int = 80
		Const SM_SAMEDISPLAYFORMAT:Int = 81
		Const SPI_GETDESKWALLPAPER:Int = $73

		Type TDisplay
			Global List:TList = New TList
			Field id:Int
			Field handle:Int
			Field x:Int
			Field y:Int
			Field width:Int
			Field height:Int
		End Type

		Type TRect
		   Field rLeft:Int
		   Field rTop:Int
		   Field rRight:Int
		   Field rBottom:Int
		End Type
		
		Extern "Win32"
			Function GetSystemMetrics:Int (nIndex:Int)"Win32"
			Function EnumDisplayMonitors:Int (hdc:Int, lprcClip:Byte Ptr, lpfnEnum:Byte Ptr, dwData:Byte Ptr)"Win32"
			Function GetCursorPos(lpPoint:Byte Ptr)"Win32" = "GetCursorPos@4"
			Function GetDIBits(hdc:Int, bitmap:Int, Start:Int, Num:Int, bits:Byte Ptr, lpbi:Byte Ptr, usage:Int)"Win32"
			Function GetWindowDC(hwnd:Int)"Win32"
			Function ReleaseDC(hwnd:Int, hdc:Int)"Win32"
			Function SystemParametersInfo (uiAction:Int, uiParam:Int, pvParam:Byte Ptr, fWinIni:Int)"Win32" = "SystemParametersInfoA@16"
		End Extern

		Function MonitorEnumProc:Byte (hMonitor:Int,hdcMonitor:Int,lprcMonitor:Byte Ptr,dwData:Int)
			Local tempRect:TRect = New TRect
			MemCopy(tempRect, lprcMonitor, SizeOf(tempRect))
			Local display:TDisplay = New TDisplay
			TDisplay.List.AddLast(display)
			display.id = TDisplay.List.Count()
			display.handle = hMonitor
			display.x = tempRect.rLeft
			display.y = tempRect.rTop
			display.width = tempRect.rRight - display.x
			display.height = tempRect.rBottom - display.y
			Return True
		End Function
		EnumDisplayMonitors (Null , Null , MonitorEnumProc , Null)
	
	Public 
?MacOS
	Import "macscreen.c"
	Private
		Extern
			Function CGDisplayCurrentMode:Byte Ptr(displayID:Byte Ptr)"MacOS"
			Function CGGetActiveDisplayList:Byte Ptr(kMaxDisplays:Int, display:Byte Ptr, numDisplays:Int Var)"MacOS"
			Function MACOS_GetWidth:Int(mode:Byte Ptr)"C"
			Function MACOS_GetHeight:Int(mode:Byte Ptr)"C"
			Function MACOS_GetBPP:Int(mode:Byte Ptr)"C"
			Function MACOS_GetHertz:Int(mode:Byte Ptr)"C"
			Function MACOS_GetMouseX:Int()"C"
			Function MACOS_GetMouseY:Int()"C"
		End Extern 
	Public
?Linux

?
 
'-------------------------------------------------------------------

Rem
bbdoc:	Get Desktop wallpaper
returns:	Path to the wallpaper as string
EndRem
Function DesktopWallpaper:String ()
	?Linux
		Return ""
	?MacOS
		Return ""
	?Win32
	  Local Bank:TBank = CreateBank(255)
		Local Result:Byte Ptr = BankBuf(Bank)
		SystemParametersInfo(SPI_GETDESKWALLPAPER, 128, Result, 0)
	  Return String.FromCString(Result)
	?
End Function

'-------------------------------------------------------------------

Rem
bbdoc: Get desktop aspect-ratio 
returns: aspect-ratio as string
about: 
<table>
<tr><th>Flag</th><th>Description</th><th>Win32</th><th>MacOS</th></tr>
<tr><td><font class=token>screen</font></td><td>desktops number (0 = primary)</td><td>Yes</td><td>Yes</td></tr>
</table>
EndRem
Function DesktopRatio:String (screen:Int=0)

			Function DAR:Int (a:Int, b:Int)
				Local fudge:Int = 0
				Local Result:Int
				If b Mod a <= fudge
					Result = a
				Else
					Result = DAR (b, a Mod b)
				EndIf
				Return Result
			End Function

	Local X:Int = DesktopWidthMulti(screen)
	Local Y:Int = DesktopHeightMulti(screen)
	Local Div:Int = DAR(X,Y)
	Local Result:String = String (X/Div) + ":" + String(Y/Div)
	Select Result
		Case "8:5" ; 	Return "16:10"
		Default ; 		Return Result
	End Select

End Function

'-------------------------------------------------------------------

Rem
bbdoc: Get amount of available desktops 
returns: amount as integer
EndRem
Function DesktopCount:Int () 
	?Win32
		Return GetSystemMetrics (SM_CMONITORS)
	?MacOS
		Local display:Byte Ptr[] = New Byte Ptr[1]
		Local iMode:Byte Ptr = Null
		Local iCount:Int
		CGGetActiveDisplayList 1, display, iCount
		Return iCount
	?Linux
		Return 0
	?
End Function

'-------------------------------------------------------------------

Rem
bbdoc: Get desktop x-coord
returns: coord as integer
about: 
<table>
<tr><th>Flag</th><th>Description</th><th>Win32</th><th>MacOS</th></tr>
<tr><td><font class=token>screen</font></td><td>desktops number (0 = primary)</td><td>Yes</td><td>No</td></tr>
</table>
EndRem
Function DesktopX:Int (screen:Int = 0) 
	If screen < 0 Then screen = 0
	?Win32
			For Local display:TDisplay = EachIn TDisplay.List
				If display.id = screen+1
					Return display.X
				EndIf
			Next
			Return 0
	?MacOS
		Return 0
	?Linux
		Return 0
	?
End Function 


'-------------------------------------------------------------------

Rem
bbdoc: Get desktop y-coord
returns: coord as integer
about: 
<table>
<tr><th>Flag</th><th>Description</th><th>Win32</th><th>MacOS</th></tr>
<tr><td><font class=token>screen</font></td><td>desktops number (0 = primary)</td><td>Yes</td><td>No</td></tr>
</table>
EndRem
Function DesktopY:Int (screen:Int = 0) 
	If screen < 0 Then screen = 0
	?Win32
			For Local display:TDisplay = EachIn TDisplay.List
				If display.id = screen+1
					Return display.Y
				EndIf
			Next
			Return 0
	?MacOS
		Return 0
	?Linux
		Return 0
	?
End Function 


'-------------------------------------------------------------------

Rem
bbdoc: Get desktop width
returns: width as integer
about: 
<table>
<tr><th>Flag</th><th>Description</th><th>Win32</th><th>MacOS</th></tr>
<tr><td><font class=token>screen</font></td><td>desktops number (0 = primary)</td><td>Yes</td><td>Yes</td></tr>
</table>
EndRem
Function DesktopWidthMulti:Int (screen:Int=0) 
	Local width:Int,height:Int,depth:Int,hertz:Int
	GetDesktopMode (width, height, depth, hertz, screen)
	Return width
End Function 


'-------------------------------------------------------------------

Rem
bbdoc: Get desktop height
returns: height as integer
about: 
<table>
<tr><th>Flag</th><th>Description</th><th>Win32</th><th>MacOS</th></tr>
<tr><td><font class=token>screen</font></td><td>desktops number (0 = primary)</td><td>Yes</td><td>Yes</td></tr>
</table>
EndRem
Function DesktopHeightMulti:Int (screen:Int=0) 
	Local width:Int,height:Int,depth:Int,hertz:Int
	GetDesktopMode (width, height, depth, hertz, screen)
	Return height
End Function 


'-------------------------------------------------------------------

Rem
bbdoc: Get desktop depth
returns: depth as integer
about: 
<table>
<tr><th>Flag</th><th>Description</th><th>Win32</th><th>MacOS</th></tr>
<tr><td><font class=token>screen</font></td><td>desktops number (0 = primary)</td><td>Yes</td><td>Yes</td></tr>
</table>
EndRem
Function DesktopDepthMulti:Int (screen:Int=0) 
	Local width:Int,height:Int,depth:Int,hertz:Int
	GetDesktopMode (width, height, depth, hertz, screen)
	Return depth
End Function 


'-------------------------------------------------------------------

Rem
bbdoc: Get desktop hertz
returns: hertz as integer
about: 
<table>
<tr><th>Flag</th><th>Description</th><th>Win32</th><th>MacOS</th></tr>
<tr><td><font class=token>screen</font></td><td>desktops number (0 = primary)</td><td>Yes</td><td>Yes</td></tr>
</table>
EndRem
Function DesktopHertzMulti:Int (screen:Int=0) 
	Local width:Int,height:Int,depth:Int,hertz:Int
	GetDesktopMode (width, height, depth, hertz, screen)
	Return hertz
End Function 


'-------------------------------------------------------------------

Rem
bbdoc: Get desktop width, height, depth, hertz
returns: int var
about: 
<table>
<tr><th>Flag</th><th>Description</th><th>Win32</th><th>MacOS</th></tr>
<tr><td><font class=token>width</font></td><td>Int Var for desktops width</td><td>Yes</td><td>Yes</td></tr>
<tr><td><font class=token>screen</font></td><td>Int Var for desktops height</td><td>Yes</td><td>Yes</td></tr>
<tr><td><font class=token>screen</font></td><td>Int Var for desktops depth</td><td>Yes</td><td>Yes</td></tr>
<tr><td><font class=token>screen</font></td><td>Int Var for desktops hertz</td><td>Yes</td><td>Yes</td></tr>
<tr><td><font class=token>screen</font></td><td>desktops number (0 = primary)</td><td>Yes</td><td>Yes</td></tr>
</table>
EndRem
Function GetDesktopMode:Int (width:Int Var, height:Int Var, depth:Int Var, hertz:Int Var, screen:Int=0) 
	?Win32
		Local hwnd:Int = GetDesktopWindow()
		Local hdc:Int = GetDC(hwnd)
		If hdc = Null Then Return -1
		depth  = GetDeviceCaps(hdc, BITSPIXEL)
		hertz  = GetDeviceCaps(hdc, VREFRESH)
		ReleaseDC(hwnd,hdc)
		If screen = -1
			width = GetSystemMetrics (SM_CXVIRTUALSCREEN)
			height = GetSystemMetrics (SM_CYVIRTUALSCREEN)
		Else
			Local valid:Byte = True
			For Local display:TDisplay = EachIn TDisplay.List
				If display.id = screen+1
					width = display.width
					height = display.height
					Exit
				EndIf
			Next
		EndIf	
	?MacOS
		Local display:Byte Ptr[] = New Byte Ptr[screen+1]
		Local iMode:Byte Ptr = Null
		Local iCount:Int
		CGGetActiveDisplayList screen+1, display, iCount
		If (screen < iCount)
			iMode  = CGDisplayCurrentMode(display[screen])
		Else
			Throw " [DesktopExt] Screen '"+screen+"' does not exist!"
		End If
		width  = MACOS_GetWidth(iMode)
		height = MACOS_GetHeight(iMode)
		depth  = MACOS_GetBPP(iMode)
		hertz  = MACOS_GetHertz(iMode)
	?Linux
		width  = 0
		height = 0
		depth  = 0
		hertz  = 0
	?
End Function 



'-------------------------------------------------------------------

Rem
bbdoc: Get desktop screenshot
returns: screenshot as pixmap
about: 
<table>
<tr><th>Flag</th><th>Description</th><th>Win32</th><th>MacOS</th></tr>
<tr><td><font class=token>flag</font></td><td>True = flip pixmap vertical</td><td>Yes</td><td>No</td></tr>
<tr><td><font class=token>screen</font></td><td>desktops number (0 = primary)</td><td>Yes</td><td>No</td></tr>
</table>
EndRem
Function DesktopPixmap:TPixmap (flag:Byte = True, Screen:Int = -1) 

	'Original Funktion von Suco-X

	?Linux
		Return Null
	?MacOS
		Return Null
	?Win32
		Local hwnd:Int = GetDesktopWindow()
		If Not hwnd Return Null
		Local hdc:Int = GetWindowDC(hwnd)
		If Not hdc Return Null
		Local hdcmem:Int = CreateCompatibleDC(hdc)
    		If Not hdcmem Return Null
		Local info:BITMAPINFOHEADER = New BITMAPINFOHEADER
		info.biSize = SizeOf(info)
		info.biPlanes = 1
		info.biCompression = 0
		Local hertz:Int,depth:Int
		
		GetDesktopMode:Int (info.biWidth,info.biHeight,depth,hertz,Screen)
		info.biBitCount = depth
		Local bmpmem:Int  = CreateCompatibleBitmap(hdc, info.biWidth, info.biHeight)
 		If (Not bmpmem) Or (Not SelectObject(hdcmem, bmpmem)) Return Null
		If Not BitBlt(hdcmem,0,0,info.biWidth,info.biHeight,hdc,DesktopX(Screen),DesktopY(Screen),ROP_SRCCOPY) Return Null


		Local out:TPixmap = CreatePixmap(info.biWidth, info.biHeight, PF_BGRA8888)
		If Not GetDIBits(hdcmem, bmpmem, 0, info.biHeight, out.PixelPtr(0,0), info, 0) Return Null
		DeleteDC(hdcmem)
		DeleteObject(bmpmem)
		ReleaseDC(hwnd, hdc)
		out = out.Convert(PF_BGR888) 'dumm gelaufen, man kann nicht direkt in dem Format grabben
		If flag = True out = YFlipPixmap(out)
		Return out
	?
End Function


'-------------------------------------------------------------------

Rem
bbdoc: Get desktop mouse x-coord
returns: coord as integer
about: 
<table>
<tr><th>Flag</th><th>Description</th><th>Win32</th><th>MacOS</th></tr>
<tr><td><font class=token>screen</font></td><td>desktops number (0 = primary)</td><td>Yes</td><td>Yes</td></tr>
</table>
EndRem
Function DesktopMouseX:Int () 
	?Linux
		Return 0
	?MacOS
		Return MACOS_GetMouseX ()
	?Win32
		Local Coord:Int[2]
		GetCursorPos(Coord)
		Return Coord[0]
	?
End Function 


'-------------------------------------------------------------------

Rem
bbdoc: Get desktop mouse y-coord
returns: coord as integer
about: 
<table>
<tr><th>Flag</th><th>Description</th><th>Win32</th><th>MacOS</th></tr>
<tr><td><font class=token>screen</font></td><td>desktops number (0 = primary)</td><td>Yes</td><td>Yes</td></tr>
</table>
EndRem
Function DesktopMouseY:Int () 
	?Linux
		Return 0
	?MacOS
		Return MACOS_GetMouseY ()
	?Win32
		Local Coord:Int[2]
		GetCursorPos(Coord)
		Return Coord[1]
	?
End Function 



