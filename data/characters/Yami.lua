function init()
	super.SetCharacterName("Yami")
	super.SetImageFile("Yami.png")
	super.LoadConfigFile("Yami.ini")
	
	super.InitStatus(1, 1000, 450)
	super.SetBaseSpeed(0.2)
	
	super.CreateSkillSlots(6)
	
	-- Skills
	super.SetSlotSkill(0, "SwordSlash")
	super.SetSlotSkill(1, "FireNuclease")
	super.SetSlotSkill(2, "ChainLightning")
	super.SetSlotSkill(3, "SoulStrike")
	super.SetSlotSkill(4, "DarkMatter")
	super.SetSlotSkill(5, "Meteor")
end