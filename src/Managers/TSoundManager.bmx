' Strict
SuperStrict

' Modules
Import BRL.Audio

' Drivers
Import BRL.FreeAudioAudio
Import BRL.DirectSoundAudio
Import BRL.OpenALAudio

' File formats
Import BRL.WAVLoader
Import BRL.OGGLoader

' Files
Import "../Global.bmx"
Import "TResourceManager.bmx"

' TSoundManager
Type TSoundManager Extends TResourceManager
	Field logger:TLog
	
	' Init
	Method Init(nLogger:TLog)
		Super.InitManager(nLogger)
		Self.resourceType = "sound channel"
		
		Self.logger = nLogger
		Self.logger.Write("Sound manager initialized")
	End Method
	
	' AddChannel
	Method AddChannel:TSoundChannel(name:String) 
		Self.logger.Write("Creating sound channel '" + name + "'")
		Local chan:TSoundChannel = TSoundChannel.Create(name, Self.logger)
		Self.AddObject(name, chan)
		Return chan
	End Method
	
	' GetChannel
	Method GetChannel:TSoundChannel(name:String)
		Return TSoundChannel(Self.resources.ValueForKey(name))
	End Method
	
	' Create
	Function Create:TSoundManager(nLogger:TLog)
		Local mgr:TSoundManager = New TSoundManager
		mgr.Init(nLogger)
		Return mgr
	End Function
End Type

' TSoundChannel
Type TSoundChannel Extends TResourceManager
	Field name:String
	'Field channel:TChannel
	Field lastAudioChannel:TChannel
	Field lastSoundName:String
	Field logger:TLog
	
	' Init
	Method Init(nName:String, nLogger:TLog) 
		Super.InitManager(nLogger)
		Super.AddExtension("wav")
		Super.AddExtension("ogg")
		Self.resourceType = "sound"
		Self.lastAudioChannel = Null
		
		Self.name = nName
		'Self.channel = AllocChannel() 
		Self.logger = nLogger
	End Method
	
	' LoadFromFile
	Method LoadFromFile:Object(file:String)
		Return LoadSound(file)
	End Method
	
	' Play
	Method Play(name:String)
		Local sound:TSound = TSound(Self.resources.ValueForKey(name))
		
		If sound <> Null
			Self.WriteLog("Playing sound '" + name + "'")
			Self.lastAudioChannel = sound.Play()
			Self.lastSoundName = name
		Else
			Self.WriteLog("Failed playing sound '" + name + "'")
		EndIf
	End Method
	
	' PlayMusic
	Method PlayMusic(name:String)
		If name <> Self.lastSoundName
			Self.StopPreviousSound()
			Self.Play(name)
		EndIf
	End Method
	
	' Cue
	Method Cue(name:String)
		Local sound:TSound = TSound(Self.resources.ValueForKey(name))
		
		If sound <> Null
			sound.Cue()
		EndIf
	End Method
	
	' WriteLog
	Method WriteLog(msg:String) 
		Self.logger.Write("[" + Self.name + "] " + msg)
	End Method
	
	' StopPreviousSound
	Method StopPreviousSound()
		If Self.lastAudioChannel <> Null
			Self.lastAudioChannel.Stop()
			Self.lastSoundName = ""
		EndIf
	End Method
	
	' Stop
	Method Stop()
		' TODO: Stop all hardware audio channels
	End Method
	
	Rem
	' Stop
	Method Stop() 
		Self.channel.Stop()
	End Method
	
	' Resume
	Method Resume() 
		Self.channel.SetPaused(False)
	End Method
	
	' Pause
	Method Pause() 
		Self.channel.SetPaused(True)
	End Method
	
	' SetPaused
	Method SetPaused(paused:Int) 
		Self.channel.SetPaused(paused)
	End Method
	
	' SetVolume
	Method SetVolume(volume:Float) 
		Self.channel.SetVolume(volume)
	End Method
	
	' SetPan
	Method SetPan(pan:Float) 
		Self.channel.SetPan(pan)
	End Method
	
	' SetDepth
	Method SetDepth(depth:Float) 
		Self.channel.SetDepth(depth)
	End Method
	
	' SetRate
	Method SetRate(rate:Float) 
		Self.channel.SetRate(rate)
	End Method
	
	' IsPlaying
	Method IsPlaying:Int() 
		Return Self.channel.Playing()
	End Method
	End Rem
	
	' Create
	Function Create:TSoundChannel(nName:String, nLogger:TLog) 
		Local chan:TSoundChannel = New TSoundChannel
		chan.Init(nName, nLogger)
		Return chan
	End Function
End Type
