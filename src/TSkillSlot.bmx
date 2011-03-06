' Strict
SuperStrict

' Files
Import "TSlot.bmx"

' TSkillSlot
Type TSkillSlot Extends TSlot
	Field skillAdvanceTriggerList:TList
	
	' Init
	Method Init(nAction:TAction = Null)
		Super.Init(nAction)
		Self.skillAdvanceTriggerList = CreateList()
	End Method
	
	' AddSkillAdvanceTrigger
	Method AddSkillAdvanceTrigger(nTrigger:TTrigger)
		Self.skillAdvanceTriggerList.AddLast(nTrigger)
	End Method
	
	' GetTriggeredSkillAdvanceTrigger
	Method GetTriggeredSkillAdvanceTrigger:TTrigger()
		If Self.skillAdvanceTriggerList.IsEmpty() = 0
			' Check each trigger
			For Local trigger:TTrigger = EachIn Self.skillAdvanceTriggerList
				' If one of them is triggered, the action will be executed
				If trigger.Triggered()
					Return trigger
				EndIf
			Next
		Else
			Return Null
		EndIf
	End Method
	
	' Create
	Function Create:TSkillSlot(nAction:TAction = Null)
		Local slot:TSkillSlot = New TSkillSlot
		slot.Init(nAction)
		Return slot
	End Function
End Type
