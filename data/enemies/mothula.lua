function init()
	super.SetName("Mothula")
	super.SetImageFile("mothula.png")
	super.InitStatus(1, 160, 200)
	super.SetSpeed(0.1)
	super.CreateSkillSlots(1)
	
	-- 0
	super.SetSlotSkill(0, "FireBall")
	nTrigger = trigger.LineRange(super)
	super.AddSlotTrigger(0, nTrigger)
end