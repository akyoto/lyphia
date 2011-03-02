SuperStrict

Import "Global.bmx"
Import "TParticleSystem.bmx"
Import "GUI/TGUI.bmx"

AppTitle = "Blitzprog Particle Editor"

Graphics 800, 600, 0, 60

Local pGroup:TParticleGroup = TParticleGroup.Create()

Local x:Int = GraphicsWidth() / 2
Local y:Int = GraphicsHeight() / 2 + 100

SetMaskColor 255, 255, 255
Local particleImg:TImage = LoadImage(FS_ROOT + "data/particles/particle-wind.png")
MidHandleImage particleImg

Global autoSlide:TList = CreateList()

' TParticleSettings
Type TParticleSettings
	Global count:Int = 0
	
	Field window:TWindow
	
	Field r:TSlider
	Field g:TSlider
	Field b:TSlider
	
	Field sX:TSlider
	Field sY:TSlider
	
	Field rot:TSlider
	
	Field a:TSlider
	
	' Init
	Method Init(gui:TGUI)
		If TParticleSettings.count = 0
			Self.window = TWindow.Create("settings" + TParticleSettings.count, "Settings Start")
		Else
			Self.window = TWindow.Create("settings" + TParticleSettings.count, "Settings End")
		EndIf
		
		Self.window.SetPositionAbs(0, 24)
		Self.window.SetSize(0.25, 1.0)
		Self.window.SetSizeAbs(0, - 24)
		gui.Add(Self.window)
		
		Self.r = TSlider.Create("r" + TParticleSettings.count, "Red")
		Self.r.SetPositionAbs(5, 5)
		Self.r.SetSize(1.0, 0)
		Self.r.SetSizeAbs(- 10, 24)
		Self.r.SetMinMax(0, 255)
		Self.r.SetDefaultValue(255)
		Self.window.Add(Self.r)
		
		Self.g = TSlider.Create("g" + TParticleSettings.count, "Green")
		Self.g.SetPositionAbs(5, 5 + 24 * 1)
		Self.g.SetSize(1.0, 0)
		Self.g.SetSizeAbs(- 10, 24)
		Self.g.SetMinMax(0, 255)
		Self.g.SetDefaultValue(255)
		Self.window.Add(Self.g)
		
		Self.b = TSlider.Create("b" + TParticleSettings.count, "Blue")
		Self.b.SetPositionAbs(5, 5 + 24 * 2)
		Self.b.SetSize(1.0, 0)
		Self.b.SetSizeAbs(- 10, 24)
		Self.b.SetMinMax(0, 255)
		Self.b.SetDefaultValue(255)
		Self.window.Add(Self.b)
		
		Self.sX = TSlider.Create("scaleX" + TParticleSettings.count, "Scale X")
		Self.sX.SetPositionAbs(5, 5 + 24 * 4)
		Self.sX.SetSize(1.0, 0)
		Self.sX.SetSizeAbs(- 10, 24)
		Self.sX.SetMinMax(0.01, 8.0)
		Self.sX.SetDefaultValue(0.5)
		Self.window.Add(Self.sX)
		
		Self.sY = TSlider.Create("scaleY" + TParticleSettings.count, "Scale Y")
		Self.sY.SetPositionAbs(5, 5 + 24 * 5)
		Self.sY.SetSize(1.0, 0)
		Self.sY.SetSizeAbs(- 10, 24)
		Self.sY.SetMinMax(0.01, 8.0)
		Self.sY.SetDefaultValue(0.5)
		Self.window.Add(Self.sY)
		
		Self.rot = TSlider.Create("rotation" + TParticleSettings.count, "Rotation")
		Self.rot.SetPositionAbs(5, 5 + 24 * 7)
		Self.rot.SetSize(1.0, 0)
		Self.rot.SetSizeAbs(- 10, 24)
		Self.rot.SetMinMax(0, 360)
		Self.rot.SetDefaultValue(0)
		Self.window.Add(Self.rot)
		
		Self.a = TSlider.Create("a" + TParticleSettings.count, "Alpha")
		Self.a.SetPositionAbs(5, 5 + 24 * 9)
		Self.a.SetSize(1.0, 0)
		Self.a.SetSizeAbs(- 10, 24)
		Self.a.SetMinMax(0, 1.0)
		Self.a.SetDefaultValue(0.5)
		Self.window.Add(Self.a)
		
		If TParticleSettings.count = 1
			Self.r.SetValue(0)
			Self.b.SetValue(0)
			Self.sX.SetValue(0.75)
			Self.sY.SetValue(0.75)
			Self.rot.SetValue(360)
			Self.a.SetDefaultValue(0.01)
		EndIf
		
		TParticleSettings.count:+1
	End Method
	
	' Create
	Function Create:TParticleSettings(gui:TGUI)
		Local cfg:TParticleSettings = New TParticleSettings
		cfg.Init(gui)
		Return cfg
	End Function
End Type

Local gui:TGUI = TGUI.Create()
Global pSettings1:TParticleSettings = TParticleSettings.Create(gui)
Global pSettings2:TParticleSettings = TParticleSettings.Create(gui)

pSettings2.window.SetPosition(0.75, 0)

Local generalSettings:TWindow = TWindow.Create("general", "General settings")
generalSettings.SetPosition(0.25, 0.80)
generalSettings.SetSize(0.5, 0.20)
gui.Add(generalSettings)

Global lifeTime:TSlider = TSlider.Create("lifeTime", "Life time")
lifeTime.SetPositionAbs(5, 5)
lifeTime.SetSize(1.0, 0)
lifeTime.SetSizeAbs(- 10, 24)
lifeTime.SetMinMax(50, 2000)
lifeTime.SetDefaultValue(1000)
generalSettings.Add(lifeTime)

Global angle:TSlider = TSlider.Create("lifeTime", "Angle")
angle.SetPositionAbs(5, 5 + 24 * 1)
angle.SetSize(1.0, 0)
angle.SetSizeAbs(- 10, 24)
angle.SetMinMax(0, 23)
angle.SetDefaultValue(23)
generalSettings.Add(angle)

Global particles:TSlider = TSlider.Create("particles", "Particles")
particles.SetPositionAbs(5, 5 + 24 * 2)
particles.SetSize(1.0, 0)
particles.SetSizeAbs(- 10, 24)
particles.SetMinMax(1, 100)
particles.SetDefaultValue(20)
generalSettings.Add(particles)

Local menuBar:TMenuBar = TMenuBar.Create("menuBar", "Editor menu", 0, 0)
menuBar.SetSizeAbs(0, 24)
menuBar.SetSize(1.0, 0) 
menuBar.SetAlpha(0.75)
gui.Add(menuBar)

' File
Local popupFile:TPopupMenu = TPopupMenu.Create("menuFile") 
menuBar.AddMenu("File", popupFile) 
popupFile.AddMenuItem("fileLoad", "Load", LoadFunc)
popupFile.AddMenuItem("fileSave", "Save", SaveFunc)

' AutoSlide for all gadgets
Local sliderMenu:TPopupMenu = lifeTime.GetPopupMenu()
sliderMenu.AddMenuItem("sliderAutoSlide", "AutoSlide", ActivateAutoSlideFunc)
For Local widget:TWidget = EachIn sliderMenu.list
	widget.SetAlpha(0.85)
Next

' Load file
LoadFunc(Null)

While AppTerminate() = 0 And KeyHit(KEY_ESCAPE) = 0
	Cls
	
	TInputSystem.Update()
	gui.Update()
	
	' Auto slide
	For Local slider:TSlider = EachIn autoSlide
		slider.SetValueRel((MilliSecs() / 2 Mod 1000) / 1000.0)
	Next
	
	' Create particles
	For Local I:Int = 1 To particles.GetValue()
		Local degree:Float = Rand(90 - angle.GetValue(), 90 + angle.GetValue())
		TParticleTween.Create( ..
							pGroup,  ..
							lifeTime.GetValue(),  ..
							particleImg,  ..
							x, y,  ..
							x + Cos(degree) * Rand(100, 500), y - Sin(degree) * Rand(100, 500),  ..
							pSettings1.a.GetValue(), pSettings2.a.GetValue(),  ..
							pSettings1.rot.GetValue(), pSettings2.rot.GetValue(),  ..
							pSettings1.sX.GetValue(), pSettings2.sX.GetValue(),  ..
							pSettings1.sY.GetValue(), pSettings2.sY.GetValue(),  ..
							pSettings1.r.GetValue(), pSettings1.g.GetValue(), pSettings1.b.GetValue(),  ..
							pSettings2.r.GetValue(), pSettings2.g.GetValue(), pSettings2.b.GetValue() ..
							..
						)
	Next
	
	'pGroup.Update()
	pGroup.Draw()
	
	gui.Draw()
	
	Flip
Wend

' LoadFunc
Function LoadFunc(widget:TWidget)
	Local ini:TINI = TINI.Create("particle.ini")
	ini.Load()
	
	lifeTime.SetValue(Float(ini.Get("General", "LifeTime")))
	angle.SetValue(Float(ini.Get("General", "Angle")))
	particles.SetValue(Float(ini.Get("General", "ParticlesPerFrame")))
	
	pSettings1.r.SetValue(Float(ini.Get("Start", "R")))
	pSettings1.g.SetValue(Float(ini.Get("Start", "G")))
	pSettings1.b.SetValue(Float(ini.Get("Start", "B")))
	pSettings1.sX.SetValue(Float(ini.Get("Start", "ScaleX")))
	pSettings1.sY.SetValue(Float(ini.Get("Start", "ScaleY")))
	pSettings1.rot.SetValue(Float(ini.Get("Start", "Rotation")))
	pSettings1.a.SetValue(Float(ini.Get("Start", "Alpha")))
	
	pSettings2.r.SetValue(Float(ini.Get("End", "R")))
	pSettings2.g.SetValue(Float(ini.Get("End", "G")))
	pSettings2.b.SetValue(Float(ini.Get("End", "B")))
	pSettings2.sX.SetValue(Float(ini.Get("End", "ScaleX")))
	pSettings2.sY.SetValue(Float(ini.Get("End", "ScaleY")))
	pSettings2.rot.SetValue(Float(ini.Get("End", "Rotation")))
	pSettings2.a.SetValue(Float(ini.Get("End", "Alpha")))
	
	autoSlide.Clear()
	autoSlide = CreateList()
	
	AutoSlideOnLoad(lifeTime)
	AutoSlideOnLoad(angle)
	AutoSlideOnLoad(particles)
	
	AutoSlideOnLoad(pSettings1.r)
	AutoSlideOnLoad(pSettings1.g)
	AutoSlideOnLoad(pSettings1.b)
	AutoSlideOnLoad(pSettings1.sX)
	AutoSlideOnLoad(pSettings1.sY)
	AutoSlideOnLoad(pSettings1.rot)
	AutoSlideOnLoad(pSettings1.a)
	
	AutoSlideOnLoad(pSettings2.r)
	AutoSlideOnLoad(pSettings2.g)
	AutoSlideOnLoad(pSettings2.b)
	AutoSlideOnLoad(pSettings2.sX)
	AutoSlideOnLoad(pSettings2.sY)
	AutoSlideOnLoad(pSettings2.rot)
	AutoSlideOnLoad(pSettings2.a)
End Function

' AutoSlideOnLoad
Function AutoSlideOnLoad(slider:TSlider)
	If slider.GetValue() < 0
		autoSlide.AddLast(slider)
	End If
End Function

' SaveFunc
Function SaveFunc(widget:TWidget)
	Local ini:TINI = TINI.Create("particle.ini")
	Local category:TINICategory
	
	' Auto slide
	For Local slider:TSlider = EachIn autoSlide
		slider.SetValueRel(- 1)
	Next
	
	ini.AddCategory("General")
	category = ini.GetCategory("General")
	category.Add("LifeTime", lifeTime.GetValue())
	category.Add("Angle", angle.GetValue())
	category.Add("ParticlesPerFrame", particles.GetValue())
	
	ini.AddCategory("Start")
	category = ini.GetCategory("Start")
	category.Add("R", pSettings1.r.GetValue())
	category.Add("G", pSettings1.g.GetValue())
	category.Add("B", pSettings1.b.GetValue())
	category.Add("ScaleX", pSettings1.sX.GetValue())
	category.Add("ScaleY", pSettings1.sY.GetValue())
	category.Add("Rotation", pSettings1.rot.GetValue())
	category.Add("Alpha", pSettings1.a.GetValue())
	
	ini.AddCategory("End")
	category = ini.GetCategory("End")
	category.Add("R", pSettings2.r.GetValue())
	category.Add("G", pSettings2.g.GetValue())
	category.Add("B", pSettings2.b.GetValue())
	category.Add("ScaleX", pSettings2.sX.GetValue())
	category.Add("ScaleY", pSettings2.sY.GetValue())
	category.Add("Rotation", pSettings2.rot.GetValue())
	category.Add("Alpha", pSettings2.a.GetValue())
	
	ini.Save()
End Function

' ActivateAutoSlideFunc
Function ActivateAutoSlideFunc(widget:TWidget)
	Local slider:TSlider = TSlider(widget)
	
	If autoSlide.Contains(slider)
		autoSlide.Remove(slider)
	Else
		autoSlide.AddLast(slider)
	EndIf
End Function
