
' TIceWave
Type TIceWave Extends TWaterMagicInstance
	Const circleSteps:Int = 10
	
	Field maxCircles:Int
	Field circlesDistance:Int
	Field lastHit:Int
	
	' Init
	Method Init(castedBy:TEntity)
		Super.InitInstance(castedBy)
		
		Self.maxRunTime = 1000
		Self.maxCircles = 12
		Self.circlesDistance = 12
		
		' Per hit
		Self.dmg = 10
	End Method
	
	' Run
	Method Run() 
		Local runtime:Int = Self.GetRunTime()
		
		If runtime > Self.maxRunTime
			Self.Remove()
		EndIf
		
		Local circle:Int = runtime / (Self.maxRunTime / maxCircles)
		
		For Local I:Int = 0 To game.speed / 8
			For Local degree:Int = 0 To 359 Step TIceWave.circleSteps
				TParticleTween.Create(..
					gsInGame.GetEffectGroup(Self.y + SinFast[degree] * perspectiveFactor * circlesDistance * circle),..
					400,..
					gsInGame.particleImgIce,..
					Self.x + CosFast[degree] * circlesDistance * circle, Self.y + SinFast[degree] * perspectiveFactor * circlesDistance * circle, ..
					Self.x + CosFast[degree] * circlesDistance * circle, Self.y + SinFast[degree] * perspectiveFactor * circlesDistance * circle - Rand(6, 6 + (maxCircles - circle) * 24),..
					0.5, 0.1,..
					Rand(0, 360), Rand(0, 360),..
					1.25, 1.75,..
					1.25, 1.75,..
					255, 255, 255,..
					192, 224, 255..
					..
				)
			Next
		Next
		
		' Collision
		If MilliSecs() - Self.lastHit >= 50
			Self.CheckCircleCollision(Self.x, Self.y, circlesDistance * circle)
			Self.lastHit = MilliSecs()
		EndIf
	End Method
	
	' Create
	Function Create:TIceWave(castedBy:TEntity)
		Local skill:TIceWave = New TIceWave
		skill.Init(castedBy)
		Return skill
	End Function
End Type

' SIceWave
Type SIceWave Extends TWaterMagic
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
			TParticleTween.Create( ..
				gsInGame.GetEffectGroup(Self.caster.GetMidY()),  ..
				250,..
				gsInGame.particleImgIce,..
				Self.caster.GetMidX(), Self.caster.GetMidY(),  ..
				Self.caster.GetMidX() + CosFast[degree] * Rand(5, 10), Self.caster.GetMidY() + SinFast[degree] * Rand(5, 10),  ..
				0.5, 0.1,..
				0, 360,..
				0.5, 0.75,..
				0.5, 0.75,..
				255, 255, 255,..
				192, 224, 255..
				..
			)
		Next
		
	End Method
	
	' Use
	Method Use() 
		gsInGame.chanEffects.Play("IceWave")
		
		TIceWave.Create(Self.caster)
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Ice Wave"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "Wave of icy water which has a 10% chance to freeze the enemy with every hit it does."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SIceWave
		skill.Init(nCaster)
		Return skill
	End Function
End Type

' TIcyRays
Type TIcyRays Extends TWaterMagicInstance
	Field degree:Int
	Field speed:Float
	
	' Init
	Method Init(castedBy:TEntity, nDegree:Int, nStartX:Int, nStartY:Int, nSpeed:Float)
		Super.InitInstance(castedBy)
		
		Self.degree = nDegree
		Self.speed = nSpeed
		Self.x = nStartX + Cos(Self.degree) * 12
		Self.y = nStartY - Sin(Self.degree) * 12
		
		Self.maxRunTime = 300
		
		Self.dmg = Rand(25, 35)
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Remove()
		EndIf
		
		Self.x :+ CosFastSec(Self.degree) * Self.speed * game.speed
		Self.y :- SinFastSec(Self.degree) * Self.speed * game.speed
		
		For Local I:Int = 0 To game.speed / 4
			Local pDegree:Int = Rand(90 - 23, 90 + 23)
			TParticleTween.Create( ..
				gsInGame.GetEffectGroup(Self.y),  ..
				600,  ..
				gsInGame.particleImgIce,..
				Self.x, Self.y,  ..
				Self.x + CosFast[pDegree] * Rand(6, 25), Self.y - SinFast[pDegree] * Rand(6, 25) * perspectiveFactor,  ..
				0.5, 0.01,  ..
				0, 360,  ..
				0.5, 1.75,  ..
				0.5, 1.75,  ..
				255, 255, 255,  ..
				128, 128, 253 ..
				..
			)
		Next
		
		' Collision
		Self.CheckRectCollision(Self.x - 2, Self.y - 2, 4, 4)
	End Method
	
	' OnHit
	Method OnHit:Int()
		TSlowDeBuff.Create(Self.caster, Self.target, 5000, 0.1)
		Self.Remove()
		Return True
	End Method
	
	' Create
	Function Create:TIcyRays(castedBy:TEntity, nDegree:Int, nStartX:Int, nStartY:Int, nSpeed:Float = 1.0)
		Local skill:TIcyRays = New TIcyRays
		skill.Init(castedBy, nDegree, nStartX, nStartY, nSpeed)
		Return skill
	End Function
End Type

' SIcyRays
Type SIcyRays Extends TWaterMagic
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
		gsInGame.chanEffects.Play("IcyRays")
		
		For Local I:Int = -2 To 2 Step 1
			TIcyRays.Create(Self.caster, Self.caster.GetDegree() + I * 7, Self.caster.GetMidX(), Self.caster.GetMidY(), 1.0)
		Next
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Icy Rays"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "Summons 5 ice rays in front of you."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SIcyRays
		skill.Init(nCaster)
		Return skill
	End Function
End Type

' SIcyFlames
Type SIcyFlames Extends TWaterMagic
	Field radius:Float
	
	' Init
	Method Init(nCaster:TEntity) 
		Super.Init(nCaster)
	End Method
	
	' Cast
	Method Cast() 
		Self.caster.Cast(Self)
		
		Local offsetX:Float
		Local offsetY:Float
		For Local degree:Int = 90 To 360 + 45 Step 45
			offsetX = CosFast[degree] * Self.radius
			offsetY = -SinFast[degree] * Self.radius * perspectiveFactor
			
			For Local I:Int = 0 To game.speed / 4
				Local pDegree:Int = Rand(90 - 23, 90 + 23)
				TParticleTween.Create( ..
					gsInGame.GetEffectGroup(Self.caster.GetMidY()),  ..
					600, ..
					gsInGame.particleImgFire, ..
					Self.caster.GetMidX() + offsetX, Self.caster.GetMidY() + offsetY,  ..
					Self.caster.GetMidX() + offsetX + CosFast[pDegree] * Rand(6, 80), Self.caster.GetMidY() + offsetY - SinFast[pDegree] * Rand(12, 80) * perspectiveFactor,  ..
					0.5, 0.01,  ..
					Rand(-180, 180), 360,  ..
					0.5 + Self.GetCastProgress(), 0.75 + Self.GetCastProgress() * 3,  ..
					0.5 + Self.GetCastProgress(), 0.75 + Self.GetCastProgress() * 3,  ..
					192, 224, 255,  ..
					64, 128, 255 ..
					..
				)
			Next
		Next
	End Method
	
	' Use
	Method Use()
		gsInGame.chanEffects.Play("IcyFlames")
		
		For Local degree:Int = 90 To 360 + 45 Step 45
			For Local rayDegree:Int = 135 Until 495 Step 30
			'For Local rayDegree:Int = degree + 180 - 45 To degree + 180 + 45 Step 15
				TIcyRays.Create(Self.caster, rayDegree, Self.caster.GetMidX() + CosFast[degree] * Self.radius, Self.caster.GetMidY() - SinFast[degree] * Self.radius * perspectiveFactor, 0.5)
			Next
		Next
		'TIcyFlame.Create(Self.caster)
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Icy Flames"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "Summons 8 icy flames of which each creates 12 ice rays when exploding."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SIcyFlames
		skill.Init(nCaster)
		Return skill
	End Function
End Type
