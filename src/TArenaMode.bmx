' Strict
SuperStrict

' Files
Import "Global.bmx"
Import "TEntity.bmx"
Import "GUI/TGUI.bmx"

' TArenaMode
Type TArenaMode
	Field img:TImage
	Field parties:TParty[]
	Field winnerTeam:TParty
	Field startTime:Int
	Field endTime:Int
	
	' New
	Method New()
		Self.parties = Null
		Self.winnerTeam = Null
	End Method
	
	' Reset
	Method Reset()
		Self.winnerTeam = Null
		
		For Local party:TParty = EachIn Self.parties
			For Local entity:TEntity = EachIn party.GetMembersList()
				entity.Reset()
			Next
		Next
	End Method
	
	' Start
	Method Start()
		Self.startTime = MilliSecs()
		Self.endTime = 0
	End Method
	
	' GetParties
	Method GetParties:TParty[]()
		Return Self.parties
	End Method
	
	' SetParties
	Method SetParties(parties:TParty[])
		Self.parties = parties
	End Method
	
	' SetWinnerParty
	Method SetWinnerParty:TParty(team:TParty)
		If Self.winnerTeam = Null
			Self.endTime = MilliSecs()
			Self.winnerTeam = team
		EndIf
	End Method
	
	' GetWinnerParty
	Method GetWinnerParty:TParty()
		Return Self.winnerTeam
	End Method
	
	' HasEnded
	Method HasEnded:Int()
		Return Self.winnerTeam <> Null
	End Method
	
	' GetDuration
	Method GetDuration:Int()
		Return Self.endTime - Self.startTime
	End Method
	
	' GetStartTime
	Method GetStartTime:Int()
		Return Self.startTime
	End Method
	
	' GetEndTime
	Method GetEndTime:Int()
		Return Self.endTime
	End Method
	
	' Abstract
	Method Update() Abstract
	Method GetOptionsWidget:TWidget() Abstract
	Method GetName:String() Abstract
End Type