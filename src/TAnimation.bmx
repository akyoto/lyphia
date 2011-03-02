' Strict
SuperStrict

' TAnimation
Type TAnimation Abstract
	Field frame:Int
	Field frameDuration:Int
	Field lastUpdate:Int
	Field active:Int = 0
	
	Method Start() Abstract
	Method NextFrame() Abstract
	Method Stop() Abstract
	
	' Play
	Method Play()
		If Self.active And MilliSecs() - Self.lastUpdate > frameDuration
			Self.NextFrame()
			Self.lastUpdate = MilliSecs()
		EndIf
	End Method
	
	' SetFrameDuration
	Method SetFrameDuration(nFrameDuration:Int)
		Self.frameDuration = nFrameDuration
	End Method
	
	' GetFrameDuration
	Method GetFrameDuration:Int()
		Return Self.frameDuration
	End Method
	
	' GetFrame
	Method GetFrame:Int()
		Return Self.frame
	End Method
	
	' IsActive
	Method IsActive:Int()
		Return Self.active
	End Method
End Type

' TAnimationNone
Type TAnimationNone
	Global Singleton:TAnimationNone = New TAnimationNone
	
	' Start
	Method Start()
		
	End Method
	
	' Play
	Method Play()
		
	End Method
	
	' Stop
	Method Stop()
		
	End Method
End Type