function init()
	super.SetCharacterName("Kyuji")
	super.SetImageFile("Kyuji.png")
	super.LoadConfigFile("Kyuji.ini")
	
	super.InitStatus(1, 1000, 450)
	super.SetBaseSpeed(0.2)
	
	super.CreateSkillSlots(4)
	
	-- Skills
	super.SetSlotSkill(0, "SwordSlash")
	super.SetSlotSkill(1, "Cleave")
	super.SetSlotSkill(2, "Hurricane")
	super.SetSlotSkill(3, "HealingWind")
end