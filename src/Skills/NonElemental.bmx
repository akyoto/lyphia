
' TSwordSlash
Type TSwordSlash Extends TNonElementalInstance
	Field degree:Int
	Field lastHit:Int
	Field combo:Int
	Field rotateDirection:Int
	Field mpGainPerHit:Float
	
	Field angleHorizontalFactor:Int
	Field angleHorizontalOffset:Int
	Field angleVerticalFactor:Int
	Field angleVerticalOffset:Int
	Field scaleX:Float
	Field scaleY:Float
	
	' Init
	Method Init(castedBy:TEntity, nCombo:Int = 1, nMPGainPerHit:Float)
		Super.InitInstance(castedBy)
		gsInGame.chanEffects.Play("SwordSlash")
		
		Self.combo = nCombo
		Self.mpGainPerHit = nMPGainPerHit
		Self.maxRunTime = 120
		
		Self.angleHorizontalFactor = 60
		Self.angleVerticalFactor = 130
		Self.angleHorizontalOffset = (180 - Self.angleHorizontalFactor) / 2
		Self.angleVerticalOffset = (180 - Self.angleVerticalFactor) / 2
		Self.scaleX = 1.0
		
		If Self.caster.animAttack.GetDirection() = TAnimationAttack.DIRECTION_LEFT Or Self.caster.animAttack.GetDirection() = TAnimationAttack.DIRECTION_RIGHT
			Self.scaleY = 0.9 * perspectiveFactor
		Else
			Self.scaleY = 0.9
		EndIf
		
		Select Self.combo
			' Sword left to right
			Case 1
				Self.degree = -Self.caster.GetDegree()
				Self.rotateDirection = 1
				Self.caster.animAttack.slashDirection = 1
				
			' Sword right to left
			Case 2
				Self.degree = -Self.caster.GetDegree() + 180
				Self.rotateDirection = -1
				Self.caster.animAttack.slashDirection = -1
				
			' Sword in front of you
			Case 3
				Self.degree = -Self.caster.GetDegree()
				Self.scaleY = 1.0
				
				Select Self.caster.animAttack.GetDirection()
					Case TAnimationAttack.DIRECTION_RIGHT
						Self.angleHorizontalFactor = 100
						Self.angleHorizontalOffset = -5
						Self.rotateDirection = 1
						Self.caster.animAttack.slashDirection = 1
						
					Case TAnimationAttack.DIRECTION_LEFT
						Self.angleHorizontalFactor = 100
						Self.angleHorizontalOffset = -185
						Self.rotateDirection = -1
						Self.caster.animAttack.slashDirection = -1
						
					Case TAnimationAttack.DIRECTION_UP, TAnimationAttack.DIRECTION_DOWN
						Self.angleVerticalFactor = 16
						Self.angleVerticalOffset = 82
						Self.rotateDirection = 1
						Self.caster.animAttack.slashDirection = 1
						Self.scaleY = 0.4
				End Select
		End Select
		
		Self.dmg = Rand(4, 6)
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Remove()
			Return
		EndIf
		
		If Self.caster.currentAnimation <> Self.caster.animAttack
			Self.caster.animAttack.SetFrameDuration(Self.maxRunTime / 3)
			Self.caster.animAttack.ApplyDirectionFromWalkAni(Self.caster.animWalk)
			Self.caster.SetAnimation(Self.caster.animAttack)
			'Self.caster.currentAnimation.Start()
		EndIf
		
		' Go to nearest enemy
		If Self.target <> Null
			Self.caster.MoveTo(Self.target.x, Self.target.y, game.speed, 26 * 26)
		End If
		
		Local handX:Int = Self.caster.animAttack.GetHandPositionX()
		Local handY:Int = Self.caster.animAttack.GetHandPositionY()
		
		Self.x = Self.caster.GetX() + handX
		Self.y = Self.caster.GetY() + handY
		
		Local rotation:Float
		If Self.caster.animAttack.GetDirection() = TAnimationAttack.DIRECTION_LEFT Or Self.caster.animAttack.GetDirection() = TAnimationAttack.DIRECTION_RIGHT
			rotation = Self.degree + Self.rotateDirection * ((Self.GetRunTime() / Float(Self.maxRunTime)) * Self.angleHorizontalFactor + Self.angleHorizontalOffset)
		Else
			rotation = Self.degree + Self.rotateDirection * ((Self.GetRunTime() / Float(Self.maxRunTime)) * Self.angleVerticalFactor + Self.angleVerticalOffset)
			If Self.combo = 3
				Self.scaleX = (Self.GetRunTime() / Float(Self.maxRunTime)) * 1.25
			EndIf
		EndIf
		
		Const ffInv:Float = 1 / 45.0
		Local rotationOffset:Int
		Local alpha:Float
		For Local i:Int = 0 To game.speed
			If i = 0
				alpha = 1.0
				rotationOffset = 0
			Else
				alpha = (1 - Abs(rotationOffset) * ffInv) * 0.5
				rotationOffset = Rand(1, 45) * Self.rotateDirection
			End If
			TParticleTween.Create( ..
							Self.caster.grpWeaponEffects,  ..
							40,  ..
							gsInGame.weaponSword,  ..
							handX, handY,  ..
							handX, handY,  ..
							alpha, alpha,  ..
							rotation - rotationOffset, rotation,  ..
							Self.rotateDirection * Self.scaleY, Self.rotateDirection * Self.scaleY,  ..
							Self.scaleX, Self.scaleX,  ..
							255, 255, 255,  ..
							255, 255, 255 ..
							..
						)
			
			' Skill effect (could be blood e.g.)
'			TParticleTween.Create( ..
'							gsInGame.GetEffectGroup(Self.y),  ..
'							100,  ..
'							gsInGame.weaponSword,  ..
'							Self.x, Self.y,  ..	' TODO: Find end of sword
'							Self.x, Self.y,  ..
'							0.5, 0.01,  ..
'							rotation - rotationOffset * 2, rotation - rotationOffset * 2,  ..
'							Self.rotateDirection * scaleY, Self.rotateDirection * scaleY,  ..
'							0.5, 0.25, ..
'							255, 0, 0,  ..
'							255, 0, 0 ..
'							..
'						)
		Next
					
		' Collision
		If MilliSecs() - Self.lastHit >= 40
			' TODO: Change collision method
			Self.CheckCircleCollision(Self.x, Self.y, gsInGame.weaponSword.height - 6)
			Self.lastHit = MilliSecs()
		EndIf
	End Method
	
	' OnHit
	Method OnHit:Int()
		Self.caster.AddMP(Self.mpGainPerHit)
		
		If Self.caster.target <> Null
			Self.caster.target.DelayCast(40)
		End If
		
		Return True
	End Method
	
	' OnRemove
	Method OnRemove()
		Self.caster.SetAnimation(Self.caster.animWalk)
		'Self.caster.currentAnimation.Play()
	End Method
	
	' Create
	Function Create:TSwordSlash(castedBy:TEntity, nCombo:Int = 1, nMPGainPerHit:Float = 0.7)
		Local skill:TSwordSlash = New TSwordSlash
		skill.Init(castedBy, nCombo, nMPGainPerHit)
		Return skill
	End Function
End Type

' SSwordSlash
Type SSwordSlash Extends TNonElemental
	Field mpGainPerHit:Float
	Field comboCounter:Int
	
	' Init
	Method Init(nCaster:TEntity)
		Super.Init(nCaster)
	End Method
	
	' Cast
	Method Cast()
		Self.caster.Cast(Self)
	End Method
	
	' Use
	Method Use()
		TSwordSlash.Create(Self.caster, Self.comboCounter, Self.mpGainPerHit)
		
		' TODO: Condition
		Self.comboCounter:+1
		If Self.comboCounter > 3
			' Reset
			Self.comboCounter = 1
		End If
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Sword Slash"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "Sword slash which absorbs " + FloatToReadableString(Self.mpGainPerHit, 1) + " MP per hit."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SSwordSlash
		skill.Init(nCaster)
		Return skill
	End Function
End Type
