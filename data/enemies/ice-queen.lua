function init()
	super.SetName("Ice Queen")
	super.SetImageFile("ice-queen.png")
	super.InitStatus(3, 250, 230)
	super.SetSpeed(0.2)
	super.CreateSkillSlots(3)
	
	-- 0
	super.SetSlotSkill(0, "IceWave")
	nTrigger = trigger.CircleRange(super, 64)
	super.AddSlotTrigger(0, nTrigger)
	
	-- 1
	super.SetSlotSkill(1, "HealingWind")
	nTrigger = trigger.HealSelf(super, 0.2)
	super.AddSlotTrigger(1, nTrigger)
	
	-- 2
	super.SetSlotSkill(2, "FireBall")
	nTrigger = trigger.LineRange(super)
	super.AddSlotTrigger(2, nTrigger)
end