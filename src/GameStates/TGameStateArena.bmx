' Strict
SuperStrict

' Modules
Import BRL.Max2D

' Files
Import "../TGame.bmx"
Import "../TFrameRate.bmx"
Import "../GUI/TGUI.bmx"
Import "../Multiplayer/TServer.bmx"
Import "../Multiplayer/TRoom.bmx"
Import "../GameStates/TGameStateInGame.bmx"

' Global
Global gsArena:TGameStateArena

' TGameStateArena
Type TGameStateArena Extends TGameState
	Const SERVER_PORT:Short = 1310
	'Const CLIENT_PORT:Short = 1310
	
	Field loggerServer:TLog
	Field loggerClient:TLog
	
	' FPS
	Field frameCounter:TFrameRate
	
	' Networking
	Field room:TRoom
	Field server:TServer
	
	' GUI
	Field gui:TGUI
	Field guiFont:TImageFont
	Field guiMutex:TMutex
	Field menuContainer:TWidget
	Field roomList:TTextField
	Field charList:TListBox
	Field joinButton:TButton
	Field hostButton:TButton
	Field roomContainer:TWidget
	Field charContainer:TWidget
	Field nameField:TTextField
	Field chatField:TTextField
	Field msgList:TListBox
	Field clientList:TListBox[2]
	Field teamChange:TButton[2]
	Field roomOptions:TGroup
	Field modeList:TListBox
	Field arenaModeIndex:Byte
	
	Field arenaModes:TArenaMode[1]
	Field parties:TParty[2]
	Field player:TPlayer
	Field nickName:String
	Field startGame:Int
	
	' Init
	Method Init()
		' Frame counter
		Self.frameCounter = TFrameRate.Create()
		
		' Resources
		Self.InitResources()
		
		' Parties
		If Self.parties[0] = Null
			For Local I:Int = 0 Until 2
				Self.parties[I] = TParty.Create(I, "Team " + (I + 1))
			Next
		EndIf
		
		' GUI
		game.logger.Write("Initializing GUI")
		Self.InitGUI()
		
		' Modes
		Self.modeList.Clear()
		Self.arenaModes[0] = TDeathMatchByKills.Create(8)
		
		' Add modes
		For Local arenaMode:TArenaMode = EachIn Self.arenaModes
			arenaMode.SetParties(Self.parties)
			Self.modeList.AddItem(arenaMode.GetName())
		Next
		
		Self.parties[0].SetColor(255, 164, 0)
		Self.parties[0].SetCastColor(255, 224, 0)
		Self.parties[1].SetColor(0, 164, 255)
		Self.parties[1].SetCastColor(0, 224, 255)
		
		' Name
		Self.nickName = "Warrior_" + Rand(1000, 9999)
		
		' Msg handlers
		TServerFuncs.InitMsgHandlers()
		TClientFuncs.InitMsgHandlers()
	End Method
	
	' InitResources
	Method InitResources()
		' Load scripts
		game.scriptMgr.AddResourcesFromDirectory(FS_ROOT + "data/enemies/")
		game.scriptMgr.AddResourcesFromDirectory(FS_ROOT + "data/skills/")
		game.scriptMgr.AddResourcesFromDirectory(FS_ROOT + "data/scripts/")
		game.scriptMgr.AddResourcesFromDirectory(FS_ROOT + "data/characters/")
		
		' Load fonts
		game.fontMgr.AddResourcesFromDirectory(FS_ROOT + "data/fonts/")
		
		' Load images
		game.logger.Write("Loading skill images")
		
		game.imageMgr.SetFlags(MIPMAPPEDIMAGE | FILTEREDIMAGE)
		game.imageMgr.AddResourcesFromDirectory(FS_ROOT + "data/skills/")
		
		game.imageMgr.SetFlags(FILTEREDIMAGE)
		game.imageMgr.AddResourcesFromDirectory(FS_ROOT + "data/arena/")
		game.imageMgr.AddResourcesFromDirectory(FS_ROOT + "data/arena/modes/")
		
		Self.guiFont = game.fontMgr.Get("ArenaGUIFont")
	End Method
	
	' InitGUI
	Method InitGUI()
		If Self.guiMutex = Null
			Self.guiMutex = CreateMutex()
		EndIf
		
		Self.guiMutex.Lock()
			Self.gui = TGUI.Create()
			
			Local bg:TImageBox = TImageBox.Create("arenaBG", game.imageMgr.Get("arena-background"))
			bg.SetSize(1.0, 1.0)
			Self.gui.Add(bg)
			
			Self.InitMenuGUI()
			Self.InitCharacterGUI()
			Self.InitRoomGUI()
		
			' Cursors
			Self.gui.SetCursor("default")
			HideMouse()
			
			' Apply font to all widgets
			Self.gui.SetFont(Self.guiFont)
		Self.guiMutex.Unlock()
		
		Self.UpdateGUIState()
		Self.UpdateParties()
	End Method
	
	' InitMenuGUI
	Method InitMenuGUI()
		' Main container
		Self.menuContainer = TWindow.Create("menuContainer", "Arena")
		Self.menuContainer.SetPosition(0.5, 0.5)
		Self.menuContainer.SetSizeAbs(180, 188)
		Self.menuContainer.SetPadding(5, 5, 5, 5)
		Self.menuContainer.UseCurrentAreaAsClientArea()
		Self.menuContainer.SetPositionAbs(-Self.menuContainer.GetWidth() / 2, -Self.menuContainer.GetHeight() / 2)
		Self.gui.Add(Self.menuContainer)
		
		' Buttons
		Self.menuContainer.Add(TLabel.Create("nameFieldLabel", "Your nickname:", 0, 0))
		
		Self.nameField = TTextField.Create("nameField", "", 0, 20, 0, 24)
		Self.nameField.SetSize(1.0, 0)
		Self.nameField.onEdit = TGameStateArena.SetNickNameFunc
		Self.menuContainer.Add(Self.nameField)
		
		Self.menuContainer.Add(TLabel.Create("roomListLabel", "Choose a room:", 0, 50))
		
		Self.roomList = TTextField.Create("roomList", "localhost", 0, 70, 0, 24)
		Self.roomList.SetSize(1.0, 0)
		Self.menuContainer.Add(Self.roomList)
		
		Self.joinButton = TButton.Create("joinButton", "Join room", 0, 100, 0, 24)
		Self.joinButton.SetSize(1.0, 0)
		Self.joinButton.onClick = TGameStateArena.JoinRoomFunc
		Self.menuContainer.Add(Self.joinButton)
		
		Self.hostButton = TButton.Create("hostButton", "Host room", 0, 125, 0, 24)
		Self.hostButton.SetSize(1.0, 0)
		Self.hostButton.onClick = TGameStateArena.HostRoomFunc
		Self.menuContainer.Add(Self.hostButton)
	End Method
	
	' InitCharacterGUI
	Method InitCharacterGUI()
		' Main container
		Self.charContainer = TWindow.Create("charContainer", "Character")
		Self.charContainer.SetPosition(0.5, 0.8)
		Self.charContainer.SetSizeAbs(200, 125)
		Self.charContainer.SetPadding(5, 5, 5, 5)
		Self.charContainer.UseCurrentAreaAsClientArea()
		Self.charContainer.SetPositionAbs(-Self.charContainer.GetWidth() / 2, -Self.charContainer.GetHeight() / 2)
		Self.gui.Add(Self.charContainer)
		
		' Char list
		Self.charList = TListBox.Create("charList")
		Self.charList.SetSize(1.0, 1.0)
		Self.charContainer.Add(Self.charList)
		
		Self.charList.AddItem("Kimiko")
		Self.charList.AddItem("Kyuji")
		Self.charList.AddItem("Mystic")
		Self.charList.AddItem("Yami")
		Self.charList.AddItem("Zeypher")
	End Method
	
	' InitRoomGUI
	Method InitRoomGUI()
		Const padding:Int = 0
		
		' Main container
		Self.roomContainer = TContainer.Create("roomContainer")
		Self.roomContainer.SetSize(1.0, 1.0)
		Self.roomContainer.SetPadding(padding, padding, padding, padding)
		Self.gui.Add(Self.roomContainer)
		
		' Msg list
		Self.msgList = TListBox.Create("msgList")
		Self.msgList.SetPosition(0, 0)
		Self.msgList.SetPositionAbs(0, 0)
		Self.msgList.SetSize(0.8, 0.8)
		Self.msgList.SetSizeAbs(0, -24 - padding)
		Self.roomContainer.Add(Self.msgList)
		
		' Chat field
		Self.chatField = TTextField.Create("chatField")
		Self.chatField.SetPosition(0, 0.8)
		Self.chatField.SetSize(0.8, 0)
		Self.chatField.SetPositionAbs(0, -24)
		Self.chatField.SetSizeAbs(0, 24)
		Self.chatField.onEnterKey = TGameStateArena.ClientSendChatMsgFunc
		Self.roomContainer.Add(Self.chatField)
		
		' Client lists
		For Local I:Int = 0 Until 2
			Self.clientList[I] = TListBox.Create("clientList" + I)
			Self.clientList[I].SetPosition(0.8, I * 0.4)
			Self.clientList[I].SetSize(0.2, 0.4)
			Self.clientList[I].SetPositionAbs(padding, 24 + padding)
			Self.roomContainer.Add(Self.clientList[I])
			
			Self.teamChange[I] = TButton.Create("teamChange" + I, "Team " + (I + 1))
			Self.teamChange[I].SetPosition(0.8, I * 0.4)
			Self.teamChange[I].SetSize(0.2, 0)
			Self.teamChange[I].SetPositionAbs(padding, 0)
			Self.teamChange[I].SetSizeAbs(-padding, 24)
			Self.teamChange[I].onClick = TGameStateArena.ChangePartyFunc
			Self.roomContainer.Add(Self.teamChange[I])
		Next
		
		Self.clientList[0].SetSizeAbs(-padding, -padding - 24 - padding)
		Self.clientList[0].SetColor(255, 224, 192)
		
		Self.clientList[1].SetSizeAbs(-padding, -24 - padding)
		Self.clientList[1].SetColor(192, 224, 255)
		
		' Room options
		Self.roomOptions = TGroup.Create("roomOptions")
		Self.roomOptions.SetPosition(0, 0.8)
		Self.roomOptions.SetSize(1.0, 0.2)
		Self.roomOptions.SetPositionAbs(0, padding)
		Self.roomOptions.SetSizeAbs(0, -padding)
		Self.roomContainer.Add(Self.roomOptions)
		
		' Mode list
		Self.modeList = TListBox.Create("modeList")
		Self.modeList.SetPosition(0.05, 0.25)
		Self.modeList.SetSize(0.25, 0.5)
		Self.modeList.onItemChange = TGameStateArena.ChangeArenaModeFunc
		Self.roomOptions.Add(Self.modeList)
		
		' Go
		Local goButton:TButton = TButton.Create("goButton", "Start")
		goButton.SetPosition(0.75, 0.25)
		goButton.SetSize(0.20, 0.5)
		goButton.onClick = TGameStateArena.StartFunc
		Self.roomOptions.Add(goButton)
		
		' Hide room container
		Self.roomContainer.SetVisible(False)
	End Method
	
	' UpdateParties
	Method UpdateParties()
		Self.guiMutex.Lock()
			For Local I:Int = 0 Until 2
				Self.clientList[I].Clear()
				For Local member:TEntity = EachIn Self.parties[I].GetMembersList()
					Self.clientList[I].AddItem member.GetName()
				Next
			Next
		Self.guiMutex.UnLock()
	End Method
	
	' Update
	Method Update()
		' Update input system
		TInputSystem.Update()
		
		' Update frame rate
		Self.frameCounter.Update()
		
		' Always select the same item
		Self.modeList.SelectItem(Self.arenaModeIndex)
		
		' GUI update
		Self.guiMutex.Lock()
			Self.gui.Update()
		Self.guiMutex.Unlock()
		
		' Server
		If Self.server <> Null
			Self.server.Update()
		EndIf
		
		' Clear screen
		Cls
		
		' GUI
		Self.guiMutex.Lock()
			Self.gui.Draw()
		Self.guiMutex.Unlock()
		
		' Swap buffers
		Flip game.vsync
		
		' Change to GS InGame
		If Self.startGame = True
			Self.StartNetworkMode()
		EndIf
		
		' Quit
		If TInputSystem.GetKeyHit(KEY_ESCAPE)
			If Self.server = Null And Self.room = Null
				game.SetGameStateByName("Menu")
			Else
				TGameStateArena.LeaveRoomFunc(Null)
			EndIf
		EndIf
	End Method
	
	' UpdateGUIState
	Method UpdateGUIState()
		Self.guiMutex.Lock()
			If Self.server <> Null Or Self.room <> Null
				Self.menuContainer.SetVisible(False)
				Self.charContainer.SetVisible(False)
				Self.roomContainer.SetVisible(True)
				Self.gui.SetAlpha(0.75)
			Else
				Self.menuContainer.SetVisible(True)
				Self.charContainer.SetVisible(True)
				Self.roomContainer.SetVisible(False)
				Self.gui.SetAlpha(1.0)
			EndIf
		Self.guiMutex.Unlock()
	End Method
	
	' JoinRoom
	Method JoinRoom(nName:String)
		' TODO: Use room name
		Try
			Local host:String = nName
			Local port:Short = TGameStateArena.SERVER_PORT
			Local characterName:String
			
			' Server log
			If Self.loggerClient = Null
				?Debug
					Self.loggerClient = TLog.Create(StandardIOStream)
				?Not Debug
					Self.loggerClient = TLog.Create(WriteFile(FS_ROOT + "logs/client.txt"))
				?
				
				Self.loggerClient.SetPrefix("[CLIENT] ")
			EndIf
			
			Self.loggerClient.Write("Connecting to '" + host + "' at port " + port + " (room '" + nName + "')")
			Self.room = TRoom.Create(host, port)
			Self.loggerClient.Write("Successfully connected.")
			
			characterName = Self.charList.GetText()
			If characterName = ""
				characterName = Self.charList.GetItemText(0)
			EndIf
			
			' Clear parties
			For Local I:Int = 0 Until 2
				Self.parties[I].Clear()
			Next
			Self.UpdateParties()
			
			Self.room.streamMutex.Lock()
				Self.room.stream.WriteByte(1)
				Self.room.stream.WriteLine(characterName)
				Self.room.stream.WriteLine(Self.nickName)
			Self.room.streamMutex.Unlock()
		Catch exception:Object
			game.logger.Write("Runtime error: " + exception.ToString())
		End Try
	End Method
	
	' HostRoom
	Method HostRoom(nName:String)
		' TODO: Use room name
		Try
			' Server log
			If Self.loggerServer = Null
				?Debug
					Self.loggerServer = TLog.Create(StandardIOStream)
				?Not Debug
					Self.loggerServer = TLog.Create(WriteFile(FS_ROOT + "logs/server.txt"))
				?
				
				Self.loggerServer.SetPrefix("[SERVER] ")
			EndIf
			
			Self.loggerServer.Write("Initializing server at port " + TGameStateArena.SERVER_PORT + " for room '" + nName + "'")
			Self.server = TServer.Create(TGameStateArena.SERVER_PORT, Self.loggerServer)
			Self.loggerServer.Write("Server successfully initialized.")
			
			' Clear parties
			For Local I:Int = 0 Until 2
				Self.parties[I].Clear()
			Next
		Catch exception:Object
			Self.loggerServer.Write("Runtime error: " + exception.ToString())
		End Try
	End Method
	
	' LeaveRoom
	Method LeaveRoom()
		If Self.room <> Null
			Self.room.Disconnect()
			Self.room = Null
			
			Self.guiMutex.Lock()
				Self.msgList.Clear()
			Self.guiMutex.Unlock()
		EndIf
		
		If Self.server <> Null
			Self.server.Remove()
			Self.server = Null
		EndIf
		
		' Clear parties
		For Local I:Int = 0 Until 2
			Self.parties[I].Clear()
		Next
		
		Self.UpdateParties()
	End Method
	
	' Remove
	Method Remove()
		If gsInGame.inNetworkMode = False
			Self.LeaveRoom()
		EndIf
		
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
		Return "Arena"
	End Method
	
	' StartNetworkMode
	Method StartNetworkMode()
		Self.startGame = False
		gsInGame.InitNetworkMode(gsArena.player, gsArena.parties, gsArena.room, gsArena.server, gsArena.gui, gsArena.arenaModes[gsArena.arenaModeIndex])
		game.SetGameStateByName("InGame")
	End Method
	
	' JoinRoomFunc
	Function JoinRoomFunc(widget:TWidget)
		gsArena.JoinRoom(gsArena.roomList.GetText())
		gsArena.UpdateGUIState()
	End Function
	
	' HostRoomFunc
	Function HostRoomFunc(widget:TWidget)
		gsArena.HostRoom(gsArena.roomList.GetText())
		gsArena.JoinRoom("127.0.0.1")
		gsArena.UpdateGUIState()
	End Function
	
	' LeaveRoomFunc
	Function LeaveRoomFunc(widget:TWidget)
		gsArena.LeaveRoom()
		gsArena.UpdateGUIState()
	End Function
	
	' SetNickNameFunc
	Function SetNickNameFunc(widget:TWidget)
		gsArena.nickName = widget.GetText()
	End Function
	
	' ClientSendChatMsgFunc
	Function ClientSendChatMsgFunc(widget:TWidget)
		If widget.GetText().length > 0
			If gsArena.room <> Null
				gsArena.room.streamMutex.Lock()
					gsArena.room.stream.WriteByte(20)
					gsArena.room.stream.WriteLine(widget.GetText())
				gsArena.room.streamMutex.Unlock()
			EndIf
			widget.SetText("")
		EndIf
	End Function
	
	' ChangePartyFunc
	Function ChangePartyFunc(widget:TWidget)
		If gsArena.room <> Null
			For Local I:Int = 0 Until 2
				If gsArena.teamChange[I] = widget
					If gsArena.parties[I].Contains(gsArena.player) = False
						gsArena.room.streamMutex.Lock()
							gsArena.room.stream.WriteByte(4)
							gsArena.room.stream.WriteByte(I)
						gsArena.room.streamMutex.Unlock()
					EndIf
					Return
				EndIf
			Next
		EndIf
	End Function
	
	' ChangeArenaModeFunc
	Function ChangeArenaModeFunc(widget:TWidget)
		If gsArena.server <> Null
			Local mode:Int = gsArena.modeList.GetSelectedItem()
			
			If mode >= 0 And mode <> gsArena.arenaModeIndex
				gsArena.room.streamMutex.Lock()
					gsArena.room.stream.WriteByte(5)
					gsArena.room.stream.WriteByte(mode)
				gsArena.room.streamMutex.Unlock()
			EndIf
		EndIf
	End Function
	
	' StartFunc
	Function StartFunc(widget:TWidget)
		If gsArena.server <> Null
			gsArena.room.streamMutex.Lock()
				gsArena.room.stream.WriteByte(255)
			gsArena.room.streamMutex.Unlock()
		EndIf
	End Function
	
	' Create
	Function Create:TGameStateArena(gameRef:TGame)
		Local gs:TGameStateArena = New TGameStateArena
		gameRef.RegisterGameState("Arena", gs)
		Return gs
	End Function
End Type

' TServerFuncs
Type TServerFuncs
	' InitMsgHandlers
	Function InitMsgHandlers()
		TServerMsgHandler.clientDisconnectFunc = TServerFuncs.ClientDisconnected
		TServerMsgHandler.SetFunction(1, TServerFuncs.ClientJoined)
		TServerMsgHandler.SetFunction(4, TServerFuncs.ChangeParty)
		TServerMsgHandler.SetFunction(5, TServerFuncs.ChangeArenaMode)
		TServerMsgHandler.SetFunction(20, TServerFuncs.ChatMsg)
		TServerMsgHandler.SetFunction(100, TServerFuncs.MovePlayer)
		TServerMsgHandler.SetFunction(101, TServerFuncs.LockPlayerDirection)
		TServerMsgHandler.SetFunction(110, TServerFuncs.StartSkillCast)
		TServerMsgHandler.SetFunction(111, TServerFuncs.EndSkillCast)
		TServerMsgHandler.SetFunction(230, TServerFuncs.PingCheck)
		'TServerMsgHandler.SetFunction(254, TServerFuncs.EndGame)		' This is done in GSInGame.UpdateArena()
		TServerMsgHandler.SetFunction(255, TServerFuncs.StartGame)
	End Function
	
	' ClientJoined
	Function ClientJoined(client:TLyphiaClient)
		Local characterName:String = client.stream.ReadLine()
		Local name:String = client.stream.ReadLine()
		Local team:Byte = (gsArena.parties[0].GetNumberOfMembers() + gsArena.parties[1].GetNumberOfMembers()) Mod 2
		
		client.player = TPlayer.Create(characterName)
		client.player.SetName(name)
		gsArena.parties[team].Add(client.player)
		If name = gsArena.nickName
			gsArena.player = client.player
		EndIf
		
		' Notify other players
		client.server.clientListMutex.Lock()
			For Local bcClient:TLyphiaClient = EachIn client.server.clientList
				' Inform existing clients about {Code + Player ID + Team number + Player name + Character} of the new player
				bcClient.streamMutex.Lock()
					bcClient.stream.WriteByte(1)
					bcClient.stream.WriteByte(client.player.GetID())
					bcClient.stream.WriteByte(team)
					bcClient.stream.WriteLine(name)
					bcClient.stream.WriteLine(characterName)
				bcClient.streamMutex.Unlock()
				
				' Tell the new player about the other clients who already joined the room
				If bcClient <> client
					client.streamMutex.Lock()
						client.stream.WriteByte(3)
						client.stream.WriteByte(bcClient.player.GetID())
						client.stream.WriteByte(bcClient.player.GetParty() = gsArena.parties[1])
						client.stream.WriteLine(bcClient.player.GetName())
						client.stream.WriteLine(bcClient.player.GetCharacterName())
					client.streamMutex.Unlock()
				EndIf
			Next
		client.server.clientListMutex.Unlock()
	End Function
	
	' ClientDisconnected
	Function ClientDisconnected(client:TLyphiaClient)
		' Notify other players
		client.server.clientListMutex.Lock()
			For Local bcClient:TLyphiaClient = EachIn client.server.clientList
				' Code + Team number + Player name
				bcClient.streamMutex.Lock()
					bcClient.stream.WriteByte(2)
					bcClient.stream.WriteByte(client.player.GetID())
					bcClient.stream.WriteByte(client.player.GetParty() = gsArena.parties[1])
					bcClient.stream.WriteLine(client.player.GetName())
				bcClient.streamMutex.Unlock()
			Next
		client.server.clientListMutex.Unlock()
	End Function
	
	' ChangeParty
	Function ChangeParty(client:TLyphiaClient)
		Local team:Byte = client.stream.ReadByte()
		
		' Notify other players
		client.server.clientListMutex.Lock()
			For Local bcClient:TLyphiaClient = EachIn client.server.clientList
				bcClient.streamMutex.Lock()
					bcClient.stream.WriteByte(4)
					bcClient.stream.WriteByte(client.player.GetID())
					bcClient.stream.WriteByte(team)
				bcClient.streamMutex.Unlock()
			Next
		client.server.clientListMutex.Unlock()
	End Function
	
	' ChangeArenaMode
	Function ChangeArenaMode(client:TLyphiaClient)
		Local mode:Byte = client.stream.ReadByte()
		
		' Notify other players
		client.server.clientListMutex.Lock()
			For Local bcClient:TLyphiaClient = EachIn client.server.clientList
				bcClient.streamMutex.Lock()
					bcClient.stream.WriteByte(5)
					bcClient.stream.WriteLine(mode)
				bcClient.streamMutex.Unlock()
			Next
		client.server.clientListMutex.Unlock()
	End Function
	
	' ChatMsg
	Function ChatMsg(client:TLyphiaClient)
		Local msg:String = client.stream.ReadLine()
		
		gsArena.loggerServer.Write("<" + client.player.GetName() + "> " + msg)
		
		' Notify other players
		client.server.clientListMutex.Lock()
			For Local bcClient:TLyphiaClient = EachIn client.server.clientList
				bcClient.streamMutex.Lock()
					bcClient.stream.WriteByte(20)
					bcClient.stream.WriteByte(client.player.GetID())
					bcClient.stream.WriteLine(msg)
				bcClient.streamMutex.Unlock()
			Next
		client.server.clientListMutex.Unlock()
	End Function
	
	' MovePlayer
	Function MovePlayer(client:TLyphiaClient)
		Local netMoveX:Byte = client.stream.ReadByte()
		Local netMoveY:Byte = client.stream.ReadByte()
		Local posX:Float = client.stream.ReadFloat()
		Local posY:Float = client.stream.ReadFloat()
		
		client.server.clientListMutex.Lock()
			For Local bcClient:TLyphiaClient = EachIn client.server.clientList
				If bcClient <> client
					bcClient.streamMutex.Lock()
						bcClient.stream.WriteByte(100)
						bcClient.stream.WriteByte(client.player.GetID())
						bcClient.stream.WriteByte(netMoveX)
						bcClient.stream.WriteByte(netMoveY)
						bcClient.stream.WriteFloat(posX)
						bcClient.stream.WriteFloat(posY)
					bcClient.streamMutex.Unlock()
				EndIf
			Next
		client.server.clientListMutex.Unlock()
		
		Rem
		Local walkX:Float = client.stream.ReadFloat()
		Local walkY:Float = client.stream.ReadFloat()
		
		' Notify other players
		client.server.clientListMutex.Lock()
			For Local bcClient:TLyphiaClient = EachIn client.server.clientList
				bcClient.streamMutex.Lock()
					bcClient.stream.WriteByte(100)
					' TODO: Check for possible errors
					bcClient.stream.WriteByte(client.player.GetID())
					bcClient.stream.WriteFloat(walkX)
					bcClient.stream.WriteFloat(walkY)
				bcClient.streamMutex.Unlock()
			Next
		client.server.clientListMutex.Unlock()
		End Rem
	End Function
	
	' LockPlayerDirection
	Function LockPlayerDirection(client:TLyphiaClient)
		Local direction:Byte = client.stream.ReadByte()
		
		client.server.clientListMutex.Lock()
			For Local bcClient:TLyphiaClient = EachIn client.server.clientList
				If bcClient <> client
					bcClient.streamMutex.Lock()
						bcClient.stream.WriteByte(101)
						bcClient.stream.WriteByte(client.player.GetID())
						bcClient.stream.WriteByte(direction)
					bcClient.streamMutex.Unlock()
				EndIf
			Next
		client.server.clientListMutex.Unlock()
	End Function
	
	' StartSkillCast
	Function StartSkillCast(client:TLyphiaClient)
		Local slotID:Byte = client.stream.ReadByte()
		
		client.server.clientListMutex.Lock()
			For Local bcClient:TLyphiaClient = EachIn client.server.clientList
				bcClient.streamMutex.Lock()
					bcClient.stream.WriteByte(110)
					bcClient.stream.WriteByte(client.player.GetID())
					bcClient.stream.WriteByte(slotID)
				bcClient.streamMutex.Unlock()
			Next
		client.server.clientListMutex.Unlock()
		
		gsArena.loggerServer.Write("Skill #" + slotID + " has been started by " + client.player.GetName())
	End Function
	
	' EndSkillCast
	Function EndSkillCast(client:TLyphiaClient)
		Local advances:Byte = client.stream.ReadByte()
		
		client.server.clientListMutex.Lock()
			For Local bcClient:TLyphiaClient = EachIn client.server.clientList
				bcClient.streamMutex.Lock()
					bcClient.stream.WriteByte(111)
					bcClient.stream.WriteByte(client.player.GetID())
					bcClient.stream.WriteByte(advances)
				bcClient.streamMutex.Unlock()
			Next
		client.server.clientListMutex.Unlock()
		
		If advances
			gsArena.loggerServer.Write("Skill has been advanced by " + client.player.GetName())
		Else
			gsArena.loggerServer.Write("Skill has not been advanced by " + client.player.GetName())
		EndIf
	End Function
	
	' PingCheck
	Function PingCheck(client:TLyphiaClient)
		client.streamMutex.Lock()
			client.stream.WriteByte(230)
		client.streamMutex.Unlock()
	End Function
	
	' StartGame
	Function StartGame(client:TLyphiaClient)
		' Notify other players
		client.server.clientListMutex.Lock()
			For Local bcClient:TLyphiaClient = EachIn client.server.clientList
				bcClient.streamMutex.Lock()
					bcClient.stream.WriteByte(255)
					bcClient.stream.WriteByte(bcClient.player.GetID())
					bcClient.stream.WriteInt(RndSeed())
					'bcClient.stream.WriteByte(client.server.clientList.length)
					'For Local bcClientTmp:TLyphiaClient = EachIn client.server.clientList
					'	bcClient.stream.WriteByte(bcClientTmp.player.GetID())
					'Next
				bcClient.streamMutex.Unlock()
			Next
		client.server.clientListMutex.Unlock()
		
		gsArena.loggerServer.Write("Game started.")
	End Function
End Type

' TClientFuncs
Type TClientFuncs
	' InitMsgHandlers
	Function InitMsgHandlers()
		TClientMsgHandler.serverDisconnectFunc = TClientFuncs.ServerDisconnected
		TClientMsgHandler.SetFunction(1, TClientFuncs.ClientJoined)
		TClientMsgHandler.SetFunction(2, TClientFuncs.ClientDisconnected)
		TClientMsgHandler.SetFunction(3, TClientFuncs.ClientList)
		TClientMsgHandler.SetFunction(4, TClientFuncs.ChangeParty)
		TClientMsgHandler.SetFunction(5, TClientFuncs.ChangeArenaMode)
		TClientMsgHandler.SetFunction(20, TClientFuncs.ChatMsg)
		TClientMsgHandler.SetFunction(30, TClientFuncs.KillPlayer)
		TClientMsgHandler.SetFunction(50, TClientFuncs.SetHP)
		TClientMsgHandler.SetFunction(100, TClientFuncs.MovePlayer)
		TClientMsgHandler.SetFunction(101, TClientFuncs.LockPlayerDirection)
		TClientMsgHandler.SetFunction(110, TClientFuncs.StartSkillCast)
		TClientMsgHandler.SetFunction(111, TClientFuncs.EndSkillCast)
		TClientMsgHandler.SetFunction(230, TClientFuncs.PingCheck)
		TClientMsgHandler.SetFunction(254, TClientFuncs.EndGame)
		TClientMsgHandler.SetFunction(255, TClientFuncs.StartGame)
	End Function
	
	' ServerDisconnected
	Function ServerDisconnected(room:TRoom)
		' TODO: Maybe a mutex is needed
		'gsArena.room.Disconnect()
		gsArena.room = Null
		gsArena.UpdateGUIState()
	End Function
	
	' ClientJoined
	Function ClientJoined(room:TRoom)
		Local playerID:Byte = room.stream.ReadByte()
		Local team:Byte = room.stream.ReadByte()
		Local name:String = room.stream.ReadLine()
		Local characterName:String = room.stream.ReadLine()
		
		If gsArena.server = Null
			Local player:TPlayer = TPlayer.Create(characterName)
			player.SetID(playerID)
			player.SetName(name)
			gsArena.parties[team].Add(player)
			If name = gsArena.nickName
				gsArena.player = player
			EndIf
		EndIf
		
		gsArena.guiMutex.Lock()
			gsArena.msgList.AddItem(name + " joined the room.")
			gsArena.msgList.ScrollToMax()
		gsArena.guiMutex.Unlock()
		
		gsArena.UpdateParties()
	End Function
	
	' ClientList
	Function ClientList(room:TRoom)
		Local playerID:Byte = room.stream.ReadByte()
		Local team:Byte = room.stream.ReadByte()
		Local name:String = room.stream.ReadLine()
		Local characterName:String = room.stream.ReadLine()
		
		Local player:TPlayer = TPlayer.Create(characterName)
		player.SetID(playerID)
		player.SetName(name)
		gsArena.parties[team].Add(player)
		
		gsArena.UpdateParties()
	End Function
	
	' ChangeParty
	Function ChangeParty(room:TRoom)
		Local playerID:Byte = room.stream.ReadByte()
		Local team:Byte = room.stream.ReadByte()
		
		Local player:TPlayer = TPlayer.players[playerID]
		
		For Local I:Int = 0 Until 256
			If TPlayer.players[I]
				Print I + " -> " + TPlayer.players[I].GetName()
			EndIf
		Next
		
		If player <> Null
			If gsArena.parties[team].Contains(player) = False
				player.SetParty(gsArena.parties[team])
				
				gsArena.guiMutex.Lock()
					gsArena.msgList.AddItem(player.GetName() + " moved to Team " + (team + 1) + ".")
					gsArena.msgList.ScrollToMax()
				gsArena.guiMutex.Unlock()
				
				gsArena.UpdateParties()
			EndIf
		EndIf
	End Function
	
	' ChangeArenaMode
	Function ChangeArenaMode(room:TRoom)
		Local mode:Byte = room.stream.ReadByte()
		
		gsArena.guiMutex.Lock()
			gsArena.arenaModeIndex = mode
		gsArena.guiMutex.Unlock()
	End Function
	
	' ChatMsg
	Function ChatMsg(room:TRoom)
		Local playerID:Byte = room.stream.ReadByte()
		Local msg:String = room.stream.ReadLine()
		
		Local nick:String = TPlayer.players[playerID].GetName()
		
		gsArena.guiMutex.Lock()
			gsArena.msgList.AddItem(nick + ": " + msg)
			gsArena.msgList.ScrollToMax()
		gsArena.guiMutex.Unlock()
	End Function
	
	' KillPlayer
	Function KillPlayer(room:TRoom)
		Local killerID:Byte = room.stream.ReadByte()
		Local killedID:Byte = room.stream.ReadByte()
		Local kills:Short = room.stream.ReadShort()
		Local deaths:Short = room.stream.ReadShort()
		
		Local killer:TPlayer = TPlayer.players[killerID]
		Local killed:TPlayer = TPlayer.players[killedID]
		
		killer.SetKillCount(kills)
		killed.SetDeathCount(deaths)
		
		Local nTileX:Int = gsInGame.map.GetStartTileX(killed.GetParty().GetID())
		Local nTileY:Int = gsInGame.map.GetStartTileY(killed.GetParty().GetID())
		killed.x = nTileX * gsInGame.map.GetTileSizeX()
		killed.y = nTileY * gsInGame.map.GetTileSizeY()
		
		If gsInGame.player = killed
			gsInGame.map.GetTileCoordsDirect(killed.GetMidX(), killed.y + killed.img.height - 5, killed.tileX, killed.tileY)
			gsInGame.tileX = killed.tileX
			gsInGame.tileY = killed.tileY
		EndIf
		
		gsArena.guiMutex.Lock()
			If killer <> Null
				gsArena.msgList.AddItem(killed.GetName() + " has been killed by " + killer.GetName() + ".")
			Else
				gsArena.msgList.AddItem(killed.GetName() + " has been killed.")
			EndIf
			gsArena.msgList.ScrollToMax()
		gsArena.guiMutex.Unlock()
		
		killed.Reset()
	End Function
	
	' SetHP
	Function SetHP(room:TRoom)
		Local playerID:Byte = room.stream.ReadByte()
		Local hp:Float = room.stream.ReadFloat()
		
		Local player:TPlayer = TPlayer.players[playerID]
		
		player.SetHP(hp)
	End Function
	
	' MovePlayer
	Function MovePlayer(room:TRoom)
		Local playerID:Byte = room.stream.ReadByte()
		Local netMoveX:Byte = room.stream.ReadByte()
		Local netMoveY:Byte = room.stream.ReadByte()
		Local posX:Float = room.stream.ReadFloat()
		Local posY:Float = room.stream.ReadFloat()
		
		Local player:TPlayer = TPlayer.players[playerID]
		
		player.SetPosition(posX, posY)
		player.SetMovement(netMoveX, netMoveY)
		
		'player.mutex.Lock()
		'	player.Walk(walkX, walkY, True, True)
		'player.mutex.Unlock()
	End Function
	
	' LockPlayerDirection
	Function LockPlayerDirection(room:TRoom)
		Local playerID:Byte = room.stream.ReadByte()
		Local direction:Byte = room.stream.ReadByte()
		
		Local player:TPlayer = TPlayer.players[playerID]
		
		player.SetDirectionLock(direction)
	End Function
	
	' StartSkillCast
	Function StartSkillCast(room:TRoom)
		Local playerID:Byte = room.stream.ReadByte()
		Local slotID:Byte = room.stream.ReadByte()
		
		Local player:TPlayer = TPlayer.players[playerID]
		Local skill:TSkill = TSkill(player.techSlots[slotID].GetAction())
		skill.Exec(Null)
		
		gsArena.loggerClient.Write(skill.GetName() + " started by " + player.GetName())
		Rem
		Local skill:TSkill
		skill = TSkill(player.techSlots[slotID].GetAction())
		
		For Local I:Int = 1 To advancement
			skill = skill.followUpSkill
		Next
		
		skill.Exec(Null)
		End Rem
	End Function
	
	' EndSkillCast
	Function EndSkillCast(room:TRoom)
		Local playerID:Byte = room.stream.ReadByte()
		Local advances:Byte = room.stream.ReadByte()
		
		Local player:TPlayer = TPlayer.players[playerID]
		
		If advances = 0
			If player.castingSkill <> Null
				player.castingSkill.Start()
				'Print player.castingSkill.GetName() " not advanced by " + player.GetName()
				gsArena.loggerClient.Write(player.castingSkill.GetName() + " ended by " + player.GetName())
			EndIf
			
			If player = gsInGame.player
				gsInGame.skillCastBar.SetVisible(False)
			EndIf
			
			player.EndCast()
		Else
			If player.castingSkill <> Null
				player.castingSkill.Advance()
				
				gsArena.loggerClient.Write(player.castingSkill.GetName() + " advanced by " + player.GetName())
			EndIf
		EndIf
	End Function
	
	' PingCheck
	Function PingCheck(room:TRoom)
		gsInGame.player.ping = MilliSecs() - gsInGame.pingSent
		
		Rem
		gsArena.guiMutex.Lock()
			gsArena.msgList.AddItem("Ping: " + gsInGame.player.ping + " ms")
			gsArena.msgList.ScrollToMax()
		gsArena.guiMutex.Unlock()
		End Rem
	End Function
	
	' EndGame
	Function EndGame(room:TRoom)
		gsArena.startGame = False
		gsInGame.returnToArena = True
		gsInGame.arenaMode.Reset()
	End Function
	
	' StartGame
	Function StartGame(room:TRoom)
		Local playerID:Byte = room.stream.ReadByte()
		Local seed:Int = room.stream.ReadInt()
		
		SeedRnd seed
		
		Rem
		For Local I:Int = 0 Until 256
			If TPlayer.players[I]
				Print I + " -> " + TPlayer.players[I].GetName()
			EndIf
		Next
		End Rem
		
		gsArena.player.SetID(playerID)
		gsArena.startGame = True
	End Function
	
	' ClientDisconnected
	Function ClientDisconnected(room:TRoom)
		Local playerID:Byte = room.stream.ReadByte()
		Local team:Byte = room.stream.ReadByte()
		Local name:String = room.stream.ReadLine()
		
		gsArena.guiMutex.Lock()
			gsArena.msgList.AddItem(name + " left the room.")
			gsArena.msgList.ScrollToMax()
			gsArena.parties[team].RemoveByName(name)
		gsArena.guiMutex.Unlock()
		
		gsArena.UpdateParties()
		
		TPlayer.players[playerID].Remove()
		
		' TODO: Mutex
		gsArena.parties[team].RemoveByName(name)
	End Function
End Type
