
' THurricane
Type THurricane Extends TAirMagicInstance
	Field playerDegree:Int
	
	Const circleSteps:Int = 10
	Const maxCircle:Int = 24 * 5
	Const maxOffset:Int = 360 * 1
	
	Field maxCircles:Int
	Field circlesDistance:Int
	Field lastHit:Int
	
	' Init
	Method Init(castedBy:TEntity)
		Super.InitInstance(castedBy)
		
		Self.playerDegree = Self.caster.GetDegree()
		
		Self.maxRunTime = 750
		Self.maxCircles = 5
		Self.circlesDistance = 24
		
		' Per hit
		Self.dmg = 20
	End Method
	
	' Run
	Method Run() 
		Local runtime:Int = Self.GetRunTime()
		
		If runtime > Self.maxRunTime
			Self.Remove()
		EndIf
		
		Self.x :+ CosFastSec(Self.playerDegree) * 0.6 * game.speed
		Self.y :- SinFastSec(Self.playerDegree) * 0.6 * game.speed
		
		Const circleRadius:Int = 24
		Const height:Int = 120'(1 - Self.GetRunTimeProgress()) * 100
		
		Local offset:Int = Self.GetRunTimeProgress() * maxOffset
		For Local circle:Int = circleRadius To maxCircle Step circleRadius
			'Local degree:Int = offset
			For Local degree:Int = offset Until offset + 360 Step 20
				For Local i:Int = 0 To game.speed / 12
					'degree = Rand(0, 359)
					TParticleTween.Create(..
						gsInGame.GetEffectGroup(Self.y + SinFastSec(degree) * circle * perspectiveFactor),  ..
						250,  ..
						gsInGame.particleImgFire,  ..
						Self.x + CosFastSec(degree) * circle, Self.y + SinFastSec(degree) * circle * perspectiveFactor - height * (circle / Float(maxCircle)),  ..
						Self.x + CosFastSec(degree) * (circle + circleRadius), Self.y + SinFastSec(degree) * (circle + circleRadius) * perspectiveFactor - Rand(0, height) * ((circle + circleRadius) / Float(maxCircle)),  ..
						0.15, 0.01,  ..
						degree, degree + 360,  ..
						0.75, 0.95,  ..
						0.75, 0.95,  ..
						255, 255, 255,  ..
						255, 255, 255 ..
						..
					)
				Next
				
				' Shadow
				TParticleTween.Create( ..
						gsInGame.GetEffectGroup(Self.y + SinFastSec(degree) * circle * perspectiveFactor),  ..
						120,  ..
						gsInGame.particleImgFire,  ..
						Self.x + CosFastSec(degree) * circle, Self.y + SinFastSec(degree) * circle * perspectiveFactor,  ..
						Self.x + CosFastSec(degree) * circle, Self.y + SinFastSec(degree) * circle * perspectiveFactor,  ..
						0.065, 0.01,  ..
						degree, degree + 360,  ..
						0.5, 0.7,  ..
						0.5, 0.7,  ..
						0, 0, 0,  ..
						0, 0, 0 ..
						..
					)
			Next
		Next
		
		' Collision
		If MilliSecs() - Self.lastHit >= 50
			Self.CheckCircleCollision(Self.x, Self.y, maxCircle)
			Self.lastHit = MilliSecs()
		EndIf
	End Method
	
'	' OnRemove
'	Method OnRemove()
'		Self.dmg = 100
'		Self.CheckCircleCollision(Self.x, Self.y, maxCircle)
'		
'		For Local circle:Int = 24 To maxCircle Step 24
'			'Local degree:Int = offset
'			For Local degree:Int = 0 Until 360 Step 20
'					TParticleTween.Create( ..
'						gsInGame.GetEffectGroup(Self.y + SinFastSec(degree) * circle * perspectiveFactor),  ..
'						1000,  ..
'						gsInGame.particleImg,  ..
'						Self.x + CosFastSec(degree) * circle, Self.y + SinFastSec(degree) * circle * perspectiveFactor,  ..
'						Self.x + CosFastSec(degree) * circle, Self.y + SinFastSec(degree) * circle * perspectiveFactor - 25,  ..
'						0.5, 0.01,  ..
'						degree, degree + 360,  ..
'						1.00, 2.00,  ..
'						1.00, 2.00,  ..
'						255, 255, 255,  ..
'						255, 0, 0 ..
'						..
'					)
'			Next
'		Next
'	End Method
	
	' Create
	Function Create:THurricane(castedBy:TEntity)
		Local skill:THurricane = New THurricane
		skill.Init(castedBy)
		Return skill
	End Function
End Type

' SHurricane
Type SHurricane Extends TAirMagic
	' Init
	Method Init(nCaster:TEntity)
		Super.Init(nCaster)
	End Method
	
	' Cast
	Method Cast() 
		Self.caster.Cast(Self)
		
		Const maxOffset:Int = 360 * 1
		Const circleRadius:Int = 24
		
		Local maxCircle:Int = circleRadius * 5
		Local offset:Int = Self.GetCastProgress() * maxOffset
		Local height:Int = Self.GetCastProgress() * 120
		For Local circle:Int = circleRadius To maxCircle Step circleRadius
			'Local degree:Int = offset
			For Local degree:Int = offset Until offset + 360 Step 20
				For Local i:Int = 0 To game.speed / 12
					'degree = Rand(0, 359)
					TParticleTween.Create(..
						gsInGame.GetEffectGroup(Self.caster.GetMidY() + SinFastSec(degree) * circle * perspectiveFactor),  ..
						250,  ..
						gsInGame.particleImgFire,  ..
						Self.caster.GetMidX() + CosFastSec(degree) * circle, Self.caster.GetMidY() + SinFastSec(degree) * circle * perspectiveFactor - height * (circle / Float(maxCircle)),  ..
						Self.caster.GetMidX() + CosFastSec(degree) * (circle + circleRadius), Self.caster.GetMidY() + SinFastSec(degree) * (circle + circleRadius) * perspectiveFactor - height * ((circle + circleRadius) / Float(maxCircle)),  ..
						0.15, 0.1,..
						degree, degree + 360,  ..
						0.5, 0.75,  ..
						0.5, 0.75,  ..
						255, 255, 255,  ..
						255, 255, 255 ..
						..
					)
				Next
				
				'Self.caster.GetMidX() + CosFastSec(degree) * (circle + circleRadius), Self.caster.GetMidY() + SinFastSec(degree) * (circle + circleRadius) * perspectiveFactor - height * ((circle + circleRadius) / Float(maxCircle)),  ..
				
				' Shadow
				TParticleTween.Create( ..
					gsInGame.GetEffectGroup(Self.caster.GetMidY() + SinFastSec(degree) * circle * perspectiveFactor),  ..
					120,  ..
					gsInGame.particleImgFire,  ..
					Self.caster.GetMidX() + CosFastSec(degree) * circle, Self.caster.GetMidY() + SinFastSec(degree) * circle * perspectiveFactor,  ..
					Self.caster.GetMidX() + CosFastSec(degree) * (circle + circleRadius), Self.caster.GetMidY() + SinFastSec(degree) * (circle + circleRadius) * perspectiveFactor,  ..
					0.065, 0.01,  ..
					degree, degree + 360,  ..
					0.4, 0.6,  ..
					0.4, 0.6,  ..
					0, 0, 0,  ..
					0, 0, 0 ..
					..
				)
			Next
		Next
		
	End Method
	
	' Use
	Method Use() 
		gsInGame.chanEffects.Play("Hurricane")
		
		THurricane.Create(Self.caster)
	End Method
	
	' GetName
	Method GetName:String()
		' TODO: Localization
		Return "Hurricane"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "Summons a hurricane."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SHurricane
		skill.Init(nCaster)
		Return skill
	End Function
End Type

' TCleave
Type TCleave Extends TAirMagicInstance
	Field degree:Int
	
	' Init
	Method Init(castedBy:TEntity, nCombo:Int)
		Super.InitInstance(castedBy)
		
		Self.degree = Self.caster.GetDegree()
		Self.maxRunTime = 200
		
		Self.x :+ CosFastSec(Self.degree) * 8
		Self.y :- SinFastSec(Self.degree) * 8
		
		Self.dmg = Rand(20, 28)
		
		TSwordSlash.Create(Self.caster, nCombo)
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Remove()
		EndIf
		
		Self.x :+ CosFastSec(Self.degree) * game.speed
		Self.y :- SinFastSec(Self.degree) * game.speed
		
		Local pDegree:Int
		
		For Local I:Int = 0 To game.speed * 2
			pDegree = Self.degree + Rand(-45, 45)
			
			TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.y),..
				200,..
				gsInGame.particleImgWind,..
				Self.x, Self.y,  ..
				Self.x + CosFastSec(pDegree) * Rand(5, 60), Self.y + SinFastSec(pDegree) * Rand(5, 60),  ..
				0.25 - Self.GetRuntimeProgress() * 0.1, 0.1,..
				-Self.degree + 90, -Self.degree + 90,..
				1.5 + Self.GetRuntimeProgress(), 0.9,..
				1.0, 0.75,..
				224, 255, 255,..
				0, 255, 128..
				..
			)
		Next
		
		' Collision
		Self.CheckCircleCollision(Self.x, Self.y, 1 + Self.GetRuntimeProgress() * 17)
	End Method
	
	' OnHit
	Method OnHit:Int()
		Self.Remove()
		Return True
	End Method
	
	' Create
	Function Create:TCleave(castedBy:TEntity, nCombo:Int)
		Local skill:TCleave = New TCleave
		skill.Init(castedBy, nCombo)
		Return skill
	End Function
End Type

' SCleave
Type SCleave Extends TAirMagic
	Field comboCounter:Int
	
	' Init
	Method Init(nCaster:TEntity) 
		Super.Init(nCaster)
		Self.comboCounter = 1
	End Method
	
	' Cast
	Method Cast()
		Self.caster.Cast(Self)
	End Method
	
	' Use
	Method Use()
		gsInGame.chanEffects.Play("Cleave")
		
		TCleave.Create(Self.caster, Self.comboCounter)
		
		' TODO: Condition
		Self.comboCounter :+ 1
		If Self.comboCounter > 2
			' Reset
			Self.comboCounter = 1
		End If
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Cleave"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "Cuts the air in front of you."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SCleave
		skill.Init(nCaster)
		Return skill
	End Function
End Type

' SHealingWind
Type SHealingWind Extends TAirMagic
	Field heal:Int
	
	' Init
	Method Init(nCaster:TEntity)
		Super.Init(nCaster)
	End Method
	
	' Cast
	Method Cast()
		Self.caster.Cast(Self)
		
		For Local i:Int = 0 To game.speed / 2
			Local degree:Int = Rand(0, 359)
			Local offset:Int = Self.caster.img.width + 6
			TParticleTween.Create( ..
						gsInGame.GetEffectGroup(Self.caster.GetY2() - 4 + SinFast[degree] * offset * perspectiveFactor),  ..
						400,  ..
						gsInGame.particleImgWind,  ..
						Self.caster.GetMidX() + CosFast[degree] * offset, Self.caster.GetY2() - 4 + SinFast[degree] * offset * perspectiveFactor,  ..
						Self.caster.GetMidX() + CosFast[degree] * offset, Self.caster.GetY() + SinFast[degree] * offset * perspectiveFactor - 20,  ..
						0.5, 0.1,..
						0, 0,  ..
						0.3, 0.5,  ..
						0.3, 0.5,  ..
						255, 255, 255,  ..
						0, 255, 0 ..
						..
					)
		Next
	End Method
	
	' Use
	Method Use()
		gsInGame.chanEffects.Play("HealingWind")
	
		Self.caster.AddHP(Self.heal)
		Self.CreateHealingView(Self.heal)
		
		For Local degree:Int = 0 Until 360 Step 10
			Local offset:Int = Self.caster.img.width + 6
			TParticleTween.Create( ..
						gsInGame.GetEffectGroup(Self.caster.GetY2() - 4 + SinFast[degree] * offset * 2 * perspectiveFactor),  ..
						Rand(400, 800),  ..
						gsInGame.particleImgWind,  ..
						Self.caster.GetMidX() + CosFast[degree] * offset / 2, Self.caster.GetY2() - 4 + SinFast[degree] * offset / 2 * perspectiveFactor,  ..
						Self.caster.GetMidX() + CosFast[degree] * offset * 2, Self.caster.GetY() + SinFast[degree] * offset * 2 * perspectiveFactor - 20,  ..
						0.5, 0.1,..
						0, 0,  ..
						0.5, 0.85,  ..
						0.5, 0.85,  ..
						255, 255, 255,  ..
						0, 255, 0 ..
						..
					)
		Next
	End Method
	
	' CreateHealingView
	Method CreateHealingView(heal:Int)
		TDamageView.Create(- heal, Self.caster.GetMidX() + Rand(- 12, 12), Self.caster.GetY() - Rand(0, 16) + TDamageView.dmgNumYOffset)
	End Method
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Healing Wind"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		' TODO: Localization
		Return "Heals you for " + Self.heal + " HP."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SHealingWind
		skill.Init(nCaster)
		Return skill
	End Function
End Type

' TWindCutter
Type TWindCutter Extends TAirMagicInstance
	Field degree:Int
	
	' Init
	Method Init(castedBy:TEntity, nCombo:Int)
		Super.InitInstance(castedBy)
		
		Self.degree = Self.caster.GetDegree()
		Self.maxRunTime = 200
		
		Self.x :+ CosFastSec(Self.degree) * 8
		Self.y :- SinFastSec(Self.degree) * 8
		
		Self.dmg = Rand(20, 28)
		
		TSwordSlash.Create(Self.caster, nCombo)
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Remove()
		EndIf
		
		Self.x :+ CosFastSec(Self.degree) * game.speed
		Self.y :- SinFastSec(Self.degree) * game.speed
		
		Local pDegree:Int
		
		For Local I:Int = 0 To game.speed * 2
			pDegree = Self.degree + Rand(-45, 45)
			
			TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.y),..
				200,..
				gsInGame.particleImgWind,..
				Self.x, Self.y,  ..
				Self.x + CosFastSec(pDegree) * Rand(5, 60), Self.y + SinFastSec(pDegree) * Rand(5, 60),  ..
				0.25 - Self.GetRuntimeProgress() * 0.1, 0.1,..
				Self.degree, Self.degree,..
				1.5 + Self.GetRuntimeProgress(), 0.9,..
				1.0, 0.75,..
				224, 255, 255,..
				0, 255, 128..
				..
			)
		Next
		
		' Collision
		Self.CheckCircleCollision(Self.x, Self.y, 1 + Self.GetRuntimeProgress() * 17)
	End Method
	
	' OnHit
	Method OnHit:Int()
		Self.Remove()
		Return True
	End Method
	
	' Create
	Function Create:TWindCutter(castedBy:TEntity, nCombo:Int)
		Local skill:TWindCutter = New TWindCutter
		skill.Init(castedBy, nCombo)
		Return skill
	End Function
End Type
