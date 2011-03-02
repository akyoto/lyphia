' Strict
SuperStrict

' Modules
Import BRL.Max2D
'Import BtbN.GLDraw2D

' Files
Import "../TGame.bmx"

' Global
Global gsExit:TGameStateExit

' TGameStateExit
Type TGameStateExit Extends TGameState
	' Init
	Method Init()
		EndGraphics()
		
		' Memory usage
		game.logger.Write("GC collect: " + GCCollect() + " bytes")
	End Method
	
	' Update
	Method Update()
		
	End Method
	
	' Remove
	Method Remove()
		' End
		game.logger.Write("End")
	End Method
	
	' OnAppSuspended
	Method OnAppSuspended()
		
	End Method
	
	' OnAppReactivated
	Method OnAppReactivated()
		
	End Method
	
	' ToString
	Method ToString:String()
		Return "Exit"
	End Method
	
	' Create
	Function Create:TGameStateExit(gameRef:TGame)
		Local gs:TGameStateExit = New TGameStateExit
		gameRef.RegisterGameState("Exit", gs)
		Return gs
	End Function
End Type

