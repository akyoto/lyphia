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
	Field joinButton:TButton
	Field hostButton:TButton
	Field roomContainer:TWidget
	Field nameField:TTextField
	Field chatField:TTextField
	Field msgList:TListBox
	Field clientList:TListBox[2]
	Field teamChange:TButton[2]
	Field roomOptions:TGroup
	
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
		
		' GUI
		game.logger.Write("Initializing GUI")
		Self.InitGUI()
		
		' Parties
		For Local I:Int = 0 Until 2
			Self.parties[I] = TParty.Create("Team " + (I + 1))
		Next
		
		' Reset
		Self.room = Null
		Self.server = Null
		Self.player = Null
		Self.startGame = False
		
		' Name
		Self.nickName = "Warrior_" + Rand(1000, 9999)
		
		' Msg handlers
		TServerFuncs.InitMsgHandlers()
		TClientFuncs.InitMsgHandlers()
	End Method
	
	' InitResources
	Method InitResources()
		' Load fonts
		game.fontMgr.AddResourcesFromDirectory(FS_ROOT + "data/fonts/")
		
		' Load images
		game.imageMgr.SetFlags(FILTEREDIMAGE)
		game.imageMgr.AddResourcesFromDirectory(FS_ROOT + "data/arena/")
		
		Self.guiFont = game.fontMgr.Get("ArenaGUIFont")
	End Method
	
	' InitGUI
	Method InitGUI()
		Self.guiMutex = CreateMutex()
		Self.guiMutex.Lock()
			Self.gui = TGUI.Create()
			
			Local bg:TImageBox = TImageBox.Create("arenaBG", game.imageMgr.Get("arena-background"))
			bg.SetSize(1.0, 1.0)
			Self.gui.Add(bg)
			
			Self.InitMenuGUI()
			Self.InitRoomGUI()
			
			' Cursors
			Self.gui.SetCursor("default")
			HideMouse()
			
			' Apply font to all widgets
			Self.gui.SetFont(Self.guiFont)
		Self.guiMutex.Unlock()
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
		
		' Go
		Local goButton:TButton = TButton.Create("goButton", "Start")
		goButton.SetSize(1.0, 1.0)
		goButton.onClick = TGameStateArena.StartFunc
		Self.roomOptions.Add(goButton)
		
		' Hide room container
		Self.roomContainer.SetVisible(False)
	End Method
	
	' Update
	Method Update()
		' Update input system
		TInputSystem.Update()
		
		' Update frame rate
		Self.frameCounter.Update()
		
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
			Self.startGame = False
			gsInGame.InitNetworkMode(gsArena.player, gsArena.parties, gsArena.room, gsArena.server)
			game.SetGameStateByName("InGame")
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
				Self.roomContainer.SetVisible(True)
				Self.gui.SetAlpha(0.75)
			Else
				Self.menuContainer.SetVisible(True)
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
			
			game.logger.Write("Connecting to '" + host + "' at port " + port + " (room '" + nName + "')")
			Self.room = TRoom.Create(host, port)
			game.logger.Write("Successfully connected.")
			
			Self.room.streamMutex.Lock()
				Self.room.stream.WriteByte(1)
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
			EndIf
			
			Self.loggerServer.Write("Initializing server at port " + TGameStateArena.SERVER_PORT + " for room '" + nName + "'")
			Self.server = TServer.Create(TGameStateArena.SERVER_PORT, Self.loggerServer)
			Self.loggerServer.Write("Server successfully initialized.")
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
				For Local I:Int = 0 Until 2
					Self.clientList[I].Clear()
					Self.parties[I].Clear()
				Next
				Self.msgList.Clear()
			Self.guiMutex.Unlock()
		EndIf
		
		If Self.server <> Null
			Self.server.Remove()
			Self.server = Null
		EndIf
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
		TServerMsgHandler.SetFunction(20, TServerFuncs.ChatMsg)
		TServerMsgHandler.SetFunction(100, TServerFuncs.MovePlayer)
		TServerMsgHandler.SetFunction(101, TServerFuncs.LockPlayerDirection)
		TServerMsgHandler.SetFunction(110, TServerFuncs.StartSkillCast)
		TServerMsgHandler.SetFunction(255, TServerFuncs.StartGame)
	End Function
	
	' ClientJoined
	Function ClientJoined(client:TLyphiaClient)
		Local name:String = client.stream.ReadLine()
		Local team:Byte = (gsArena.parties[0].GetNumberOfMembers() + gsArena.parties[1].GetNumberOfMembers()) Mod 2
		
		client.player = TPlayer.Create("")
		client.player.SetName(name)
		gsArena.parties[team].Add(client.player)
		If name = gsArena.nickName
			gsArena.player = client.player
		EndIf
		
		' Notify other players
		client.server.clientListMutex.Lock()
			For Local bcClient:TLyphiaClient = EachIn client.server.clientList
				' Inform existing clients about {Code + Player ID + Team number + Player name} of the new player
				bcClient.streamMutex.Lock()
					bcClient.stream.WriteByte(1)
					bcClient.stream.WriteByte(client.player.GetID())
					bcClient.stream.WriteByte(team)
					bcClient.stream.WriteLine(name)
				bcClient.streamMutex.Unlock()
				
				' Tell the new player about the other clients who already joined the room
				If bcClient <> client
					client.streamMutex.Lock()
						client.stream.WriteByte(3)
						client.stream.WriteByte(bcClient.player.GetID())
						client.stream.WriteByte(bcClient.player.GetParty() = gsArena.parties[1])
						client.stream.WriteLine(bcClient.player.GetName())
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
					bcClient.stream.WriteLine(client.player.GetName())
					bcClient.stream.WriteByte(team)
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
					bcClient.stream.WriteLine(client.player.GetName())
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
	End Function
	
	' StartGame
	Function StartGame(client:TLyphiaClient)
		' Notify other players
		client.server.clientListMutex.Lock()
			For Local bcClient:TLyphiaClient = EachIn client.server.clientList
				bcClient.streamMutex.Lock()
					bcClient.stream.WriteByte(255)
					bcClient.stream.WriteByte(bcClient.player.GetID())
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
		TClientMsgHandler.SetFunction(20, TClientFuncs.ChatMsg)
		TClientMsgHandler.SetFunction(50, TClientFuncs.SetHP)
		TClientMsgHandler.SetFunction(100, TClientFuncs.MovePlayer)
		TClientMsgHandler.SetFunction(101, TClientFuncs.LockPlayerDirection)
		TClientMsgHandler.SetFunction(110, TClientFuncs.StartSkillCast)
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
		
		If gsArena.server = Null
			Local player:TPlayer = TPlayer.Create("")
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
			gsArena.clientList[team].AddItem(name)
		gsArena.guiMutex.Unlock()
	End Function
	
	' ClientList
	Function ClientList(room:TRoom)
		Local playerID:Byte = room.stream.ReadByte()
		Local team:Byte = room.stream.ReadByte()
		Local name:String = room.stream.ReadLine()
		
		Local player:TPlayer = TPlayer.Create("")
		player.SetID(playerID)
		player.SetName(name)
		gsArena.parties[team].Add(player)
		
		gsArena.guiMutex.Lock()
			gsArena.clientList[team].AddItem(name)
		gsArena.guiMutex.Unlock()
	End Function
	
	' ChangeParty
	Function ChangeParty(room:TRoom)
		Local name:String = room.stream.ReadLine()
		Local team:Byte = room.stream.ReadByte()
		Local player:TEntity
		
		For Local I:Int = 0 Until 2
			If I = team
				Continue
			EndIf
			
			player = gsArena.parties[I].GetByName(name)
			If player <> Null
				If gsArena.parties[team].Contains(player) = False
					player.SetParty(gsArena.parties[team])
					
					gsArena.guiMutex.Lock()
						gsArena.clientList[I].RemoveItemByText(name)
						gsArena.clientList[team].AddItem(name)
						gsArena.msgList.AddItem(name + " moved to Team " + (team + 1) + ".")
						gsArena.msgList.ScrollToMax()
					gsArena.guiMutex.Unlock()
				EndIf
			EndIf
		Next
	End Function
	
	' ChatMsg
	Function ChatMsg(room:TRoom)
		Local nick:String = room.stream.ReadLine()
		Local msg:String = room.stream.ReadLine()
		
		gsArena.guiMutex.Lock()
			gsArena.msgList.AddItem(nick + ": " + msg)
			gsArena.msgList.ScrollToMax()
		gsArena.guiMutex.Unlock()
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
		player.techSlots[slotID].GetAction().Exec(Null)
	End Function
	
	' StartGame
	Function StartGame(room:TRoom)
		Local playerID:Byte = room.stream.ReadByte()
		
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
			gsArena.clientList[team].RemoveItemByText(name)
			gsArena.parties[team].RemoveByName(name)
		gsArena.guiMutex.Unlock()
		
		TPlayer.players[playerID].Remove()
		
		' TODO: Mutex
		gsArena.parties[team].RemoveByName(name)
	End Function
End Type
