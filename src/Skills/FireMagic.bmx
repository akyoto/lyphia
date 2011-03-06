
' TFireBall
Type TFireBall Extends TFireMagicInstance
	Field degree:Int
	
	' Init
	Method Init(castedBy:TEntity)
		Super.InitInstance(castedBy)
		
		Self.degree = Self.caster.GetDegree()
		Self.maxRunTime = 750
		
		Self.dmg = Rand(30, 40)
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Remove()
		EndIf
		
		Self.x:+CosFastSec(Self.degree) * 1.25 * game.speed
		Self.y:-SinFastSec(Self.degree) * 1.25 * game.speed
		
		' TODO: Remove hardcoded stuff
		Local pDegree:Int
		Local direction:Int
		Local damping:Float
		Local fireOffsetCos:Float
		Local fireOffsetSin:Float
		
		For Local I:Int = 0 To game.speed
			pDegree = Rand(0, 359)
			direction = ( (I Mod 2) * 2 - 1) ' -1 or 1 depending on I
			damping = (1.0 - Self.GetRunTime() / Float(maxRunTime))
			damping = damping * damping
			fireOffsetCos = -CosFastSec(Self.degree) * (I / Float(game.speed + 0.001)) * game.speed + damping * CosFastSec(Self.GetRunTime() + 90) * 12 * direction
			fireOffsetSin = SinFastSec(Self.degree) * (I / Float(game.speed + 0.001)) * game.speed + damping * -SinFastSec(Self.GetRunTime()) * 12 * direction * perspectiveFactor
			
			TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.y + fireOffsetSin),..
				200,..
				gsInGame.particleImg,..
				Self.x + fireOffsetCos, Self.y + SinFastSec(Self.degree) * (I / Float(game.speed)) * game.speed + fireOffsetSin,  ..
				Self.x + fireOffsetCos + CosFast[pDegree] * Rand(5, 20), Self.y + fireOffsetSin + SinFast[pDegree] * Rand(5, 20),  ..
				0.5, 0.1,..
				0, 360,..
				0.5, 0.75,..
				0.5, 0.75,..
				255, 128 + Rand(0, 127) * direction, 0,..
				192, 180, 160..
				..
			)
		Next
		
		' Collision
		Self.CheckRectCollision(Self.x - 3, Self.y - 3, 6, 6)
	End Method
	
	' OnHit
	Method OnHit:Int()
		TBurnDeBuff.Create(Self.caster, Self.target, 6000, 5, 2000)
		Self.Remove()
		Return True
	End Method
	
	' Create
	Function Create:TFireBall(castedBy:TEntity)
		Local skill:TFireBall = New TFireBall
		skill.Init(castedBy)
		Return skill
	End Function
End Type

' SFireBall
Type SFireBall Extends TFireMagic
	' Init
	Method Init(nCaster:TEntity) 
		Super.Init(nCaster)
	End Method
	
	' Cast
	Method Cast()
		Self.caster.Cast(Self)
		
		Local pDegree:Int
		For Local i:Int = 0 To game.speed / 8
			pDegree = Rand(0, 359)
			TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.caster.GetMidY()),  ..
				250,..
				gsInGame.particleImg,..
				Self.caster.GetMidX(), Self.caster.GetMidY(),  ..
				Self.caster.GetMidX() + CosFast[pDegree] * Rand(5, 10), Self.caster.GetMidY() + SinFast[pDegree] * Rand(5, 10),  ..
				0.5, 0.1,..
				0, 360,..
				0.5, 0.75,..
				0.5, 0.75,..
				255, 0, 0,..
				192, 180, 160..
				..
			)
		Next
	End Method
	
	' Use
	Method Use()
		gsInGame.chanEffects.Play("FireBall")
		
		TFireBall.Create(Self.caster)
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Fire Ball"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "Summons a fire ball in front of you."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SFireBall
		skill.Init(nCaster)
		Return skill
	End Function
End Type

' TFireBreath
Type TFireBreath Extends TFireMagicInstance
	Field degree:Int
	Field lastHit:Int
	
	' Init
	Method Init(castedBy:TEntity)
		Super.InitInstance(castedBy)
		
		Self.maxRunTime = 1000
		
		Self.dmg = Rand(2, 4)
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Remove()
		EndIf
		
		Self.degree = Self.caster.GetDegree()
		
		Self.x = Self.caster.GetMidX() + CosFastSec(Self.degree) * 4
		Self.y = Self.caster.GetMidY() - SinFastSec(Self.degree) * 4 - 5
		
		Local pDegree:Int
		For Local i:Int = 0 To game.speed / 8
			pDegree = Rand(Self.degree - 20, Self.degree + 20)
			TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.y),  ..		' Effect group
				250,..							' Life time
				gsInGame.particleImgFire,..				' Image
				Self.x, Self.y,  ..					' Start position
				Self.x + CosFastSec(pDegree) * 100, Self.y - SinFastSec(pDegree) * 100,  ..	' End position
				0.4, 0.01,..							' Alpha
				0, 360,..							' Rotation
				0.5, 0.75,..						' Scale X (start, end)
				0.5, 0.75,..						' Scale Y (start, end)
				255, 0, 0,..						' Color (start)
				220, 200, 0..							' Color (end)
			)
		Next
		
		' Collision
		If MilliSecs() - Self.lastHit >= 250
			Self.CheckCircleCollision(Self.x, Self.y, 100)
			Self.lastHit = MilliSecs()
		EndIf
		'Self.CheckCircleArcCollision(Self.x, Self.y, 100, Self.degree - 20, Self.degree + 20)
	End Method
	
	' OnHit
	Method OnHit:Int()
		TBurnDeBuff.Create(Self.caster, Self.target, 12000, 10, 3000)
		'Self.Remove()
		Return True
	End Method
	
	' Create
	Function Create:TFireBreath(castedBy:TEntity)
		Local skill:TFireBreath = New TFireBreath
		skill.Init(castedBy)
		Return skill
	End Function
End Type

' SFireBreath
Type SFireBreath Extends TFireMagic
	' Init
	Method Init(nCaster:TEntity) 
		Super.Init(nCaster)
	End Method
	
	' Cast
	Method Cast()
		Self.caster.Cast(Self)
		
		Local pDegree:Int
		For Local i:Int = 0 To game.speed / 8
			pDegree = Rand(0, 359)
			TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.caster.GetMidY()),  ..
				250,..
				gsInGame.particleImg,..
				Self.caster.GetMidX(), Self.caster.GetMidY(),  ..
				Self.caster.GetMidX() + CosFast[pDegree] * Rand(5, 10), Self.caster.GetMidY() + SinFast[pDegree] * Rand(5, 10),  ..
				0.5, 0.1,..
				0, 360,..
				0.5, 0.75,..
				0.5, 0.75,..
				255, 0, 0,..
				192, 180, 160..
				..
			)
		Next
	End Method
	
	' Use
	Method Use()
		gsInGame.chanEffects.Play("FireBreath")
		
		TFireBreath.Create(Self.caster)
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Fire Breath"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "Summons a fire breath in front of you."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SFireBreath
		skill.Init(nCaster)
		Return skill
	End Function
End Type

' TMeteor
Type TMeteor Extends TFireMagicInstance
	Field explosionRadius:Int
	Field meteorScale:Float
	Field offsetX:Int
	Field offsetY:Int
	
	' Init
	Method Init(castedBy:TEntity, nX:Int, nY:Int, nExplosionRadius:Int, nOffsetX:Int, nOffsetY:Int)
		Super.InitInstance(castedBy)
		
		Self.x = nX
		Self.y = nY
		Self.explosionRadius = nExplosionRadius
		Self.offsetX = nOffsetX
		Self.offsetY = nOffsetY
		
		Self.maxRunTime = 550
		Self.dmg = Rand(50, 70) + Self.explosionRadius * 1.5
		
		Self.meteorScale = Float(Self.explosionRadius) / gsInGame.particleImgFire.width + 0.3
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Explode()
			Return
		EndIf
		
		' Shadow
		For Local I:Int = 0 To game.speed * 0.1
			TParticleTween.Create( ..
				gsInGame.GetEffectGroup(Self.y),  ..
				150,  ..
				gsInGame.particleImgFire,  ..
				Self.x, Self.y,  ..
				Self.x, Self.y,  ..
				0.0125 * (1 + Self.GetRuntimeProgress()), 0.01,  ..
				0, Rand(180, 540),  ..
				Self.meteorScale * Self.GetRuntimeProgress(), Self.meteorScale * Self.GetRuntimeProgress(),  ..
				Self.meteorScale * Self.GetRuntimeProgress(), Self.meteorScale * Self.GetRuntimeProgress(),  ..
				0, 0, 0,  ..
				0, 0, 0 ..
				..
			)
		Next
		
		For Local I:Int = 0 To game.speed * 0.75
			Local pDegree:Int = Rand(90 - 14, 90 + 14)
			
			' Fire
			TParticleTween.Create( ..
				gsInGame.GetEffectGroup(Self.y),  ..
				300,  ..
				gsInGame.particleImgFire,..
				Self.x + (1 - Self.GetRuntimeProgress()) * Self.offsetX, Self.y + (1 - Self.GetRuntimeProgress()) * -Self.offsetY,  ..
				Self.x + (1 - Self.GetRuntimeProgress()) * Self.offsetX + CosFast[pDegree] * Rand(6, 100), Self.y + (1 - Self.GetRuntimeProgress()) * -Self.offsetY - SinFast[pDegree] * Rand(6, 100) * perspectiveFactor,  ..
				0.5, 0.01,  ..
				Rand(-90, 90), Rand(-180, 180),  ..
				Self.meteorScale + Rnd(-1.0, 1.0), 0.25 + Rnd(-0.2, 0.2),  ..
				Self.meteorScale + Rnd(-1.0, 1.0), 0.25 + Rnd(-0.2, 0.2),  ..
				255 - Rand(0, 20), 218 + Rand(-20, 20), 0,  ..
				255 - Rand(0, 20), 60 + Rand(-20, 20), 0 ..
				..
			)
		Next
	End Method
	
	' Explode
	Method Explode()
		gsInGame.chanEffects.Play("MeteorExplode")
		
		For Local I:Int = 1 To Self.explosionRadius * 2
			Local pDegree:Int = Rand(0, 360)
			TParticleTween.Create( ..
				gsInGame.GetEffectGroup(Self.y),  ..
				600,  ..
				gsInGame.particleImgFire,..
				Self.x, Self.y,  ..
				Self.x + CosFast[pDegree] * Rand(Self.explosionRadius / 2, Self.explosionRadius * 2.5), Self.y - SinFast[pDegree] * Rand(Self.explosionRadius / 2, Self.explosionRadius * 2.5) * perspectiveFactor,  ..
				0.45, 0.001,  ..
				Rand(0, 360), Rand(0, 360),  ..
				2.0 + Rnd(-0.5, 0.5), 0.35 + Rnd(-0.2, 0.2),  ..
				2.0 + Rnd(-0.5, 0.5), 0.35 + Rnd(-0.2, 0.2),  ..
				225 - Rand(0, 20), 178 + Rand(-20, 20), 0,  ..
				225 - Rand(0, 20), 40 + Rand(-20, 20), 0 ..
				..
			)
		Next
		
		' Collision
		Self.CheckCircleCollision(Self.x, Self.y, Self.explosionRadius)
		Self.Remove()
	End Method
	
	' OnHit
	Method OnHit:Int()
		TBurnDeBuff.Create(Self.caster, Self.target, 9000, 8, 3000)
		'Self.Remove()
		Return True
	End Method
	
	' Create
	Function Create:TMeteor(castedBy:TEntity, nX:Int, nY:Int, nExplosionRadius:Int = 70, nOffsetX:Int = 70, nOffsetY:Int = 400)
		Local skill:TMeteor = New TMeteor
		skill.Init(castedBy, nX, nY, nExplosionRadius, nOffsetX, nOffsetY)
		Return skill
	End Function
End Type

' SMeteor
Type SMeteor Extends TFireMagic
	' Init
	Method Init(nCaster:TEntity) 
		Super.Init(nCaster)
		
		Self.SetFollowUpSkill(SMeteorRain.Create(nCaster))
	End Method
	
	' Cast
	Method Cast() 
		Self.caster.Cast(Self)
	End Method
	
	' Use
	Method Use()
		gsInGame.chanEffects.Play("Meteor")
		
		' Calculate X, Y offset
		Local x:Int, y:Int
		Local degree:Int = Self.caster.GetDegree()
		x = CosFastSec(degree) * 200
		
		If Self.caster.animWalk.GetDirection() = TAnimationWalk.DIRECTION_UP Or Self.caster.animWalk.GetDirection() = TAnimationWalk.DIRECTION_DOWN
			y = -SinFastSec(degree) * 200 * perspectiveFactor
		Else
			y = -SinFastSec(degree) * 200
		EndIf
		
		TMeteor.Create(Self.caster, Self.caster.GetMidX() + x, Self.caster.GetMidY() + y, 70, 70, 400)
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Meteor"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "Summons a meteor in front of you."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SMeteor
		skill.Init(nCaster)
		Return skill
	End Function
End Type

' TMeteorRain
Type TMeteorRain Extends TFireMagicInstance
	Field radius:Int
	Field lastMeteorTime:Int
	Field meteorInterval:Int
	
	' Init
	Method Init(castedBy:TEntity, nX:Int, nY:Int, nRadius:Int)
		Super.InitInstance(castedBy)
		
		Self.x = nX
		Self.y = nY
		Self.radius = nRadius
		
		Self.maxRunTime = 3000
		Self.lastMeteorTime = 0
		Self.meteorInterval = 100
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Remove()
			Return
		EndIf
		
		If MilliSecs() - Self.lastMeteorTime >= Self.meteorInterval
			Local degree:Int = Rand(0, 360)
			Local randRadius:Int = Rand(0, Self.radius)
			gsInGame.chanEffects.Play("Meteor")
			TMeteor.Create(Self.caster, Self.x + CosFastSec(degree) * randRadius, Self.y - SinFastSec(degree) * randRadius * perspectiveFactor, Rand(10, 14), Rand(-170, 170), Rand(200, 400))
			Self.lastMeteorTime = MilliSecs()
		EndIf
	End Method
	
	' OnHit
	Method OnHit:Int()
		'Self.Remove()
		Return True
	End Method
	
	' Create
	Function Create:TMeteorRain(castedBy:TEntity, nX:Int, nY:Int, nRadius:Int)
		Local skill:TMeteorRain = New TMeteorRain
		skill.Init(castedBy, nX, nY, nRadius)
		Return skill
	End Function
End Type

' SMeteorRain
Type SMeteorRain Extends TFireMagic
	' Init
	Method Init(nCaster:TEntity) 
		Super.Init(nCaster)
		
		Self.SetFollowUpSkill(SInferno.Create(nCaster))
	End Method
	
	' Cast
	Method Cast()
		Self.caster.Cast(Self)
		
		Local degree:Int
		For Local i:Int = 0 To game.speed / 8
			degree = Rand(0, 359)
			TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.caster.GetMidY()),  ..
				250,..
				gsInGame.particleImg,..
				Self.caster.GetMidX(), Self.caster.GetMidY(),  ..
				Self.caster.GetMidX() + CosFast[degree] * Rand(5, 10), Self.caster.GetMidY() + SinFast[degree] * Rand(5, 10),  ..
				0.5, 0.1,..
				0, 360,..
				0.5, 0.75,..
				0.5, 0.75,..
				255, 0, 0,..
				192, 180, 160..
				..
			)
		Next
	End Method
	
	' Use
	Method Use()
		gsInGame.chanEffects.Play("MeteorRain")
		
		' Calculate X, Y
		Local x:Float, y:Float
		Local casterDegree:Int = Self.caster.GetDegree()
		x = CosFastSec(casterDegree) * 200
		
		If Self.caster.animWalk.GetDirection() = TAnimationWalk.DIRECTION_UP Or Self.caster.animWalk.GetDirection() = TAnimationWalk.DIRECTION_DOWN
			y = -SinFastSec(casterDegree) * 200 * perspectiveFactor
		Else
			y = -SinFastSec(casterDegree) * 200
		EndIf
		
		TMeteorRain.Create(Self.caster, Self.caster.GetMidX() + x, Self.caster.GetMidY() + y, 42)
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Meteor Rain"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "Meteors are falling every 0.1 seconds for 3 seconds on an area in front of you."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SMeteorRain
		skill.Init(nCaster)
		Return skill
	End Function
End Type

' SInferno
Type SInferno Extends TFireMagic
	' Init
	Method Init(nCaster:TEntity) 
		Super.Init(nCaster)
	End Method
	
	' Cast
	Method Cast()
		Self.caster.Cast(Self)
		
		Local degree:Int
		For Local i:Int = 0 To game.speed / 8
			degree = Rand(0, 359)
			TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.caster.GetMidY()),  ..
				250,..
				gsInGame.particleImg,..
				Self.caster.GetMidX(), Self.caster.GetMidY(),  ..
				Self.caster.GetMidX() + CosFast[degree] * Rand(5, 10), Self.caster.GetMidY() + SinFast[degree] * Rand(5, 10),  ..
				0.5, 0.1,..
				0, 360,..
				0.5, 0.75,..
				0.5, 0.75,..
				255, 0, 0,..
				192, 180, 160..
				..
			)
		Next
	End Method
	
	' Use
	Method Use()
		gsInGame.chanEffects.Play("Inferno")
		
		For Local I:Int = 1 To 3
			TMeteorRain.Create(Self.caster, Self.caster.GetMidX(), Self.caster.GetMidY(), 300)
		Next
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Inferno"
	End Method
	
	' GetDescription
	Method GetDescription:String()
		' TODO: Localization
		Return "Meteors are falling every 0.1 seconds for 3 seconds on a huge area around you."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SInferno
		skill.Init(nCaster)
		Return skill
	End Function
End Type

' TFireNuclease
Type TFireNuclease Extends TFireMagicInstance
	Field degree:Int
	
	' Init
	Method Init(castedBy:TEntity)
		Super.InitInstance(castedBy)
		
		Self.degree = Self.caster.GetDegree()
		Self.maxRunTime = 750
		
		Self.dmg = Rand(30, 40)
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Remove()
		EndIf
		
		Self.x:+CosFastSec(Self.degree) * 1.25 * game.speed
		Self.y:-SinFastSec(Self.degree) * 1.25 * game.speed
		
		' TODO: Remove hardcoded stuff
		Local pDegree:Int
		Local direction:Int
		Local damping:Float
		Local fireOffsetCos:Float
		Local fireOffsetSin:Float
		
		For Local I:Int = 0 To game.speed
			pDegree = Rand(0, 359)
			direction = ((I Mod 2) * 2 - 1) ' -1 or 1 depending on I
			damping = (1.0 - Self.GetRunTime() / Float(maxRunTime))
			damping = damping * damping
			fireOffsetCos = -CosFastSec(Self.degree) * (I / Float(game.speed + 0.001)) * game.speed + damping * CosFastSec(Self.GetRunTime() + 90) * 24 * direction
			fireOffsetSin = SinFastSec(Self.degree) * (I / Float(game.speed + 0.001)) * game.speed + damping * -SinFastSec(Self.GetRunTime()) * 96 * direction * perspectiveFactor
			
			TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.y + fireOffsetSin),..
				200,..
				gsInGame.particleImg,..
				Self.x + fireOffsetCos, Self.y + SinFastSec(Self.degree) * (I / Float(game.speed)) * game.speed + fireOffsetSin,  ..
				Self.x + fireOffsetCos + CosFast[pDegree] * Rand(5, 20), Self.y + fireOffsetSin + SinFast[pDegree] * Rand(5, 20),  ..
				0.5, 0.1,..
				0, 360,..
				0.5, 0.75,..
				0.5, 0.75,..
				255, 128 + Rand(0, 127) * direction, 0,..
				192, 180, 160..
				..
			)
		Next
		
		' Collision
		Self.CheckRectCollision(Self.x - 3, Self.y - 3, 6, 6)
	End Method
	
	' OnHit
	Method OnHit:Int()
		TBurnDeBuff.Create(Self.caster, Self.target, 6000, 5, 2000)
		Self.Remove()
		Return True
	End Method
	
	' Create
	Function Create:TFireNuclease(castedBy:TEntity)
		Local skill:TFireNuclease = New TFireNuclease
		skill.Init(castedBy)
		Return skill
	End Function
End Type

' SFireNuclease
Type SFireNuclease Extends TFireMagic
	' Init
	Method Init(nCaster:TEntity) 
		Super.Init(nCaster)
	End Method
	
	' Cast
	Method Cast()
		Self.caster.Cast(Self)
		
		Local pDegree:Int
		For Local i:Int = 0 To game.speed / 8
			pDegree = Rand(0, 359)
			TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.caster.GetMidY()),  ..
				250,..
				gsInGame.particleImg,..
				Self.caster.GetMidX(), Self.caster.GetMidY(),  ..
				Self.caster.GetMidX() + CosFast[pDegree] * Rand(5, 10), Self.caster.GetMidY() + SinFast[pDegree] * Rand(5, 10),  ..
				0.5, 0.1,..
				0, 360,..
				0.5, 0.75,..
				0.5, 0.75,..
				255, 0, 0,..
				192, 180, 160..
				..
			)
		Next
	End Method
	
	' Use
	Method Use()
		gsInGame.chanEffects.Play("FireNuclease")
		
		TFireNuclease.Create(Self.caster)
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Fire Nuclease"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "TODO"
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SFireNuclease
		skill.Init(nCaster)
		Return skill
	End Function
End Type

