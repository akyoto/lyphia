' Strict
SuperStrict

' Modules
Import BRL.PolledInput
Import PUB.FreeJoy

' Files
Import "TTrigger.bmx"

' TKeyTrigger
Type TKeyTrigger Extends TTrigger
	Field key:Int
	Field holdDown:Int
	
	' Init
	Method Init(nKey:Int, nHoldDown:Int = 0)
		Self.SetKey(nKey)
		Self.SetHoldDown(nHoldDown)
	End Method
	
	' SetKey
	Method SetKey(nKey:Int)
		Self.key = nKey
	End Method
	
	' SetHoldDown
	Method SetHoldDown(nHoldDown:Int)
		Self.holdDown = nHoldDown
	End Method
	
	' Triggered
	Method Triggered:Int()
		If Self.holdDown = True
			Return TInputSystem.GetKeyDown(Self.key)
		Else
			Return TInputSystem.GetKeyHit(Self.key)
		EndIf
	End Method
	
	' Create
	Function Create:TKeyTrigger(nKey:Int, nHoldDown:Int = 0)
		Local kt:TKeyTrigger = New TKeyTrigger
		kt.Init(nKey, nHoldDown)
		Return kt
	End Function
End Type

' TJoyKeyTrigger
Type TJoyKeyTrigger Extends TTrigger
	Field key:Int
	Field holdDown:Int
	
	' Init
	Method Init(nKey:Int, nHoldDown:Int = 0)
		Self.SetKey(nKey)
		Self.SetHoldDown(nHoldDown)
	End Method
	
	' SetKey
	Method SetKey(nKey:Int)
		Self.key = nKey
	End Method
	
	' SetHoldDown
	Method SetHoldDown(nHoldDown:Int)
		Self.holdDown = nHoldDown
	End Method
	
	' Triggered
	Method Triggered:Int()
		If Self.holdDown = True
			Return JoyDown(Self.key)
		Else
			Return JoyHit(Self.key)
		EndIf
	End Method
	
	' Create
	Function Create:TJoyKeyTrigger(nKey:Int, nHoldDown:Int = 0)
		Local kt:TJoyKeyTrigger = New TJoyKeyTrigger
		kt.Init(nKey, nHoldDown)
		Return kt
	End Function
End Type

' TJoyMoveTrigger
Type TJoyMoveTrigger Extends TTrigger
	Const AXIS_X:Int = 0
	Const AXIS_Y:Int = 1
	
	Field axis:Int
	Field sign:Int
	Field deadZone:Float
	
	' Init
	Method Init(nAxis:Int, nSign:Int = 1)
		Self.SetAxis(nAxis)
		Self.SetDirection(nSign)
		Self.SetDeadZone(0.98)
	End Method
	
	' SetAxis
	Method SetAxis(nAxis:Int)
		Self.axis = nAxis
	End Method
	
	' SetDirection
	Method SetDirection(nDirection:Int)
		Self.sign = nDirection
	End Method
	
	' SetDeadZone
	Method SetDeadZone(nDeadZone:Int)
		Self.deadZone = nDeadZone
	End Method
	
	' Triggered
	Method Triggered:Int()
		Select axis
			Case AXIS_X
				If Self.sign = 1
					Return JoyX() > Self.deadZone
				Else
					Return JoyX() < -Self.deadZone
				EndIf
				
			Case AXIS_Y
				If Self.sign = 1
					Return JoyY() > Self.deadZone
				Else
					Return JoyY() < -Self.deadZone
				EndIf
				
			Default
				Return False
		End Select
	End Method
	
	' Create
	Function Create:TJoyMoveTrigger(nAxis:Int, nSign:Int = 1)
		Local kt:TJoyMoveTrigger = New TJoyMoveTrigger
		kt.Init(nAxis, nSign)
		Return kt
	End Function
End Type

' TJoyHatTrigger
Type TJoyHatTrigger Extends TTrigger
	Const AXIS_X:Int = 0
	Const AXIS_Y:Int = 1
	
	Field axis:Int
	Field sign:Int
	
	' Init
	Method Init(nAxis:Int, nSign:Int = 1)
		Self.SetAxis(nAxis)
		Self.SetDirection(nSign)
	End Method
	
	' SetAxis
	Method SetAxis(nAxis:Int)
		Self.axis = nAxis
	End Method
	
	' SetDirection
	Method SetDirection(nDirection:Int)
		Self.sign = nDirection
	End Method
	
	' Triggered
	Method Triggered:Int()
		If JoyCount() = 0
			Return False
		EndIf
		
		' TODO: Add mathematical calculation based on the JoyHat() value
		Select axis
			Case AXIS_X
				If Self.sign = 1
					Return JoyHat() = 0.25 Or JoyHat() = 0.125 Or JoyHat() = 0.375
				Else
					Return JoyHat() = 0.75 Or JoyHat() = 0.875 Or JoyHat() = 0.625
				EndIf
				
			Case AXIS_Y
				If Self.sign = 1
					Return JoyHat() = 0.50 Or JoyHat() = 0.625 Or JoyHat() = 0.375
				Else
					Return JoyHat() = 0.00 Or JoyHat() = 0.125 Or JoyHat() = 0.875
				EndIf
				
			Default
				Return False
		End Select
	End Method
	
	' Create
	Function Create:TJoyHatTrigger(nAxis:Int, nSign:Int = 1)
		Local kt:TJoyHatTrigger = New TJoyHatTrigger
		kt.Init(nAxis, nSign)
		Return kt
	End Function
End Type

' TInputSystem
Type TInputSystem
	Const MAX_MOUSE_BUTTONS:Int = 3
	Const MAX_KEYS:Int = 256
	
	Global mx:Int, my:Int, mz:Int
	Global mxs:Int, mys:Int, mzs:Int
	Global mh:Int[MAX_MOUSE_BUTTONS], md:Int[MAX_MOUSE_BUTTONS], mu:Int[MAX_MOUSE_BUTTONS]
	Global kh:Int[MAX_KEYS], kd:Int[MAX_KEYS]
	
	Global mxC:Int, myC:Int, mzC:Int
	Global mxsC:Int, mysC:Int, mzsC:Int
	Global mhC:Int[MAX_MOUSE_BUTTONS], mdC:Int[MAX_MOUSE_BUTTONS], muC:Int[MAX_MOUSE_BUTTONS]
	Global khC:Int[MAX_KEYS], kdC:Int[MAX_KEYS]
	'Global scanToAscii:Byte[256]
	
	' New
	Method New()
		RuntimeError "This is a manager class"
	End Method
	
	' Update
	Function Update()
		Local nX:Int = MouseX()
		Local nY:Int = MouseY() 
		Local nZ:Int = MouseZ()
		
		' Custom mouse speed calculation
		mxs = nX - mx
		mys = nY - my
		mzs = nZ - mz
		mx = nX
		my = nY
		mz = nZ
		
		' Mouse buttons
		For Local i:Int = 0 Until MAX_MOUSE_BUTTONS
			mh[i] = MouseHit(i + 1)
			
			mu[i] = md[i]
			md[i] = MouseDown(i + 1)
			
			If mu[i]
				mu[i] = mu[i] - md[i]
			EndIf
		Next
		
		' Keyboard
		For Local i:Int = 1 Until MAX_KEYS
			kh[i] = KeyHit(i)
			kd[i] = KeyDown(i)
		Next
		
		' Create a copy
		TInputSystem.SaveKeyEvents()
		TInputSystem.SaveMouseEvents()
		TInputSystem.SaveMouseSpeed()
	End Function
	
	' GetMouseHit
	Function GetMouseHit:Int(button:Int)
		Return mh[button - 1]
	End Function
	
	' GetMouseDown
	Function GetMouseDown:Int(button:Int)
		Return md[button - 1]
	End Function
	
	' GetMouseUp
	Function GetMouseUp:Int(button:Int)
		Return mu[button - 1]
	End Function
	
	' GetKeyHit
	Function GetKeyHit:Int(key:Int)
		Return kh[key]
	End Function
	
	' GetKeyDown
	Function GetKeyDown:Int(key:Int)
		Return kd[key]
	End Function
	
	' GetMouseX
	Function GetMouseX:Int()
		Return mx
	End Function
	
	' GetMouseY
	Function GetMouseY:Int()
		Return my
	End Function
	
	' GetMouseZ
	Function GetMouseZ:Int()
		Return mz
	End Function
	
	' GetMouseXSpeed
	Function GetMouseXSpeed:Int()
		Return mxs
	End Function
	
	' GetMouseYSpeed
	Function GetMouseYSpeed:Int()
		Return mys
	End Function
	
	' GetMouseZSpeed
	Function GetMouseZSpeed:Int()
		Return mzs
	End Function
	
	' GetNextChar
	Function GetNextChar:Int()
		Return GetChar()
	End Function
	
	' GetString
	Function GetString:String()
		Local stri:String
		Local char:Int = GetChar()
		While char <> 0
			stri:+Chr(char)
			char = GetChar()
		Wend
		Return stri
	End Function
	
	' EraseAllEvents
	Function EraseAllEvents()
		Self.EraseKeyEvents()
		Self.EraseMouseEvents()
	End Function
	
	' ResetCharacterQueue
	Function ResetCharacterQueue()
		'FlushKeys()
		While GetChar()
		Wend
	End Function
	
	' EraseKeyEvents
	Function EraseKeyEvents()
		For Local i:Int = 0 Until MAX_KEYS
			kh[i] = 0
			kd[i] = 0
		Next
	End Function
	
	' EraseMouseEvents
	Function EraseMouseEvents()
		For Local i:Int = 0 Until MAX_MOUSE_BUTTONS
			mh[i] = 0
			md[i] = 0
			mu[i] = 0
		Next
		TInputSystem.EraseMouseSpeed()
	End Function
	
	' EraseMouseSpeed
	Function EraseMouseSpeed()
		mxs = 0
		mys = 0
		mzs = 0
	End Function
	
	' SaveKeyEvents
	Function SaveKeyEvents()
		For Local i:Int = 0 Until MAX_KEYS
			khC[i] = kh[i]
			kdC[i] = kd[i]
		Next
	End Function
	
	' SaveMouseEvents
	Function SaveMouseEvents()
		For Local i:Int = 0 Until MAX_MOUSE_BUTTONS
			mhC[i] = mh[i]
			
			muC[i] = mdC[i]
			mdC[i] = md[i]
			
			If muC[i]
				muC[i] = muC[i] - mdC[i]
			EndIf
		Next
	End Function
	
	' SaveMouseSpeed
	Function SaveMouseSpeed()
		mxsC = mxs
		mysC = mys
		mzsC = mzs
	End Function
	
	' SomethingHappened
	Function SomethingHappened:Int()
		If mxsC <> 0 Or mysC <> 0 Or mzsC <> 0
			Return True
		EndIf
		
		' Mouse buttons
		For Local i:Int = 0 Until MAX_MOUSE_BUTTONS
			If mhC[i] Or mdC[i] Or muC[i]
				Return True
			EndIf
		Next
		
		' Keyboard
		For Local i:Int = 1 Until MAX_KEYS
			If khC[i] Or kdC[i]
				Return True
			EndIf
		Next
		
		Return False
	End Function
End Type

Rem
' Scan code to ascii code
TInputSystem.scanToAscii[  1] = 27
TInputSystem.scanToAscii[  2] = 49
TInputSystem.scanToAscii[  3] = 50
TInputSystem.scanToAscii[  4] = 51
TInputSystem.scanToAscii[  5] = 52
TInputSystem.scanToAscii[  6] = 53
TInputSystem.scanToAscii[  7] = 54
TInputSystem.scanToAscii[  8] = 55
TInputSystem.scanToAscii[  9] = 56
TInputSystem.scanToAscii[ 10] = 57
TInputSystem.scanToAscii[ 11] = 48
TInputSystem.scanToAscii[ 12] = 219
TInputSystem.scanToAscii[ 13] = 0
TInputSystem.scanToAscii[ 14] = 8
TInputSystem.scanToAscii[ 15] = 9
TInputSystem.scanToAscii[ 16] = 81
TInputSystem.scanToAscii[ 17] = 87
TInputSystem.scanToAscii[ 18] = 69
TInputSystem.scanToAscii[ 19] = 82
TInputSystem.scanToAscii[ 20] = 84
TInputSystem.scanToAscii[ 21] = 90
TInputSystem.scanToAscii[ 22] = 85
TInputSystem.scanToAscii[ 23] = 73
TInputSystem.scanToAscii[ 24] = 79
TInputSystem.scanToAscii[ 25] = 80
TInputSystem.scanToAscii[ 26] = 186
TInputSystem.scanToAscii[ 27] = 0
TInputSystem.scanToAscii[ 28] = 13
TInputSystem.scanToAscii[ 29] = 162
TInputSystem.scanToAscii[ 30] = 65
TInputSystem.scanToAscii[ 31] = 83
TInputSystem.scanToAscii[ 32] = 68
TInputSystem.scanToAscii[ 33] = 70
TInputSystem.scanToAscii[ 34] = 71
TInputSystem.scanToAscii[ 35] = 72
TInputSystem.scanToAscii[ 36] = 74
TInputSystem.scanToAscii[ 37] = 75
TInputSystem.scanToAscii[ 38] = 76
TInputSystem.scanToAscii[ 39] = 222
TInputSystem.scanToAscii[ 40] = 220
TInputSystem.scanToAscii[ 41] = 221
TInputSystem.scanToAscii[ 42] = 160
TInputSystem.scanToAscii[ 43] = 0
TInputSystem.scanToAscii[ 44] = 89
TInputSystem.scanToAscii[ 45] = 88
TInputSystem.scanToAscii[ 46] = 67
TInputSystem.scanToAscii[ 47] = 86
TInputSystem.scanToAscii[ 48] = 66
TInputSystem.scanToAscii[ 49] = 78
TInputSystem.scanToAscii[ 50] = 77
TInputSystem.scanToAscii[ 51] = 188
TInputSystem.scanToAscii[ 52] = 190
TInputSystem.scanToAscii[ 53] = 189
TInputSystem.scanToAscii[ 54] = 161
TInputSystem.scanToAscii[ 55] = 106
TInputSystem.scanToAscii[ 56] = 18
TInputSystem.scanToAscii[ 57] = 32
TInputSystem.scanToAscii[ 58] = 20
TInputSystem.scanToAscii[ 59] = 112
TInputSystem.scanToAscii[ 60] = 113
TInputSystem.scanToAscii[ 61] = 114
TInputSystem.scanToAscii[ 62] = 115
TInputSystem.scanToAscii[ 63] = 116
TInputSystem.scanToAscii[ 64] = 117
TInputSystem.scanToAscii[ 65] = 118
TInputSystem.scanToAscii[ 66] = 119
TInputSystem.scanToAscii[ 67] = 120
TInputSystem.scanToAscii[ 68] = 121
TInputSystem.scanToAscii[ 69] = 144
TInputSystem.scanToAscii[ 70] = 145
TInputSystem.scanToAscii[ 71] = 103
TInputSystem.scanToAscii[ 72] = 104
TInputSystem.scanToAscii[ 73] = 105
TInputSystem.scanToAscii[ 74] = 109
TInputSystem.scanToAscii[ 75] = 100
TInputSystem.scanToAscii[ 76] = 101
TInputSystem.scanToAscii[ 77] = 102
TInputSystem.scanToAscii[ 78] = 107
TInputSystem.scanToAscii[ 79] = 97
TInputSystem.scanToAscii[ 80] = 98
TInputSystem.scanToAscii[ 81] = 99
TInputSystem.scanToAscii[ 82] = 96
TInputSystem.scanToAscii[ 83] = 110
TInputSystem.scanToAscii[ 84] = 0
TInputSystem.scanToAscii[ 85] = 0
TInputSystem.scanToAscii[ 86] = 0
TInputSystem.scanToAscii[ 87] = 122
TInputSystem.scanToAscii[ 88] = 123

TInputSystem.scanToAscii[153] = 176
TInputSystem.scanToAscii[154] = 0
TInputSystem.scanToAscii[155] = 0
TInputSystem.scanToAscii[156] = 108
TInputSystem.scanToAscii[157] = 163
TInputSystem.scanToAscii[158] = 0
TInputSystem.scanToAscii[159] = 0
TInputSystem.scanToAscii[160] = 173
TInputSystem.scanToAscii[161] = 0
TInputSystem.scanToAscii[162] = 179
TInputSystem.scanToAscii[163] = 0
TInputSystem.scanToAscii[164] = 178
TInputSystem.scanToAscii[165] = 0
TInputSystem.scanToAscii[166] = 0
TInputSystem.scanToAscii[167] = 0
TInputSystem.scanToAscii[168] = 0
TInputSystem.scanToAscii[169] = 0
TInputSystem.scanToAscii[170] = 0
TInputSystem.scanToAscii[171] = 0
TInputSystem.scanToAscii[172] = 0
TInputSystem.scanToAscii[173] = 0
TInputSystem.scanToAscii[174] = 175
TInputSystem.scanToAscii[175] = 0
TInputSystem.scanToAscii[176] = 174
TInputSystem.scanToAscii[177] = 0
TInputSystem.scanToAscii[178] = 172
TInputSystem.scanToAscii[179] = 0
TInputSystem.scanToAscii[180] = 0
TInputSystem.scanToAscii[181] = 111
TInputSystem.scanToAscii[182] = 0
TInputSystem.scanToAscii[183] = 44
TInputSystem.scanToAscii[184] = 18
TInputSystem.scanToAscii[185] = 0
TInputSystem.scanToAscii[186] = 0
TInputSystem.scanToAscii[187] = 0
TInputSystem.scanToAscii[188] = 0
TInputSystem.scanToAscii[189] = 0
TInputSystem.scanToAscii[190] = 0
TInputSystem.scanToAscii[191] = 0
TInputSystem.scanToAscii[192] = 0
TInputSystem.scanToAscii[193] = 0
TInputSystem.scanToAscii[194] = 0
TInputSystem.scanToAscii[195] = 0
TInputSystem.scanToAscii[196] = 0
TInputSystem.scanToAscii[197] = 19
TInputSystem.scanToAscii[198] = 0
TInputSystem.scanToAscii[199] = 36
TInputSystem.scanToAscii[200] = 38
TInputSystem.scanToAscii[201] = 33
TInputSystem.scanToAscii[202] = 0
TInputSystem.scanToAscii[203] = 37
TInputSystem.scanToAscii[204] = 0
TInputSystem.scanToAscii[205] = 39
TInputSystem.scanToAscii[206] = 0
TInputSystem.scanToAscii[207] = 35
TInputSystem.scanToAscii[208] = 40
TInputSystem.scanToAscii[209] = 34
TInputSystem.scanToAscii[210] = 45
TInputSystem.scanToAscii[211] = 46
TInputSystem.scanToAscii[212] = 0
TInputSystem.scanToAscii[213] = 0
TInputSystem.scanToAscii[214] = 0
TInputSystem.scanToAscii[215] = 0
TInputSystem.scanToAscii[216] = 0
TInputSystem.scanToAscii[217] = 0
TInputSystem.scanToAscii[218] = 0
TInputSystem.scanToAscii[219] = 91
TInputSystem.scanToAscii[220] = 92
TInputSystem.scanToAscii[221] = 93
TInputSystem.scanToAscii[222] = 0
TInputSystem.scanToAscii[223] = 0
TInputSystem.scanToAscii[224] = 0
TInputSystem.scanToAscii[225] = 0
TInputSystem.scanToAscii[226] = 0
TInputSystem.scanToAscii[227] = 0
TInputSystem.scanToAscii[228] = 0
TInputSystem.scanToAscii[229] = 0
TInputSystem.scanToAscii[230] = 171
TInputSystem.scanToAscii[231] = 168
TInputSystem.scanToAscii[232] = 169
TInputSystem.scanToAscii[233] = 166
TInputSystem.scanToAscii[234] = 0
TInputSystem.scanToAscii[235] = 0
TInputSystem.scanToAscii[236] = 180
TInputSystem.scanToAscii[237] = 181
End Rem
