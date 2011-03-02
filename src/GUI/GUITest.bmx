Rem
	Blitzprog GUI
	
	(C) Eduard Urbach
End Rem

' Strict
SuperStrict

' You need this in order to use the Blitzprog Precompiler
'Import BRL.Retro

' Files
Import "TGUI.bmx"

' Set root dir for skin files
FS_ROOT = "../../"

' Window
SetGraphicsDriver GLMax2DDriver()
Graphics 1000, 700

' Load font
'SetImageFont LoadImageFont("../Cartoon Bold.ttf", 12, SMOOTHFONT)

' Create a gui
Local gui:TGUI = TGUI.Create()

Local win:TWindow = TWindow.Create("win", "TestWindow", 0, 0, 0, 0)
gui.root.Add(win)

win.SetPosition(0.25, 0.25) 
win.SetPositionAbs(100, 100)
win.SetSizeAbs(0, 0)
win.SetSize(0.5, 0.5)

Local group1:TGroup = TGroup.Create("group1", "Group 1")
group1.SetSize(1.0, 0.5)
group1.SetPosition(0, 0)
group1.SetColor(255, 128, 0)
win.Add(group1) 

Local group2:TGroup = TGroup.Create("group2", "Group 2")
group2.SetSize(1.0, 0.5) 
group2.SetPosition(0, 0.5) 
group2.SetColor(0, 128, 255)
win.Add(group2)

Local txt:TTextField = TTextField.Create("txt", "TestText", 5, 5)
txt.SetSize(0.5, 0)
txt.SetSizeAbs(0, 24)
'group2.Add(txt)

Local list:TListBox = TListBox.Create("list")
list.SetPosition(0.02, 0.02)
'list.SetSize(0.5, 0.5)
list.SetSizeAbs(200, 100)
list.onItemChange = ListBox_OnItemChange
group2.Add(list)

list.AddItem "Test 1"
list.AddItem "Test 2"
list.AddItem "Test 3"

Print list.needsScrollBar

list.AddItem "Test 1"
list.AddItem "Test 2"
list.AddItem "Test 3"
list.AddItem "Test 1"
list.AddItem "Test 2"
list.AddItem "Test 3"

Print list.needsScrollBar

Local chk:TCheckBox = TCheckBox.Create("chk", "TestCheckBox", 5, 5)
'chk.SetSize(0.5, 0)
'chk.SetSizeAbs(0, 24)
group1.Add(chk)

SetBlend ALPHABLEND

' Main loop
While AppTerminate() = 0 And KeyDown(KEY_ESCAPE) = 0
	TInputSystem.Update()
	gui.Update()
	
	Cls
	
	gui.Draw()
	
	DrawText "Abs: " + win.cAbs.ToString(), 5, 5
	DrawText "Rel: " + win.cRel.ToString(), 5, 25
	
	DrawText "root.rX: " + gui.root.rX, 5, 45
	DrawText "root.rY: " + gui.root.rY, 5, 65
	DrawText "root.rWidth: " + gui.root.rWidth, 5, 85
	DrawText "root.rHeight: " + gui.root.rHeight, 5, 105
	DrawText "root.cRel: " + gui.root.cRel.ToString(), 5, 125
	
	DrawText "Win.padding: " + win.padding.ToString(), 5, 145
	DrawText "Win.rWidth: " + win.rWidth, 5, 165
	DrawText "Win.rHeight: " + win.rHeight, 5, 185
	DrawText "Win.relOffset.x: " + win.GetRelOffsetX(), 5, 205
	DrawText "Win.relOffset.y: " + win.GetRelOffsetY(), 5, 225
	
	DrawText "Cursor: " + txt.cursorStart, 5, 265
	DrawText "CursorEnd: " + txt.cursorEnd, 5, 285
	
	DrawText "MouseHit: " + TInputSystem.GetMouseHit(1), 5, 325
	DrawText "MouseDown: " + TInputSystem.GetMouseDown(1), 5, 345
	
	Flip 1
	WaitSystem
Wend

' Quit
End

' ListBox_OnItemChange
Function ListBox_OnItemChange(widget:TWidget)
	Print TListBox(widget).GetText()
End Function