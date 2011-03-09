' Includes
Include "Buffs/Buffs.bmx"
Include "Buffs/DeBuffs.bmx"

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
	
	' Clear
	Method Clear()
		Self.list.Clear()
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
