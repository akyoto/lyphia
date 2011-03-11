' Strict
SuperStrict

' Modules
Import BRL.Threads

' SpawnHTTPThread
Function SpawnHTTPThread:TThread(url:String)
	Return CreateThread(SpawnHTTPThreadFunc, url)
End Function

' SpawnHTTPThreadFunc
Function SpawnHTTPThreadFunc:Object(url:Object)
	Local stream:TStream = ReadStream(String(url))
	
	While stream.Eof() = False
		stream.ReadLine()
	Wend
End Function