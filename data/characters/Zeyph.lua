function init()
	super.SetCharacterName("Zeyph")
	super.SetImageFile("Zeyph.png")
	super.LoadConfigFile("Zeyph.ini")
	
	super.InitStatus(1, 1000, 450)
	super.SetSpeed(0.2)
	
	super.CreateSkillSlots(4)
	
	-- Skills
	super.SetSlotSkill(0, "SwordSlash")
	super.SetSlotSkill(1, "IcyRays")
	super.SetSlotSkill(2, "IceWave")
	super.SetSlotSkill(3, "IcyFlames")
end