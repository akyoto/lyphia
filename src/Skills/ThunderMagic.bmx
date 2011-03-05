
' TThunderSphere
Type TThunderSphere Extends TThunderMagicInstance
	Field degree:Int
	
	' Init
	Method Init(castedBy:TEntity)
		Super.InitInstance(castedBy)
		
		Self.degree = Self.caster.GetDegree()
		Self.maxRunTime = 750
		
		Self.dmg = 100
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Remove()
		EndIf
		
		Self.x :+ CosFastSec(Self.degree) * 1.25 * game.speed
		Self.y :- SinFastSec(Self.degree) * 1.25 * game.speed
		
		For Local I:Int = 0 To game.speed
			Local pDegree:Int = Rand(0, 359)
			TParticleTween.Create( ..
				gsInGame.GetEffectGroup(Self.y),  ..
				500,  ..
				gsInGame.particleImg,..
				Self.x, Self.y,  ..
				Self.x + CosFast[pDegree] * Rand(20, 80), Self.y + SinFast[pDegree] * Rand(20, 80),  ..
				0.5, 0.01,  ..
				pDegree, pDegree,  ..
				0.95, 0.75,  ..
				0.95, 0.1,  ..
				255, 255, 0,  ..
				192, 192, 0 ..
				..
			)
		Next
		
		' Collision
		Self.CheckRectCollision(Self.x - 4, Self.y - 4, 8, 8)
	End Method
	
	' OnHit
	Method OnHit:Int()
		Self.Remove()
		Return True
	End Method
	
	' Create
	Function Create:TThunderSphere(castedBy:TEntity)
		Local skill:TThunderSphere = New TThunderSphere
		skill.Init(castedBy)
		Return skill
	End Function
End Type

' SThunderSphere
Type SThunderSphere Extends TThunderMagic
	' Init
	Method Init(nCaster:TEntity) 
		Super.Init(nCaster)
	End Method
	
	' Cast
	Method Cast() 
		Self.caster.Cast(Self)
		
		' TODO: Remove hardcoded stuff
		Local degree:Int
		For Local i:Int = 0 To game.speed / 8
			degree = Rand(0, 359)
			TParticleTween.Create(..
				gsInGame.GetEffectGroup(gsInGame.player.GetMidY()),..
				250,..
				gsInGame.particleImg,..
				Self.caster.GetMidX(), Self.caster.GetMidY(),  ..
				Self.caster.GetMidX() + CosFast[degree] * Rand(20, 40), Self.caster.GetMidY() + SinFast[degree] * Rand(20, 40),  ..
				0.5, 0.1,..
				0, 360,..
				0.5, 0.75,..
				0.5, 0.75,..
				255, 255, 0,  ..
				192, 180, 160..
				..
			)
			
			Local castRadius:Int = 64
			For Local a:Int = -1 To 1 Step 2
				TParticleTween.Create( ..
					gsInGame.GetEffectGroup(Self.caster.GetMidY() + a * SinFastSec(Self.GetCastProgress() * 360) * castRadius * Self.GetCastProgressLeft()),  ..
					400,  ..
					gsInGame.particleImg,..
					Self.caster.GetMidX() + a * CosFastSec(Self.GetCastProgress() * 360) * castRadius * Self.GetCastProgressLeft(), Self.caster.GetMidY() + a * SinFastSec(Self.GetCastProgress() * 360) * castRadius * Self.GetCastProgressLeft(),  ..
					Self.caster.GetMidX() + a * CosFastSec(Self.GetCastProgress() * 360) * castRadius * Self.GetCastProgressLeft() + CosFast[degree] * Rand(5, 10), Self.caster.GetMidY() + a * SinFastSec(Self.GetCastProgress() * 360) * castRadius * Self.GetCastProgressLeft() + SinFast[degree] * Rand(5, 10),  ..
					0.5, 0.1,..
					0, 360,..
					0.3, 0.5,  ..
					0.3, 0.5,  ..
					255, 255, 0,  ..
					192, 180, 160..
					..
				)
			Next
		Next
	End Method
	
	' Use
	Method Use()
		gsInGame.chanEffects.Play("ThunderSphere")
		
		TThunderSphere.Create(Self.caster)
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Thunder Sphere"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "Summens a lightning ball in front of you."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SThunderSphere
		skill.Init(nCaster)
		Return skill
	End Function
End Type

' TChainLightning
Type TChainLightning Extends TThunderMagicInstance
	Field dmgInterval:Int
	Field lastHit:Int
	
	Field castPointX:Int
	Field castPointY:Int
	Field entityList:TMap
	
	' Init
	Method Init(castedBy:TEntity, nCastPointX:Int, nCastPointY:Int, nEntityList:TMap)
		Super.InitInstance(castedBy)
		
		Self.castPointX = nCastPointX
		Self.castPointY = nCastPointY
		Self.entityList = nEntityList
		
		Self.maxRunTime = 250
		
		Self.dmg = Rand(3, 5)
		Self.dmgInterval = 500
		Self.lastHit = 0
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Remove()
			Return
		EndIf
		
		' Collision
		If MilliSecs() - Self.lastHit >= Self.dmgInterval
			Self.CheckCircleCollision(Self.castPointX, Self.castPointY, 150)
			Self.lastHit = MilliSecs()
		EndIf
		
		If Self.target <> Null And Self.target.IsAlive() And Self.entityList.ValueForKey(Self.target) = Self
			' TODO: Visualization
			DrawLine Self.castPointX, Self.castPointY, Self.target.GetMidX(), Self.target.GetMidY()
		EndIf
	End Method
	
	' OnHit
	Method OnHit:Int()
		If Self.entityList.Contains(Self.target)
			If Self.target.IsAlive() = False
				Self.entityList.Remove(Self.target)
			EndIf
			
			' Go on searching a target
			Return True
		Else
			If Self.target.IsAlive()
				Self.entityList.Insert(Self.target, Self)
				TChainLightning.Create(Self.caster, Self.target.GetMidX(), Self.target.GetMidY(), Self.entityList)
			EndIf
			Self.Remove()
			
			' Stop searching a target
			Return False
		EndIf
	End Method
	
	' Create
	Function Create:TChainLightning(castedBy:TEntity, nCastPointX:Int, nCastPointY:Int, nEntityList:TMap)
		Local skill:TChainLightning = New TChainLightning
		skill.Init(castedBy, nCastPointX, nCastPointY, nEntityList)
		Return skill
	End Function
End Type

' SChainLightning
Type SChainLightning Extends TThunderMagic
	Field entityList:TMap
	
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
		Self.entityList = CreateMap()
		TChainLightning.Create(Self.caster, Self.caster.GetMidX(), Self.caster.GetMidY(), Self.entityList)
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Chain Lightning"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "Creates a lightning chain which goes from enemy to enemy."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SChainLightning
		skill.Init(nCaster)
		Return skill
	End Function
End Type

' TSoulStrike
Type TSoulStrike Extends TThunderMagicInstance
	Field degree:Int

	' Init
	Method Init(castedBy:TEntity)
		Super.InitInstance(castedBy)
	
		Self.degree = Self.caster.GetDegree()
		Self.maxRunTime = 750
		
		Self.dmg = Rand(40, 50)
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
			pDegree = 100
			direction = ( (I Mod 2) * 16 - -10) * perspectiveFactor
			damping = (1.0 - Self.GetRunTime() / Float(maxRunTime))
			damping = damping * damping
			fireOffsetCos = -CosFastSec(Self.degree) * (I / Float(game.speed + 1)) * game.speed + damping * CosFastSec(Self.GetRunTime() + 90) * 12 * direction
			fireOffsetSin = SinFastSec(Self.degree) * (I / Float(game.speed + 1)) * game.speed + damping * -SinFastSec(Self.GetRunTime()) * 12 * direction * perspectiveFactor
			
			TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.y + fireOffsetSin),..
				200,..
				gsInGame.particleImgFire,..
				Self.x + fireOffsetCos, Self.y + SinFastSec(Self.degree) * (I / Float(game.speed)) * game.speed + fireOffsetSin,  ..
				Self.x + fireOffsetCos + CosFast[pDegree] * Rand(5, 20), Self.y + fireOffsetSin + SinFast[pDegree] * Rand(5, 20),  ..
				0.5, 0.1,..
				0, 360,..
				0.5, 0.75,..
				0.5, 0.75,..
				255, 253 + Rand(0, 127) * direction, 0,..
				0, 0, 0..
				..
			)
		Next
		
		' Collision
		Self.CheckRectCollision(Self.x - 3, Self.y - 3, 6, 6)
	End Method
	
	' OnHit
	Method OnHit:Int()
		Self.Remove()
		Return True
	End Method
	
	' Create
	Function Create:TSoulStrike(castedBy:TEntity)
		Local skill:TSoulStrike = New TSoulStrike
		skill.Init(castedBy)
		Return skill
	End Function
End Type

' SSoulStrike
Type SSoulStrike Extends TThunderMagic
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
				255, 255, 0,..
				192, 180, 160..
				..
			)
		Next
	End Method
	
	' Use
	Method Use()
		gsInGame.chanEffects.Play("Meteor")
		
		TSoulStrike.Create(Self.caster)
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Soul Strike"
	End Method
' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "Summons 2 Souls of you which are slashing the enemy."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SSoulStrike
		skill.Init(nCaster)
		Return skill
	End Function
End Type

