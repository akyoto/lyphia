' Strict
SuperStrict

' Files
Import "Global.bmx"
Import "Utilities/Math.bmx"
Import "Utilities/Graphics.bmx"
Import "Utilities/Reflection.bmx"
Import "TEntity.bmx"
Import "TTrigger.bmx"
Import "TLua.bmx"
Import "AStar.bmx"

' TEnemy
Type TEnemy Extends TEntity
	Field spawn:TEnemySpawn
	Field path:TList
	Field link:TLink
	
	Field hasRangeSkills:Int
	
	' Init
	Method Init(scriptFile:String)
		Super.Init(scriptFile)
		'Super.InitStatus(1, 250, 230)
		
		Self.spawn = Null
		Self.path = Null
		Self.link = Null
		Self.target = Null
		
		Self.hasRangeSkills = True
	End Method
	
	' SetImageFile
	Method SetImageFile(nFile:String)
		' TODO: Remove hardcoded stuff
		SetMaskColor 255, 255, 255
		
		Self.img = LoadAnimImage(FS_ROOT + "data/enemies/" + nFile, 24, 32, 0, 24, MIPMAPPEDIMAGE)
	End Method
	
	' Draw
	Method Draw()
		' Offset
		Self.grpWeaponEffects.SetOffset(Self.GetX(), Self.GetY())
		
		SetColor 255, 255, 255
		If Self.animAttack.GetDirection() = TAnimationAttack.DIRECTION_UP
			Self.grpWeaponEffects.Draw()
			ResetMax2D()
			DrawImage Self.img, Int(Self.x), Int(Self.y), Self.currentAnimation.GetFrame()
		Else
			DrawImage Self.img, Int(Self.x), Int(Self.y), Self.currentAnimation.GetFrame()
			Self.grpWeaponEffects.Draw()
			ResetMax2D()
		EndIf
		
		' Draw HP and MP
		If Self.target <> Null
			SetColor 0, 0, 0
			DrawRectOutline Int(Self.x), Int(Self.y) - 13, Self.img.width, 5
			SetColor 255, 0, 0
			DrawRect Int(Self.x) + 1, Int(Self.y) - 12, (Self.hp / Self.maxHP) * (Self.img.width - 2), 3
			
			SetColor 0, 0, 0
			DrawRectOutline Int(Self.x), Int(Self.y) - 8, Self.img.width, 5
			SetColor 0, 0, 255
			DrawRect Int(Self.x) + 1, Int(Self.y) - 7, (Self.mp / Self.maxMP) * (Self.img.width - 2), 3
		EndIf
	End Method
	
	' DrawInEditor
	Method DrawInEditor(scaleX:Float, scaleY:Float)
		DrawImage Self.img, Self.x * scaleX, Self.y * scaleY, Self.currentAnimation.GetFrame()
	End Method
	
	' Update
	Method Update()
		'Self.currentAnimation.Play()
		
		' HP regen
		If MilliSecs() - Self.lastHPRegen >= 1000
			Self.AddHP(Self.maxHP * Self.hpRegen)
			Self.lastHPRegen = MilliSecs()
		End If
		
		' MP regen
		If MilliSecs() - Self.lastMPRegen >= 1000
			Self.AddMP(Self.maxMP * Self.mpRegen)
			Self.lastMPRegen = MilliSecs()
		End If
		
		' Buffs
		Self.UpdateBuffs()
	End Method
	
	' Die
	Method Die()
		' Remove from spawn
		Self.spawn.enemy = Null
		Self.spawn = Null
		
		' Remove from visible list
		If Self.link
			Self.link.Remove()
			Self.link = Null
		EndIf
		
		Self.target = Null
		
		GCCollect()
	End Method
	
	' Create
	Function Create:TEnemy(scriptFile:String)
		Local enemy:TEnemy = New TEnemy
		enemy.Init(scriptFile)
		Return enemy
	End Function
End Type

' TAITriggerFactory
Type TAITriggerFactory
	Global instance:TAITriggerFactory = New TAITriggerFactory
	
	' HealSelf
	Method HealSelf:TAIHealSelfTrigger(nEntity:TEntity, hpPercentage:Float)
		Return TAIHealSelfTrigger.Create(nEntity, hpPercentage)
	End Method
	
	' LineRange
	Method LineRange:TAILineRangeTrigger(nEntity:TEntity)
		Return TAILineRangeTrigger.Create(nEntity)
	End Method
	
	' CircleRange
	Method CircleRange:TAICircleRangeTrigger(nEntity:TEntity, nDistance:Int)
		Return TAICircleRangeTrigger.Create(nEntity, nDistance)
	End Method
End Type
LuaRegisterObject(TAITriggerFactory.instance, "trigger")

' TAIHealSelfTrigger
Type TAIHealSelfTrigger Extends TTrigger
	Field entity:TEntity
	Field lowHP:Float
	
	' Init
	Method Init(nEntity:TEntity, hpPercentage:Float)
		Self.entity = nEntity
		Self.lowHP = hpPercentage
	End Method
	
	' Triggered
	Method Triggered:Int()
		Return (Self.entity.hp / Self.entity.maxHP) < Self.lowHP	' e.g. lower than 10% of own HP
	End Method
	
	' Create
	Function Create:TAIHealSelfTrigger(nEntity:TEntity, hpPercentage:Float)
		Local t:TAIHealSelfTrigger = New TAIHealSelfTrigger
		t.Init(nEntity, hpPercentage)
		Return t
	End Function
End Type

' TAILineRangeTrigger
Type TAILineRangeTrigger Extends TTrigger
	Field entity:TEntity
	
	' Init
	Method Init(nEntity:TEntity)
		Self.entity = nEntity
	End Method
	
	' Triggered
	Method Triggered:Int()
		Return TEntity.OnSameLine(Self.entity, Self.entity.target)
	End Method
	
	' Create
	Function Create:TAILineRangeTrigger(nEntity:TEntity)
		Local t:TAILineRangeTrigger = New TAILineRangeTrigger
		t.Init(nEntity)
		Return t
	End Function
End Type

' TAICircleRangeTrigger
Type TAICircleRangeTrigger Extends TTrigger
	Field entity:TEntity
	Field distSq:Int
	
	' Init
	Method Init(nEntity:TEntity, nDistance:Int)
		Self.entity = nEntity
		Self.distSq = nDistance * nDistance
	End Method
	
	' Triggered
	Method Triggered:Int()
		Return DistanceSq(Self.entity.x, Self.entity.y, Self.entity.target.x, Self.entity.target.y) <= Self.distSq
	End Method
	
	' Create
	Function Create:TAICircleRangeTrigger(nEntity:TEntity, nDistance:Int)
		Local t:TAICircleRangeTrigger = New TAICircleRangeTrigger
		t.Init(nEntity, nDistance)
		Return t
	End Function
End Type

' TEnemySpawn
Type TEnemySpawn
	Field enemy:TEnemy
	Field enemyType:String
	Field tileX:Int
	Field tileY:Int
	Field posX:Int
	Field posY:Int
	
	' Init
	Method Init(nEnemyType:String, nTileX:Int, nTileY:Int, nPosX:Int, nPosY:Int)
		Self.tileX = nTileX
		Self.tileY = nTileY
		Self.posX = nPosX
		Self.posY = nPosY
		Self.enemyType = nEnemyType
		Self.enemy:TEnemy = TEnemy.Create(Self.enemyType)
		Self.enemy.spawn = Self
		Self.enemy.x = Self.posX
		Self.enemy.y = Self.posY
	End Method
	
	' Create
	Function Create:TEnemySpawn(nEnemyType:String, nTileX:Int, nTileY:Int, nPosX:Int, nPosY:Int)
		Local enemySpawn:TEnemySpawn = New TEnemySpawn
		enemySpawn.Init(nEnemyType:String, nTileX, nTileY, nPosX, nPosY)
		Return enemySpawn
	End Function
End Type