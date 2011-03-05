
' TBuffContainer
Type TBuffContainer
	Field list:TList
	Field onAdd(buff:TBuff)
	Field onRemove(buff:TBuff)
	
	' Init
	Method Init()
		Self.list = CreateList()
		Self.onAdd = Null
		Self.onRemove = Null
	End Method
	
	' Add
	Method Add(buff:TBuff)
		buff.link = Self.list.AddLast(buff)
		If Self.onAdd <> Null
			Self.onAdd(buff)
		EndIf
	End Method
	
	' Update
	Method Update()
		For Local buff:TBuff = EachIn Self.list
			If buff.GetRemainingTime() <= 0
				buff.Remove()
				If Self.onRemove <> Null
					Self.onRemove(buff)
				EndIf
			Else
				buff.OnFrame()
			EndIf
		Next
	End Method
	
	' Create
	Function Create:TBuffContainer()
		Local buffcon:TBuffContainer = New TBuffContainer
		buffcon.Init()
		Return buffcon
	End Function
End Type

' TBuff
Type TBuff
	Field buffStartTime:Int
	Field lifeTime:Int
	Field link:TLink
	Field caster:TEntity
	Field target:TEntity
	Field img:TImage
	
	' InitBuff
	Method InitBuff(nCaster:TEntity, nTarget:TEntity, nLifeTime:Int)
		Self.buffStartTime = MilliSecs()
		
		Self.caster = nCaster
		Self.target = nTarget
		Self.lifeTime = nLifeTime
		
		' Load skill image
		Local buffName:String = GetTypeName(Self)
		Self.img = game.imageMgr.Get(buffName[1..buffName.length - 4])	' T[...]Buff
		
		If Self.IsDebuff()
			Self.target.GetDebuffContainer().Add(Self)
		Else
			Self.target.GetBuffContainer().Add(Self)
		EndIf
		
		Self.OnBegin()
	End Method
	
	' Remove
	Method Remove()
		If Self.link
			Self.link.Remove()
		EndIf
		Self.OnEnd()
	End Method
	
	' GetCaster
	Method GetCaster:TEntity()
		Return Self.caster
	End Method
	
	' GetTarget
	Method GetTarget:TEntity()
		Return Self.target
	End Method
	
	' GetStartTime
	Method GetStartTime:Int()
		Return Self.buffStartTime
	End Method
	
	' GetRemainingTime
	Method GetRemainingTime:Int()
		Return Max((Self.buffStartTime + Self.lifeTime) - MilliSecs(), 0)
	End Method
	
	' GetImage
	Method GetImage:TImage()
		Return Self.img
	End Method
	
	' Abstract
	Method OnBegin() Abstract
	Method OnFrame() Abstract
	Method OnEnd() Abstract
	Method GetName:String() Abstract
	Method GetDescription:String() Abstract
	Method IsDebuff:Int() Abstract
End Type

' TRecoveryBuff
Type TRecoveryBuff Extends TBuff
	Field heal:Int
	Field healInterval:Int
	Field lastHeal:Int
	
	' Init
	Method Init(nCaster:TEntity, nTarget:TEntity, nLifeTime:Int, nHeal:Int, nHealInterval:Int)
		Super.InitBuff(nCaster, nTarget, nLifeTime)
		Self.heal = nHeal
		Self.healInterval = nHealInterval
		Self.lastHeal = 0
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

' TImmobilizationDeBuff
Type TImmobilizationDeBuff Extends TBuff
	Field targetBaseSpeed:Float
	
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

