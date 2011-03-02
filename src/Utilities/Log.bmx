' Strict
SuperStrict

' Modules
Import BRL.Max2D

' Files
Import "../TLog.bmx"

' Log_LoadImage
Function Log_LoadImage:TImage(logger:TLog, url:Object, flags:Int = -1)
	logger.Write("Loading image '" + url.ToString() + "'")
	Return LoadImage(url, flags)
End Function