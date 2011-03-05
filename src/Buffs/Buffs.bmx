
' TRecoveryBuff
Type TRecoveryBuff Extends TBuff
	Field heal:Int
	Field healInterval:Int
	Field lastHeal:Int
	
	' Init
	Method Init(nCaster:TEntity, nTarget:TEntity, nLifeTime:Int, nHeal:Int, nHealInterval:Int)
		Self.heal = nHeal
		Self.healInterval = nHealInterval
		Self.lastHeal = 0
		
		Super.InitBuff(nCaster, nTarget, nLifeTime)
	End Method
	
	' GetName
	Method GetName:String()
		Return "Recovery"
	End Method
	
	' GetDescription
	Method GetDescription:String()
		Return "Recovers " + Self.heal + " HP every " + Self.healInterval / 1000.0 + " seconds."
	End Method
	
	' OnBegin
	Method OnBegin()
		
	End Method
	
	' OnFrame
	Method OnFrame()
		If MilliSecs() - Self.lastHeal >= Self.healInterval
			Self.GetTarget().AddHP(Self.heal)
			Self.CreateHealingView(Self.heal)
			Self.lastHeal = MilliSecs()
		EndIf
	End Method
	
	' CreateHealingView
	Method CreateHealingView(heal:Int)
		TDamageView.Create(- heal, Self.caster.GetMidX() + Rand(- 12, 12), Self.caster.GetY() - Rand(0, 16) + TDamageView.dmgNumYOffset)
	End Method
	
	' OnEnd
	Method OnEnd()
		
	End Method
	
	' IsDebuff
	Method IsDebuff:Int()
		Return False
	End Method
	
	' Create
	Function Create:TRecoveryBuff(nCaster:TEntity, nTarget:TEntity, nLifeTime:Int, nHeal:Int, nHealInterval:Int)
		Local buff:TRecoveryBuff = New TRecoveryBuff
		buff.Init(nCaster, nTarget, nLifeTime, nHeal, nHealInterval)
		Return buff
	End Function
End Type
