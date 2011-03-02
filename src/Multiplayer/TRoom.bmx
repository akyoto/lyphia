' Strict
SuperStrict

' Modules
Import Vertex.BNetEx
Import BRL.Threads

' Files
Import "../TGame.bmx"

' TRoom
Type TRoom
	Field name:String
	
	Field host:String
	Field port:Short
	
	Field ip:Int
	Field stream:TTCPStream
	Field streamMutex:TMutex
	
	Field sendThread:TThread
	
	' Connect
	Method Connect(nHost:String, nPort:Int)
		Self.host = nHost
		Self.port = nPort
		
		Self.streamMutex = CreateMutex()
		
		' Connecting
		Self.ip = TNetwork.GetHostIP(Self.host)
		If Self.ip = 0 Then Throw("Host not found")
		
		Self.streamMutex.Lock()
			Self.stream = New TTCPStream
			If Self.stream.Init() = 0 Then Throw("Can't create socket")
			Self.stream.SetTimeouts(game.receiveTimeout, game.sendTimeout, game.acceptTimeout)
			If Self.stream.SetLocalPort() = 0 Then Throw("Can't set local port")
			Self.stream.SetRemoteIP(Self.ip)
			Self.stream.SetRemotePort(Self.port)
			If Self.stream.Connect() = 0 Then Throw("Can't connect to host")
		Self.streamMutex.Unlock()
		
		Self.sendThread = CreateThread(RoomThreadFunc, Self)
	End Method
	
	' Disconnect
	Method Disconnect()
		If Self.stream
			Self.stream.Close()
			Self.stream = Null
		EndIf
	End Method
	
	' Create
	Function Create:TRoom(nHost:String, nPort:Int)
		Local room:TRoom = New TRoom
		room.Connect(nHost, nPort)
		Return room
	End Function
End Type

' TClientMsgHandler
Type TClientMsgHandler
	Global msgFunc(room:TRoom)[256]
	Global serverConnectFunc(room:TRoom) = ClientDoNothing
	Global serverDisconnectFunc(room:TRoom) = ClientDoNothing
	
	' HandleMsg
	Function HandleMsg(room:TRoom)
		Local code:Byte
		
		room.streamMutex.Lock()
			code = room.stream.ReadByte()
		room.streamMutex.UnLock()
		
		If msgFunc[code] <> Null
			msgFunc[code](room)
		EndIf
	End Function
	
	' SetFunction
	Function SetFunction(code:Byte, nMsgFunc(room:TRoom))
		msgFunc[code] = nMsgFunc
	End Function
End Type

' RoomThreadFunc
Function RoomThreadFunc:Object(data:Object)
	Local room:TRoom = TRoom(data)
	Local stream:TTCPStream = room.stream
	
	TClientMsgHandler.serverConnectFunc(room)
	
	While stream <> Null And stream.GetState() = 1
		room.streamMutex.Lock()
			If stream.RecvAvail()
				' Receive msg
				While stream.RecvMsg()
				Wend
				
				' Check type of msg
				If stream.Size() > 0 Then
					While stream.Eof() = 0
						TClientMsgHandler.HandleMsg(room)
					Wend
				EndIf
			EndIf
		room.streamMutex.Unlock()
			
		room.streamMutex.Lock()
			' Send
			While stream.SendMsg()
			Wend
		room.streamMutex.Unlock()
		
		Delay game.networkThreadDelay
	Wend
	
	room.Disconnect()
	
	TClientMsgHandler.serverDisconnectFunc(room)
End Function

' ClientDoNothing
Function ClientDoNothing(room:TRoom)
	
End Function
