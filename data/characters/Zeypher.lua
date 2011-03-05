function init()
	super.SetCharacterName("Zeypher")
	super.SetImageFile("Zeypher.png")
	super.LoadConfigFile("Zeypher.ini")
	
	super.InitStatus(1, 1000, 450)
	super.SetBaseSpeed(0.2)
	
	super.CreateSkillSlots(4)
	
	-- Skills
	super.SetSlotSkill(0, "SwordSlash")
	super.SetSlotSkill(1, "IcyRays")
	super.SetSlotSkill(2, "IceWave")
	super.SetSlotSkill(3, "IcyFlames")
end