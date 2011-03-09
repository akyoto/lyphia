' Strict
SuperStrict

' Files
Import "../Global.bmx"
Import "../TArenaMode.bmx"

' TDeathMatchByKills
Type TDeathMatchByKills Extends TArenaMode
	Field killLimit:Int
	
	' Init
	Method Init(nLimit:Int)
		Self.img = game.imageMgr.Get("dm-2")
		MidHandleImage Self.img
		
		Self.SetKillLimit(nLimit)
	End Method
	
	' GetName
	Method GetName:String()
		Return "Death Match (by kills)"
	End Method
	
	' GetOptionsWidget
	Method GetOptionsWidget:TWidget()
		Return Null
	End Method
	
	' GetKillLimit
	Method GetKillLimit:Int()
		Return Self.killLimit
	End Method
	
	' SetKillLimit
	Method SetKillLimit(limit:Int)
		Self.killLimit = limit
	End Method
	
	' Update
	Method Update()
		For Local party:TParty = EachIn Self.parties
			If party.GetKillCount() >= Self.GetKillLimit()
				Self.SetWinnerParty(party)
				Return
			EndIf
		Next
	End Method
	
	' Create
	Function Create:TDeathMatchByKills(nKillLimit:Int)
		Local mode:TDeathMatchByKills = New TDeathMatchByKills
		mode.Init(nKillLimit)
		Return mode
	End Function
End Type