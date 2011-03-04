' Strict
SuperStrict

' Modules
Import BRL.Max2D
'Import BtbN.GLDraw2D

' Files
Import "Global.bmx"
Import "TGame.bmx"
Import "TLua.bmx"
Import "TSlot.bmx"
Import "TDamageView.bmx"
Import "TINILoader.bmx"
Import "TAnimation.bmx"
Import "TParticleSystem.bmx"
Import "Utilities/Math.bmx"
Import "Utilities/Graphics.bmx"
Import "Utilities/Reflection.bmx"

' Includes
Include "TSkill.bmx"
Include "TBuff.bmx"
Include "TParty.bmx"

' TEntity
Type TEntity
	Const DIRECTION_UP:Int = 1
	Const DIRECTION_RIGHT:Int = 2
	Const DIRECTION_DOWN:Int = 3
	Const DIRECTION_LEFT:Int = 4
	
	' Lua
	Field luaScript:TLuaScript
	Field luaObject:TLuaObject
	
	Field name:String
	
	Field level:Int
	
	Field ep:Int
	Field epNext:Int
	
	Field hp:Float, maxHP:Float
	Field mp:Float, maxMP:Float
	
	Field hpRegen:Float
	Field mpRegen:Float
	Field lastHPRegen:Int
	Field lastMPRegen:Int
	
	Field str:Float
	Field def:Float
	Field mag:Float
	Field res:Float
	
	Field x:Float
	Field y:Float
	
	Field tileX:Int
	Field tileY:Int
	
	Field img:TImage
	
	Field speed:Float
	Field directionLocked:Int
	
	Field currentAnimation:TAnimation
	
	Field killCount:Int
	Field deathCount:Int
	
	' Network
	Field netHP:Float
	Field netMP:Float
	
	' Party
	Field party:TParty
	Field partyLink:TLink
	
	' Skills
	Field techSlots:TSlot[]
	
	' Buffs
	Field buffs:TBuffContainer
	Field debuffs:TBuffContainer
	
	' Own weapon effects
	Field grpWeaponEffects:TParticleGroup
	
	' Animations
	Field animWalk:TAnimationWalk
	Field animCast:TAnimationCast
	Field animAttack:TAnimationAttack
	
	Field isWalking:Int
	Field baseDirection:Int
	Field castingSkill:TSkill
	Field mpEffectFunc()
	
	' Used for TEnemy
	Field target:TEntity
	Field killedBy:TEntity
	Field isPlayerFlag:Int
	
	' Init
	Method Init(luaFile:String)
		' Animations
		Self.animWalk = TAnimationWalk.Create()
		Self.animCast = TAnimationCast.Create()
		Self.animAttack = TAnimationAttack.Create()
		Self.SetAnimation(Self.animWalk)
		
		' Buff containers
		Self.buffs = TBuffContainer.Create()
		Self.debuffs = TBuffContainer.Create()
		
		' Direction
		Self.SetDirectionLock(False)
		
		' Lua
		If luaFile.Length > 0
			Self.luaScript = game.scriptMgr.Get(luaFile)
			Self.luaObject = Self.luaScript.CreateInstance(Self)
			Self.luaObject.Invoke("init", Null)
		EndIf
	End Method
	
	' InitStatus
	Method InitStatus(nLevel:Int, nHPMax:Float, nMPMax:Float)
		Self.level = nLevel
		
		Self.maxHP = nHPMax
		Self.hp = Self.maxHP
		
		Self.maxMP = nMPMax
		Self.mp = Self.maxMP
		
		Self.hpRegen = 0.005
		Self.mpRegen = 0.02
		
		' TODO: Other values
		
		' Particle groups
		Self.grpWeaponEffects = TParticleGroup.Create()
		
		Self.SetSpeed(0.2)
	End Method
	
	' IsPlayer
	Method IsPlayer:Int()
		Return Self.isPlayerFlag
	End Method
	
	' SetPosition
	Method SetPosition(nX:Float, nY:Float)
		Self.x = nX
		Self.y = nY
	End Method
	
	' Move
	Method Move(mX:Float, mY:Float)
		Self.x :+ mX * Self.speed
		Self.y :+ mY * Self.speed
	End Method
	
	' SetName
	Method SetName(nName:String)
		Self.name = nName
	End Method
	
	' CreateSkillSlots
	Method CreateSkillSlots(num:Int)
		Self.techSlots = New TSlot[num]
	End Method
	
	' SetSlotSkill
	Method SetSlotSkill(num:Int, skillName:String)
		Local skill:TSkill
		
		Try
			'skill = TSkill.Create(skillName, Self)
			skill = TSkill(CreateObjectFromClass("S" + skillName))
			skill.Init(Self)
		Catch a:String
			Print "Skill '" + skillName + "' does not exist."
			End
		Catch luaError:Object
			Print "Lua error: " + luaError.ToString()
			End
		End Try
		
		Self.techSlots[num] = TSlot.Create(skill)
	End Method
	
	' AddSlotTrigger
	Method AddSlotTrigger(num:Int, trigger:TTrigger)
		Self.techSlots[num].AddTrigger(trigger)
	End Method
	
	' SetAnimation
	Method SetAnimation(anim:TAnimation)
		If Self.currentAnimation = anim
			If Self.currentAnimation.IsActive() = 0
				Self.currentAnimation.Start()
			EndIf
			Return
		EndIf
		
		If Self.currentAnimation <> Null
			Self.currentAnimation.Stop()
		EndIf
		
		Self.currentAnimation = anim
		
		If Self.currentAnimation <> Null
			Self.currentAnimation.Start()
		EndIf
	End Method
	
	' Draw
	Method Draw()
		' Offset
		Self.grpWeaponEffects.SetOffset(Self.GetX(), Self.GetY())
		
		ResetMax2D()
		If Self.animAttack.GetDirection() = TAnimationAttack.DIRECTION_UP
			Self.grpWeaponEffects.Draw()
			
			' TODO: Remove hardcoded shadow
			Rem
			ResetMax2D()
			.SetColor 0, 0, 0
			.SetAlpha 0.15
			.SetScale 1, 0.65
			.SetRotation -15
			DrawImage Self.img, Int(Self.x) - 6, Int(Self.y) + 8, Self.currentAnimation.GetFrame()
			End Rem
			
			ResetMax2D()
			DrawImage Self.img, Int(Self.x), Int(Self.y), Self.currentAnimation.GetFrame()
		Else
			' TODO: Remove hardcoded shadow
			Rem
			.SetColor 0, 0, 0
			.SetAlpha 0.15
			.SetScale 1, 0.65
			.SetRotation -15
			DrawImage Self.img, Int(Self.x) - 6, Int(Self.y) + 8, Self.currentAnimation.GetFrame()
			ResetMax2D()
			End Rem
			
			DrawImage Self.img, Int(Self.x), Int(Self.y), Self.currentAnimation.GetFrame()
			Self.grpWeaponEffects.Draw()
			ResetMax2D()
		EndIf
	End Method
	
	 ' DrawHPAndMP
	Method DrawHPAndMP()
		SetColor 0, 0, 0
		DrawRectOutline Int(Self.x), Int(Self.y) - 13, Self.img.width, 5
		SetColor 255, 0, 0
		DrawRect Int(Self.x) + 1, Int(Self.y) - 12, (Self.hp / Self.maxHP) * (Self.img.width - 2), 3
		
		SetColor 0, 0, 0
		DrawRectOutline Int(Self.x), Int(Self.y) - 8, Self.img.width, 5
		SetColor 0, 0, 255
		DrawRect Int(Self.x) + 1, Int(Self.y) - 7, (Self.mp / Self.maxMP) * (Self.img.width - 2), 3
	End Method
	
	' SetSpeed
	Method SetSpeed(nSpeed:Float)
		Self.speed = nSpeed
		Self.animWalk.SetFrameDuration(15 / Self.speed)
	End Method
	
	' SetParty
	Method SetParty(nParty:TParty)
		If Self.party <> Null
			Self.party.Remove(Self)
		EndIf
		
		nParty.Add(Self)
	End Method
	
	' GetName
	Method GetName:String()
		Return Self.name
	End Method
	
	' GetKillCount
	Method GetKillCount:Int()
		Return Self.killCount
	End Method
	
	' GetDeathCount
	Method GetDeathCount:Int()
		Return Self.deathCount
	End Method
	
	' GetParty
	Method GetParty:TParty()
		Return Self.party
	End Method
	
	' GetDegree
	Method GetDegree:Int()
		Return Self.animWalk.GetDegree()
	End Method
	
	' GetMidX
	Method GetMidX:Int() 
		Return Self.x + Self.img.width / 2
	End Method
	
	' GetMidY
	Method GetMidY:Int() 
		Return Self.y + Self.img.height / 2
	End Method
	
	' GetX
	Method GetX:Float()
		Return Self.x
	End Method
	
	' GetY
	Method GetY:Float()
		Return Self.y
	End Method
	
	' GetX2
	Method GetX2:Int()
		Return Self.x + Self.img.width
	End Method
	
	' GetY2
	Method GetY2:Int()
		Return Self.y + Self.img.height
	End Method
	
	' SetKillCount
	Method SetKillCount(kills:Int)
		Self.killCount = kills
	End Method
	
	' SetDeathCount
	Method SetDeathCount(deaths:Int)
		Self.deathCount = deaths
	End Method
	
	' SetDirectionLock
	Method SetDirectionLock(lockedDirection:Int)
		If lockedDirection
			Self.SetDirection(lockedDirection)
		EndIf
		
		Self.directionLocked = lockedDirection
	End Method
	
	' SetDirection
	Method SetDirection(entDirection:Int)
		If Self.directionLocked
			Return
			'gsInGame.player.animWalk.SetDirection(dir)
			'gsInGame.player.animAttack.ApplyDirectionFromWalkAni(gsInGame.player.animWalk)
		EndIf
		
		Select entDirection
			Case TEntity.DIRECTION_UP
				Self.animWalk.SetDirection(TAnimationWalk.DIRECTION_UP)
				Self.animCast.SetDirection(TAnimationWalk.DIRECTION_UP)
				
			Case TEntity.DIRECTION_DOWN
				Self.animWalk.SetDirection(TAnimationWalk.DIRECTION_DOWN)
				Self.animCast.SetDirection(TAnimationWalk.DIRECTION_DOWN)
				
			Case TEntity.DIRECTION_LEFT
				Self.animWalk.SetDirection(TAnimationWalk.DIRECTION_LEFT)
				Self.animCast.SetDirection(TAnimationWalk.DIRECTION_LEFT)
				
			Case TEntity.DIRECTION_RIGHT
				Self.animWalk.SetDirection(TAnimationWalk.DIRECTION_RIGHT)
				Self.animCast.SetDirection(TAnimationWalk.DIRECTION_RIGHT)
		End Select
		
		Self.animAttack.ApplyDirectionFromWalkAni(Self.animWalk)
	End Method
	
	' UpdateDirection
	Method UpdateDirection(mX:Float, mY:Float)
		If mX = 0 And mY = 0
			Return
		End If
		
		Self.baseDirection = Self.animWalk.GetDirectionByCoords(mX, mY)
		
		If Self.directionLocked = 0
			Self.animWalk.SetDirection(Self.baseDirection)
			Self.animAttack.ApplyDirectionFromWalkAni(Self.animWalk)
		EndIf
	End Method
	
	' DelayCast
	Method DelayCast(byTime:Int)
		If Self.castingSkill <> Null
			Self.castingSkill.DelayCast(byTime)
		End If
	End Method
	
	' MoveTo
	Method MoveTo(toX:Int, toY:Int, wspeed:Float, toleranceSq:Int = 25)
		Local nXS:Int = toX - Self.x
		Local nYS:Int = toY - Self.y
		
		If DistanceSq2(nXS, nYS) < toleranceSq
			Return
		EndIf
		
		Local nXSgn:Int = Sgn(nXS)
		Local nYSgn:Int = Sgn(nYS)
		
		If nXSgn <> 0 Or nYSgn <> 0
			Self.Walk(nXSgn * wspeed, nYSgn * wspeed)
			'If nXS > nYS
			'	Self.UpdateDirection(nXS, 0)
			'ElseIf nXS = nYS
				Self.UpdateDirection(nXS, nYS)
			'Else
			'	Self.UpdateDirection(0, nYS)
			'EndIf
			'enemy.animWalk.Play()
		EndIf
	End Method
	
	' Walk
	Method Walk(mX:Float, mY:Float, reallyMoveX:Int = True, reallyMoveY:Int = True)
		If Self.castingSkill = Null And Self.currentAnimation <> Self.animAttack
			If Self.animWalk.IsActive() = True
				If mX = 0.0 And mY = 0.0
					Self.animWalk.Stop()
					'Print "Stopped"
					Return
				EndIf
				
				' Check whether we have changed the direction
				Local directionX:Int = Self.animWalk.GetDirectionByCoordsUnsafe(mX, 0)
				Local directionY:Int = Self.animWalk.GetDirectionByCoordsUnsafe(0, mY)
				
				If Self.baseDirection <> directionX And Self.baseDirection <> directionY
					Self.UpdateDirection(mX, mY)
				EndIf
			Else
				If mX = 0.0 And mY = 0.0
					Return
				EndIf
				
				Self.UpdateDirection(mX, mY)
				Self.SetAnimation(Self.animWalk)
				'Print "Started"
			EndIf
		EndIf
		
		If reallyMoveX = False
			mX = 0
		End If
		If reallyMoveY = False
			mY = 0
		End If
		
		Self.Move(mX, mY)
	End Method
	
	' Cast
	Method Cast(skill:TSkill)
		Self.castingSkill = skill
		
		If Self.animCast.IsActive() = True
			' TODO: ...
		ElseIf skill.castTime > 0
			Self.SetAnimation(Self.animCast) 
			Self.animCast.SetDirection(Self.animWalk.GetDirection())
		EndIf
	End Method
	
	' IsAlive
	Method IsAlive:Int()
		Return Self.hp > 0
	End Method
	
	' SetHP
	Method SetHP(amount:Float)
		Self.hp = amount
		
		If Self.hp > Self.maxHP
			Self.hp = Self.maxHP
		EndIf
	End Method
	
	' AddHP
	Method AddHP(amount:Float)
		Self.hp:+amount
		
		If Self.hp > Self.maxHP
			Self.hp = Self.maxHP
		EndIf
	End Method
	
	' LoseHP
	Method LoseHP(amount:Float, caster:TEntity = Null)
		Self.hp:-amount
		
		If Self.hp <= 0
			' Register kill
			If Self.killedBy = Null
				Self.killedBy = caster
				
				caster.SetKillCount(caster.GetKillCount() + 1)
				Self.SetDeathCount(Self.GetDeathCount() + 1)
			EndIf
			
			Self.hp = 0
			Self.Die()
		EndIf
		
		If Self.target = Null
			Self.target = caster
		EndIf
	End Method
	
	' AddMP
	Method AddMP(amount:Float)
		Self.mp:+amount
		
		If Self.mp > Self.maxMP
			Self.mp = Self.maxMP
		EndIf
	End Method
	
	' HasEnoughMP
	Method HasEnoughMP:Int(costAbs:Int, costRel:Float = 0.0) 
		Return costAbs + costRel * Self.maxMP <= Self.mp
	End Method
	
	' UseMP
	Method UseMP:Int(costAbs:Int, costRel:Float = 0.0) 
		Self.mp :- costAbs + costRel * Self.maxMP
		
		If Self.mpEffectFunc <> Null
			Self.mpEffectFunc() 
		EndIf
	End Method
	
	' EndCast
	Method EndCast()
		Self.SetAnimation(Self.animWalk) 
		Self.castingSkill = Null
	End Method
	
	' UpdateBuffs
	Method UpdateBuffs()
		Self.buffs.Update()
		Self.debuffs.Update()
	End Method
	
	' GetBuffContainer
	Method GetBuffContainer:TBuffContainer()
		Return Self.buffs
	End Method
	
	' GetDebuffContainer
	Method GetDebuffContainer:TBuffContainer()
		Return Self.debuffs
	End Method
	
	' PositionToString
	Method PositionToString:String()
		Return Int(Self.x) + ", " + Int(Self.y)
	End Method
	
	' SetImageFile
	Method SetImageFile(nFile:String) Abstract
	
	' Update
	Method Update() Abstract
	
	' Die
	Method Die() Abstract
	
	' OnSameLine
	Function OnSameLine:Int(a:TEntity, b:TEntity, skillRangeX:Int = -12, skillRangeY:Int = -16)
		' Check vertically
		If RectInRect(a.x - skillRangeX, 0, a.img.width + skillRangeX * 2, b.y + b.img.height, b.x, b.y, b.img.width, b.img.height)
			Return 1
		End If
		
		' Check horizontally
		If RectInRect(0, a.y - skillRangeY, b.x + b.img.width, a.img.height + skillRangeY * 2, b.x, b.y, b.img.width, b.img.height)
			Return 2
		End If
		
		Return 0
	End Function
End Type

' TAnimationWalk
Type TAnimationWalk Extends TAnimation
	Const DIRECTION_UP:Int = 1	' Frame number
	Const DIRECTION_RIGHT:Int = 7	' Frame number
	Const DIRECTION_DOWN:Int = 13	' Frame number
	Const DIRECTION_LEFT:Int = 19	' Frame number
	
	' Animation depends on the direction
	Field direction:Int
	Field wasLeft:Int
	
	' SetDirection
	Method SetDirection(direc:Int)
		If Self.direction <> direc
			Self.direction = direc
			Self.NextFrame()
		EndIf
	End Method
	
	' GetDirection
	Method GetDirection:Int()
		Return Self.direction
	End Method
	
	' GetDirectionByCoords
	Method GetDirectionByCoords:Int(mX:Float, mY:Float)
		If mY < 0
			Return TAnimationWalk.DIRECTION_UP
		ElseIf mY > 0
			Return TAnimationWalk.DIRECTION_DOWN
		ElseIf mX < 0
			Return TAnimationWalk.DIRECTION_LEFT
		ElseIf mX > 0
			Return TAnimationWalk.DIRECTION_RIGHT
		Else
			Return Self.direction
		EndIf
	End Method
	
	' GetDirectionByCoordsUnsafe
	Method GetDirectionByCoordsUnsafe:Int(mX:Float, mY:Float)
		If mY < 0
			Return TAnimationWalk.DIRECTION_UP
		ElseIf mY > 0
			Return TAnimationWalk.DIRECTION_DOWN
		ElseIf mX < 0
			Return TAnimationWalk.DIRECTION_LEFT
		ElseIf mX > 0
			Return TAnimationWalk.DIRECTION_RIGHT
		Else
			Return 0
		EndIf
	End Method
	
	' GetDegreeByCoords
	Method GetDegreeByCoords:Int(mX:Float, mY:Float)
		If mY < 0
			Return -90
		ElseIf mY > 0
			Return 90
		ElseIf mX < 0
			Return 180
		ElseIf mX > 0
			Return 0
		Else
			Return Self.GetDegree()
		EndIf
	End Method
	
	' Start
	Method Start()
		Self.frame = Self.direction
		Self.active = True
	End Method
	
	' NextFrame
	Method NextFrame()
		Select Self.frame
			Case Self.direction					' Starting frame of a direction
				If Self.wasLeft
					Self.frame :+ 1
				Else
					Self.frame :- 1
				EndIf
				
			Case Self.direction + 1				' "Right" frame
				Self.frame :- 1
				Self.wasLeft = False
				
			Case Self.direction - 1				' "Left" frame
				Self.frame :+ 1
				Self.wasLeft = True
				
			Default							' Set new direction
				Self.frame = Self.direction
		End Select
	End Method
	
	' Stop
	Method Stop()
		Self.frame = Self.direction
		Self.active = False
	End Method
	
	' GetDegree
	Method GetDegree:Int()
		Select Self.direction
			Case TAnimationWalk.DIRECTION_UP
				Return 90
				
			Case TAnimationWalk.DIRECTION_RIGHT
				Return 0
				
			Case TAnimationWalk.DIRECTION_DOWN
				Return -90
				
			Case TAnimationWalk.DIRECTION_LEFT
				Return 180
		End Select
	End Method
	
	' Create
	Function Create:TAnimationWalk()
		Local anim:TAnimationWalk = New TAnimationWalk
		anim.SetDirection(TAnimationWalk.DIRECTION_DOWN)
		Return anim
	End Function
End Type

' TAnimationCast
Type TAnimationCast Extends TAnimation
	' Animation depends on the direction
	Field direction:Int
	
	' SetDirection
	Method SetDirection(direc:Int)
		If Self.direction <> direc
			Self.direction = direc
			Self.NextFrame()
		EndIf
	End Method
	
	' GetDirection
	Method GetDirection:Int()
		Return Self.direction
	End Method
		
	' Start
	Method Start()
		Self.frame = Self.direction + 1
		Self.active = True
	End Method
	
	' NextFrame
	Method NextFrame()
		Self.frame = Self.direction - 1
	End Method
	
	' Stop
	Method Stop()
		Self.frame = Self.direction
		Self.active = False
	End Method
	
	' Create
	Function Create:TAnimationCast()
		Local anim:TAnimationCast = New TAnimationCast
		anim.SetDirection(TAnimationWalk.DIRECTION_DOWN)
		Return anim
	End Function
End Type

' TAnimationAttack
Type TAnimationAttack Extends TAnimation
	Const DIRECTION_UP:Int = 4	' Frame number
	Const DIRECTION_RIGHT:Int = 10	' Frame number
	Const DIRECTION_DOWN:Int = 16	' Frame number
	Const DIRECTION_LEFT:Int = 22	' Frame number
	
	' Animation depends on the direction
	Field direction:Int
	Field frameHandPos:Int[,]
	Field slashDirection:Int
	
	' SetDirection
	Method SetDirection(direc:Int)
		If Self.direction <> direc
			Self.direction = direc
			Self.NextFrame()
		EndIf
	End Method
	
	' ApplyDirectionFromWalkAni
	Method ApplyDirectionFromWalkAni(walkAni:TAnimationWalk)
		Select walkAni.GetDirection()
			Case TAnimationWalk.DIRECTION_DOWN
				Self.direction = TAnimationAttack.DIRECTION_DOWN
				
			Case TAnimationWalk.DIRECTION_UP
				Self.direction = TAnimationAttack.DIRECTION_UP
				
			Case TAnimationWalk.DIRECTION_LEFT
				Self.direction = TAnimationAttack.DIRECTION_LEFT
				
			Case TAnimationWalk.DIRECTION_RIGHT
				Self.direction = TAnimationAttack.DIRECTION_RIGHT
		End Select
	End Method
	
	' LoadConfig
	Method LoadConfig(file:String)
		Local ini:TINI = TINI.Create(file)
		ini.Load()
		
		For Local I:Int = 0 To 1
			Local xy:String = "X"
			If I = 1
				xy = "Y"
			EndIf
			
			Self.frameHandPos[TAnimationAttack.DIRECTION_UP - 1, I] = Int(ini.Get("Up", "Left" + xy))
			Self.frameHandPos[TAnimationAttack.DIRECTION_DOWN - 1, I] = Int(ini.Get("Down", "Left" + xy))
			Self.frameHandPos[TAnimationAttack.DIRECTION_LEFT - 1, I] = Int(ini.Get("Left", "Left" + xy))
			Self.frameHandPos[TAnimationAttack.DIRECTION_RIGHT - 1, I] = Int(ini.Get("Right", "Left" + xy))
			
			Self.frameHandPos[TAnimationAttack.DIRECTION_UP, I] = Int(ini.Get("Up", "Center" + xy))
			Self.frameHandPos[TAnimationAttack.DIRECTION_DOWN, I] = Int(ini.Get("Down", "Center" + xy))
			Self.frameHandPos[TAnimationAttack.DIRECTION_LEFT, I] = Int(ini.Get("Left", "Center" + xy))
			Self.frameHandPos[TAnimationAttack.DIRECTION_RIGHT, I] = Int(ini.Get("Right", "Center" + xy))
			
			Self.frameHandPos[TAnimationAttack.DIRECTION_UP + 1, I] = Int(ini.Get("Up", "Right" + xy))
			Self.frameHandPos[TAnimationAttack.DIRECTION_DOWN + 1, I] = Int(ini.Get("Down", "Right" + xy))
			Self.frameHandPos[TAnimationAttack.DIRECTION_LEFT + 1, I] = Int(ini.Get("Left", "Right" + xy))
			Self.frameHandPos[TAnimationAttack.DIRECTION_RIGHT + 1, I] = Int(ini.Get("Right", "Right" + xy))
		Next
	End Method
	
	' GetHandPositionX
	Method GetHandPositionX:Int()
		Return Self.frameHandPos[Self.frame, 0]
	End Method
	
	' GetHandPositionY
	Method GetHandPositionY:Int()
		Return Self.frameHandPos[Self.frame, 1]
	End Method
	
	' GetDirection
	Method GetDirection:Int()
		Return Self.direction
	End Method
		
	' Start
	Method Start()
		Self.frame = Self.direction + Self.slashDirection
		Self.lastUpdate = MilliSecs()
		Self.active = True
	End Method
	
	' NextFrame
	Method NextFrame()
		Select Self.frame
			Case Self.direction + Self.slashDirection
				Self.frame:-Self.slashDirection
				
			Case Self.direction
				Self.frame:-Self.slashDirection
				
			Case Self.direction - Self.slashDirection
				Self.frame:+Self.slashDirection
				
			Default
				Self.frame = Self.direction + slashDirection
		End Select
	End Method
	
	' Stop
	Method Stop()
		Self.frame = Self.direction
		Self.active = False
	End Method
	
	' Create
	Function Create:TAnimationAttack()
		Local anim:TAnimationAttack = New TAnimationAttack
		anim.frameHandPos = New Int[TAnimationAttack.DIRECTION_LEFT + 2, 2]
		anim.SetDirection(TAnimationAttack.DIRECTION_DOWN)
		anim.slashDirection = 1
		Return anim
	End Function
End Type
