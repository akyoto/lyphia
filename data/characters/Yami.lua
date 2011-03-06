function init()
	super.SetCharacterName("Yami")
	super.SetImageFile("Yami.png")
	super.LoadConfigFile("Yami.ini")
	
	super.InitStatus(1, 1000, 450)
	super.SetBaseSpeed(0.2)
	
	super.CreateSkillSlots(9)
	
	-- Skills
	super.SetSlotSkill(0, "SwordSlash")
	super.SetSlotSkill(1, "FireBall")
	super.SetSlotSkill(2, "FireBreath")
	super.SetSlotSkill(3, "Meteor")
	super.SetSlotSkill(4, "DarkMatter")
	super.SetSlotSkill(5, "Hurricane")
	super.SetSlotSkill(6, "SoulStrike")
	super.SetSlotSkill(7, "ArcaneShadowOrb2")
	super.SetSlotSkill(8, "DarkHole")
end