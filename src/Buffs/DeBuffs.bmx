
' TSlowDeBuff
Type TSlowDeBuff Extends TBuff
	Field slowFactor:Float
	
	' Init
	Method Init(nCaster:TEntity, nTarget:TEntity, nLifeTime:Int, nSlowFactor:Float)
		Self.slowFactor = nSlowFactor
		
		Super.InitBuff(nCaster, nTarget, nLifeTime)
	End Method
	
	' GetName
	Method GetName:String()
		Return "Slow"
	End Method
	
	' GetDescription
	Method GetDescription:String()
		Return "Slows the target by " + Int(Self.slowFactor * 100) + " % for " + Self.lifeTime / 1000.0 + " seconds."
	End Method
	
	' OnBegin
	Method OnBegin()
		Self.target.AddSpeedMultiplier(-Self.slowFactor)
	End Method
	
	' OnFrame
	Method OnFrame()
		
	End Method
		
	' OnEnd
	Method OnEnd()
		Self.target.AddSpeedMultiplier(Self.slowFactor)
	End Method
	
	' IsDebuff
	Method IsDebuff:Int()
		Return True
	End Method
	
	' Create
	Function Create:TSlowDeBuff(nCaster:TEntity, nTarget:TEntity, nLifeTime:Int, nSlowFactor:Float)
		Local buff:TSlowDeBuff = New TSlowDeBuff
		buff.Init(nCaster, nTarget, nLifeTime, nSlowFactor)
		Return buff
	End Function
End Type

' TImmobilizationDeBuff
Type TImmobilizationDeBuff Extends TBuff
	' Init
	Method Init(nCaster:TEntity, nTarget:TEntity, nLifeTime:Int)
		Super.InitBuff(nCaster, nTarget, nLifeTime)
	End Method
	
	' GetName
	Method GetName:String()
		Return "Immobilization"
	End Method
	
	' GetDescription
	Method GetDescription:String()
		Return "Immobilizes the target for " + Self.lifeTime / 1000.0 + " seconds."
	End Method
	
	' OnBegin
	Method OnBegin()
		Self.target.AddSpeedMultiplier(-1.0)
	End Method
	
	' OnFrame
	Method OnFrame()
		
	End Method
		
	' OnEnd
	Method OnEnd()
		Self.target.AddSpeedMultiplier(1.0)
	End Method
	
	' IsDebuff
	Method IsDebuff:Int()
		Return True
	End Method
	
	' Create
	Function Create:TImmobilizationDeBuff(nCaster:TEntity, nTarget:TEntity, nLifeTime:Int)
		Local buff:TImmobilizationDeBuff = New TImmobilizationDeBuff
		buff.Init(nCaster, nTarget, nLifeTime)
		Return buff
	End Function
End Type

' TBurnDeBuff
Type TBurnDeBuff Extends TBuff
	Field tickDmg:Int
	Field tickInterval:Int
	Field lastTick:Int
	
	' Init
	Method Init(nCaster:TEntity, nTarget:TEntity, nLifeTime:Int, nTickDmg:Int, nTickInterval:Int)
		Self.tickDmg = nTickDmg
		Self.tickInterval = nTickInterval
		
		Super.InitBuff(nCaster, nTarget, nLifeTime)
	End Method
	
	' GetName
	Method GetName:String()
		Return "Burn"
	End Method
	
	' GetDescription
	Method GetDescription:String()
		Return "Deals " + Self.tickDmg + " damage every " + Self.tickInterval / 1000.0 + " seconds."
	End Method
	
	' OnBegin
	Method OnBegin()
		
	End Method
	
	' OnFrame
	Method OnFrame()
		If MilliSecs() - Self.lastTick >= Self.tickInterval
			Self.GetTarget().LoseHP(Self.tickDmg, Self.caster)
			Self.CreateDmgView(Self.tickDmg)
			Self.lastTick = MilliSecs()
		EndIf
	End Method
		
	' OnEnd
	Method OnEnd()
		
	End Method
	
	' CreateDmgView
	Method CreateDmgView(dmg:Int)
		TDamageView.Create(dmg, Self.target.GetMidX() + Rand(- 12, 12), Self.target.GetY() - Rand(0, 16) + TDamageView.dmgNumYOffset)
	End Method
	
	' IsDebuff
	Method IsDebuff:Int()
		Return True
	End Method
	
	' Create
	Function Create:TBurnDeBuff(nCaster:TEntity, nTarget:TEntity, nLifeTime:Int, nTickDmg:Int, nTickInterval:Int)
		Local buff:TBurnDeBuff = New TBurnDeBuff
		buff.Init(nCaster, nTarget, nLifeTime, nTickDmg, nTickInterval)
		Return buff
	End Function
End Type
