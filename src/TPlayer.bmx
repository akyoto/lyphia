' Strict
SuperStrict

' Files
Import "Global.bmx"
Import "TEntity.bmx"

' TPlayer
Type TPlayer Extends TEntity
	Global count:Byte
	Global players:TPlayer[256]
	
	Field id:Byte
	
	Field mutex:TMutex
	
	Field movementX:Byte
	Field movementY:Byte
	
	Field characterName:String
	
	' Init
	Method Init(scriptFile:String)
		Self.isPlayerFlag = True
		
		Super.Init(scriptFile)
		
		Self.SetName(Self.characterName)
		
		' Skill slots
		'Self.techSlots = New TSlot[4 + 4 + 4 + 1]
		
		' TODO: Remove hardcoded stuff
		'Self.SetImageFile("Kimiko.png")
		
		Self.mutex = CreateMutex()
		
		' Find a ID
		While TPlayer.players[TPlayer.count] <> Null
			TPlayer.count = (TPlayer.count + 1) Mod 256
		Wend
		
		Self.SetID(TPlayer.count)
	End Method
	
	' LoadConfigFile
	Method LoadConfigFile(file:String)
		Self.animAttack.LoadConfig(FS_ROOT + "data/characters/" + file)
	End Method
	
	' GetID
	Method GetID:Int()
		Return Self.id
	End Method
	
	' SetID
	Method SetID(nID:Int)
		Self.id = nID
		TPlayer.players[Self.id] = Self
	End Method
	
	' SetMovement
	Method SetMovement(mX:Byte, mY:Byte)
		Self.movementX = mX
		Self.movementY = mY
	End Method
	
	' SetImageFile
	Method SetImageFile(nFile:String)
		' TODO: Remove hardcoded stuff
		SetMaskColor 255, 255, 255
		
		Local pixmap:TPixmap = LoadPixmap(FS_ROOT + "data/characters/" + nFile)
		Local frameWidth:Int = pixmap.width / 6
		Local frameHeight:Int = pixmap.height / 4
		
		Self.img = LoadAnimImage(pixmap, frameWidth, frameHeight, 0, 24)
	End Method
	
	' SetMPEffectFunc
	Method SetMPEffectFunc(func() ) 
		Self.mpEffectFunc = func
	End Method
	
	' SetCharacterName
	Method SetCharacterName(name:String)
		Self.characterName = name
	End Method
	
	' GetCharacterName
	Method GetCharacterName:String()
		Return Self.characterName
	End Method
	
	' Update
	Method Update()
		Self.mutex.Lock()
			Self.currentAnimation.Play()
			
			' HP regen
			If MilliSecs() - Self.lastHPRegen >= 1000
				Self.AddHP(Self.maxHP * Self.hpRegen)
				Self.lastHPRegen = MilliSecs()
			End If
			
			' MP regen
			If MilliSecs() - Self.lastMPRegen >= 1000
				Self.AddMP(Self.maxMP * Self.mpRegen)
				Self.lastMPRegen = MilliSecs()
			End If
			
			' Buffs
			Self.UpdateBuffs()
		Self.mutex.Unlock()
	End Method
	
	' Remove
	Method Remove()
		TPlayer.players[Self.id] = Null
	End Method
	
	' Die
	Method Die()
		
	End Method
	
	' Create
	Function Create:TPlayer(scriptFile:String)
		Local player:TPlayer = New TPlayer
		player.Init(scriptFile)
		Return player
	End Function
End Type
