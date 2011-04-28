function init()
	super.SetCharacterName("Kimiko")
	super.SetImageFile("Kimiko.png")
	super.LoadConfigFile("Kimiko.ini")
	
	super.InitStatus(1, 1000, 450)
	super.SetBaseSpeed(0.2)
	
	super.CreateSkillSlots(4)
	
	-- Skills
	super.SetSlotSkill(0, "SwordSlash")
	super.SetSlotSkill(1, "FireBall")
	super.SetSlotSkill(2, "FireBreath")
	super.SetSlotSkill(3, "Meteor")
end