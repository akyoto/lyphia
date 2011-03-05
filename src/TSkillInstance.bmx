
' TSkillInstance
Type TSkillInstance
	' Link
	Field link:TLink
	
	' Position
	Field x:Float, y:Float
	
	' Damage
	Field dmg:Int
	Field caster:TEntity
	Field target:TEntity
	Field luaObject:TLuaObject
	
	' The time in millisecs it started
	Field started:Int
	
	' The time it persists
	Field maxRunTime:Int
	
	' Init
	Method InitInstance(castedBy:TEntity)
		Self.link = gsInGame.runningSkills.AddLast(Self) 
		Self.started = MilliSecs()
		Self.maxRunTime = 0
		
		Self.caster = castedBy
		Self.target = Null
		Self.x = Self.caster.GetMidX()
		Self.y = Self.caster.GetMidY()
		
		'Self.luaObject = luaScript.CreateInstance(Self)
		'Self.luaObject.Invoke("init", Null)
	End Method
	
	' SetPosition
	Method SetPosition(nX:Int, nY:Int)
		Self.x = nX
		Self.y = nY
	End Method
	
	' GetRunTime
	Method GetRunTime:Int() 
		Return MilliSecs() - Self.started
	End Method
	
	' GetRunTimeProgress
	Method GetRunTimeProgress:Float()
		Return Self.GetRunTime() / Float(Self.maxRunTime)
	End Method
	
	' DoHit
	Method DoHit:Int(enemy:TEntity)
		' Damage
		enemy.LoseHP(Self.dmg, Self.caster)
		TDamageView.Create(Self.dmg, enemy.GetMidX() + Rand(- 12, 12), enemy.GetY() - Rand(0, 16) + TDamageView.dmgNumYOffset)
		
		Self.target = enemy
		
		Return Self.OnHit()
	End Method
	
	' CheckCollision
	' TODO: Return collision status
	Method CheckRectCollision(x:Int, y:Int, width:Int, height:Int)
		If TPlayer(Self.caster)
			' Collision with an enemy
			Local enemy:TEntity
			
			For enemy = EachIn gsInGame.enemiesOnScreen
				If enemy <> Null
					If RectInRect(x, y, width, height, enemy.x, enemy.y, enemy.img.width, enemy.img.height)
						If Self.DoHit(enemy) = False
							Return
						EndIf
					EndIf
				EndIf
			Next
			
			' Network players
			For Local party:TParty = EachIn gsInGame.parties
				If party = Self.caster.GetParty()
					Continue
				EndIf
				
				For enemy = EachIn party.GetMembersList()
					If RectInRect(x, y, width, height, enemy.x, enemy.y, enemy.img.width, enemy.img.height)
						If Self.DoHit(enemy) = False
							Return
						EndIf
					EndIf
				Next
			Next
		Else
			Local ctarget:TEntity = Self.caster.target
			If RectInRect(x, y, width, height, ctarget.x, ctarget.y, ctarget.img.width, ctarget.img.height)
				If Self.DoHit(ctarget) = False
					Return
				EndIf
			EndIf
		EndIf
	End Method
	
	' CheckCircleCollision
	' TODO: Return collision status
	Method CheckCircleCollision(x:Int, y:Int, radius:Int)
		If TPlayer(Self.caster)
			' Collision with an enemy
			Local enemy:TEntity
			
			For enemy = EachIn gsInGame.enemiesOnScreen
				If enemy <> Null
					If CircleInRect(x, y, radius, enemy.x, enemy.y, enemy.img.width, enemy.img.height)
						If Self.DoHit(enemy) = False
							Return
						EndIf
					EndIf
				EndIf
			Next
			
			' Network players
			For Local party:TParty = EachIn gsInGame.parties
				If party = Self.caster.GetParty()
					Continue
				EndIf
				
				For enemy = EachIn party.GetMembersList()
					If CircleInRect(x, y, radius, enemy.x, enemy.y, enemy.img.width, enemy.img.height)
						If Self.DoHit(enemy) = False
							Return
						EndIf
					EndIf
				Next
			Next
		Else
			' TODO: Enemies' skill collision
			Local ctarget:TEntity = Self.caster.target
			If CircleInRect(x, y, radius, ctarget.x, ctarget.y, ctarget.img.width, ctarget.img.height)
				If Self.DoHit(ctarget) = False
					Return
				EndIf
			EndIf
		EndIf
	End Method
	
	' Run
	Method Run()
		If Self.GetRunTime() > Self.maxRunTime
			Self.Remove()
		EndIf
		
		'Self.luaObject.Invoke("run", Null)
	End Method
	
	' OnHit
	Method OnHit:Int()
		'Self.luaObject.Invoke("onHit", Null)
		Return True
	End Method
	
	' OnRemove
	Method OnRemove()
		'Self.luaObject.Invoke("onRemove", Null)
	End Method
	
	' Remove
	Method Remove()
		Self.OnRemove()
		Self.link.Remove()
	End Method
End Type
