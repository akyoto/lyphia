
' TParty
Type TParty
	Field id:Int
	Field name:String
	Field members:TList
	
	Field r:Int, g:Int, b:Int
	Field castR:Int, castG:Int, castB:Int
	
	' Init
	Method Init(nID:Int, nName:String)
		Self.name = nName
		Self.members = CreateList()
		
		Self.id = nID
	End Method
	
	' Add
	Method Add(nEntity:TEntity)
		nEntity.party = Self
		nEntity.partyLink = Self.members.AddLast(nEntity)
	End Method
	
	' Remove
	Method Remove(nEntity:TEntity)
		If nEntity.partyLink <> Null
			nEntity.partyLink.Remove()
		Else
			Throw "'" + nEntity.GetName() + "' has no party"
		EndIf
	End Method
	
	' SetColor
	Method SetColor(nR:Int, nG:Int, nB:Int)
		Self.r = nR
		Self.g = nG
		Self.b = nB
	End Method
	
	' SetCastColor
	Method SetCastColor(nR:Int, nG:Int, nB:Int)
		Self.castR = nR
		Self.castG = nG
		Self.castB = nB
	End Method
	
	' Clear
	Method Clear()
		For Local entity:TEntity = EachIn Self.members
			entity.SetKillCount(0)
			Self.Remove(entity)
		Next
	End Method
	
	' Contains
	Method Contains:Int(nEntity:TEntity)
		If nEntity = Null
			Return False
		EndIf
		Return nEntity.GetParty() = Self
	End Method
	
	' GetID
	Method GetID:Int()
		Return Self.id
	End Method
	
	' GetName
	Method GetName:String()
		Return Self.name
	End Method
	
	' GetKillCount
	Method GetKillCount:Int()
		Local kills:Int = 0
		For Local entity:TEntity = EachIn Self.members
			kills :+ entity.GetKillCount()
		Next
		Return kills
	End Method
	
	' GetByName
	Method GetByName:TEntity(nName:String)
		For Local entity:TEntity = EachIn Self.members
			If entity.GetName() = nName
				Return entity
			EndIf
		Next
	End Method
	
	' RemoveByName
	Method RemoveByName(nName:String)
		For Local entity:TEntity = EachIn Self.members
			If entity.GetName() = nName
				Self.Remove(entity)
				Return
			EndIf
		Next
	End Method
	
	' GetMembersList
	Method GetMembersList:TList()
		Return Self.members
	End Method
	
	' GetNumberOfMembers
	Method GetNumberOfMembers:Int()
		Return Self.members.Count()
	End Method
	
	' ToString
	Method ToString:String()
		Local stri:String = Self.name + ": "
		For Local entity:TEntity = EachIn Self.members
			stri :+ entity.GetName() + ", "
		Next
		Return stri[..stri.length - 2]
	End Method
	
	' Create
	Function Create:TParty(nID:Int, nName:String)
		Local party:TParty = New TParty
		party.Init(nID, nName)
		Return party
	End Function
End Type
