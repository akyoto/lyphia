' Strict
SuperStrict

' Modules
Import BRL.Max2D

' Files
Import "../TGame.bmx"
Import "../TFrameRate.bmx"
Import "../GUI/TGUI.bmx"
Import "TGameStateInGame.bmx"

' Global
Global gsMenu:TGameStateMenu

' TGameStateMenu
Type TGameStateMenu Extends TGameState	
	' FPS
	Field frameCounter:TFrameRate
		
	' GUI
	Field gui:TGUI
	Field guiFont:TImageFont
	Field playerStatsFont:TImageFont
	Field playerStatsNameFont:TImageFont
	Field menuContainer:TWidget
	
	' Init
	Method Init()
		' Frame counter
		Self.frameCounter = TFrameRate.Create()
		
		' Resources
		Self.InitResources()
		
		' GUI
		game.logger.Write("Initializing GUI")
		Self.InitGUI()
		
		' Reset InGame network state
		gsInGame.inNetworkMode = False
		
		' Fetch player info
		CreateThread(TGameStateMenu.GetPlayerInfoThreadFunc, Null)
	End Method
	
	' InitResources
	Method InitResources()
		' Load fonts
		game.fontMgr.AddResourcesFromDirectory(FS_ROOT + "data/fonts/")
		
		' Load images
		game.imageMgr.SetFlags(FILTEREDIMAGE)
		game.imageMgr.AddResourcesFromDirectory(FS_ROOT + "data/menu/")
		
		Self.guiFont = game.fontMgr.Get("MenuFont")
		Self.playerStatsFont = game.fontMgr.Get("PlayerStatsFont")
		Self.playerStatsNameFont = game.fontMgr.Get("PlayerStatsNameFont")
	End Method
	
	' InitGUI
	Method InitGUI()
		Self.gui = TGUI.Create()
		
		Local bg:TImageBox = TImageBox.Create("menuBG", game.imageMgr.Get("menu-background"))
		bg.SetSize(1.0, 1.0)
		Self.gui.Add(bg)
		
		Self.InitMenuGUI()
		
		' Cursors
		Self.gui.SetCursor("default")
		HideMouse()
		
		' Apply font to all widgets
		Self.gui.SetFont(Self.guiFont)
	End Method
	
	' InitMenuGUI
	Method InitMenuGUI()
		' Main container
		Self.menuContainer = TWindow.Create("menuContainer", "Main menu")
		Self.menuContainer.SetPosition(0.5, 0.5)
		Self.menuContainer.SetSizeAbs(180, 200)
		Self.menuContainer.SetPadding(5, 5, 5, 5)
		Self.menuContainer.UseCurrentAreaAsClientArea()
		Self.menuContainer.SetPositionAbs(-Self.menuContainer.GetWidth() / 2, -Self.menuContainer.GetHeight() / 2)
		Self.gui.Add(Self.menuContainer)
		
		Local gameState:String[] = ["InGame", "Arena", "Editor", "Exit"]
		Local button:TButton
		For Local I:Int = 0 To 3
			button = TButton.Create(gameState[I], gameState[I])
			button.onClick = TGameStateMenu.StartFunc
			Self.menuContainer.Add(button)
		Next
		
		Self.menuContainer.ApplyLayoutTable(4, 1)
	End Method
	
	' Update
	Method Update()
		' Update input system
		TInputSystem.Update()
		
		' Update frame rate
		Self.frameCounter.Update()
		
		' GUI update
		Self.gui.Update()
		
		' Clear screen
		Cls
		
		' GUI
		Self.gui.Draw()
		
		' Account info
		SetImageFont Self.playerStatsNameFont
		DrawText String(game.accountInfo.ValueForKey("name")), 15, 15
		
		SetImageFont Self.playerStatsFont
		DrawText "Points:", 25, 55
		DrawText "Kills:", 25, 75
		DrawText "Wins:", 25, 95
		DrawText "Loses:", 25, 115
		
		DrawText String(game.accountInfo.ValueForKey("points")), 105, 55
		DrawText String(game.accountInfo.ValueForKey("kills")), 105, 75
		DrawText String(game.accountInfo.ValueForKey("wins")), 105, 95
		DrawText String(game.accountInfo.ValueForKey("loses")), 105, 115
		
		' Swap buffers
		Flip game.vsync
		
		' Quit
		If TInputSystem.GetKeyHit(KEY_ESCAPE)
			game.accountID = 0
			game.accountInfo = CreateMap()
			game.SetGameStateByName("LogIn")
		EndIf
	End Method
		
	' Remove
	Method Remove()
		game.logger.Write("Average FPS was: " + Int(Self.frameCounter.GetAverageFPS()))
	End Method
	
	' GetPlayerInfoThreadFunc
	Function GetPlayerInfoThreadFunc:Object(obj:Object)
		' Account
		Local infoStream:TStream = ReadStream(HOST_ROOT + "lyphia/user/info.php?id=" + game.accountID)
		If infoStream.ReadLine() <> "-1"
			game.accountInfo.Insert("points", infoStream.ReadLine())
			game.accountInfo.Insert("kills", infoStream.ReadLine())
			game.accountInfo.Insert("wins", infoStream.ReadLine())
			game.accountInfo.Insert("loses", infoStream.ReadLine())
		Else
			' TODO: Error msg
			game.logger.Write("Failed fetching account stats")
			Return Null
		EndIf
	End Function
	
	' OnAppSuspended
	Method OnAppSuspended()
		
	End Method
	
	' OnAppReactivated
	Method OnAppReactivated()
		
	End Method
	
	' ToString
	Method ToString:String()
		Return "Menu"
	End Method
		
	' StartFunc
	Function StartFunc(widget:TWidget)
		game.SetGameStateByName(widget.GetID())
	End Function
	
	' Create
	Function Create:TGameStateMenu(gameRef:TGame)
		Local gs:TGameStateMenu = New TGameStateMenu
		gameRef.RegisterGameState("Menu", gs)
		Return gs
	End Function
End Type
