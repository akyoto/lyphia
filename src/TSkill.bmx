
' TSkill
Type TSkill Extends TAction
	' Skill preview
	Field img:TImage
	
	' Lua
	Field luaScript:TLuaScript
	Field luaObject:TLuaObject
	
	' Who casts it
	Field caster:TEntity
	
	' HP cost
	Field hpCostAbs:Int
	Field hpCostRel:Float
	
	' MP cost
	Field mpCostAbs:Int
	Field mpCostRel:Float
	
	' Cooldown
	Field cooldown:Int
	Field lastCast:Int
	
	' Time to cast the spell (in milliseconds)
	Field castTime:Int
	Field castStarted:Int
	Field canMoveWhileCasting:Int
	
	' Following skill
	Field followUpSkill:TSkill
	Field preSkill:TSkill
	Field hasBeenAdvanced:Int
	Field slot:TSkillSlot
	
	' Network
	Field endSkillSent:Int
	
	' Init
	Method Init(nCaster:TEntity)	'skillName:String, 
		Self.hpCostAbs = 0
		Self.hpCostRel = 0.0
		Self.mpCostAbs = 0
		Self.mpCostRel = 0.0
		Self.cooldown = 0
		Self.lastCast = 0
		Self.castTime = 0
		Self.canMoveWhileCasting = 0
		
		Self.SetCaster(nCaster)
		
		' Determine skill name by object type name
		Local skillName:String = GetTypeName(Self)[1..]
		
		' Lua script
		Self.luaScript = game.scriptMgr.Get(skillName)
		If Self.luaScript <> Null
			Self.luaObject = Self.luaScript.CreateInstance(Self)
			Self.luaObject.Invoke("init", Null)
		EndIf
		
		' Cheat !!!
		If 0'Self.caster.luaScript = Null
			Self.cooldown = 0
			Self.mpCostAbs = 0
			Self.mpCostRel = 0
			'Self.castTime = 0
			Self.canMoveWhileCasting = 1
		EndIf
		
		Self.img = game.imageMgr.Get(skillName)
		Self.followUpSkill = Null
	End Method
	
	' SetFollowUpSkill
	Method SetFollowUpSkill(skill:TSkill)
		Self.followUpSkill = skill
		skill.preSkill = Self
	End Method
	
	' CanBeCasted
	Method CanBeCasted:Int()
		Return MilliSecs() - Self.lastCast > Self.cooldown And Self.caster.HasEnoughMP(Self.mpCostAbs, Self.mpCostRel)
	End Method
	
	' CanBeAdvanced
	Method CanBeAdvanced:Int()
		Return Self.followUpSkill <> Null
	End Method
	
	' Exec
	Method Exec(trigger:TTrigger)
		If Self.CanBeCasted()
			If trigger = Null Or Self.caster.IsPlayer() = Null
				Self.castStarted = MilliSecs()
				Self.Cast()
				Self.endSkillSent = False
			EndIf
		Else
			' TODO: Print info message
		EndIf
	End Method
	
	' GetAdvancementLevel
	Method GetAdvancementLevel:Int()
		Local skill:TSkill = Self
		Local level:Int = 0
		
		While skill.preSkill <> Null
			level :+ 1
			skill = skill.preSkill
		Wend
		
		Return level
	End Method
	
	' GetCastProgress
	Method GetCastProgress:Float()
		If Self.castTime = 0
			Return 1.0
		EndIf
		Return Min(1, (MilliSecs() - Self.castStarted) / Float(Self.castTime))
	End Method
	
	' GetCastProgressLeft
	Method GetCastProgressLeft:Float()
		If Self.castTime = 0
			Return 0.0
		EndIf
		Return Max(0, 1.0 - (MilliSecs() - Self.castStarted) / Float(Self.castTime))
	End Method
	
	' GetCastTime
	Method GetCastTime:Int()
		Return Self.castTime
	End Method
	
	' GetCooldown
	Method GetCooldown:Int()
		Return Self.cooldown
	End Method
	
	' GetMPCostAsString
	Method GetMPCostAsString:String()
		If Self.mpCostRel <> 0
			Return Self.mpCostAbs + " + " + FloatToReadableString(Self.mpCostRel * 100) + "%"
		Else
			Return Self.mpCostAbs
		EndIf
	End Method
	
	' GetCooldownProgress
	Method GetCooldownProgress:Float()
		If Self.cooldown = 0
			Return 1.0
		EndIf
		Return Min(1, (MilliSecs() - Self.lastCast) / Float(Self.cooldown))
	End Method
	
	' GetCooldownProgressLeft
	Method GetCooldownProgressLeft:Float()
		If Self.cooldown = 0
			Return 0.0
		EndIf
		Return Max(0, 1.0 - (MilliSecs() - Self.lastCast) / Float(Self.cooldown))
	End Method
	
	' DelayCast
	Method DelayCast(byTime:Int)
		Self.castStarted:+byTime
	End Method
	
	' SetSlot
	Method SetSlot(nSlot:TSkillSlot)
		Self.slot = nSlot
		
		If Self.followUpSkill <> Null
			Self.followUpSkill.SetSlot(Self.slot)
		EndIf
	End Method
	
	' SetCaster
	Method SetCaster(nCaster:TEntity)
		Self.caster = nCaster
	End Method
	
	' GoingToAdvance
	Method GoingToAdvance:Int()
		Return Self.followUpSkill <> Null And Self.followUpSkill.CanBeCasted() And Self.slot.GetTriggeredSkillAdvanceTrigger() <> Null
	End Method
	
	' GetSlot
	Method GetSlot:TSlot()
		Return Self.slot
	End Method
	
	' Advance
	Method Advance()
		' Start the next skill
		Self.followUpSkill.Exec(Null)
		
		' Set flag to true
		Self.hasBeenAdvanced = True
		
		' Set the flag for the pre skill to False
		'If Self.preSkill <> Null
		'	Self.preSkill.hasBeenAdvanced = False
		'EndIf
		
		Self.GetSlot().SetAction(Self.followUpSkill)
	End Method
	
	' Start
	Method Start()
		If Self.caster <> Null And Self.CanBeCasted()
			Self.lastCast = MilliSecs()
			Self.caster.UseMP(Self.mpCostAbs, Self.mpCostRel)
			Self.Use()
		EndIf
	End Method
	
	' Cast
	Method Cast() Abstract
	'	Self.luaObject.Invoke("cast", Null)
	'End Method
	
	' Use
	Method Use() Abstract
	'	Self.luaObject.Invoke("use", Null)
	'End Method
		
	' TODO: Localization
	Method GetName:String() Abstract
	Method GetDescription:String() Abstract
	
	Rem
	' Create
	Function Create:TSkill(skillName:String, nCaster:TEntity)
		Local skill:TSkill = New TSkill
		skill.Init(skillName, nCaster)
		Return skill
	End Function
	End Rem
End Type
