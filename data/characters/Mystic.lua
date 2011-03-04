function init()
	super.SetCharacterName("Mystic")
	super.SetImageFile("Mystic.png")
	super.LoadConfigFile("Mystic.ini")
	
	super.InitStatus(1, 1000, 450)
	super.SetSpeed(0.2)
	
	super.CreateSkillSlots(3)
	
	-- Skills
	super.SetSlotSkill(0, "SwordSlash")
	super.SetSlotSkill(1, "ThunderSphere")
	super.SetSlotSkill(2, "ChainLightning")
end