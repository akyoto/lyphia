' Strict
SuperStrict

' TFrameRate
Type TFrameRate
	Field lastUpdate:Int
	Field frames:Int
	Field fps:Int
	Field sumFps:Float
	Field sumFpsCounted:Int
	Field updateInterval:Int
	Field customFunc(fr:TFrameRate)
	
	' Init
	Method Init(nUpdateInterval:Int)
		Self.lastUpdate = MilliSecs()
		Self.frames = 0
		Self.fps = 0
		Self.updateInterval = nUpdateInterval
		Self.customFunc = Null
	End Method
	
	' SetCustomFunction
	Method SetCustomFunction(nCustomFunc(fr:TFrameRate))
		Self.customFunc = nCustomFunc
	End Method
	
	' Update
	Method Update()
		Self.frames :+ 1
		
		If MilliSecs() - Self.lastUpdate >= Self.updateInterval
			Self.fps = Self.frames
			Self.frames = 0
			Self.lastUpdate = MilliSecs()
			
			Self.sumFps :+ Self.fps
			Self.sumFpsCounted :+ 1
			
			If Self.customFunc <> Null
				Self.customFunc(Self)
			EndIf
		EndIf
	End Method
	
	' UpdatePause
	Method UpdatePause()
		Self.lastUpdate = MilliSecs()
	End Method
	
	' GetFPS
	Method GetFPS:Int()
		Return Self.fps
	End Method
	
	' GetAverageFPS
	Method GetAverageFPS:Float()
		If Self.sumFpsCounted <> 0
			Return Self.sumFps / Self.sumFpsCounted
		Else
			Return 0
		EndIf
	End Method
	
	' Create
	Function Create:TFrameRate(updateInterval:Int = 1000)
		Local frameRate:TFrameRate = New TFrameRate
		frameRate.Init(updateInterval)
		Return frameRate
	End Function
End Type