
' TDarkMatter
Type TDarkMatter Extends TShadowMagicInstance
	Field degree:Int
	Field lastHit:Int
	Field bonusDMG:Int
	
	' Init
	Method Init(castedBy:TEntity, nX:Int, nY:Int, nbonusDMG:Int)
		Super.InitInstance(castedBy)
		Self.bonusDMG = nbonusDMG
		Self.degree = Self.caster.GetDegree()
		Self.maxRunTime = 10000
		Self.x = nX
		Self.y = nY
		Self.dmg = Rand(40, 50) + Self.bonusDMG
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Remove()
		EndIf
		
		Local pDegree:Int
		For Local i:Int = 0 To game.speed / 8
			pDegree = Rand(Self.degree+0, Self.degree + 360)
  			TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.y),  ..  							' Effect group
				250,..       			 								' Life time
				gsInGame.particleImgFire,..    								' Image
				Self.x , Self.y,  ..     						' Start position
				Self.x + CosFastSec(pDegree) * 20, Self.y - SinFastSec(pDegree) * 20 *perspectiveFactor,  ..     							' End position
				0.5, 0.1,..       									' Alpha
				0, 360,..       										' Rotation
				1, 1.5,..      									' Scale X (start, end)
				1, 1.5,..      									' Scale Y (start, end)
				255, 255, 255,..      									' Color (start)
				0, 0, 0..       									' Color (end)
   			)
		Next
		
		' Collision
		If MilliSecs() - Self.lastHit >= 500
			Self.CheckRectCollision(Self.x - 3, Self.y - 3, 6, 6)
			Self.lastHit = MilliSecs()
		EndIf
	End Method
	
	' OnHit
	Method OnHit:Int()
		'Self.Remove()
		Return True
	End Method
	
	' Create
	Function Create:TDarkMatter(castedBy:TEntity, nX:Int, nY:Int, nbonusDMG:Int = 10)
		Local skill:TDarkMatter = New TDarkMatter
		skill.Init(castedBy, nX, nY, nbonusDMG)
		Return skill
	End Function
End Type

' SDarkMatter
Type SDarkMatter Extends TShadowMagic
	Field radius:Float
	Field degree:Int
	Field balldegree:Int
	' Init
	Method Init(nCaster:TEntity) 
		Super.Init(nCaster)
		
		Self.SetFollowUpSkill(STwilight.Create(nCaster))
	End Method
	
	' Cast
	Method Cast() 
		Self.caster.Cast(Self)
		
		Local pDegree:Int
		pDegree = Self.caster.GetDegree()
		For Local ballDegree:Int = -30 To 30 Step 30
		Local casterOffsetX:Float = CosFastSec(Self.caster.GetDegree()+balldegree) * 80
		Local casterOffsetY:Float = SinFastSec(Self.caster.GetDegree()+balldegree) * 80
		For Local i:Int = 0 To game.speed / 8
			pDegree = Rand(Self.degree+0, Self.degree + 360)
				TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.caster.GetMidY()),  ..  							' Effect group
				650,..       			 								' Life time
				gsInGame.particleImgFire,..    								' Image
				Self.caster.GetMidX() + casterOffsetX, Self.caster.GetMidY() - casterOffsetY,  ..     						' Start position
				Self.caster.GetMidX() + casterOffsetX, Self.caster.GetMidY() - casterOffsetY,  ..     							' End position
				0.5, 0.01,..       									' Alpha
				0, 360,..       										' Rotation
				1, 1.5,..      										' Scale X (start, end)
				1, 1.5,..      										' Scale Y (start, end)
				255, 255, 255,..      									' Color (start)
				0, 0, 0..       		
		)
		Next
		Next
	End Method
	
	' Use
	Method Use()
		gsInGame.chanEffects.Play("DarkMatter")
		
		For Local ballDegree:Int = -30 To 30 Step 30
			TDarkMatter.Create(Self.caster, Self.caster.GetMidX() + CosFastSec(Self.caster.GetDegree() + ballDegree) * 80, Self.caster.GetMidY() - SinFastSec(Self.caster.GetDegree() + ballDegree) * 80, 10)
		Next
	End Method
	
	' GetName
	Method GetName:String() 
		Return "Dark Matter"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		Return "Summons 3 pillars of Dark Matter."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SDarkMatter
		skill.Init(nCaster)
		Return skill
	End Function
End Type


' STwilight
Type STwilight Extends TShadowMagic
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
		'gsInGame.chanEffects.Play("Twilight")
		
		For Local ballDegree:Int = 0 To 360 Step 30
		If ballDegree Mod 45 > 0
			TDarkMatter.Create(Self.caster, Self.caster.GetMidX() + CosFastSec(Self.caster.GetDegree() + ballDegree) * 120, Self.caster.GetMidY() - SinFastSec(Self.caster.GetDegree() + ballDegree) * 120, 10)
		End If			
		Next
	End Method
	
	' GetName
	Method GetName:String() 
		Return "Dark Matter"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		Return "Summons 3 pillars of Dark Matter."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New STwilight
		skill.Init(nCaster)
		Return skill
	End Function
End Type

' TArcaneShadowOrb2
Type TArcaneShadowOrb2 Extends TShadowMagicInstance
	Field degree:Int
	Field lastHit:Int
	Field bonusDMG:Int
	Field speed:Float
	
	' Init
	Method Init(castedBy:TEntity, nX:Int, nY:Int, nbonusDMG:Int)
		Super.InitInstance(castedBy)
		Self.bonusDMG = nbonusDMG
		Self.degree = Self.caster.GetDegree()
		Self.maxRunTime = 10000
		Self.x = nX
		Self.y = nY
		Self.dmg = Rand(40, 50) + Self.bonusDMG
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Remove()
		EndIf
		
		Self.x :+ CosFastSec(Self.degree) * Self.speed * game.speed
		Self.y :- SinFastSec(Self.degree) * Self.speed * game.speed
		
		Local pDegree:Float
		For Local spread:Int = 0 To 180 Step 20
			If spread Mod 60 > 0
				For Local I:Int = 0 To game.speed / 4
					pDegree = Rand(90 -22.5, 90+22.5)
					
					TParticleTween.Create( ..
						gsInGame.GetEffectGroup(Self.y),  ..
						650,  ..
						gsInGame.particleImgIce,..
						Self.x + spread, Self.y + spread,  ..
						Self.x + CosFast[pDegree] * Rand(30, 125) + spread, Self.y - SinFast[pDegree] * Rand(30, 125) + spread * perspectiveFactor,  ..
						0.5, 0.01,  ..
						0, 360,  ..
						0.5, 1.75,  ..
						0.5, 1.75,  ..
						255, 255, 255,  ..
						0, 0, 0 ..
						..
					)
				Next
			End If	
		Next
		
		' Collision
		If MilliSecs() - Self.lastHit >= 500
			Self.CheckRectCollision(Self.x - 3, Self.y - 3, 6, 6)
			Self.lastHit = MilliSecs()
		EndIf
	End Method
	
	' OnHit
	Method OnHit:Int()
		'Self.Remove()
		Return True
	End Method
	
	' Create
	Function Create:TArcaneShadowOrb2(castedBy:TEntity, nX:Int, nY:Int, nbonusDMG:Int = 10)
		Local skill:TArcaneShadowOrb2 = New TArcaneShadowOrb2
		skill.Init(castedBy, nX, nY, nbonusDMG)
		Return skill
	End Function
End Type

' SArcaneShadowOrb2
Type SArcaneShadowOrb2 Extends TShadowMagic
	Field radius:Float
	Field degree:Int
	' Init
	Method Init(nCaster:TEntity) 
		Super.Init(nCaster)
		Self.degree = Self.caster.GetDegree()
		
	End Method
	
	' Cast
	Method Cast() 
		Self.caster.Cast(Self)
		
		Local pDegree:Int
		pDegree = Self.caster.GetDegree()
		Local casterOffsetX:Float = CosFastSec(Self.caster.GetDegree()) * 100
		Local casterOffsetY:Float = SinFastSec(Self.caster.GetDegree()) * 100
		For Local i:Int = 0 To game.speed / 8
			pDegree = Rand(Self.degree+0, Self.degree + 360)
				TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.caster.GetMidY()),  ..  							' Effect group
				7500,..       			 								' Life time
				gsInGame.particleImgFire,..    								' Image
				Self.caster.GetMidX() + casterOffsetX, Self.caster.GetMidY() - casterOffsetY,  ..     						' Start position
				Self.caster.GetMidX() + casterOffsetX, Self.caster.GetMidY() - casterOffsetY,  ..     							' End position
				0.5, 0.01,..       									' Alpha
				360, 0,..       										' Rotation
				1, 1.5,..      										' Scale X (start, end)
				1, 1.5,..      										' Scale Y (start, end)
				255, 255, 255,..      									' Color (start)
				0, 0, 0..       		
		)
		Next

	End Method
	
	' Use
	Method Use()
		gsInGame.chanEffects.Play("ArcaneShadowOrb2")
		
			TArcaneShadowOrb2.Create(Self.caster, Self.caster.GetMidX() + CosFastSec(Self.caster.GetDegree()) * 100, Self.caster.GetMidY() - SinFastSec(Self.caster.GetDegree()) * 100, 10)
			End Method
	
	' GetName
	Method GetName:String() 
		Return "ArcaneShadowOrbs2"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		Return "Creates a radar of Shadow Orbs."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SArcaneShadowOrb2
		skill.Init(nCaster)
		Return skill
	End Function
End Type

' TDarkHole
Type TDarkHole Extends TShadowMagicInstance
	Field degree:Int
	Field lastHit:Int
	Field bonusDMG:Int
	Field speed:Float
	
	' Init
	Method Init(castedBy:TEntity, nX:Int, nY:Int, nbonusDMG:Int)
		Super.InitInstance(castedBy)
		Self.bonusDMG = nbonusDMG
		Self.degree = Self.caster.GetDegree()
		Self.maxRunTime = 10000
		Self.x = nX
		Self.y = nY
		Self.dmg = Rand(40, 50) + Self.bonusDMG
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Remove()
		EndIf
		
		Self.x :+ CosFastSec(Self.degree) * Self.speed * game.speed
		Self.y :- SinFastSec(Self.degree) * Self.speed * game.speed
		
		For Local I:Int = 0 To game.speed / 4
			Local Pillar:Float = Rand(0, 360)

			TParticleTween.Create( ..
				gsInGame.GetEffectGroup(Self.y),  ..
				2500,  ..
				gsInGame.particleImgIce,..
				Self.x , Self.y ,  ..
				Self.x + CosFast[Pillar] * Rand(30, 125), Self.y - SinFast[Pillar] * Rand(30, 125) * perspectiveFactor,  ..
				0.5, 0.01,  ..
				0, 360,  ..
				1.75, 0.5,  ..
				1.75, 0.5,  ..
				255, 255, 255,  ..
				0, 0, 0 ..
				..
			)
		Next
		' Collision
		If MilliSecs() - Self.lastHit >= 500
			Self.CheckRectCollision(Self.x - 3, Self.y - 3, 6, 6)
			Self.lastHit = MilliSecs()
		EndIf
	End Method
	
	' OnHit
	Method OnHit:Int()
		'Self.Remove()
		Return True
	End Method
	
	' Create
	Function Create:TDarkHole(castedBy:TEntity, nX:Int, nY:Int, nbonusDMG:Int = 10)
		Local skill:TDarkHole = New TDarkHole
		skill.Init(castedBy, nX, nY, nbonusDMG)
		Return skill
	End Function
End Type

' SDarkHole
Type SDarkHole Extends TShadowMagic
	Field radius:Float
	Field degree:Int
	' Init
	Method Init(nCaster:TEntity) 
		Super.Init(nCaster)
		Self.degree = Self.caster.GetDegree()
		
	End Method
	
	' Cast
	Method Cast() 
		Self.caster.Cast(Self)
		
		Local pDegree:Int
		pDegree = Self.caster.GetDegree()
		Local casterOffsetX:Float = CosFastSec(Self.caster.GetDegree()) * 100
		Local casterOffsetY:Float = SinFastSec(Self.caster.GetDegree()) * 100
		For Local i:Int = 0 To game.speed / 8
			pDegree = Rand(Self.degree+0, Self.degree + 360)
				TParticleTween.Create(..
				gsInGame.GetEffectGroup(Self.caster.GetMidY()),  ..  							' Effect group
				650,..       			 								' Life time
				gsInGame.particleImgFire,..    								' Image
				Self.caster.GetMidX() + casterOffsetX, Self.caster.GetMidY() - casterOffsetY,  ..     						' Start position
				Self.caster.GetMidX() + casterOffsetX, Self.caster.GetMidY() - casterOffsetY,  ..     							' End position
				0.5, 0.01,..       									' Alpha
				0, 360,..       										' Rotation
				1, 1.5,..      										' Scale X (start, end)
				1, 1.5,..      										' Scale Y (start, end)
				255, 255, 255,..      									' Color (start)
				0, 0, 0..       		
		)
		Next

	End Method
	
	' Use
	Method Use()
		gsInGame.chanEffects.Play("DarkHole")
		
			TDarkHole.Create(Self.caster, Self.caster.GetMidX() + CosFastSec(Self.caster.GetDegree()) * 100, Self.caster.GetMidY() - SinFastSec(Self.caster.GetDegree()) * 100, 10)
			End Method
	
	' GetName
	Method GetName:String() 
		Return "ArcaneShadowOrbs2"
	End Method
	
	' GetDescription
	Method GetDescription:String() 
		Return "Creates a radar of Shadow Orbs."
	End Method
	
	' Create
	Function Create:TSkill(nCaster:TEntity)
		Local skill:TSkill = New SDarkHole
		skill.Init(nCaster)
		Return skill
	End Function
End Type


