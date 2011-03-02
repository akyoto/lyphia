' Strict
SuperStrict

' Modules
Import Vertex.BNetEx
Import BRL.Threads

' Files
Import "../TPlayer.bmx"

' TClient
Type TClient
	Field stream:TTCPStream
	Field streamMutex:TMutex
	Field link:TLink
	Field thread:TThread
	Field server:TServer
	Field ipString:String
	
	' InitClient
	Method InitClient(nStream:TTCPStream, nServer:TServer)
		Self.stream = nStream
		Self.streamMutex = CreateMutex()
		Self.server = nServer
		Self.ipString = TNetwork.StringIP(Self.stream.GetLocalIP())
		Self.link = Null
		Self.thread = Null
	End Method
	
	' Remove
	Method Remove()
		Self.server.clientListMutex.Lock()
			Self.link.Remove()
			If Self.stream <> Null
				Self.stream.Close()
				Self.stream = Null
			EndIf
		Self.server.clientListMutex.Unlock()
	End Method
	
	' Create
	Function Create:TClient(nStream:TTCPStream, nServer:TServer)
		Local client:TClient = New TClient
		client.InitClient(nStream, nServer)
		Return client
	End Function
End Type

' TLyphiaClient
Type TLyphiaClient Extends TClient
	Field player:TPlayer
	
	' Init
	Method Init(nStream:TTCPStream, nServer:TServer)
		Self.InitClient(nStream, nServer)
		Self.player = Null 'TPlayer.Create("")
	End Method
	
	' Create
	Function Create:TLyphiaClient(nStream:TTCPStream, nServer:TServer)
		Local client:TLyphiaClient = New TLyphiaClient
		client.Init(nStream, nServer)
		Return client
	End Function
End Type

' TServer
Type TServer
	Field stream:TTCPStream
	Field clientList:TList
	Field clientListMutex:TMutex
	Field port:Short
	Field logger:TLog
	Field logMutex:TMutex
	
	' Init
	Method Init(nPort:Short, nLogger:TLog)
		Self.stream = New TTCPStream
		Self.clientList = CreateList()
		Self.clientListMutex = CreateMutex()
		Self.logMutex = CreateMutex()
		Self.port = nPort
		Self.logger = nLogger
		
		If Self.stream.Init() = 0 Then Throw("Can't create socket")
		Self.stream.SetTimeouts(game.receiveTimeout, game.sendTimeout, game.acceptTimeout)
		If Self.stream.SetLocalPort(Self.port) = 0 Then Throw("Can't set local port")
		If Self.stream.Listen() = 0 Then Throw("Can't set socket to listen")
	End Method
	
	' Update
	Method Update()
		Local newClientStream:TTCPStream = Self.stream.Accept()
		
		If newClientStream <> Null
			Self.logMutex.Lock()
				logger.Write("New client:")
				logger.Write(" * IP: " + TNetwork.StringIP(newClientStream.GetLocalIP()))
				logger.Write(" * Port: " + newClientStream.GetLocalPort())
			Self.logMutex.Unlock()
			
			Local client:TLyphiaClient = TLyphiaClient.Create(newClientStream, Self)
			
			Self.clientListMutex.Lock()
				client.link = Self.clientList.AddLast(client)
			Self.clientListMutex.Unlock()
			
			client.thread = CreateThread(ClientThreadFunc, client)
		EndIf
	End Method
	
	' Remove
	Method Remove()
		Self.clientListMutex.Lock()
			For Local client:TClient = EachIn Self.clientList
				client.Remove()
			Next
		Self.clientListMutex.Unlock()
		
		If Self.stream <> Null
			Self.stream.Close()
			Self.stream = Null
		EndIf
	End Method
	
	' Create
	Function Create:TServer(nPort:Short, nLogger:TLog)
		Local server:TServer = New TServer
		server.Init(nPort, nLogger)
		Return server
	End Function
End Type

' TServerMsgHandler
Type TServerMsgHandler
	Global msgFunc(client:TLyphiaClient)[256]
	Global clientConnectFunc(client:TLyphiaClient) = ServerDoNothing
	Global clientDisconnectFunc(client:TLyphiaClient) = ServerDoNothing
	
	' HandleMsg
	Function HandleMsg(client:TLyphiaClient)
		Local code:Byte = client.stream.ReadByte()
		
		If msgFunc[code] <> Null
			msgFunc[code](client)
		EndIf
	End Function
	
	' SetFunction
	Function SetFunction(code:Byte, nMsgFunc(client:TLyphiaClient))
		msgFunc[code] = nMsgFunc
	End Function
End Type

' ClientThreadFunc
Function ClientThreadFunc:Object(data:Object)
	Local client:TLyphiaClient = TLyphiaClient(data)
	Local server:TServer = client.server
	Local stream:TTCPStream = client.stream
	
	server.logMutex.Lock()
		server.logger.Write("New thread for client: " + client.ipString)
	server.logMutex.Unlock()
	
	TServerMsgHandler.clientConnectFunc(client)
	
	While stream.GetState() = 1
		client.streamMutex.Lock()
		If stream.RecvAvail()
			' Receive msg
			While stream.RecvMsg()
			Wend
			client.streamMutex.Unlock()
			
			' Check type of msg
			If stream.Size() > 0 Then
				While stream.Eof() = 0
					TServerMsgHandler.HandleMsg(client)
				Wend
			EndIf
		Else
			client.streamMutex.Unlock()
			Delay game.networkThreadDelay
		EndIf
		
		' Send msg
		client.streamMutex.Lock()
			While stream.SendMsg()
			Wend
		client.streamMutex.Unlock()
	Wend
	
	' Disconnected
	server.logMutex.Lock()
		server.logger.Write(client.player.GetName() + " (" + client.ipString + ") disconnected.")
	server.logMutex.Unlock()
	stream.Close()
	
	client.Remove()
	
	TServerMsgHandler.clientDisconnectFunc(client)
End Function

' ServerDoNothing
Function ServerDoNothing(client:TLyphiaClient)
	
End Function
