' Strict
SuperStrict

' Modules
Import BRL.Max2D
'Import BtbN.GLDraw2D
Import BRL.FreeTypeFont
Import BRL.Retro
Import PUB.FreeJoy
Import BRL.Audio
Import BRL.OpenALAudio
Import BRL.FreeAudioAudio
Import Vertex.BNetEx

' Files
Import "../TGame.bmx"
Import "../TINILoader.bmx"
Import "../Utilities/System.bmx"
Import "../Utilities/Math.bmx"

' Global
Global gsInit:TGameStateInit

' TGameStateInit
Type TGameStateInit Extends TGameState
	Field ini:TINI
	
	' Init
	Method Init()
		' Title
		AppTitle = "Lyphia"
		
		' Mode
		?Debug
			game.logger.Write("Debug mode")
		?Not Debug
			game.logger.Write("Release mode")
		?
		
		' Register global game object
		LuaRegisterObject(game, "game")
		
		' Load configuration
		Self.LoadConfiguration(FS_ROOT + "config.ini")
		
		' Graphics modes
		game.logger.Write(CountGraphicsModes() + " available graphics modes:")
		For Local mode:TGraphicsMode = EachIn GraphicsModes()
			game.logger.Write(" * " + mode.width + " x " + mode.height + " (" + mode.depth + " bit, " + mode.hertz + " Hz, " + GetGraphicsRatioString(mode.width, mode.height) + ")")
		Next
		
		' Create window
		game.SetVideoMode(Int(Self.ini.Get("Graphics", "Width")), Int(Self.ini.Get("Graphics", "Height")), Int(Self.ini.Get("Graphics", "Fullscreen")), Self.ini.Get("Graphics", "Driver"))
		
		' Seed
		SeedRnd MilliSecs()
		
		' Try to enable OpenAL
		Local canUseOpenAL:Int = OpenALInstalled()
		game.logger.Write("OpenAL installed: " + BoolToYesNo(canUseOpenAL))
		If canUseOpenAL
			EnableOpenALAudio()
		EndIf
		
		' Audio drivers
		Local audDrivers:String[] = AudioDrivers()
		game.logger.Write("Audio drivers:")
		For Local audDriver:String = EachIn audDrivers
			game.logger.Write(" * " + audDriver)
		Next
		
		' Init audio driver
		If AudioDriverExists(game.audioDriver)
			game.logger.Write("Init audio driver '" + game.audioDriver + "'")
			SetAudioDriver game.audioDriver
		Else
			game.logger.Write("Audio driver '" + game.audioDriver + "' does not exist")
		EndIf
		
		' Audio channels
		game.soundMgr.AddChannel("Effects")
		
		' Input
		EnablePolledInput()
		
		' Network adapter
		Local adapterInfo:TAdapterInfo
		game.logger.Write("Network adapter information:")
		If TNetwork.GetAdapterInfo(adapterInfo) = 0 Then
			game.logger.Write("Failed to get network adapter information.")
			game.logger.Write("Maybe there is no network adapter or no network driver installed.")
		Else
			game.logger.Write("Device: " + adapterInfo.Device)
			game.logger.Write(" * MAC Address:       " + TNetwork.StringMAC(adapterInfo.MAC))
			game.logger.Write(" * IP Address:        " + TNetwork.StringIP(adapterInfo.Address))
			game.logger.Write(" * Broadcast Address: " + TNetwork.StringIP(adapterInfo.Broadcast))
			game.logger.Write(" * Netmask:           " + TNetwork.StringIP(adapterInfo.Netmask))
		EndIf
		
		' Network settings
		game.receiveTimeout = Int(Self.ini.Get("Network", "ReceiveTimeout"))
		game.sendTimeout = Int(Self.ini.Get("Network", "SendTimeout"))
		game.acceptTimeout = Int(Self.ini.Get("Network", "AcceptTimeout"))
		game.networkThreadDelay = Int(Self.ini.Get("Network", "ThreadDelay"))
		
		' Joysticks
		Local joyCountVal:Int = JoyCount()
		If joyCountVal <> TInputSystem.countGamePads
			TInputSystem.countGamePads = joyCountVal
			game.logger.Write("Number of gamepads: " + TInputSystem.countGamePads)
			If TInputSystem.countGamePads > 0
				game.logger.Write(TLog.separator)
				For Local i:Int = 0 Until TInputSystem.countGamePads
					game.logger.Write("GamePad [" + (i + 1) +"]:")
					game.logger.Write(" * Name:       " + JoyName(i))
					game.logger.Write(" * AxisCaps:   " + Bin(JoyAxisCaps(i)))
					game.logger.Write(" * ButtonCaps: " + Bin(JoyButtonCaps(i)))
					game.logger.Write(" * X:          " + JoyX(i))
					game.logger.Write(" * Y:          " + JoyY(i))
					game.logger.Write(TLog.separator)
				Next
			EndIf
		EndIf
		
		' System info
		?Win32
			game.logger.Write("OS version: " + GetOSVersion())
			game.logger.Write("Number of processors: " + GetProcessorCount())
			game.logger.Write("Processor architecture: " + GetProcessorArchitecture())
		?
		
		' Hide mouse
		HideMouse
	End Method
	
	' Update
	Method Update()
		
	End Method
	
	' Remove
	Method Remove()
		
	End Method
	
	' OnAppSuspended
	Method OnAppSuspended()
		
	End Method
	
	' OnAppReactivated
	Method OnAppReactivated()
		
	End Method
	
	' LoadConfiguration
	Method LoadConfiguration(file:String)
		' Read config file
		Self.ini = TINI.Create(file)
		Self.ini.Load()
		
		' Size of the window
		game.vsync = Int(Self.ini.Get("Graphics", "VSync"))
		game.audioDriver = Self.ini.Get("Audio", "Driver")
	End Method
	
	' ToString
	Method ToString:String()
		Return "Init"
	End Method
	
	' Create
	Function Create:TGameStateInit(gameRef:TGame)
		Local gs:TGameStateInit = New TGameStateInit
		gameRef.RegisterGameState("Init", gs)
		Return gs
	End Function
End Type
