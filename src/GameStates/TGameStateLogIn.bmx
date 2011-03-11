' Strict
SuperStrict

' Modules
Import BRL.Max2D

' Files
Import "../TGame.bmx"
Import "../TFrameRate.bmx"
Import "../GUI/TGUI.bmx"
Import "../Utilities/MD5.bmx"
Import "TGameStateMenu.bmx"

' Global
Global gsLogIn:TGameStateLogIn

' TGameStateLogIn
Type TGameStateLogIn Extends TGameState	
	' FPS
	Field frameCounter:TFrameRate
	
	' GUI
	Field gui:TGUI
	Field guiFont:TImageFont
	Field menuContainer:TWidget
	
	Field nameField:TTextField
	Field pwField:TTextField
	Field loginButton:TButton
	Field registerButton:TButton
	Field loginThread:TThread
	
	' Init
	Method Init()
		' Frame counter
		Self.frameCounter = TFrameRate.Create()
		
		' Resources
		Self.InitResources()
		
		' GUI
		game.logger.Write("Initializing GUI")
		Self.InitGUI()
		
		Self.loginThread = Null
		
		' Temporarily
		'Self.nameField.SetText("a")
		'Self.pwField.SetText("a")
		'TGameStateLogIn.LoginFunc(Null)
	End Method
	
	' InitResources
	Method InitResources()
		' Load fonts
		game.fontMgr.AddResourcesFromDirectory(FS_ROOT + "data/fonts/")
		
		' Load images
		game.imageMgr.SetFlags(FILTEREDIMAGE)
		game.imageMgr.AddResourcesFromDirectory(FS_ROOT + "data/menu/")
		
		Self.guiFont = game.fontMgr.Get("MenuFont")
	End Method
	
	' InitGUI
	Method InitGUI()
		Self.gui = TGUI.Create()
		
		Local bg:TImageBox = TImageBox.Create("menuBG", game.imageMgr.Get("login-background"))
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
		Self.menuContainer = TWindow.Create("menuContainer", "Login")
		Self.menuContainer.SetPosition(0.5, 0.5)
		Self.menuContainer.SetSizeAbs(250, 151)
		Self.menuContainer.SetPadding(5, 5, 5, 5)
		Self.menuContainer.UseCurrentAreaAsClientArea()
		Self.menuContainer.SetPositionAbs(-Self.menuContainer.GetWidth() / 2, -Self.menuContainer.GetHeight() / 2)
		Self.gui.Add(Self.menuContainer)
		
		Self.nameField = TTextField.Create("nameField", "", 0, 16)
		Self.nameField.SetSizeAbs(0, 24)
		Self.nameField.SetSize(1.0, 0)
		Self.menuContainer.Add(Self.nameField)
		
		Self.pwField = TTextField.Create("pwField", "", 0, 58)
		Self.pwField.SetDisplayCharacter("*")
		Self.pwField.SetSizeAbs(0, 24)
		Self.pwField.SetSize(1.0, 0)
		Self.menuContainer.Add(Self.pwField)
		
		Self.menuContainer.Add(TLabel.Create("nameLabel", "Name:"))
		Self.menuContainer.Add(TLabel.Create("pwLabel", "Password:", 0, 42))
		
		Self.loginButton:TButton = TButton.Create("loginButton", "Login")
		Self.loginButton.SetSize(0.45, 0)
		Self.loginButton.SetSizeAbs(0, 24)
		Self.loginButton.SetPosition(0.025, 0)
		Self.loginButton.SetPositionAbs(0, 87)
		Self.loginButton.onClick = TGameStateLogIn.LoginFunc
		Self.menuContainer.Add(Self.loginButton)
		
		Self.registerButton:TButton = TButton.Create("registerButton", "Create account")
		Self.registerButton.SetSize(0.45, 0)
		Self.registerButton.SetSizeAbs(0, 24)
		Self.registerButton.SetPosition(0.525, 0)
		Self.registerButton.SetPositionAbs(0, 87)
		Self.registerButton.onClick = TGameStateLogIn.RegisterFunc
		Self.menuContainer.Add(Self.registerButton)
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
		
		' Swap buffers
		Flip game.vsync
		
		' Quit
		If TInputSystem.GetKeyHit(KEY_ESCAPE)
			game.SetGameState(Null)
		EndIf
		
		If game.accountID > 0
			game.SetGameStateByName("Menu")
		EndIf
	End Method
		
	' Remove
	Method Remove()
		game.logger.Write("Average FPS was: " + Int(Self.frameCounter.GetAverageFPS()))
	End Method
	
	' OnAppSuspended
	Method OnAppSuspended()
		
	End Method
	
	' OnAppReactivated
	Method OnAppReactivated()
		
	End Method
	
	' ToString
	Method ToString:String()
		Return "LogIn"
	End Method
	
	' LoginFunc
	Function LoginFunc(widget:TWidget)
		Local loginInfo:String[] = New String[2]
		loginInfo[0] = gsLogIn.nameField.GetText()
		loginInfo[1] = MD5(MD5(gsLogIn.pwField.GetText()))
		
		gsLogIn.loginThread = CreateThread(TGameStateLogIn.LoginThreadFunc, loginInfo)
	End Function
	
	' LoginThreadFunc
	Function LoginThreadFunc:Object(obj:Object)
		Local loginInfo:String[] = String[](obj)
		Local accName:String = loginInfo[0]
		Local pw:String = loginInfo[1]
		Print pw
		
		' Account
		Local loginStream:TStream = ReadStream(HOST_ROOT + "lyphia/user/login.php?login=" + accName + "&password=" + pw)
		
		Local result:Int = Int(loginStream.ReadLine())
		Local playerName:String = loginStream.ReadLine()
		
		If result > 0
			game.accountInfo.Insert("name", playerName)
			game.accountID = result
		EndIf
	End Function
	
	' RegisterFunc
	Function RegisterFunc(widget:TWidget)
		Print "Register."
	End Function
	
	' Create
	Function Create:TGameStateLogIn(gameRef:TGame)
		Local gs:TGameStateLogIn = New TGameStateLogIn
		gameRef.RegisterGameState("LogIn", gs)
		Return gs
	End Function
End Type
