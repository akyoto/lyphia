
' SRecovery
Type SRecovery Extends TLightMagic
	Field heal:Int
	Field healInterval:Int
	Field lifeTime:Int
	
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
		gsInGame.chanEffects.Play("Recovery")
		
		TRecoveryBuff.Create(Self.caster, Self.caster, Self.lifeTime, Self.heal, Self.healInterval)
		
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
	
	' GetName
	Method GetName:String() 
		' TODO: Localization
		Return "Recovery"
	End Method
	
	' GetDescription
	Method GetDescription:String()
		' TODO: Localization
		Return "Recovers " + Self.heal + " HP every " + MSToSeconds(Self.healInterval) + " seconds for " + MSToSeconds(Self.lifeTime) + " seconds."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SRecovery
		skill.Init(nCaster)
		Return skill
	End Function
End Type
