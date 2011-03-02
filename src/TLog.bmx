' Strict
SuperStrict

' Modules
Import BRL.System
Import BRL.Stream

?Threaded
Import BRL.Threads
?

' Files
Import "Global.bmx"

' TLog
Type TLog
	Const separator:String = "------------------------------------------------------"
	
	Field stream:TStream
	Field lastLogTime:Int
	
	?Threaded
		Field streamMutex:TMutex
	?
	
	' Init
	Method Init(nStream:TStream)
		Self.stream = nStream
		Self.lastLogTime = 0
		
		?Threaded
			Self.streamMutex = CreateMutex()
		?
	End Method
	
	' Delete
	Method Delete()
		Self.Remove()
	End Method
	
	' Remove
	Method Remove()
		If Self.stream
			Self.stream.Close()
		EndIf
		Self.stream = Null
	End Method
	
	' Write
	Method Write(msg:String)
		If Self.stream <> Null
			Local postFix:String = ""
			
			?Threaded
				Self.streamMutex.Lock()
			?
			
			If Self.lastLogTime <> 0
				postFix = " [" + (MilliSecs() - Self.lastLogTime) + " ms]" + NEWLINE
			EndIf
			
			Self.stream.WriteString(postFix + CurrentDate() + " - " + CurrentTime() + " : " + msg)
			Self.stream.Flush()
			Self.lastLogTime = MilliSecs()
			
			?Threaded
				Self.streamMutex.Unlock()
			?
		EndIf
	End Method
	
	' Create
	Function Create:TLog(nStream:TStream)
		Local logger:TLog = New TLog
		logger.Init(nStream)
		Return logger
	End Function
End Type

