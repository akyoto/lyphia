' Strict
SuperStrict

' Files
Import "TTrigger.bmx"
Import "TAction.bmx"

' Init class
TSlot.InitClass()

' TSlot
Type TSlot
	Global list:TList
	
	Field triggerList:TList
	Field triggeredEarlier:Int
	Field action:TAction
	
	' Init
	Method Init(nAction:TAction = Null)
		Self.triggerList = CreateList() 
		Self.triggeredEarlier = False
		Self.SetAction(nAction)
	End Method
	
	' AddTrigger
	Method AddTrigger(nTrigger:TTrigger)
		Self.triggerList.AddLast(nTrigger)
	End Method
	
	' GetAction
	Method GetAction:TAction()
		Return Self.action
	End Method
	
	' SetAction
	Method SetAction(nAction:TAction)
		Self.action = nAction
	End Method
	
	' GetTriggeredTrigger
	Method GetTriggeredTrigger:TTrigger()
		If Self.triggerList.IsEmpty() = 0
			' Check each trigger
			For Local trigger:TTrigger = EachIn Self.triggerList
				' If one of them is triggered, the action will be executed
				If trigger.Triggered()
					Return trigger
				EndIf
			Next
		Else
			Return Null
		EndIf
	End Method
	
	' Exec
	Method Exec()
		If Self.action <> Null
			Self.action.Exec(Null)
		EndIf
	End Method
	
	' Update
	Method Update()
		If Self.action = Null
			Return
		EndIf
		
		Local trigger:TTrigger = Self.GetTriggeredTrigger()
		If trigger <> Null
			If Self.triggeredEarlier = False
				action.ExecStart(trigger)
				Self.triggeredEarlier = True
			EndIf
			Self.action.Exec(trigger)
		Else
			Self.triggeredEarlier = False
		EndIf
	End Method
	
	' WasTriggeredEarlier
	Method WasTriggeredEarlier:Int()
		Return Self.triggeredEarlier
	End Method
	
	' InitClass
	Function InitClass()
		TSlot.list = CreateList()
	End Function
	
	' Create
	Function Create:TSlot(nAction:TAction = Null)
		Local slot:TSlot = New TSlot
		slot.Init(nAction)
		Return slot
	End Function
End Type

' UpdateSlots
Function UpdateSlots(slotArray:TSlot[])
	' Check each slot in array
	For Local slot:TSlot = EachIn slotArray
		slot.Update()
	Next
End Function