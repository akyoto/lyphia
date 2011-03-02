' TGameState
Type TGameState Abstract
	'Field game:TGame
	
	' Init
	Method Init() Abstract
	
	' Update
	Method Update() Abstract
	
	' Remove
	Method Remove() Abstract
	
	' OnAppSuspended
	Method OnAppSuspended() Abstract
	
	' OnAppReactivated
	Method OnAppReactivated() Abstract
	
	' OnAppTerminate
	'Method OnAppTerminate() Abstract
	
	' ToString
	Method ToString:String() Abstract
End Type