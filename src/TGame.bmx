' Strict
SuperStrict

' Modules
Import BRL.Map
Import BRL.Max2D
Import BRL.GLMax2D

?Threaded
Import BRL.Threads
?

?Win32
Import BRL.D3D7Max2D
Import BRL.D3D9Max2D
?

' Files
Import "Global.bmx"
Import "TLog.bmx"
Import "TLua.bmx"
Import "TInputSystem.bmx"
Import "Managers/TImageManager.bmx"
Import "Managers/TSoundManager.bmx"
Import "Managers/TScriptManager.bmx"
Import "Managers/TFontManager.bmx"

' Includes
Include "TGameState.bmx"

' Singleton
Global game:TGame

' TGame
Type TGame
	' Manager instances
	Field imageMgr:TImageManager
	Field soundMgr:TSoundManager
	Field scriptMgr:TScriptManager
	Field fontMgr:TFontManager
	
	' Graphics configuration
	Field gfx:TGraphics
	Field gfxWidth:Int
	Field gfxHeight:Int
	Field gfxWidthHalf:Int
	Field gfxHeightHalf:Int
	Field fullscreen:Int
	Field driver:String
	Field audioDriver:String
	Field vsync:Int
	
	' Account
	Field accountID:Int
	Field accountInfo:TMap
	
	' Network
	Field receiveTimeout:Int
	Field sendTimeout:Int
	Field acceptTimeout:Int
	Field networkThreadDelay:Int
	
	Field frameTime:Int
	Field lastFrameTimeUpdate:Int
	Field speed:Int
	
	?Threaded
		Field appCheckThread:TThread
	?Not Threaded
		Field oldAppSuspended:Int
	?
	
	' Map containing all game state names and references
	Field mapGS:TMap
	
	' Active game state
	Field gameState:TGameState
	
	' Log
	Field logger:TLog
	Field loggerDetail:TLog
	
	' Init
	Method Init()
		' Log
		?Debug
			Self.logger = TLog.Create(StandardIOStream)
		?Not Debug
			Self.logger = TLog.Create(WriteFile(FS_ROOT + "logs/main.txt"))
		?
		
		' Detail Log
		?Debug
			Self.loggerDetail = TLog.Create(StandardIOStream)
		?Not Debug
			Self.loggerDetail = TLog.Create(WriteFile(FS_ROOT + "logs/detail.txt"))
		?
		
		' Manager instances
		Self.soundMgr = TSoundManager.Create(TLog.Create(WriteFile(FS_ROOT + "logs/audio.txt")))
		Self.imageMgr = TImageManager.Create(TLog.Create(WriteFile(FS_ROOT + "logs/images.txt")))
		Self.scriptMgr = TScriptManager.Create(TLog.Create(WriteFile(FS_ROOT + "logs/scripts.txt")))
		Self.fontMgr = TFontManager.Create(TLog.Create(WriteFile(FS_ROOT + "logs/fonts.txt")))
		
		Self.mapGS = CreateMap()
		Self.speed = 0.0
		
		?Threaded
			Self.appCheckThread = Null
		?
		
		' Account
		Self.accountID = 0
		Self.accountInfo = CreateMap()
		
		' Lua object
		LuaRegisterObject(Self, "game")
	End Method
	
	' RegisterGameState
	Method RegisterGameState(name:String, ref:TGameState) 
		mapGS.Insert(name, ref)
		LuaRegisterObject(ref, "gs" + name)
	End Method
	
	' SetGameState
	Method SetGameState(gs:TGameState)
		' Quit old game state
		If Self.gameState <> Null
			Self.gameState.Remove()
		EndIf
		
		' Change game state
		Self.gameState = gs
		
		' Init new game state
		If Self.gameState <> Null
			If Self.logger <> Null
				Self.logger.Write(TLog.separator)
				Self.logger.Write("Changing game state to: " + Self.gameState.ToString())
			EndIf
			
			Self.gameState.Init()
		EndIf
	End Method
	
	' GetGameState
	Method GetGameState:TGameState()
		Return Self.gameState
	End Method
	
	' SetGameStateByName
	Method SetGameStateByName(name:String) 
		Self.SetGameState(TGameState(Self.mapGS.ValueForKey(name)))
	End Method
	
	' GetGameStateByName
	Method GetGameStateByName:TGameState(name:String)
		Return TGameState(Self.mapGS.ValueForKey(name))
	End Method
	
	' Run
	Method Run()
		?Threaded
			Self.appCheckThread = CreateThread(TGame.AppThread, Null)
		?Not Threaded
			Local nowSuspended:Int
		?
		
		While Self.IsRunning() And AppTerminate() = 0
			Self.frameTime = MilliSecs() - Self.lastFrameTimeUpdate
			Self.speed = Self.frameTime
			
			Self.lastFrameTimeUpdate = MilliSecs()
			
			?Not Threaded
				nowSuspended = AppSuspended()
				If Self.oldAppSuspended = False And nowSuspended = True
					Self.gameState.OnAppSuspended()
				ElseIf Self.oldAppSuspended = True And nowSuspended = False
					Self.gameState.OnAppReactivated()
				EndIf
				Self.oldAppSuspended = nowSuspended
			?
			
			If Self.speed <> 0
				If Self.speed > 40
					Self.loggerDetail.Write("FrameTime = " + Self.frameTime)
					If Self.speed > 80
						Self.speed = 80
					EndIf
				EndIf
				Self.gameState.Update()
			Else
				' Reduce CPU usage
				'Self.loggerDetail.Write("FrameTime = 0")
				Delay 1
			EndIf
		Wend
	End Method
	
	' IsRunning
	Method IsRunning:Int()
		Return Self.gameState <> Null
	End Method
	
	' Remove
	Method Remove()
		Self.SetGameState(Null)
		Self.logger.Remove()
		
		?Threaded
			WaitThread Self.appCheckThread
		?
	End Method
	
	' SetVideoMode
	Method SetVideoMode(width:Int, height:Int, nFullscreen:Int, nDriver:String)
		' Select driver
		Self.driver = nDriver
		
		' Select graphics driver
		Select game.driver.ToUpper()
			?Win32
			Case "DIRECT3D7", "DIRECTX7", "D3D7", "DX7"
				game.logger.Write("Init graphics driver: Direct3D7")
				SetGraphicsDriver D3D7Max2DDriver()
				
			Case "DIRECT3D9", "DIRECTX9", "D3D9", "DX9"
				game.logger.Write("Init graphics driver: Direct3D9")
				SetGraphicsDriver D3D9Max2DDriver()
			?
			Default
				game.logger.Write("Init graphics driver: OpenGL")
				SetGraphicsDriver GLMax2DDriver()
		End Select
		
		' Desktop size
		If width < 0
			width = DesktopWidth() 'DesktopWidthMulti(-width - 1)
		EndIf
		If height < 0
			height = DesktopHeight() 'DesktopHeightMulti(-height - 1)
		EndIf
		
		' Assign values
		Self.gfxWidth = width
		Self.gfxHeight = height
		Self.gfxWidthHalf = width / 2
		Self.gfxHeightHalf = height / 2
		Self.fullscreen = nFullscreen
		
		' Graphics window
		If game.fullscreen
			game.logger.Write("Init graphics window: " + game.gfxWidth + " x " + game.gfxHeight + " (Fullscreen)")
		Else
			game.logger.Write("Init graphics window: " + game.gfxWidth + " x " + game.gfxHeight)
		EndIf
		
		If game.gfx <> Null
			CloseGraphics game.gfx
			game.gfx = Null
		EndIf
		
		' TODO: Hertz
		game.gfx = CreateGraphics(Self.gfxWidth, Self.gfxHeight, Self.fullscreen * 32, 75, GRAPHICS_BACKBUFFER)
		SetGraphics game.gfx
	End Method
	
	' AppThread
	?Threaded
	Function AppThread:Object(data:Object)
		Local oldAppSuspended:Int = False
		Local nowSuspended:Int
		
		While game.IsRunning()
			' AppSuspended check
			nowSuspended = AppSuspended()
			If oldAppSuspended = False And nowSuspended = True
				game.gameState.OnAppSuspended()
			ElseIf oldAppSuspended = True And nowSuspended = False
				game.gameState.OnAppReactivated()
			EndIf
			oldAppSuspended = nowSuspended
			
			Delay 20
		Wend
		
		Return Null
	End Function
	?
	
	' Create
	Function Create:TGame()
		Local game:TGame = New TGame
		game.Init()
		Return game
	End Function
End Type
