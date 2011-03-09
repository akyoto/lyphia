' Strict
SuperStrict

' Modules
Import BRL.Max2D
'Import BtbN.GLDraw2D
Import BRL.Reflection
Import PUB.FreeJoy

' Files
Import "../TGame.bmx"
Import "../TFrameRate.bmx"
Import "../TPlayer.bmx"
Import "../TEnemy.bmx"
Import "../TTileMap.bmx"
Import "../TINILoader.bmx"
Import "../TSlot.bmx"
Import "../TArenaMode.bmx"
Import "../TDamageView.bmx"
Import "../Multiplayer/TRoom.bmx"
Import "../Multiplayer/TServer.bmx"
Import "../GUI/TGUI.bmx"
Import "../Utilities/Math.bmx"
Import "../Utilities/Graphics.bmx"
Import "../Utilities/Reflection.bmx"
Import "../ArenaModes/TDeathMatchByKills.bmx"

' Includes
Include "../TSkillInstance.bmx"
Include "../SkillTypes.bmx"
Include "../Skills.bmx"

' Global
Global gsInGame:TGameStateInGame

' Const
Const perspectiveFactor:Float = 0.75

' TGameStateInGame
Type TGameStateInGame Extends TGameState
	' Factor for Y coordinates
	
	Field player:TPlayer
	Field map:TTileMap
	Field frameCounter:TFrameRate
	Field enemiesOnScreen:TList
	Field scriptCoords:TMap
	Field currentScriptName:String
	Field oldHP:Float
	Field lastHPUpdate:Int
	Field arenaMode:TArenaMode
	
	' Walk
	Field walkX:Float
	Field walkY:Float
	
	' Slots
	Field moveSlots:TSlot[]
	Field otherSlots:TSlot[]
	
	' Skills
	Field runningSkills:TList
	
	' Particle groups
	Field grpSkillEffects:TParticleGroup[]
	Field grpPostEffects:TParticleGroup
	Field grpGuiEffects:TParticleGroup
	
	' Threads
	?Threaded
		Field grpSkillEffectsCleanThread:TThread
		Field threadsRunning:Int
	?Not Threaded
		Field lastParticleClear:Int
	?
	
	' Sound
	Field chanEffects:TSoundChannel
	
	' GUI
	Field gui:TGUI
	Field guiFont:TImageFont
	Field guiFontTitle:TImageFont
	Field dmgFont:TImageFont
	Field regionPreviewFont:TImageFont
	Field playerTitleFont:TImageFont
	Field inGameChatFont:TImageFont
	Field arenaBroadcastFont:TImageFont
	
	Field skillView:TContainer
	Field skillCastBar:TProgressBar
	Field buffView:TWidget
	Field debuffView:TWidget
	
	' TODO: Remove hardcoded stuff
	Field deadZone:Float = 0.5
	Field imgMP:TImage
	Field imgMPFull:TImage
	Field imgHP:TImage[4]
	
	' Particles
	Field particleImg:TImage
	Field particleImgIce:TImage
	Field particleImgWind:TImage
	Field particleImgFire:TImage
	Field weaponSword:TImage
	
	' Status
	Field statusX:Int, statusY:Int
	Field tileX:Int, tileY:Int
	
	Field isPausedFlag:Int
	Field pauseTextWritten:Int
	
	' Network
	Field inNetworkMode:Int
	Field parties:TParty[]
	Field room:TRoom
	Field server:TServer
	Field arenaGUI:TGUI
	
	Field pingSent:Int
	
	Field netWalkX:Byte
	Field netWalkY:Byte
	
	Field lastArenaUpdate:Int
	Field lastPingCheck:Int
	
	Field returnToArena:Int
	
	' Init
	Method Init()
		'Self.inNetworkMode = False
		
		' Register global game object
		game.logger.Write("Registering global script variables")
		LuaRegisterObject(TParticleFactory.instance, "particleSystem")
		
		' Pause flag
		Self.isPausedFlag = False
		Self.pauseTextWritten = 0	' times
		
		' This will save the position of teleport scripts
		Self.scriptCoords = CreateMap()
		
		' Frame counter
		Self.frameCounter = TFrameRate.Create()
		
		' Resources
		Self.InitResources()
		
		' Enemies
		game.logger.Write("Creating enemy list")
		Self.enemiesOnScreen = CreateList()
		
		' Create player
		game.logger.Write("Initializing player")
		
		If Self.inNetworkMode = False
			Self.player = TPlayer.Create("Zeypher")
			
			Self.parties = New TParty[1]
			Self.parties[0] = TParty.Create(0, "My party")
			Self.parties[0].Add(Self.player)
		Else
			Self.netWalkX = 0
			Self.netWalkY = 0
		EndIf
		
		' TODO: player.SetPosition()
		Self.player.SetMPEffectFunc(TGameStateInGame.AddMPEffect)
		Self.player.GetBuffContainer().onAdd = TGameStateInGame.OnBuffAdd
		Self.player.GetDebuffContainer().onAdd = TGameStateInGame.OnBuffAdd
		Self.player.GetBuffContainer().onRemove = TGameStateInGame.OnBuffRemove
		Self.player.GetDebuffContainer().onRemove = TGameStateInGame.OnBuffRemove
		
		' Load map
		game.logger.Write("Loading map")
		Self.map = TTileMap.Create()
		Self.map.LoadINI(FS_ROOT + "data/layers/tilemap.ini")
		Self.map.SetScreenSize(game.gfxWidth, game.gfxHeight)
		Self.map.InitTextureAtlas()
		Self.map.LoadLayers(FS_ROOT + "data/layers/layer-")
		
		If Self.inNetworkMode
			Self.ChangeMap("arena_01")
		Else
			Self.ChangeMap("lyphia")
		EndIf
		
		' TODO: Remove hardcoded stuff
		Self.moveSlots = New TSlot[5]
		Self.otherSlots = New TSlot[2]
		
		' Move slots
		game.logger.Write("Setting up movement slots")
		Self.moveSlots[0] = TSlot.Create(TActionMove.Create(TAnimationWalk.DIRECTION_UP))
		Self.moveSlots[0].AddTrigger(TKeyTrigger.Create(KEY_UP, True))
		Self.moveSlots[0].AddTrigger(TJoyHatTrigger.Create(TJoyHatTrigger.AXIS_Y, -1))
		
		Self.moveSlots[1] = TSlot.Create(TActionMove.Create(TAnimationWalk.DIRECTION_DOWN))
		Self.moveSlots[1].AddTrigger(TKeyTrigger.Create(KEY_DOWN, True))
		Self.moveSlots[1].AddTrigger(TJoyHatTrigger.Create(TJoyHatTrigger.AXIS_Y, 1))
		
		Self.moveSlots[2] = TSlot.Create(TActionMove.Create(TAnimationWalk.DIRECTION_LEFT))
		Self.moveSlots[2].AddTrigger(TKeyTrigger.Create(KEY_LEFT, True))
		Self.moveSlots[2].AddTrigger(TJoyHatTrigger.Create(TJoyHatTrigger.AXIS_X, -1))
		
		Self.moveSlots[3] = TSlot.Create(TActionMove.Create(TAnimationWalk.DIRECTION_RIGHT))
		Self.moveSlots[3].AddTrigger(TKeyTrigger.Create(KEY_RIGHT, True))
		Self.moveSlots[3].AddTrigger(TJoyHatTrigger.Create(TJoyHatTrigger.AXIS_X, 1))
		
		Self.moveSlots[4] = TSlot.Create(TActionLockDirection.Create())
		Self.moveSlots[4].AddTrigger(TKeyTrigger.Create(KEY_LSHIFT, True))
		
		' Tech slots
		game.logger.Write("Setting up skill slots")
		
		' Set up triggers
		For Local index:Int = 0 Until Self.player.techSlots.length
			Self.player.techSlots[index].AddTrigger(TKeyTrigger.Create(KEY_1 + index))
			Self.player.techSlots[index].AddTrigger(TJoyKeyTrigger.Create(index))
			
			Self.player.techSlots[index].AddSkillAdvanceTrigger(TKeyTrigger.Create(KEY_1 + index, True))
			Self.player.techSlots[index].AddSkillAdvanceTrigger(TJoyKeyTrigger.Create(index, True))
		Next
		
		' GUI
		game.logger.Write("Initializing GUI")
		Self.InitGUI()
		
		' Walk
		Self.walkX = 0
		Self.walkY = 0
		
		' Skills
		Self.runningSkills = CreateList()
		
		game.logger.Write("Setting up particle groups")
		Self.grpSkillEffects = New TParticleGroup[Self.map.height]
		Self.grpPostEffects = TParticleGroup.Create()
		Self.grpGuiEffects = TParticleGroup.Create()
		
		' Effect groups
		For Local I:Int = 0 Until Self.map.height
			Self.grpSkillEffects[I] = TParticleGroup.Create()
		Next
		
		?Threaded
			Self.threadsRunning = True
			Self.grpSkillEffectsCleanThread = CreateThread(TGameStateInGame.UpdateParticlesOutOfScreenThread, Null)
		?
		
		' Walk
		Self.statusX = 80 + 16
		Self.statusY = 80 + 16
		
		' Music
		'Local music:TSound = LoadSound(FS_ROOT + "data/music/Okary-0.4.ogg", SOUND_LOOP)
		'PlaySound music
		
		' Should be the last call in Init
		If Self.inNetworkMode
			Self.arenaMode.Start()
		EndIf
	End Method
	
	' InitResources
	Method InitResources()
		game.logger.Write("Loading scripts")
		game.scriptMgr.AddResourcesFromDirectory(FS_ROOT + "data/enemies/")
		game.scriptMgr.AddResourcesFromDirectory(FS_ROOT + "data/skills/")
		game.scriptMgr.AddResourcesFromDirectory(FS_ROOT + "data/scripts/")
		game.scriptMgr.AddResourcesFromDirectory(FS_ROOT + "data/characters/")
		
		game.logger.Write("Loading skill images")
		game.imageMgr.SetFlags(MIPMAPPEDIMAGE | FILTEREDIMAGE)
		game.imageMgr.AddResourcesFromDirectory(FS_ROOT + "data/skills/")
		
		game.logger.Write("Loading fonts")
		game.fontMgr.AddResourcesFromDirectory(FS_ROOT + "data/fonts/")
		
		game.logger.Write("Loading status images")
		game.imageMgr.AddResourcesFromDirectory(FS_ROOT + "data/status/hp/")
		
		' TODO: Remove hardcoded stuff
		game.logger.Write("Loading particle images")
		game.imageMgr.SetFlags(MIPMAPPEDIMAGE | FILTEREDIMAGE)
		game.imageMgr.AddResourcesFromDirectory(FS_ROOT + "data/particles/")
		
		game.logger.Write("Loading sounds")
		Self.chanEffects = game.soundMgr.GetChannel("Effects")
		Self.chanEffects.AddResourcesFromDirectory(FS_ROOT + "data/sounds/")
		
		game.logger.Write("Modifying resources")
		
		' Fonts
		Self.guiFont = game.fontMgr.Get("GUIFont")
		Self.guiFontTitle = game.fontMgr.Get("GUITitleFont")
		Self.dmgFont = game.fontMgr.Get("DamageFont")
		Self.regionPreviewFont = game.fontMgr.Get("RegionFont")
		Self.playerTitleFont = game.fontMgr.Get("PlayerTitleFont")
		Self.inGameChatFont = game.fontMgr.Get("InGameChatFont")
		Self.arenaBroadcastFont = game.fontMgr.Get("ArenaBroadcastFont")
		
		' Particles
		Self.particleImg = game.imageMgr.Get("particle-main")
		MidHandleImage Self.particleImg
		Self.particleImgIce = game.imageMgr.Get("particle-ice")
		MidHandleImage Self.particleImgIce
		Self.particleImgWind = game.imageMgr.Get("particle-wind")
		MidHandleImage Self.particleImgWind
		Self.particleImgFire = game.imageMgr.Get("particle-fire")
		MidHandleImage Self.particleImgFire
		Self.weaponSword = LoadImage(FS_ROOT + "data/items/weapons/earth-sword.png")
		SetImageHandle Self.weaponSword, Self.weaponSword.width / 2, 32 '34
		'SetImageHandle Self.weaponSword, 4, 32
		
		' Status HP graphics
		Self.imgHP[0] = game.imageMgr.Get("hp_NW")
		Self.imgHP[1] = game.imageMgr.Get("hp_SW")
		Self.imgHP[2] = game.imageMgr.Get("hp_SE")
		Self.imgHP[3] = game.imageMgr.Get("hp_NE")
		SetImageHandle Self.imgHP[0], Self.imgHP[0].width, Self.imgHP[0].height
		SetImageHandle Self.imgHP[1], Self.imgHP[1].width, 0
		SetImageHandle Self.imgHP[2], 0, 0
		SetImageHandle Self.imgHP[3], 0, Self.imgHP[3].height
		
		' Status MP graphics
		Self.imgMP = LoadAnimImage(FS_ROOT + "data/status/mp/mp.png", 118, 1, 0, 118) 
		Self.imgMPFull = LoadImage(FS_ROOT + "data/status/mp/mp-full.png")
		MidHandleImage Self.imgMP
		MidHandleImage Self.imgMPFull
	End Method
	
	' InitGUI
	Method InitGUI()
		Self.gui = TGUI.Create()
		
		' Skill view
		Local skillSizeInPx:Int = 48
		Self.skillView = TContainer.Create("skillView")
		Self.skillView.SetSize(0, 0)
		Self.skillView.SetSizeAbs(skillSizeInPx * Self.player.techSlots.length, skillSizeInPx)
		Self.skillView.Dock(TWidget.DOCK_BOTTOM)
		Self.skillView.SetColor(255, 255, 255)
		Self.gui.Add(Self.skillView)
		
		Local skillBox:TImageBox
		
		' TODO: Remove hardcoded stuff
		For Local I:Int = 0 Until Self.player.techSlots.length
			skillBox = TImageBox.Create("skill" + I, Null, 0, 0, 0)
			skillBox.SetPosition(skillSizeInPx * I / Float(skillSizeInPx * Self.player.techSlots.length), 0)
			skillBox.SetSize(1.0 / Self.player.techSlots.length, 1)
			skillBox.SetSizeAbs(0, 0)
			Self.skillView.Add(skillBox)
		Next
		
		' View skills
		For Local I:Int = 0 Until Self.player.techSlots.length
			If Self.player.techSlots[I] <> Null
				Local skill:TSkill = TSkill(Self.player.techSlots[I].GetAction())
				If skill <> Null
					skillBox = TImageBox(Self.skillView.GetChild("skill" + I))
					skillBox.SetImage(skill.img)
				EndIf
			EndIf
		Next
		
		' Skill cast bar
		Self.skillCastBar = TProgressBar.Create("skillCastBar")
		Self.skillCastBar.SetPosition(0.5, 0.75)
		Self.skillCastBar.SetPositionAbs(-100, -12)
		Self.skillCastBar.SetSizeAbs(200, 24)
		Self.skillCastBar.SetAlpha(0.75)
		Self.skillCastBar.SetVisible(False)
		Self.gui.Add(Self.skillCastBar)
		
		' Buff container
		Self.buffView = TContainer.Create("buffs")
		Self.buffView.SetSizeAbs(0, 32)
		Self.buffView.Dock(TWidget.DOCK_TOP | TWidget.DOCK_RIGHT)
		Self.gui.Add(Self.buffView)
		
		Self.debuffView = TContainer.Create("debuffs")
		Self.debuffView.SetSizeAbs(0, 32)
		Self.debuffView.SetPosition(1.0, 0.0)
		Self.debuffView.SetPositionAbs(0, Self.buffView.GetHeight())
		Self.gui.Add(Self.debuffView)
		
		' Cursors
		Self.gui.SetCursor("default")
		HideMouse()
		
		' Apply font to all widgets
		Self.gui.SetFont(Self.guiFont)
		
		' Network mode
		If Self.inNetworkMode
			Local msgList:TWidget = Self.arenaGUI.GetRoot().GetChild("roomContainer").GetChild("msgList")
			msgList.SetAlpha(0.5)
			msgList.SetFont(Self.inGameChatFont)
			msgList.SetSize(0, 0)
			msgList.SetSizeAbs(300, 100)
			msgList.SetPosition(0, 1)
			msgList.SetPositionAbs(5, -(100 + 5 + 48))
			Self.gui.Add(msgList)
			
			msgList.UpdatePosition()
			msgList.UpdateScreenPosition()
			msgList.Update()
		EndIf
		
		' Fonts
		'Self.infoWindow.SetFont(Self.guiFontTitle)
	End Method
	
	' InitNetworkMode
	Method InitNetworkMode(nPlayer:TPlayer, nParties:TParty[], nRoom:TRoom, nServer:TServer, nArenaGUI:TGUI, nArenaMode:TArenaMode)
		Self.player = nPlayer
		Self.room = nRoom
		Self.server = nServer
		Self.parties = nParties
		Self.arenaGUI = nArenaGUI
		Self.arenaMode = nArenaMode
		
		Self.inNetworkMode = True
	End Method
	
	' Update
	Method Update()
		' Return to arena
		If Self.returnToArena
			Self.returnToArena = False
			game.SetGameStateByName("Arena")
		EndIf
		
		' Check whether game is paused
		If Self.IsPaused()
			If Self.pauseTextWritten > 1
				frameCounter.UpdatePause()
				Return
			Else
				Self.gui.HideCursor()
			EndIf
		Else
			If Self.pauseTextWritten > 0
				HideMouse()
				Self.gui.ShowCursor()
			EndIf
			Self.pauseTextWritten = 0
		EndIf
		
		' Update frame rate
		Self.frameCounter.Update()
		
		' GUI update
		Self.gui.Update()
		
		' Input
		Self.UpdateInput()
		Self.UpdateParties()
		
		' Clear screen
		Cls
		
		' Reset color, alpha, rotation
		ResetMax2D()
		
		' Draw
		Self.map.Draw(TGameStateInGame.OnMapRow)
		
		' Update casting of the current skill
		Self.UpdateSkillCast()
		
		' Map offset
		SetOrigin Int(Self.map.originX), Int(Self.map.originY)
		
		' AI
		Self.UpdateEnemies()
		
		' Update buffs
		Self.UpdateBuffView()
		
		' Update currently running skills
		Self.UpdateRunningSkills()
		
		' Damage numbers
		Self.DrawDamageNumbers()
		
		' Back to normal offset
		SetOrigin 0, 0
		
		' Post particle effects
		grpPostEffects.Draw()
		
		' Info
		ResetMax2D()
		
		SetImageFont Self.guiFont
		DrawText "FPS: " + frameCounter.GetFPS(), 5, 5 + 190
		DrawText "Average FPS: " + Int(frameCounter.GetAverageFPS()), 5, 20 + 190
		
		?Debug
		DrawText "Player: " + Self.player.PositionToString(), 5, 35 + 190
		DrawText "Move: " + Self.walkX + ", " + Self.walkY, 5, 50 + 190
		DrawText "Tile: " + Self.tileX + ", " + Self.tileY, 5, 65 + 190
		DrawText "Offset: " + Self.map.GetRealOffsetX() + ", " + Self.map.GetRealOffsetY(), 5, 80 + 190
		DrawText "Enemies: " + Self.enemiesOnScreen.Count(), 5, 95 + 190
		DrawText "Particles: " + TParticle.count, 5, 110 + 190
		?
		
		?Debug
		DrawText "Animation: " + GetTypeName(Self.player.currentAnimation), 5, 125 + 190
		DrawText "Anim.Frame: " + Self.player.currentAnimation.frame, 5, 140 + 190
		?
		
		' Network mode
		If Self.inNetworkMode
			DrawText "[Team 1] Kills: " + Self.parties[0].GetKillCount(), 5, 155 + 190
			DrawText "[Team 2] Kills: " + Self.parties[1].GetKillCount(), 5, 170 + 190
			DrawText "Ping: " + Self.player.ping + " ms", 5, 200 + 190
		EndIf
		
		' Status
		Self.DrawStatus()
		
		' GUI
		'Self.gui.SetAlpha 1
		Self.gui.Draw()
		grpGuiEffects.Draw()
		
		' Skill Outline
		Self.UpdateSkillView()
		
		' Pause
		If Self.IsPaused()
			' Nubek - Tal der Simorith
			' Tamburin - Stadt des ewigen Lichts
			Local txt:String = "P a u s e"
			SetAlpha 1
			SetColor 255, 255, 255
			SetImageFont Self.regionPreviewFont
			DrawText txt, game.gfxWidthHalf - TextWidth(txt) / 2, game.gfxHeightHalf - TextHeight(txt) / 2
			Self.pauseTextWritten :+ 1
		EndIf
		
		' Networking
		If Self.inNetworkMode
			Self.UpdateArena()
		EndIf
		
		' Particles out of screen
		?Not Threaded
		If MilliSecs() - Self.lastParticleClear > 1000
			Self.lastParticleClear = MilliSecs()
			Self.UpdateParticlesOutOfScreen()
		End If
		?
		
		' Swap buffers
		Flip game.vsync
	End Method
	
	' UpdateSkillView
	Method UpdateSkillView()
		Local skill:TSkill
		For Local I:Int = 0 Until Self.player.techSlots.length
			Local skillBox:TImageBox = TImageBox(Self.skillView.GetChild("skill" + I))
			
			SetAlpha 1
			SetColor 0, 0, 0
			DrawRectOutline skillBox.GetX() - 1, skillBox.GetY(), skillBox.GetWidth() + 1, skillBox.GetHeight()
			
			' TODO: Remove hardcoded stuff
			Local keyStr:String = "1234567890QWERASDF"
			SetColor 255, 255, 255
			DrawText Chr(keyStr[I]), skillBox.GetX() + 3, skillBox.GetY() + 3
			
			' Show cooldown / cast
			If Self.player.techSlots[I] <> Null
				skill = TSkill(Self.player.techSlots[I].GetAction())
				If skill <> Null
					skillBox.SetImage(skill.img)
					
					If skill = Self.player.castingSkill
						SetAlpha 0.05 + (1 - skill.GetCastProgress()) * 0.2
						SetColor 255, 255, 255
						DrawRect skillBox.GetX(), skillBox.GetY(), skillBox.GetWidth(), skillBox.GetHeight()
					EndIf
					
					If skill.cooldown > 0
						SetAlpha 0.75
						SetColor 0, 0, 0
						DrawRect skillBox.GetX(), skillBox.GetY() + skill.GetCooldownProgress() * skillBox.GetHeight(), skillBox.GetWidth(), skill.GetCooldownProgressLeft() * skillBox.GetHeight()
					EndIf
					
					If Self.player.HasEnoughMP(skill.mpCostAbs, skill.mpCostRel) = False
						SetAlpha 0.5
						SetColor 0, 0, 0
						DrawRect skillBox.GetX(), skillBox.GetY(), skillBox.GetWidth(), skillBox.GetHeight()
					EndIf
				EndIf
			EndIf
			
			' Skill description
			' TODO: Remove hardcoded
			If PointInRect(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), skillBox.GetX(), skillBox.GetY(), skillBox.GetWidth(), skillBox.GetHeight())
				SetAlpha 1
				SetColor 0, 0, 0
				DrawRectOutline Self.skillView.GetX() - 1, Self.skillView.GetY() - 100, Self.skillView.GetWidth() + 1, 100
				
				SetAlpha 0.85
				DrawRect Self.skillView.GetX() - 1, Self.skillView.GetY() - 100, Self.skillView.GetWidth() + 1, 100
				
				SetColor 255, 255, 255
				DrawText skill.GetName(), Self.skillView.GetX() + 4, Self.skillView.GetY() - 95
				DrawText skill.GetDescription(), Self.skillView.GetX() + 4, Self.skillView.GetY() - 75
				DrawText "Cooldown: " + MSToSeconds(skill.GetCooldown()) + " seconds", Self.skillView.GetX() + 4, Self.skillView.GetY() - 55
				DrawText "Cast time: " + MSToSeconds(skill.GetCastTime()) + " seconds", Self.skillView.GetX() + 4, Self.skillView.GetY() - 40
				DrawText "MP cost: " + skill.GetMPCostAsString() + " MP", Self.skillView.GetX() + 4, Self.skillView.GetY() - 25
			EndIf
		Next
	End Method
	
	' UpdateBuffView
	Method UpdateBuffView()
		Local buff:TBuff
		Local icon:TWidget
		Local label:TWidget
		For Local widget:TWidget = EachIn Self.buffView.GetChildsList()
			buff = TBuff(widget.GetMetaData())
			label = widget.GetChild(widget.GetID() + "_label")
			icon = widget.GetChild(widget.GetID() + "_icon")
			
			label.SetText(Int(Ceil(buff.GetRemainingTime() / 1000.0)))
			
			If buff.GetRemainingTime() <= 3000
				icon.SetAlpha(0.25 + 0.5 * SinFastSec(buff.GetRemainingTime() * 0.5))
			Else
				icon.SetAlpha(Min(1.0, 0.4 + buff.GetRemainingTime() * 0.0001))
			EndIf
			
			label.SetAlpha(icon.GetAlpha())
			
			'SetColor 0, 0, 0
			'DrawRectOutline icon.GetX(), icon.GetY(), icon.GetWidth(), icon.GetHeight()
		Next
	End Method
	
	' UpdateParties
	Method UpdateParties()
		For Local party:TParty = EachIn Self.parties
			For Local player:TPlayer = EachIn party.GetMembersList()
				Self.map.GetTileCoordsDirect(player.GetMidX(), player.y + player.img.height - 5, player.tileX, player.tileY)
				
				Local walkX:Float
				Local walkY:Float
				
				' Set walk speed
				Select player.movementX
					Case 1
						walkX = -game.speed
						
					Case 2
						walkX = game.speed
						
					Default
						walkX = 0
				End Select
				
				Select player.movementY
					Case 1
						walkY = -game.speed
						
					Case 2
						walkY = game.speed
						
					Default
						walkY = 0
				End Select
				
				' Walk
				If (player.castingSkill = Null Or player.castingSkill.canMoveWhileCasting) 'And player.currentAnimation <> player.animAttack
					Local oldTileX:Int, oldTileY:Int
					Local tileXNext:Int, tileYNext:Int
					
					' Collision test
					oldTileX = Self.tileX
					oldTileY = Self.tileY
					If Self.map.GetTileCoordsDirect(player.GetMidX(), player.y + player.img.height - 5, Self.tileX, Self.tileY)
						' Check script
						If oldTileX <> Self.tileX Or oldTileY <> Self.tileY
							Local scriptName:String = Self.map.GetScript(Self.tileX, Self.tileY)
							If scriptName.length > 0
								Self.currentScriptName = scriptName
								Local script:TLuaScript = game.scriptMgr.Get(scriptName)
								Local luaObject:TLuaObject = script.CreateInstance(Self)
								luaObject.Invoke("run", Null)
							Else
								Self.currentScriptName = ""
							EndIf
						EndIf
						
						' Moving
						player.mutex.Lock()
							Self.map.GetTileCoordsDirect(player.GetMidX() + walkX, player.y + walkY + player.img.height - 5, tileXNext, tileYNext)
							
							Local moveX:Int = True
							Local moveY:Int = True
							
							If Self.tileX <> tileXNext
								If Abs(tileXNext - Self.tileX) > 1
									tileXNext = Self.tileX + Sgn(tileXNext - Self.tileX)
								EndIf
								For Local layer:Int = 0 Until Self.map.GetLayers()
									If walkX > 0 And Self.map.GetTileType(layer, tileXNext, Self.tileY).mLeft = False
										moveX = False
									ElseIf walkX < 0 And Self.map.GetTileType(layer, tileXNext, Self.tileY).mRight = False
										moveX = False
									EndIf
								Next
							EndIf
							
							If Self.tileY <> tileYNext
								If Abs(tileYNext - Self.tileY) > 1
									tileYNext = Self.tileY + Sgn(tileYNext - Self.tileY)
								EndIf
								For Local layer:Int = 0 Until Self.map.GetLayers()
									If walkY > 0 And Self.map.GetTileType(layer, Self.tileX, tileYNext).mTop = False
										moveY = False
									ElseIf walkY < 0 And Self.map.GetTileType(layer, Self.tileX, tileYNext).mBottom = False
										moveY = False
									EndIf
								Next
							EndIf
						player.mutex.Unlock()
						
						player.Walk(walkX, walkY, moveX, moveY)
					EndIf
				EndIf
				
				player.Update()
			Next
		Next
	End Method
	
	' UpdateInput
	Method UpdateInput()
		' Update input system
		TInputSystem.Update()
		
		' Check triggers
		For Local I:Int = 0 To 3
			Self.moveSlots[I].Update()
			
			If Self.moveSlots[I].GetTriggeredTrigger() = Null
				Select I
					Case 0 ' Up
						If Self.player.movementY = 1
							Self.player.movementY = 0
							
							If gsInGame.inNetworkMode
								gsInGame.room.streamMutex.Lock()
									gsInGame.room.stream.WriteByte(100)
									gsInGame.room.stream.WriteByte(Self.player.movementX)
									gsInGame.room.stream.WriteByte(0)
									gsInGame.room.stream.WriteFloat(Self.player.x)
									gsInGame.room.stream.WriteFloat(Self.player.y)
								gsInGame.room.streamMutex.Unlock()
							EndIf
						EndIf
					Case 1 ' Down
						If Self.player.movementY = 2
							Self.player.movementY = 0
							
							If gsInGame.inNetworkMode
								gsInGame.room.streamMutex.Lock()
									gsInGame.room.stream.WriteByte(100)
									gsInGame.room.stream.WriteByte(Self.player.movementX)
									gsInGame.room.stream.WriteByte(0)
									gsInGame.room.stream.WriteFloat(Self.player.x)
									gsInGame.room.stream.WriteFloat(Self.player.y)
								gsInGame.room.streamMutex.Unlock()
							EndIf
						EndIf
					Case 2 ' Left
						If Self.player.movementX = 1
							Self.player.movementX = 0
							
							If gsInGame.inNetworkMode
								gsInGame.room.streamMutex.Lock()
									gsInGame.room.stream.WriteByte(100)
									gsInGame.room.stream.WriteByte(0)
									gsInGame.room.stream.WriteByte(Self.player.movementY)
									gsInGame.room.stream.WriteFloat(Self.player.x)
									gsInGame.room.stream.WriteFloat(Self.player.y)
								gsInGame.room.streamMutex.Unlock()
							EndIf
						EndIf
					Case 3 ' Right
						If Self.player.movementX = 2
							Self.player.movementX = 0
							
							If gsInGame.inNetworkMode
								gsInGame.room.streamMutex.Lock()
									gsInGame.room.stream.WriteByte(100)
									gsInGame.room.stream.WriteByte(0)
									gsInGame.room.stream.WriteByte(Self.player.movementY)
									gsInGame.room.stream.WriteFloat(Self.player.x)
									gsInGame.room.stream.WriteFloat(Self.player.y)
								gsInGame.room.streamMutex.Unlock()
							EndIf
						EndIf
				End Select
			EndIf
		Next
		
		' Update skill slots if not casting
		If Self.player.castingSkill = Null
			UpdateSlots(player.techSlots)
			
			For Local I:Byte = 0 Until Self.player.techSlots.length
				Local slot:TSlot = Self.player.techSlots[I]
				
				If slot.WasTriggeredEarlier()
					If Self.inNetworkMode
						If TSkill(slot.GetAction()).CanBeCasted()
							Self.room.streamMutex.Lock()
								Self.room.stream.WriteByte(110)
								Self.room.stream.WriteByte(I)
							Self.room.streamMutex.Unlock()
						EndIf
					Else
						slot.GetAction().Exec(Null)
					EndIf
				EndIf
			Next
		EndIf
		
		Rem
		If MilliSecs() - Self.sentPosLast > 20
			Self.room.streamMutex.Lock()
				Self.room.stream.WriteByte(100)
				Self.room.stream.WriteFloat(Self.walkXNet)
				Self.room.stream.WriteFloat(Self.walkYNet)
				Self.walkXNet = 0
				Self.walkYNet = 0
			Self.room.streamMutex.Unlock()
			Self.sentPosLast = MilliSecs()
		EndIf
		End Rem
		
		' Adjust map offset
		Self.map.SetOffset(Self.player.GetMidX() - game.gfxWidthHalf, Self.player.GetMidY() - game.gfxHeightHalf)
		Self.map.LimitOffset()
		
		' Lock direction slot
		Self.moveSlots[4].Update()
		
		' Ctrl
		If TInputSystem.GetKeyDown(KEY_LCONTROL) 
			' Ctrl + E = Open Editor
			If TInputSystem.GetKeyHit(KEY_E)
				game.SetGameStateByName("Editor")
			EndIf
		EndIf
		
		' Quit
		If TInputSystem.GetKeyHit(KEY_ESCAPE)
			If Self.inNetworkMode
				game.SetGameStateByName("Arena")
			Else
				game.SetGameStateByName("Menu")
			EndIf
		EndIf
	End Method
	
	' UpdateSkillCast
	Method UpdateSkillCast()
		For Local party:TParty = EachIn Self.parties
			For Local player:TPlayer = EachIn party.GetMembersList()
				Local skill:TSkill = player.castingSkill
				
				If skill <> Null
					Local progress:Float = skill.GetCastProgress()
					skill.Cast()
					
					' TODO: Remove hardcoded stuff
					If progress < 1.0
						If player = Self.player
							Self.skillCastBar.SetVisible(True)
							Self.skillCastBar.SetProgress(progress)
						EndIf
					Else
						Local slot:TSlot = skill.GetSlot()
						
						If Self.inNetworkMode = False
							' Hide cast bar
							Self.skillCastBar.SetVisible(False)
							
							If skill.GoingToAdvance()
								skill.Advance()
							Else
								skill.Start()
								player.EndCast()
								
								While TSkill(slot.GetAction()).preSkill <> Null
									slot.SetAction(TSkill(slot.GetAction()).preSkill)
								Wend
							EndIf
						Else
							If skill.CanBeAdvanced() = True
								If player = Self.player And skill.endSkillSent = False
									'skill.Start()
									Self.room.streamMutex.Lock()
										Self.room.stream.WriteByte(111)
										Self.room.stream.WriteByte(skill.GoingToAdvance())
									Self.room.streamMutex.Unlock()
									skill.endSkillSent = True
								EndIf
							Else
								Self.skillCastBar.SetVisible(False)
								
								skill.Start()
								player.EndCast()
							EndIf
						EndIf
					EndIf
				EndIf
			Next
		Next
	End Method
	
	' UpdateRunningSkills
	Method UpdateRunningSkills()
		For Local skill:TSkillInstance = EachIn Self.runningSkills
			skill.Run()
		Next
	End Method
	
	' UpdateEnemies
	Method UpdateEnemies()
		' Collision with an enemy
		Local enemy:TEnemy
		
		' Check for new enemies
		If 1 'Self.walkX <> 0 Or Self.walkY <> 0
			Self.FindVisibleEnemies()
		EndIf
		
		' Update visible enemies
		For enemy = EachIn Self.enemiesOnScreen
			If enemy.x + enemy.img.width < Self.map.tileLeft * Self.map.tileSizeX Or enemy.x > Self.map.tileRight * Self.map.tileSizeX Or ..
				enemy.y + enemy.img.height < Self.map.tileTop * Self.map.tileSizeY Or enemy.y > Self.map.tileBottom * Self.map.tileSizeY
				' Remove enemy from visible enemies list
				enemy.link.Remove()
				enemy.link = Null
				Continue
			End If
				
			enemy.Update()
			
			If enemy.target <> Null
				If enemy.path = Null
					Local eX:Int, eY:Int
					If Self.map.GetTileCoordsDirect(enemy.x, enemy.y, eX, eY)
						If enemy.hasRangeSkills
							' Ranged
							' Find nearest position on line to cast from
							Local distX:Int = enemy.x - enemy.target.x
							Local distY:Int = enemy.y - enemy.target.y
							If distX < distY
								enemy.path = TNode.AStar(4, eX, eY, enemy.target.x / Self.map.tileSizeX, eY, Self.map.cost, 0, - 1, True, ASWEIGHTENED | ASSMOOTHENED | ASCLIMBNFALL, 0)
							Else
								enemy.path = TNode.AStar(4, eX, eY, eX, enemy.target.y / Self.map.tileSizeY, Self.map.cost, 0, - 1, True, ASWEIGHTENED | ASSMOOTHENED | ASCLIMBNFALL, 0)
							EndIf
						Else
							' Melee
							enemy.path = TNode.AStar(8, eX, eY, enemy.target.x / Self.map.tileSizeX, enemy.target.y / Self.map.tileSizeY, Self.map.cost, 0, - 1, True, ASWEIGHTENED | ASSMOOTHENED | ASCLIMBNFALL, 0)
						EndIf
						
						' Delete first node
						If enemy.path <> Null
							TNode(enemy.path.First()).Close()
						EndIf
					EndIf
				Else
					' Path already calculated, find the way to the target
					Local sameLine:Int = TEntity.OnSameLine(enemy, enemy.target)
					
					' Update tech slots
					If enemy.castingSkill = Null
						UpdateSlots(enemy.techSlots)
					EndIf
					
					If enemy.hasRangeSkills And sameLine
						' Turn to the right direction to face the target
						Select sameLine
							' Vertical
							Case 1
								If enemy.target.y < enemy.y
									enemy.SetDirection(TEntity.DIRECTION_UP)
								Else
									enemy.SetDirection(TEntity.DIRECTION_DOWN)
								EndIf
								
							' Horizontal
							Case 2
								If enemy.target.x < enemy.x
									enemy.SetDirection(TEntity.DIRECTION_LEFT)
								Else
									enemy.SetDirection(TEntity.DIRECTION_RIGHT)
								EndIf
						End Select
					ElseIf enemy.castingSkill = Null Or enemy.castingSkill.canMoveWhileCasting
						' Melee
						Local nextNode:TNode = TNode(enemy.path.First())
						
						If nextNode = Null
							enemy.path = Null
						Else
							Local nX:Int = nextNode.x * Self.map.tileSizeX
							Local nY:Int = nextNode.y * Self.map.tileSizeY
							Local nXS:Int = nX + Self.map.tileSizeX / 2 - enemy.x
							Local nYS:Int = nY + Self.map.tileSizeY / 2 - enemy.y
							
							If DistanceSq2(nXS, nYS) < 9
								nextNode.Close()
							EndIf
							
							nXS = Sgn(nXS)
							nYS = Sgn(nYS)
							
							'enemy.MoveTo(nX + Self.map.tileSizeX / 2, nY + Self.map.tileSizeY / 2)
							
							'DrawText GetTypeName(enemy.currentAnimation), enemy.x, enemy.y
							
							If nXS <> 0 Or nYS <> 0
								enemy.Walk(nXS * game.speed, nYS * game.speed)
								
								If enemy.castingSkill = Null
									enemy.UpdateDirection(nXS, nYS)
									enemy.animWalk.Play()
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
			
			' Skill slots
			If enemy.castingSkill <> Null
				Local progress:Float = enemy.castingSkill.GetCastProgress()
				enemy.castingSkill.Cast()
				
				If progress >= 1.0
					enemy.castingSkill.Start()
					enemy.EndCast()
				EndIf
			EndIf
		Next
	End Method
	
	' UpdateArena
	Method UpdateArena()
		If Self.server <> Null
			If MilliSecs() - Self.lastArenaUpdate > 250
				Self.server.clientListMutex.Lock()
					' Data about all players...
					Local player:TPlayer
					For Local bcClient:TLyphiaClient = EachIn Self.server.clientList
						player = bcClient.player
						
						' Kill
						If player.killedBy <> Null
							' Send all clients
							For Local client:TLyphiaClient = EachIn Self.server.clientList
								client.streamMutex.Lock()
									client.stream.WriteByte(30)
									client.stream.WriteByte(TPlayer(player.killedBy).GetID())
									client.stream.WriteByte(player.GetID())
									client.stream.WriteShort(player.killedBy.GetKillCount())
									client.stream.WriteShort(player.GetDeathCount())
								client.streamMutex.Unlock()
							Next
							
							player.hp = player.maxHP
							player.mp = player.maxMP
							player.killedBy = Null
						EndIf
						
						' HP update
						If player.hp <> player.netHP
							' Send all clients except myself
							For Local client:TLyphiaClient = EachIn Self.server.clientList
								If client.player <> Self.player
									client.streamMutex.Lock()
										client.stream.WriteByte(50)
										client.stream.WriteByte(player.GetID())
										client.stream.WriteFloat(player.hp)
									client.streamMutex.Unlock()
								EndIf
							Next
							
							player.netHP = player.hp
						EndIf
					Next
				Self.server.clientListMutex.Unlock()
				Self.lastArenaUpdate = MilliSecs()
			EndIf
		EndIf
		
		' Ping check
		If Self.inNetworkMode
			If MilliSecs() - Self.lastPingCheck > 1000
				room.streamMutex.Lock()
					room.stream.WriteByte(230)
				room.streamMutex.UnLock()
				
				Self.pingSent = MilliSecs()
				Self.lastPingCheck = MilliSecs()
			EndIf
			
			' Arena mode check
			Self.arenaMode.Update()
			If Self.arenaMode.HasEnded()
				SetImageFont Self.arenaBroadcastFont
				DrawTextCentered Self.arenaMode.GetWinnerParty().GetName() + " wins", game.gfxWidthHalf, game.gfxHeightHalf / 2
				
				If Self.server <> Null
					If MilliSecs() - Self.arenaMode.GetEndTime() > 5000
						' Send all clients
						For Local client:TLyphiaClient = EachIn Self.server.clientList
							client.streamMutex.Lock()
								client.stream.WriteByte(254)
							client.streamMutex.Unlock()
						Next
					EndIf
				EndIf
			Else
				' Mode logo
				If MilliSecs() - Self.arenaMode.GetStartTime() <= 3000
					ResetMax2D()
					
					Local invAlpha:Float = (MilliSecs() - Self.arenaMode.GetStartTime()) / 3000.0
					invAlpha = invAlpha * invAlpha
					SetAlpha 1.0 - invAlpha
					DrawImage Self.arenaMode.img, game.gfxWidthHalf, game.gfxHeightHalf / 2
				EndIf
			EndIf
		EndIf
	End Method
	
	' FindVisibleEnemies
	Method FindVisibleEnemies()
		Local h:Int
		Local enemySpawn:TEnemySpawn
		Local enemy:TEnemy
		
		For h = Self.map.tileTop To Self.map.tileBottom
			For enemySpawn = EachIn gsInGame.map.enemySpawns[h]
				enemy = enemySpawn.enemy
				If enemy <> Null
					If enemy.link = Null
						enemy.link = Self.enemiesOnScreen.AddLast(enemy)
					EndIf
				EndIf
			Next
		Next
	End Method
	
	' ChangeMap
	Method ChangeMap(nMap:String)
		Self.map.Load(FS_ROOT + "data/maps/" + nMap + ".map")
		
		If Self.inNetworkMode
			For Local I:Int = 0 Until Self.parties.length
				Local party:TParty = Self.parties[I]
				For Local player:TPlayer = EachIn party.GetMembersList()
					If player = Self.player
						MovePlayerToTile(Self.map.GetStartTileX(I), Self.map.GetStartTileY(I))
					Else
						player.x = Self.map.GetStartTileX(I) * Self.map.GetTileSizeX()
						player.y = Self.map.GetStartTileY(I) * Self.map.GetTileSizeY()
					EndIf
				Next
			Next
		Else
			MovePlayerToTile(Self.map.GetStartTileX(0), Self.map.GetStartTileY(0))
		EndIf
	End Method
	
	' Teleport
	Method Teleport(toMap:String, toMap2:String = "")
		If toMap2 = ""
			Self.ChangeMap(toMap)
			Return
		EndIf
		
		If Self.map.GetName() = toMap
			Self.scriptCoords.Insert(Self.currentScriptName, TBox.Create(Self.tileX, Self.tileY))
			Self.ChangeMap(toMap2)
		ElseIf Self.map.GetName() = toMap2
			Self.ChangeMap(toMap)
			Local coordsBox:TBox = TBox(Self.scriptCoords.ValueForKey(Self.currentScriptName))
			Self.MovePlayerToTile(coordsBox.x1, coordsBox.y1)
		EndIf
		
		' Fix game.speed after loading
		game.lastFrameTimeUpdate = MilliSecs()
	End Method
	
	' MovePlayerToTile
	Method MovePlayerToTile(nTileX:Int, nTileY:Int)
		Self.player.x = nTileX * Self.map.GetTileSizeX()
		Self.player.y = nTileY * Self.map.GetTileSizeY()
		Self.map.GetTileCoordsDirect(Self.player.GetMidX(), Self.player.y + player.img.height - 5, Self.player.tileX, Self.player.tileY)
		Self.tileX = Self.player.tileX
		Self.tileY = Self.player.tileY
	End Method
	
	' DrawDamageNumbers
	Method DrawDamageNumbers()
		SetImageFont Self.dmgFont
		For Local dmg:TDamageView = EachIn TDamageView.list
			dmg.Draw(game.speed)
		Next
	End Method
	
	' DrawStatus
	Method DrawStatus()
		Self.DrawHP() 
		Self.DrawMP()
	End Method
	
	' DrawHP
	Method DrawHP()
		If Self.oldHP = 0
			Self.oldHP = Self.player.hp
			Return
		End If
		
		Const steps:Int = 4
		
		' Really hardcoded...
		Local positionX:Int = 80 + 16
		Local positionY:Int = 80 + 15
		Local start:Int = 90
		Local limitOld:Int = start + (Self.oldHP / Self.player.maxHP) * 360
		Local limit:Int = start + (Self.player.hp / Self.player.maxHP) * 360
		Local drawLimit:Int
		
		If limit < 450
			SetLineWidth steps
			For Local size:Int = 65 To 80
				If limit > 360 And limitOld > 360
					start = 360
				ElseIf limit > 270 And limitOld > 270
					start = 270
				ElseIf limit > 180 And limitOld > 180
					start = 180
				EndIf
				
				' HP Changes
				drawLimit = limit
				If Self.oldHP > Self.player.hp
					SetBlend SHADEBLEND
					SetColor 255, (size - 65) * 10 + 32, 16
					For Local I:Int = limit Until limitOld Step steps
						DrawLine positionX + CosFast[I] * size, positionY - SinFast[I] * size, positionX + CosFast[I + steps] * size, positionY - SinFast[I + steps] * size
					Next
				ElseIf Self.oldHP < Self.player.hp
					SetColor 255, 192, 0
					SetBlend ALPHABLEND
					SetAlpha 0.15
					For Local I:Int = limitOld Until limit Step steps
						DrawLine positionX + CosFast[I] * size, positionY - SinFast[I] * size, positionX + CosFast[I + steps] * size, positionY - SinFast[I + steps] * size
					Next
					
					drawLimit = limitOld
				EndIf
				
				' Old HP
				SetBlend SOLIDBLEND
				SetColor 255, (size - 65) * 10, 0
				For Local I:Int = start To drawLimit Step steps
					DrawLine positionX + CosFast[I] * size, positionY - SinFast[I] * size, positionX + CosFast[I + steps] * size, positionY - SinFast[I + steps] * size
				Next
			Next
			SetLineWidth 1
		EndIf
		
		' Optimization images
		SetBlend ALPHABLEND
		SetAlpha 1
		SetColor 255, 255, 255
		If limit > 180 And limitOld > 180
			DrawImage Self.imgHP[0], positionX + 1, positionY + 1
		EndIf
		If limit > 270 And limitOld > 270
			DrawImage Self.imgHP[1], positionX + 1, positionY
		EndIf
		If limit > 360 And limitOld > 360
			DrawImage Self.imgHP[2], positionX, positionY
		EndIf
		If limit >= 450
			DrawImage Self.imgHP[3], positionX, positionY + 1
		EndIf
		
		' Save HP
		If MilliSecs() - Self.lastHPUpdate > 400 Or Self.oldHP = Self.player.hp
			Self.oldHP = Self.player.hp
			Self.lastHPUpdate = MilliSecs()
		EndIf
	End Method
	
	' DrawMP
	Method DrawMP() 
		' TODO: Remove hardcoded stuff
		Local limit:Int = 118 - (Self.player.mp / Self.player.maxMP) * 118
		SetColor 255, 255, 255
		SetAlpha 0.35
		
		For Local I:Int = 0 Until limit
			DrawImage Self.imgMP, 16 + 80, 16 + 80 - 118 / 2 + I, I
		Next
		
		SetAlpha 1
		For Local I:Int = limit Until 118
			DrawImage Self.imgMP, 16 + 80, 16 + 80 - 118 / 2 + I, I
		Next
	End Method
	
	' AddMPEffect
	Function AddMPEffect() 
		Local maxCircles:Float = 8
		For Local I:Int = 0 To maxCircles
			Local degree:Int = Rand(0, 359)
			TParticleTween.Create(..
				gsInGame.grpPostEffects,..
				500,..
				gsInGame.imgMPFull,..
				gsInGame.statusX, gsInGame.statusY,..
				gsInGame.statusX, gsInGame.statusY,..
				0.1, 0.01,..
				degree, degree,..
				1, 1 + (0.3) * I / maxCircles,..
				1, 1 + (0.3) * I / maxCircles,..
				255, 255, 255,..
				255, 255, 255..
				..
			)
		Next
	End Function
	
	' GetEffectGroup
	Method GetEffectGroup:TParticleGroup(yPos:Int)
		If Self.player.animWalk.GetDirection() = TAnimationWalk.DIRECTION_UP
			yPos :- Self.map.tileSizeY / 2
		Else
			yPos :+ Self.map.tileSizeY / 2
		EndIf
		
		Local row:Int = yPos / Self.map.tileSizeY
		If row < 0
			row = 0
		EndIf
		If row >= Self.map.height
			row = Self.map.height - 1
		EndIf
		Return Self.grpSkillEffects[row]
	End Method
	
	' Remove
	Method Remove()
		?Threaded
			AtomicSwap Self.threadsRunning, False
			WaitThread Self.grpSkillEffectsCleanThread
		?
		
		game.logger.Write("Average FPS was: " + Int(Self.frameCounter.GetAverageFPS()))
		
		If Self.inNetworkMode
			' TODO: Back to arena
		EndIf
	End Method
	
	' OnAppSuspended
	Method OnAppSuspended()
		Self.Pause()
		ShowMouse()
	End Method
	
	' OnAppReactivated
	Method OnAppReactivated()
		Self.Resume()
		HideMouse()
		
		' TODO: Fix HideMouse() bug (temporary bug fix is used in the Update() function)
	End Method
	
	' Pause
	Method Pause()
		If Self.inNetworkMode = False
			Self.isPausedFlag = True
		EndIf
	End Method
	
	' Resume
	Method Resume()
		Self.isPausedFlag = False
	End Method
	
	' IsPaused
	Method IsPaused:Int()
		Return Self.isPausedFlag
	End Method
	
	' ToString
	Method ToString:String()
		Return "InGame"
	End Method
	
	' OnMapRow
	Function OnMapRow(row:Int)
		' Parties (network mode)
		For Local party:TParty = EachIn gsInGame.parties
			For Local player:TPlayer = EachIn party.GetMembersList()
				If row = player.tileY
					' Draw nickname
					If gsInGame.inNetworkMode
						.SetColor 0, 0, 0
						.SetImageFont gsInGame.playerTitleFont
						DrawTextCentered player.GetName(), player.GetMidX(), player.GetY() - 24
						
						player.DrawHPAndMP()
						player.DrawPartyIndicator()
					EndIf
					
					' This will ResetMax2D()
					player.Draw()
				EndIf
			Next
		Next
		
		' TODO: Optimize this
		For Local enemy:TEnemy = EachIn gsInGame.enemiesOnScreen
			If row = Int(enemy.y / gsInGame.map.tileSizeY)
				enemy.Draw()
			EndIf
		Next
		
		'gsInGame.grpSkillEffectsMutex.Lock()
			gsInGame.grpSkillEffects[row].Draw()
		'gsInGame.grpSkillEffectsMutex.Unlock()
		ResetMax2D()
	End Function
	
	' OnSkillHover
	Function OnSkillHover(widget:TWidget)
		If TSkill(widget.GetMetaData())
			Local skill:TSkill = TSkill(widget.GetMetaData())
			Print skill.GetName()
		ElseIf TBuff(widget.GetMetaData())
			
		EndIf
	End Function
	
	' OnBuffAdd
	Function OnBuffAdd(buff:TBuff)
		Global buffCount:Int = 0
		
		Local buffView:TWidget
		If buff.IsDebuff()
			buffView = gsInGame.debuffView
		Else
			buffView = gsInGame.buffView
		EndIf
		
		buffCount :+ 1
		Local con:TContainer = TContainer.Create("buff" + buffCount)
		Local imgBox:TImageBox = TImageBox.Create("buff" + buffCount + "_icon", buff.GetImage())
		Local label:TLabel = TLabel.Create("buff" + buffCount + "_label", buff.GetRemainingTime())
		label.Dock(TWidget.DOCK_BOTTOM)
		imgBox.SetSize(1.0, 1.0)
		imgBox.SetBorderWidth(1)
		con.Add(imgBox)
		con.Add(label)
		con.SetMetaData(buff)
		buffView.Add(con)
		
		buffView.ApplyLayoutTable(1, buffView.GetNumberOfChilds())
		buffView.SetSizeAbs(buffView.GetNumberOfChilds() * buffView.GetHeight(), -1)
		
		'TLabel.Create("buff" + buffCount + "_label", buff.GetName())
	End Function
	
	' OnBuffRemove
	Function OnBuffRemove(buff:TBuff)
		Local buffView:TWidget
		If buff.IsDebuff()
			buffView = gsInGame.debuffView
		Else
			buffView = gsInGame.buffView
		EndIf
		
		For Local widget:TWidget = EachIn buffView.GetChildsList()
			If widget.GetMetaData() = buff
				widget.Remove()
				buffView.ApplyLayoutTable(1, buffView.GetNumberOfChilds())
				buffView.SetSizeAbs(buffView.GetNumberOfChilds() * buffView.GetHeight(), -1)
				Return
			EndIf
		Next
	End Function
	
	' UpdateParticlesOutOfScreen
	Method UpdateParticlesOutOfScreen(rangeTiles:Int = 100)
		Local I:Int
		
		'Self.grpSkillEffectsMutex.Lock()
			For I = Max(0, gsInGame.map.tileTop - rangeTiles) Until gsInGame.map.tileTop
				Self.grpSkillEffects[I].Update()
			Next
			
			For I = Min(gsInGame.map.tileBottom + 0, gsIngame.map.height - 1) Until Min(gsInGame.map.height, gsInGame.map.tileBottom + rangeTiles)
				Self.grpSkillEffects[I].Update()
			Next
		'Self.grpSkillEffectsMutex.Unlock()
	End Method
	
	' UpdateParticlesOutOfScreenThread
	?Threaded
	Function UpdateParticlesOutOfScreenThread:Object(data:Object)
		While gsInGame.threadsRunning
			gsInGame.UpdateParticlesOutOfScreen()
			Delay 200
			
			'GCCollect()
			'Delay 10
		Wend
		
		Return Null
	End Function
	?
	
	Rem
	' CreateSkillInstance
	Method CreateSkillInstance(nCaster:TEntity)
		TSkillInstance.Create(nCaster, nCaster.castingSkill.luaScriptInstance)
	End Method
	End Rem
	
	' Create
	Function Create:TGameStateInGame(gameRef:TGame)
		Local gs:TGameStateInGame = New TGameStateInGame
		gameRef.RegisterGameState("InGame", gs)
		Return gs
	End Function
End Type

' TActionMove
Type TActionMove Extends TAction
	Field direction:Int
	
	' Init
	Method Init(nDirection:Int)
		Self.direction = nDirection
	End Method
	
	' Exec
	Method Exec(trigger:TTrigger)
		Select Self.direction
			Case TAnimationWalk.DIRECTION_UP
				If gsInGame.player.movementY <> 1
					If gsInGame.inNetworkMode
						gsInGame.room.streamMutex.Lock()
							gsInGame.room.stream.WriteByte(100)
							gsInGame.room.stream.WriteByte(gsInGame.player.movementX)
							gsInGame.room.stream.WriteByte(1)
							gsInGame.room.stream.WriteFloat(gsInGame.player.x)
							gsInGame.room.stream.WriteFloat(gsInGame.player.y)
						gsInGame.room.streamMutex.Unlock()
					EndIf
					gsInGame.player.movementY = 1
				EndIf
				'gsInGame.map.Scroll(0, -game.speed)
				
			Case TAnimationWalk.DIRECTION_DOWN
				If gsInGame.player.movementY <> 2
					If gsInGame.inNetworkMode
						gsInGame.room.streamMutex.Lock()
							gsInGame.room.stream.WriteByte(100)
							gsInGame.room.stream.WriteByte(gsInGame.player.movementX)
							gsInGame.room.stream.WriteByte(2)
							gsInGame.room.stream.WriteFloat(gsInGame.player.x)
							gsInGame.room.stream.WriteFloat(gsInGame.player.y)
						gsInGame.room.streamMutex.Unlock()
					EndIf
					gsInGame.player.movementY = 2
				EndIf
				'gsInGame.map.Scroll(0, game.speed)
				
			Case TAnimationWalk.DIRECTION_LEFT
				If gsInGame.player.movementX <> 1
					If gsInGame.inNetworkMode
						gsInGame.room.streamMutex.Lock()
							gsInGame.room.stream.WriteByte(100)
							gsInGame.room.stream.WriteByte(1)
							gsInGame.room.stream.WriteByte(gsInGame.player.movementY)
							gsInGame.room.stream.WriteFloat(gsInGame.player.x)
							gsInGame.room.stream.WriteFloat(gsInGame.player.y)
						gsInGame.room.streamMutex.Unlock()
					EndIf
					gsInGame.player.movementX = 1
				EndIf
				
				'gsInGame.map.Scroll(-game.speed, 0)
				
			Case TAnimationWalk.DIRECTION_RIGHT
				If gsInGame.player.movementX <> 2
					If gsInGame.inNetworkMode
						gsInGame.room.streamMutex.Lock()
							gsInGame.room.stream.WriteByte(100)
							gsInGame.room.stream.WriteByte(2)
							gsInGame.room.stream.WriteByte(gsInGame.player.movementY)
							gsInGame.room.stream.WriteFloat(gsInGame.player.x)
							gsInGame.room.stream.WriteFloat(gsInGame.player.y)
						gsInGame.room.streamMutex.Unlock()
					EndIf
					gsInGame.player.movementX = 2
				EndIf
				
				'gsInGame.map.Scroll(game.speed, 0)
		End Select
		
		Rem
		If TInputSystem.GetKeyDown(KEY_UP) Or JoyY() < -deadZone
			walkY :- game.speed
		EndIf
		If TInputSystem.GetKeyDown(KEY_DOWN) Or JoyY() > deadZone
			walkY :+ game.speed
		EndIf
		If TInputSystem.GetKeyDown(KEY_LEFT) Or JoyX() < -deadZone
			walkX :- game.speed
		EndIf
		If TInputSystem.GetKeyDown(KEY_RIGHT) Or JoyX() > deadZone
			walkX :+ game.speed
		EndIf
		End Rem
	End Method
	
	' Create
	Function Create:TActionMove(nDirection:Int)
		Local action:TActionMove = New TActionMove
		action.Init(nDirection)
		Return action
	End Function
End Type

' TActionEnter
Type TActionEnter Extends TAction
	' Init
	Method Init()
		
	End Method
	
	' Exec
	Method Exec(trigger:TTrigger)
		
	End Method
	
	' Create
	Function Create:TActionEnter()
		Local action:TActionEnter = New TActionEnter
		action.Init()
		Return action
	End Function
End Type

' TActionLockDirection
Type TActionLockDirection Extends TAction
	' Init
	Method Init()
		
	End Method
	
	' ExecStart
	Method ExecStart(trigger:TTrigger)
		Local dir:Byte = gsInGame.player.animWalk.GetDirection()
		
		If gsInGame.inNetworkMode
			gsInGame.room.streamMutex.Lock()
				gsInGame.room.stream.WriteByte(101)
				gsInGame.room.stream.WriteByte(dir)
			gsInGame.room.streamMutex.Unlock()
		EndIf
		
		gsInGame.player.SetDirectionLock(dir)
	End Method
	
	' ExecEnd
	Method ExecEnd()
		If gsInGame.inNetworkMode
			gsInGame.room.streamMutex.Lock()
				gsInGame.room.stream.WriteByte(101)
				gsInGame.room.stream.WriteByte(0)
			gsInGame.room.streamMutex.Unlock()
		EndIf
		
		gsInGame.player.SetDirectionLock(False)
	End Method
	
	' Create
	Function Create:TActionLockDirection()
		Local action:TActionLockDirection = New TActionLockDirection
		action.Init()
		Return action
	End Function
End Type
