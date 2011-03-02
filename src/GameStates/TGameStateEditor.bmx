' Strict
SuperStrict

' Modules
Import BRL.Max2D
'Import BtbN.GLDraw2D

' Files
Import "../TGame.bmx"
Import "../TFrameRate.bmx"
Import "../TPlayer.bmx"
Import "../TTileMap.bmx"
Import "../TINILoader.bmx"
Import "../GUI/TGUI.bmx"
Import "../Utilities/Graphics.bmx"

' Global
Global gsEditor:TGameStateEditor

' TGameStateEditor
Type TGameStateEditor Extends TGameState
	Const SCROLL_BORDER:Int = 10
	
	Field frameCounter:TFrameRate
	Field map:TTileMap
	Field regionPreviewFont:TImageFont
	Field currentTile:Byte
	Field currentLayer:Byte
	Field currentEnemyType:String
	Field isEditing:Int
	Field lastTimeEdited:Int
	Field returnedFromEditing:Int
	Field oldGUIAlpha:Float
	Field scrollSpeed:Float
	Field loggerEditor:TLog
	
	' Options
	Field viewGrid:Int
	Field viewCollision:Int
	Field viewStart:Int
	Field viewTemplate:Int
	Field viewByteCode:Int
	Field viewAutoTiles:Int
	Field viewHighlightLayer:Int
	Field filterTemplate:Int
	
	' GUI
	Field gui:TGUI
	Field guiFont:TImageFont
	Field guiFontTitle:TImageFont
	Field infoWindow:TWindow
	Field posLabel:TLabel
	Field tilesDrawnLabel:TLabel
	Field tileWindow:TWindow
	Field optionsWindow:TWindow
	Field skillsWindow:TWindow
	Field skillsList:TListBox
	Field scriptsWindow:TWindow
	Field scriptsList:TListBox
	Field enemiesWindow:TWindow
	Field enemiesList:TListBox
	Field layersWindow:TWindow
	Field layersList:TListBox
	Field mapsWindow:TWindow
	Field mapsList:TListBox
	Field mapOptions:TGroup
	Field viewOptions:TGroup
	Field zoomSlider:TSlider
	Field tileMenu:TPopupMenu
	
	' Images
	Field arrowImg:TImage
	Field scriptImg:TImage
	Field templateImg:TImage
	Field templatePixmap:TPixmap
	
	' Cursor
	Field x:Int
	Field y:Int
	
	' Tile menu
	Field savedX:Int
	Field savedY:Int
	
	?Threaded
		Field fillPreviewThread:TThread
		Field fillPreviewNodes:TList
		Field fillPreviewNodesMutex:TMutex
	?
	
	' Init
	Method Init()
		' Detail Log
		?Debug
			Self.loggerEditor = TLog.Create(StandardIOStream)
		?Not Debug
			Self.loggerEditor = TLog.Create(WriteFile(FS_ROOT + "logs/editor.txt"))
		?
		
		Self.isEditing = 0
		Self.lastTimeEdited = 0
		Self.returnedFromEditing = 0
		
		Self.currentEnemyType = ""
		
		Self.currentLayer = 0
		Self.x = 0
		Self.y = 0
		
		' Init
		SetBlend ALPHABLEND
		SetMaskColor 255, 255, 255
		MoveMouse game.gfxWidthHalf, game.gfxHeightHalf
		
		' Frame counter
		frameCounter = TFrameRate.Create()
		
		' Init resources
		Self.InitResources()
		
		' Init GUI
		Self.InitGUI()
		
		' TileMap
		Self.InitEngine()
		
		' TODO: Remove hardcoded stuff
		Self.SetScrollSpeed(2)
		Self.currentTile = 10
		
		' Fill preview
		?Threaded
			Self.fillPreviewThread = Null
			Self.fillPreviewNodes = CreateList()
			Self.fillPreviewNodesMutex = CreateMutex()
		?
		
		' Memory usage
		Self.loggerEditor.Write("GC Memory allocated: " + GCMemAlloced() + " bytes")
	End Method
	
	' InitResources
	Method InitResources()
		' Load scripts
		game.scriptMgr.AddResourcesFromDirectory(FS_ROOT + "data/enemies/")
		game.scriptMgr.AddResourcesFromDirectory(FS_ROOT + "data/scripts/")
		
		' Load fonts
		game.fontMgr.AddResourcesFromDirectory(FS_ROOT + "data/fonts/")
		
		Self.guiFont = game.fontMgr.Get("EditorGUIFont")
		Self.guiFontTitle = game.fontMgr.Get("EditorGUITitleFont")
 		Self.regionPreviewFont = game.fontMgr.Get("RegionFont")
		
		' Load images
		game.imageMgr.SetFlags(FILTEREDIMAGE | MIPMAPPEDIMAGE)
		game.imageMgr.AddResourcesFromDirectory(FS_ROOT + "data/editor/")
		Self.scriptImg = game.imageMgr.Get("editor-script")
		Self.arrowImg = game.imageMgr.Get("collision-arrow")
		MidHandleImage Self.arrowImg
		
		' Map template
		Self.LoadTemplate()
	End Method
	
	' InitEngine
	Method InitEngine()
		' TileMap
		Self.map = TTileMap.Create()
		Self.map.LoadINI(FS_ROOT + "data/layers/tilemap.ini")
		Self.map.SetScreenSize(game.gfxWidth, game.gfxHeight)
		Self.map.InitTextureAtlas()
		Self.map.LoadLayers(FS_ROOT + "data/layers/layer-")
		
		' Load a map
		Self.mapsList.SelectItem(0)
		
		' Fill tile window with tile data
		For Local layer:Int = 1 To Self.map.layers
			' Add layers to layer selection
			Local ini:TINI = TINI.Create(FS_ROOT + "data/layers/layer-" + layer + "/layer.ini")
			ini.Load()
			
			Self.layersList.AddItem("[" + layer + "] " + ini.Get("Layer", "Name"))
			
			' Tile window
			Local currentContainer:TGroup
			currentContainer = TGroup.Create("tilesContainer" + layer, "Tiles[" + layer + "]")
			currentContainer.SetSize(1.0, 1.0)
			currentContainer.SetColor(0, 0, 0)
			
			For Local byteCode:Int = 1 Until TTileMap.MAX_TILES
				If Self.map.byteToTile[layer - 1, byteCode] <> TTileType.NullTile
					Local widget:TWidget = TImageBox.Create(String(byteCode), Self.map.atlasImage[layer - 1], byteCode, 0, 0)
					widget.onClick = TGameStateEditor.SetTileByWidget
					currentContainer.Add(widget)
				EndIf
			Next
			
			Self.tileWindow.SetSizeAbs(Self.map.GetTileSizeX() * 6, Self.map.GetTileSizeY() * 5)
			currentContainer.ApplyLayoutTable(5, 6, True)
			currentContainer.SetVisible(layer = 1)
			Self.tileWindow.Add(currentContainer)
		Next
		Self.layersList.SelectItem(0)
		
		' Change tile window layout
		Self.tileWindow.UseCurrentAreaAsClientArea()
		Self.tileWindow.SetPositionAbs(5, -Self.tileWindow.GetHeight() - 5)
		
		' TODO: Remove hardcoded stuff
		'Self.map.FillAll(0, 1)
		'Self.map.FillAll(1, 0)
	End Method
	
	' InitGUI
	Method InitGUI()
		Self.gui = TGUI.Create()
		
		' Info window
		Self.infoWindow = TWindow.Create("infoWindow", "Info", -155, -100, 150, 95)
		Self.infoWindow.SetPosition(1.0, 1.0)
		Self.gui.Add(infoWindow)
		
		Local gfxLabel:TLabel = TLabel.Create("gfxLabel", game.gfxWidth + " x " + game.gfxHeight, 5, 5)
		Self.infoWindow.Add(gfxLabel) 
		
		Self.posLabel = TLabel.Create("posLabel", "", 5, 5 + gfxLabel.textSizeY + 5)
		Self.infoWindow.Add(Self.posLabel)
		
		Self.tilesDrawnLabel = TLabel.Create("tilesDrawLabel", "", 5, 5 + gfxLabel.textSizeY * 2 + 5 * 2)
		Self.infoWindow.Add(Self.tilesDrawnLabel)
		
		' Tile window
		Self.tileWindow = TWindow.Create("tileWindow", "Tiles")
		Self.tileWindow.SetPosition(0, 1.0)
		Self.gui.Add(Self.tileWindow)
		
		' Options window
		Self.optionsWindow = TWindow.Create("optionsWindow", "Options", -245, 5 + 24, 240, 260)
		Self.optionsWindow.SetPosition(1.0, 0)
		Self.optionsWindow.SetPadding(5, 5, 5, 5)
		Self.gui.Add(Self.optionsWindow)
		
		' Enemies window
		Self.enemiesWindow = TWindow.Create("enemiesWindow", "Enemies", 5, 5 + 24, 130, 0)
		Self.enemiesWindow.SetSize(0, 0.2)
		Self.gui.Add(Self.enemiesWindow)
		
		Self.enemiesList = TListBox.Create("enemiesList")
		Self.enemiesList.onItemChange = TGameStateEditor.ChangeEnemyType
		Self.enemiesList.SetSize(1.0, 1.0)
		Self.enemiesWindow.Add(Self.enemiesList)
		
		Local files:String[] = LoadDir(FS_ROOT + "data/enemies/")
		For Local file:String = EachIn files
			If ExtractExt(file).ToLower() = "lua"
				Self.enemiesList.AddItem(StripAll(file))
			EndIf
		Next
		
		' Scripts window
		Self.scriptsWindow = TWindow.Create("scriptsWindow", "Scripts", 5 + Self.enemiesWindow.GetWidth() + 5, 5 + 24, 130, 0)
		Self.scriptsWindow.SetSize(0, 0.2)
		Self.gui.Add(Self.scriptsWindow)
		
		Self.scriptsList = TListBox.Create("scriptsList")
		Self.scriptsList.onItemChange = TGameStateEditor.ChangeEnemyType
		Self.scriptsList.SetSize(1.0, 1.0)
		Self.scriptsWindow.Add(Self.scriptsList)
		
		files = LoadDir(FS_ROOT + "data/scripts/")
		For Local file:String = EachIn files
			If ExtractExt(file).ToLower() = "lua"
				Self.scriptsList.AddItem(StripAll(file))
			EndIf
		Next
		
		' Maps window
		Self.mapsWindow = TWindow.Create("mapsWindow", "Maps", -135, 0, 130, 0)
		Self.mapsWindow.SetPosition(1.0, 0.5)
		Self.mapsWindow.SetSize(0, 0.2)
		Self.gui.Add(Self.mapsWindow)
		
		Self.mapsList = TListBox.Create("mapsList")
		Self.mapsList.onItemChange = TGameStateEditor.LoadFunc
		Self.mapsList.SetSize(1.0, 1.0)
		Self.mapsWindow.Add(Self.mapsList)
		
		Self.ReloadMapList()
		
		Rem
		' Skills window
		Self.skillsWindow = TWindow.Create("skillsWindow", "Skills", 5 + Self.scriptsWindow.GetWidth() + 5, 5 + 24, 120, 300)
		Self.gui.Add(Self.skillsWindow)
		
		Self.skillsList = TListBox.Create("skillsList")
		Self.skillsList.onItemChange = TGameStateEditor.ChangeSkillType
		Self.skillsList.SetSize(1.0, 1.0)
		Self.skillsWindow.Add(Self.skillsList)
		
		files = LoadDir(FS_ROOT + "data/skills/")
		For Local file:String = EachIn files
			If ExtractExt(file).ToLower() = "lua"
				Self.skillsList.AddItem(StripAll(file))
			EndIf
		Next
		
		Self.skillsWindow.SetVisible(False)
		End Rem
		
		' Layers window
		Self.layersWindow = TWindow.Create("layersWindow", "Layers", 5, -75, 130, 0)
		Self.layersWindow.SetPosition(0.0, 0.54)
		Self.layersWindow.SetSize(0, 0.2)
		Self.gui.Add(Self.layersWindow)
		
		Self.layersList = TListBox.Create("skillsList")
		Self.layersList.onItemChange = TGameStateEditor.ChangeLayer
		Self.layersList.SetSize(1.0, 1.0)
		Self.layersWindow.Add(Self.layersList)
		
		' Map options
		Self.mapOptions = TGroup.Create("mapOptions", "Map options", 0, 0)
		Self.mapOptions.SetPosition(0, 0)
		Self.mapOptions.SetSize(1.0, 0.5)
		Self.mapOptions.SetAlpha(0)
		Self.optionsWindow.Add(Self.mapOptions)
		
		' View options
		Self.viewOptions = TGroup.Create("viewOptions", "View options", 0, 0)
		Self.viewOptions.SetPosition(0, 0.5)
		Self.viewOptions.SetSize(1.0, 0.5)
		Self.viewOptions.SetAlpha(0)
		Self.optionsWindow.Add(Self.viewOptions)
		
		' View options elements
		Local gridCheckBox:TCheckBox = TCheckBox.Create("gridCheckBox", "Grid", 0, 0)
		gridCheckBox.onClick = TGameStateEditor.ToggleGrid
		Self.viewOptions.Add(gridCheckBox)
		
		Local movementCheckBox:TCheckBox = TCheckBox.Create("movementCheckBox", "Collision", 0, 20)
		movementCheckBox.onClick = TGameStateEditor.ToggleMovement
		Self.viewOptions.Add(movementCheckBox)
		
		Local startTileCheckBox:TCheckBox = TCheckBox.Create("startCheckBox", "Start", 0, 40) 
		startTileCheckBox.onClick = TGameStateEditor.ToggleStart
		startTileCheckBox.SetState(True)
		Self.viewOptions.Add(startTileCheckBox)
		
		Local templCheckBox:TCheckBox = TCheckBox.Create("templCheckBox", "Template", 0, 0)
		templCheckBox.onClick = TGameStateEditor.ToggleTemplate
		templCheckBox.SetPosition(0.5, 0)
		Self.viewOptions.Add(templCheckBox)
		
		Local templFilteredCheckBox:TCheckBox = TCheckBox.Create("templFilteredCheckBox", "Filter template", 0, 20)
		templFilteredCheckBox.onClick = TGameStateEditor.ToggleTemplateFilter
		templFilteredCheckBox.SetPosition(0.5, 0)
		Self.viewOptions.Add(templFilteredCheckBox)
		
		Local autoTilesCheckBox:TCheckBox = TCheckBox.Create("autoTileCheckBox", "Autotiles", 0, 40)
		autoTilesCheckBox.onClick = TGameStateEditor.ToggleAutoTiles
		autoTilesCheckBox.SetPosition(0.5, 0)
		autoTilesCheckBox.SetState(True)
		Self.viewOptions.Add(autoTilesCheckBox)
		
		Local highlightLayerCheckBox:TCheckBox = TCheckBox.Create("highlightLayerCheckBox", "Highlight layer", 0, 60)
		highlightLayerCheckBox.onClick = TGameStateEditor.ToggleHighlightLayer
		highlightLayerCheckBox.SetPosition(0.5, 0)
		highlightLayerCheckBox.SetState(False)
		Self.viewOptions.Add(highlightLayerCheckBox)
		
		Local byteCodeCheckBox:TCheckBox = TCheckBox.Create("byteCodeCheckBox", "Byte code", 0, 60)
		byteCodeCheckBox.onClick = TGameStateEditor.ToggleByteCode
		Self.viewOptions.Add(byteCodeCheckBox)
		
		Local mapNameLabel:TLabel = TLabel.Create("mapNameLabel", "Name: ", 0, 0 + 2)
		Self.mapOptions.Add(mapNameLabel)
		
		Self.zoomSlider = TSlider.Create("zoomSlider", "Zoom", 0, -20)
		Self.zoomSlider.SetMinMax(0.125, 2.0)
		Self.zoomSlider.SetDefaultValue(1.0)
		Self.zoomSlider.SetPosition(0, 1.0)
		Self.zoomSlider.SetSize(1.0, 0) 
		Self.zoomSlider.SetSizeAbs(0, 20)
		Self.zoomSlider.onSlide = TGameStateEditor.ChangeZoom
		Self.viewOptions.Add(Self.zoomSlider)		
		
		' Map options elements
		Local mapNameInput:TTextField = TTextField.Create("mapNameInput", "", 0, 0)
		mapNameInput.SetPosition(0.25, 0)
		mapNameInput.SetSize(0.75, 0)
		mapNameInput.SetSizeAbs(0, 20)
		Self.mapOptions.Add(mapNameInput)
		
		Local mapSizeXLabel:TLabel = TLabel.Create("mapWidthLabel", "Width: ", 0, 25 + 2)
		Self.mapOptions.Add(mapSizeXLabel)
		
		Local mapSizeInputX:TTextField = TTextField.Create("mapWidthInput", "", 0, 25)
		mapSizeInputX.SetPosition(0.25, 0)
		mapSizeInputX.SetSize(0.75, 0)
		mapSizeInputX.SetSizeAbs(0, 20)
		Self.mapOptions.Add(mapSizeInputX)
		
		Local mapSizeYLabel:TLabel = TLabel.Create("mapHeightLabel", "Height: ", 0, 50 + 2)
		Self.mapOptions.Add(mapSizeYLabel)
		
		Local mapSizeInputY:TTextField = TTextField.Create("mapHeightInput", "", 0, 50)
		mapSizeInputY.SetPosition(0.25, 0)
		mapSizeInputY.SetSize(0.75, 0)
		mapSizeInputY.SetSizeAbs(0, 20)
		Self.mapOptions.Add(mapSizeInputY)
		
		Local mapUpdate:TButton = TButton.Create("mapUpdate", "Update", 0, 75)
		mapUpdate.SetSize(1.0, 0)
		mapUpdate.SetSizeAbs(0, 24)
		mapUpdate.SetAlpha(0.75)
		mapUpdate.onClick = TGameStateEditor.UpdateMapFunc
		Self.mapOptions.Add(mapUpdate)
		
		' Menu
		Self.InitGUIMenu()
		
		' Cursors
		Self.gui.SetCursor("default")
		Self.gui.HideCursor()
		ShowMouse()
		
		' Apply font to all widgets
		Self.gui.SetFont(Self.guiFont)
		
		' Fonts
		For Local window:TWidget = EachIn Self.gui.GetRoot().GetChildsList()
			If TWindow(window)
				window.SetFont(Self.guiFontTitle)
			EndIf
		Next
	End Method
	
	' InitGUIMenu
	Method InitGUIMenu() 
		Local popupAlphaValue:Float = 0.85
		
		Local menuBar:TMenuBar = TMenuBar.Create("menuBar", "Editor menu", 0, 0) 
		menuBar.SetSizeAbs(0, 20) 
		menuBar.SetSize(1.0, 0) 
		menuBar.SetAlpha(0.75)
		Self.gui.GetRoot().Add(menuBar)
		
		' File
		Local popupFile:TPopupMenu = TPopupMenu.Create("menuFile")
		popupFile.SetAlpha(popupAlphaValue)
		menuBar.AddMenu("File", popupFile)
		popupFile.AddMenuItem("fileLoad", "Load", TGameStateEditor.LoadFunc)
		popupFile.AddMenuItem("fileSave", "Save", TGameStateEditor.SaveFunc)
		popupFile.AddMenuItem("filePlay", "Play", TGameStateEditor.PlayFunc)
		
		' Edit
		Local popupEdit:TPopupMenu = TPopupMenu.Create("menuEdit")
		popupEdit.SetAlpha(popupAlphaValue)
		menuBar.AddMenu("Edit", popupEdit)
		popupEdit.AddMenuItem("editGoStart", "Go to start point", TGameStateEditor.GoToStartLocation)
		popupEdit.AddMenuItem("editClearLayer", "Clear layer", TGameStateEditor.ClearLayer)
		popupEdit.AddMenuItem("editGenTemplate", "Generate from template", TGameStateEditor.GenerateFromTemplate)
		
		' Windows
		Local popupWindows:TPopupMenu = TPopupMenu.Create("menuWindows")
		popupWindows.SetAlpha(popupAlphaValue)
		menuBar.AddMenu("Windows", popupWindows)
		
		For Local window:TWidget = EachIn Self.gui.GetRoot().GetChildsList()
			If TWindow(window)
				Local icon:TImage = Null
				If window.IsVisible()
					icon = Self.gui.skin.checkbox.checked
				Else
					icon = Self.gui.skin.checkbox.unchecked
				EndIf
				popupWindows.AddMenuItem("windows" + window.GetText(), window.GetText(), TGameStateEditor.ToggleWindowVisibility, icon)
				popupWindows.SetMenuItemAffectingWidget("windows" + window.GetText(), window)
			EndIf
		Next
		
		' Popup for root
		Self.tileMenu = TPopupMenu.Create("menuTile")
		Self.tileMenu.SetAlpha(popupAlphaValue)
		Self.gui.AddMenu(Self.tileMenu)
		Self.tileMenu.onVisible = TGameStateEditor.PopupMenuFunc
		Self.tileMenu.AddMenuItem("popupCopy", "Copy", TGameStateEditor.CopyFunc)
		'Self.tileMenu.AddMenuItem("popupSelect", "Select area (not implemented yet)", TGameStateEditor.SelectAreaFunc)
		Self.tileMenu.AddMenuItem("popupAddEnemy", "Add enemy spawn", TGameStateEditor.AddEnemySpawnFunc)
		Self.tileMenu.AddMenuItem("popupRemoveEnemy", "Remove enemy spawn", TGameStateEditor.RemoveEnemySpawnFunc)
		Self.tileMenu.AddMenuItem("popupAddScript", "Add script", TGameStateEditor.AddScriptFunc)
		Self.tileMenu.AddMenuItem("popupRemoveScript", "Remove script", TGameStateEditor.RemoveScriptFunc)
		Self.tileMenu.AddMenuItem("popupFill", "Fill", TGameStateEditor.FillFunc)
		Self.tileMenu.AddMenuItem("popupFillDiagonally", "Fill diagonally", TGameStateEditor.FillDiagonalFunc)
		Self.tileMenu.AddMenuItem("popupErase", "Erase", TGameStateEditor.EraseFunc)
		Self.tileMenu.AddMenuItem("popupSetStart", "Set start point", TGameStateEditor.SetStartTileFunc)
		
		Self.tileMenu.SetMenuItemIcon("popupAddScript", Self.scriptImg)
		Self.tileMenu.SetMenuItemIcon("popupRemoveScript", Self.scriptImg)
		
		' Hover
		?Threaded
			Self.tileMenu.GetChild("popupFill").onEnter = TGameStateEditor.FillPreviewFunc
			Self.tileMenu.GetChild("popupFill").onLeave = TGameStateEditor.FillPreviewHideFunc
			Self.tileMenu.GetChild("popupFillDiagonally").onEnter = TGameStateEditor.FillPreviewFunc
			Self.tileMenu.GetChild("popupFillDiagonally").onLeave = TGameStateEditor.FillPreviewHideFunc
		?
		
		' Update menu
		TGameStateEditor.ChangeEnemyType(Self.enemiesList)
	End Method
	
	' LoadTemplate
	Method LoadTemplate()
		Self.templatePixmap = LoadPixmap(FS_ROOT + "data/maps/lyphia-template.png")
		Self.templateImg = LoadImage(Self.templatePixmap, Self.filterTemplate * FILTEREDIMAGE) 
	End Method
	
	' Update
	Method Update()
		' Update input system
		TInputSystem.Update()
		
		' Don't do anything if mouse/keyboard has not been used
		If TInputSystem.SomethingHappened() = False And MilliSecs() - Self.returnedFromEditing > 250
			?Threaded
				If Self.fillPreviewThread = Null Or ThreadRunning(Self.fillPreviewThread) = False
					Return
				EndIf
			?Not Threaded
				Return
			?
		EndIf
		
		' Update GUI system
		If Self.isEditing = False
			Self.gui.Update()
		EndIf
		Self.isEditing = False
		
		' Scrolling
		Self.ScrollKeyboard()
		Self.ScrollMouse()
		
		' Update
		frameCounter.Update()
		
		' Clear screen
		Cls
		
		' Reset color, alpha, rotation
		ResetMax2D()
		
		' Draw map
		If Self.viewHighlightLayer
			Self.map.Draw(TGameStateEditor.OnMapRow, Self.viewAutoTiles, Self.currentLayer + 1)
		Else
			Self.map.Draw(TGameStateEditor.OnMapRow, Self.viewAutoTiles)
		EndIf
		
		' Reset (map offset)
		SetOrigin Int(Self.map.originX), Int(Self.map.originY)
		SetAlpha 1
		
		' Enemy spawns
		Self.map.DrawEnemySpawns()
		
		' Grid
		If Self.viewGrid
			Self.map.DrawGrid()
		EndIf
		
		' Movement view
		If Self.viewCollision
			Self.map.DrawMovement(Self.currentLayer, Self.arrowImg)
		EndIf
		
		' Start view
		If Self.viewStart
			Self.map.DrawStartTile()
		EndIf
		
		' Scripts
		SetAlpha 1
		SetColor 255, 255, 255
		Self.map.DrawScripts(Self.scriptImg)
		
		' Fill preview
		?Threaded
			Self.DrawFillPreview()
		?
		
		' Byte code view
		If Self.viewByteCode
			SetAlpha 0.85
			SetColor 0, 0, 0
			SetImageFont Self.guiFontTitle
			Self.map.DrawByteCode(Self.currentLayer)
		EndIf
		
		' Template
		If Self.viewTemplate
			SetScale Self.map.width * Self.map.tileSizeX / Float(Self.templateImg.width), Self.map.height * Self.map.tileSizeY / Float(Self.templateImg.height)
			SetAlpha 0.5
			SetColor 255, 255, 255
			DrawImage Self.templateImg, 0, 0
			SetScale 1, 1
		EndIf
		
		' Reset offset
		SetOrigin 0, 0
		
		' Test
		Rem
		SetBlend LIGHTBLEND
		SetColor 32, 32, 32
		DrawRect 0, 0, GraphicsWidth(), GraphicsHeight() 
		SetBlend ALPHABLEND
		End Rem
		
		' Edit map
		Self.Edit()
		
		' Scroll border
		'SetAlpha 0.15
		'SetColor 255, 255, 255
		'DrawRectOutline 0, 0, game.gfxWidth, game.gfxHeight, SCROLL_BORDER
		
		' GUI
		Self.infoWindow.SetText("FPS: " + Self.frameCounter.GetFPS())	' TODO: Custom frame counter function
		Self.tilesDrawnLabel.SetText("Tiles drawn: " + Self.map.GetNumberOfTilesOnScreen())
		
		' More alpha while editing
		If Self.isEditing = 1
			If MilliSecs() - Self.lastTimeEdited > 1000
				Self.gui.SetAlpha 1 - Min((MilliSecs() - Self.lastTimeEdited - 1000) / 1000.0, 1)
			EndIf
			Self.returnedFromEditing = MilliSecs()
			Self.oldGUIAlpha = Self.gui.GetAlpha()
		Else
			If Self.gui.GetAlpha() < 1.0
				Self.gui.SetAlpha Min(Self.oldGUIAlpha + (MilliSecs() - Self.returnedFromEditing) / 250.0, 1)
			Else
				Self.lastTimeEdited = MilliSecs()
			EndIf
		EndIf
		
		Self.gui.Draw()
		
		If Self.gui.GetHoveredWidget() <> Null And Self.gui.GetHoveredWidget().GetParent() <> Null And Self.gui.GetHoveredWidget().GetParent().IsChildOf(Self.tileWindow)
			SetAlpha 1
			SetColor 255, 255, 255
			DrawRectOutline Self.gui.GetHoveredWidget().GetX() - 1, Self.gui.GetHoveredWidget().GetY() - 1, Self.gui.GetHoveredWidget().GetWidth() + 2, Self.gui.GetHoveredWidget().GetHeight() + 2
		EndIf
		
		' Swap buffers
		Flip game.vsync
		
		' Ctrl
		If TInputSystem.GetKeyDown(KEY_LCONTROL) 
			' TODO: Remove hardcoded stuff
			If TInputSystem.GetKeyHit(KEY_S)
				Self.map.Save(FS_ROOT + "data/maps/lyphia.map")
			EndIf
			
			If TInputSystem.GetKeyHit(KEY_L)
				Self.map.Load(FS_ROOT + "data/maps/lyphia.map")
			EndIf
			
			' Ctrl + E = Open Editor
			If TInputSystem.GetKeyHit(KEY_E)
				game.SetGameStateByName("InGame")
			EndIf
		EndIf
		
		' Quit
		If TInputSystem.GetKeyHit(KEY_ESCAPE)
			game.SetGameStateByName("Menu")
		EndIf
	End Method
	
	' Edit
	Method Edit()
		' Get coordinates
		If Self.map.GetTileCoords(TInputSystem.GetMouseX(), TInputSystem.GetMouseY(), Self.x, Self.y)
			Self.posLabel.SetText("Layer " + (Self.currentLayer + 1) + " | " + "X: " + Self.x + ", Y: " + Self.y)
			
			'SetAlpha 0.25
			'SetColor 0, 0, 0
			'DrawRectOutline 1 + Int(Self.map.originX) + Self.x * Self.map.tileSizeX, 1 + Int(Self.map.originY) + Self.y * Self.map.tileSizeY, Self.map.tileSizeX, Self.map.tileSizeY
			
			SetAlpha 0.5
			SetColor 255, 255, 255
			DrawRect Int(Self.map.originX) + Self.x * Self.map.tileSizeX, Int(Self.map.originY) + Self.y * Self.map.tileSizeY, Self.map.tileSizeX, Self.map.tileSizeY
			DrawRectOutline Int(Self.map.originX) + Self.x * Self.map.tileSizeX, Int(Self.map.originY) + Self.y * Self.map.tileSizeY, Self.map.tileSizeX, Self.map.tileSizeY
			
			' Edit
			If TInputSystem.GetMouseDown(1)
				Self.map.Set(Self.currentLayer, Self.x, Self.y, Self.currentTile)
				Self.isEditing = True
			EndIf
			
			If TInputSystem.GetMouseHit(2)
				Self.savedX = Self.x
				Self.savedY = Self.y
				Self.tileMenu.Popup()
				Self.isEditing = True
			EndIf
		Else
			Self.posLabel.SetText("")
		EndIf
	End Method
	
	' ReloadMapList
	Method ReloadMapList()
		Self.mapsList.Clear()
		
		Local files:String[] = LoadDir(FS_ROOT + "data/maps/")
		For Local file:String = EachIn files
			If ExtractExt(file).ToLower() = "map"
				Self.mapsList.AddItem(StripAll(file))
			EndIf
		Next
	End Method
	
	' SetScrollSpeed
	Method SetScrollSpeed(nSpeed:Float)
		Self.scrollSpeed = nSpeed
	End Method
	
	' ScrollKeyboard
	Method ScrollKeyboard()
		' Scroll left
		If TInputSystem.GetKeyDown(KEY_LEFT)
			Self.map.Scroll(-game.speed * Self.scrollSpeed * 2, 0)
		EndIf
		
		' Scroll right
		If TInputSystem.GetKeyDown(KEY_RIGHT)
			Self.map.Scroll(game.speed * Self.scrollSpeed * 2, 0)
		EndIf
		
		' Scroll up
		If TInputSystem.GetKeyDown(KEY_UP)
			Self.map.Scroll(0, -game.speed * Self.scrollSpeed * 2)
		EndIf
		
		' Scroll down
		If TInputSystem.GetKeyDown(KEY_DOWN)
			Self.map.Scroll(0, game.speed * Self.scrollSpeed * 2)
		EndIf
	End Method
	
	' ScrollMouse
	Method ScrollMouse()
		' Be able to "hold" the map with the middle mouse button (scrolling/moving the map)
		If TInputSystem.GetMouseDown(3)
			Self.map.Scroll(-TInputSystem.GetMouseXSpeed(), -TInputSystem.GetMouseYSpeed())
			Self.isEditing = True
		EndIf
		
		Self.zoomSlider.SetValueRel(Self.zoomSlider.GetValueRel() + TInputSystem.GetMouseZSpeed() * 0.05)
		
		Rem
		' Scroll left
		If TInputSystem.GetMouseX() < SCROLL_BORDER
			Self.map.Scroll(-game.speed * Self.scrollSpeed * 0.05 * (SCROLL_BORDER - TInputSystem.GetMouseX()), 0)
		EndIf
		
		' Scroll right
		If TInputSystem.GetMouseX() > game.gfxWidth - SCROLL_BORDER
			Self.map.Scroll(game.speed * Self.scrollSpeed * 0.05 * (SCROLL_BORDER - (game.gfxWidth - TInputSystem.GetMouseX())), 0)
		EndIf
		
		' Scroll up
		If TInputSystem.GetMouseY() < SCROLL_BORDER
			Self.map.Scroll(0, -game.speed * Self.scrollSpeed * 0.05 * (SCROLL_BORDER - TInputSystem.GetMouseY()))
		EndIf
		
		' Scroll down
		If TInputSystem.GetMouseY() > game.gfxHeight - SCROLL_BORDER
			Self.map.Scroll(0, game.speed * Self.scrollSpeed * 0.05 * (SCROLL_BORDER - (game.gfxHeight - TInputSystem.GetMouseY())))
		EndIf
		End Rem
	End Method
	
	' DrawFillPreview
	?Threaded
	Method DrawFillPreview()
		Self.fillPreviewNodesMutex.Lock()
			'SetAlpha 0.3
			'SetColor 255, 255, 255
			'SetBlend SHADEBLEND
			'Self.map.DrawPathWithTile(Self.fillPreviewNodes, Self.currentLayer, Self.currentTile)
			Self.map.DrawPath(Self.fillPreviewNodes, 255, 255, 255, 0.15)
			'SetBlend ALPHABLEND
		Self.fillPreviewNodesMutex.Unlock()
	End Method
	?
	
	' Remove
	Method Remove()
		
	End Method
	
	' SetTileByWidget
	Function SetTileByWidget(widget:TWidget)
		gsEditor.currentTile = Int(widget.id)
	End Function
	
	' ToggleGrid
	Function ToggleGrid(widget:TWidget)
		gsEditor.viewGrid = TCheckBox(widget).GetState()
	End Function
	
	' ToggleMovement
	Function ToggleMovement(widget:TWidget)
		gsEditor.viewCollision = TCheckBox(widget).GetState()
	End Function
	
	' ToggleStart
	Function ToggleStart(widget:TWidget)
		gsEditor.viewStart = TCheckBox(widget).GetState()
	End Function
	
	' ToggleByteCode
	Function ToggleByteCode(widget:TWidget)
		gsEditor.viewByteCode = TCheckBox(widget).GetState()
	End Function
	
	' ToggleTemplate
	Function ToggleTemplate(widget:TWidget)
		gsEditor.viewTemplate = TCheckBox(widget).GetState()
	End Function
	
	' ToggleTemplateFilter
	Function ToggleTemplateFilter(widget:TWidget)
		gsEditor.filterTemplate = TCheckBox(widget).GetState() 
		gsEditor.LoadTemplate()
	End Function
	
	' ToggleAutoTiles
	Function ToggleAutoTiles(widget:TWidget)
		gsEditor.viewAutoTiles = TCheckBox(widget).GetState()
	End Function
	
	' ToggleWindowVisibility
	Function ToggleWindowVisibility(widget:TWidget)
		widget.ToggleVisibility()
		
		' Change icon
		Local menu:TPopupMenu = gsEditor.gui.GetRoot().GetChild("menuBar").GetChild("menuBar2").GetPopupMenu()
		For Local item:TWidget = EachIn menu.GetChildsList()
			If item.GetAffectingWidget() = widget
				If widget.IsVisible()
					menu.SetMenuItemIcon(item.GetID(), gsEditor.gui.skin.checkbox.checked)
				Else
					menu.SetMenuItemIcon(item.GetID(), gsEditor.gui.skin.checkbox.unchecked)
				EndIf
			EndIf
		Next
	End Function
	
	' ToggleHighlightLayer
	Function ToggleHighlightLayer(widget:TWidget)
		gsEditor.viewHighlightLayer = TCheckBox(widget).GetState()
	End Function
	
	' GoToStartLocation
	Function GoToStartLocation(widget:TWidget)
		gsEditor.map.SetOffsetToTileCentered(gsEditor.map.GetStartTileX(), gsEditor.map.GetStartTileY())
	End Function
	
	' ChangeZoom
	Function ChangeZoom(widget:TWidget) 
		gsEditor.map.SetZoom(TSlider(widget).GetValue())
	End Function
	
	' ClearLayer
	Function ClearLayer(widget:TWidget) 
		' TODO: Remove hardcoded stuff
		gsEditor.map.FillAll(gsEditor.currentLayer, gsEditor.currentTile)
	End Function
	
	' GenerateFromTemplate
	Function GenerateFromTemplate(widget:TWidget) 
		Local scaleX:Float = gsEditor.map.width / Float(gsEditor.templateImg.width) 
		Local scaleY:Float = gsEditor.map.height / Float(gsEditor.templateImg.height)
		Local oldX:Int
		Local oldY:Int
		Local oldXSet:Int[] = New Int[gsEditor.map.height]
		Local oldYSet:Int
		Local i:Int
		Local h:Int
		Local rgba:Int
		
		' TODO: Remove hardcoded stuff
		' INI
		Local ini:TINI = TINI.Create(FS_ROOT + "data/maps/lyphia.ini") 
		Local autoTerrain:TINICategory
		ini.Load() 
		autoTerrain = ini.GetCategory("AutoTerrain")
		
		' TODO: Remove hardcoded stuff
		Local bc:Int
		
		For i = 0 Until gsEditor.templateImg.width
			For h = 0 Until gsEditor.templateImg.height
				rgba = ReadPixel(gsEditor.templatePixmap, i, h)
				If rgba Shr 24 > 0
					
					bc = Int(autoTerrain.Get("R" + ((rgba & $FF0000) Shr 16)))
					If bc = 0
						bc = gsEditor.currentTile
					EndIf
					
					gsEditor.map.tiles[0, i * scaleX, h * scaleY] = bc
					
					' Fill gaps Y
					If oldYSet 'And Int(h * scaleY) - oldY >= 1
						For Local fillLine:Int = 1 To Int(h * scaleY) - oldY
							gsEditor.map.tiles[0, i * scaleX, oldY + fillLine] = bc
							oldXSet[oldY + fillLine] = Int(h * scaleY) - oldY
						Next
					EndIf
					
					' Fill gaps X
					If oldXSet[h * scaleY] 'And Int(i * scaleX) - oldX >= 1
						For Local fillLineX:Int = 1 To Int(i * scaleX) - oldX
							For Local fillLineY:Int = 1 To Int(h * scaleY) - oldY'oldXSet[h * scaleY]
								gsEditor.map.tiles[0, oldX + fillLineX, oldY + fillLineY] = bc
							Next
						Next
					EndIf
					
					oldXSet[h * scaleY] = True
					oldYSet = True
				Else
					oldXSet[h * scaleY] = False
					oldYSet = False
				EndIf
				
				oldY = Int(h * scaleY)
			Next
			
			oldX = Int(i * scaleX)
		Next
		
		gsEditor.map.RegenerateAutoTileInformation()
	End Function
	
	' LoadFunc
	Function LoadFunc(widget:TWidget)
		Local mapName:String = gsEditor.mapsList.GetText()
		If mapName <> ""
			gsEditor.map.Load(FS_ROOT + "data/maps/" + mapName + ".map")
			
			' Jump to start location
			gsEditor.map.SetOffsetToTileCentered(gsEditor.map.GetStartTileX(), gsEditor.map.GetStartTileY())
		Else
			' This will do TTileMap.Init()
			gsEditor.map.LoadINI(FS_ROOT + "data/layers/tilemap.ini")
		EndIf
		
		' Map options
		gsEditor.mapOptions.GetChild("mapNameInput").SetText(gsEditor.map.GetName())
		gsEditor.mapOptions.GetChild("mapWidthInput").SetText(gsEditor.map.GetWidth())
		gsEditor.mapOptions.GetChild("mapHeightInput").SetText(gsEditor.map.GetHeight())
	End Function
	
	' SaveFunc
	Function SaveFunc(widget:TWidget)
		Local mapName:String = gsEditor.mapsList.GetText()
		If mapName <> ""
			If gsEditor.mapsList.GetText() <> gsEditor.map.GetName()
				DeleteFile FS_ROOT + "data/maps/" + gsEditor.mapsList.GetText() + ".map"
			EndIf
			gsEditor.map.Save(FS_ROOT + "data/maps/" + gsEditor.map.GetName() + ".map")
			gsEditor.mapsList.SetItemText(gsEditor.mapsList.GetSelectedItem(), gsEditor.map.GetName())
			gsEditor.ReloadMapList()
			
			' TODO: Search the map with the same name and select it
		Else
			gsEditor.map.Save(FS_ROOT + "data/maps/" + gsEditor.map.GetName() + ".map")
			gsEditor.ReloadMapList()
		EndIf
	End Function
	
	' UpdateMapFunc
	Function UpdateMapFunc(widget:TWidget)
		gsEditor.map.name = gsEditor.mapOptions.GetChild("mapNameInput").GetText()
		gsEditor.map.Resize(Int(gsEditor.mapOptions.GetChild("mapWidthInput").GetText()), Int(gsEditor.mapOptions.GetChild("mapHeightInput").GetText()))
	End Function
	
	' PlayFunc
	Function PlayFunc(widget:TWidget)
		game.SetGameStateByName("InGame")
	End Function
	
	' SetStartTileFunc
	Function SetStartTileFunc(widget:TWidget)
		gsEditor.map.SetStartTile(gsEditor.savedX, gsEditor.savedY)
	End Function
	
	' CopyFunc
	Function CopyFunc(widget:TWidget)
		gsEditor.currentTile = gsEditor.map.Get(gsEditor.currentLayer, gsEditor.savedX, gsEditor.savedY)
	End Function
	
	' FillFunc
	Function FillFunc(widget:TWidget)
		gsEditor.map.FillAt(gsEditor.currentLayer, gsEditor.savedX, gsEditor.savedY, gsEditor.currentTile)
	End Function
	
	' FillDiagonalFunc
	Function FillDiagonalFunc(widget:TWidget)
		gsEditor.map.FillAt(gsEditor.currentLayer, gsEditor.savedX, gsEditor.savedY, gsEditor.currentTile, True)
	End Function
	
	' EraseFunc
	Function EraseFunc(widget:TWidget)
		gsEditor.map.Set(gsEditor.currentLayer, gsEditor.savedX, gsEditor.savedY, 0)
	End Function
	
	' SelectAreaFunc
	Function SelectAreaFunc(widget:TWidget)
		' TODO: Implement
	End Function
	
	?Threaded
	' FillPreviewFunc
	Function FillPreviewFunc(widget:TWidget)
		'If gsEditor.fillPreviewThread <> Null
			'WaitThread gsEditor.fillPreviewThread
			'gsEditor.fillPreviewThread = Null
		'EndIf
		
		gsEditor.fillPreviewNodesMutex.Lock()
			gsEditor.fillPreviewNodes.Clear()
		gsEditor.fillPreviewNodesMutex.Unlock()
		
		gsEditor.fillPreviewThread = CreateThread(FillPreviewThreadFunc, TBox.Create(gsEditor.savedX, gsEditor.savedY, gsEditor.currentLayer, widget.GetID() = "popupFillDiagonally"))
	End Function
	
	' FillPreviewHideFunc
	Function FillPreviewHideFunc(widget:TWidget)
		gsEditor.fillPreviewNodesMutex.Lock()
			gsEditor.fillPreviewNodes.Clear()
		gsEditor.fillPreviewNodesMutex.Unlock()
		
		'If gsEditor.fillPreviewThread <> Null
		'	WaitThread gsEditor.fillPreviewThread
		'EndIf
	End Function
	
	' FillPreviewThreadFunc
	Function FillPreviewThreadFunc:Object(data:Object)
		' Not the best way to get parameters I admit...but it works :S
		Local dataBox:TBox = TBox(data)
		Local nX:Int = dataBox.x1
		Local nY:Int = dataBox.y1
		Local nLayer:Int = dataBox.x2
		Local goDiagonal:Int = dataBox.y2
		
		Local queue:TList = gsEditor.fillPreviewNodes
		Local old:Byte = gsEditor.map.tiles[nLayer, nX, nY]
		Local link:TLink
		Local node:TTileNode
		Local runs:Int = 0
		
		Local worldCopy:Int[gsEditor.map.GetWidth(), gsEditor.map.GetHeight()]
		
		link = queue.AddLast(TTileNode.Create(nLayer, nX, nY))
		
		While link <> Null
			gsEditor.fillPreviewNodesMutex.Lock()
				node = TTileNode(link.Value())
				
				' West
				If node.x > 0 And gsEditor.map.tiles[node.layer, node.x - 1, node.y] = old And worldCopy[node.x - 1, node.y] = False
					worldCopy[node.x - 1, node.y] = True
					queue.AddLast(TTileNode.Create(node.layer, node.x - 1, node.y))
				EndIf
				
				' East
				If node.x < gsEditor.map.width - 1 And gsEditor.map.tiles[node.layer, node.x + 1, node.y] = old And worldCopy[node.x + 1, node.y] = False
					worldCopy[node.x + 1, node.y] = True
					queue.AddLast(TTileNode.Create(node.layer, node.x + 1, node.y))
				EndIf
				
				' North
				If node.y > 0 And gsEditor.map.tiles[node.layer, node.x, node.y - 1] = old And worldCopy[node.x, node.y - 1] = False
					worldCopy[node.x, node.y - 1] = True
					queue.AddLast(TTileNode.Create(node.layer, node.x, node.y - 1))
				EndIf
				
				' South
				If node.y < gsEditor.map.height - 1 And gsEditor.map.tiles[node.layer, node.x, node.y + 1] = old And worldCopy[node.x, node.y + 1] = False
					worldCopy[node.x, node.y + 1] = True
					queue.AddLast(TTileNode.Create(node.layer, node.x, node.y + 1))
				EndIf
				
				If goDiagonal
					' Northwest
					If node.x > 0 And node.y > 0 And gsEditor.map.tiles[node.layer, node.x - 1, node.y - 1] = old And worldCopy[node.x - 1, node.y - 1] = False
						worldCopy[node.x - 1, node.y - 1] = True
						queue.AddLast(TTileNode.Create(node.layer, node.x - 1, node.y - 1))
					EndIf
					
					' Northeast
					If node.x < gsEditor.map.width - 1 And node.y > 0 And gsEditor.map.tiles[node.layer, node.x + 1, node.y - 1] = old And worldCopy[node.x + 1, node.y - 1] = False
						worldCopy[node.x + 1, node.y - 1] = True
						queue.AddLast(TTileNode.Create(node.layer, node.x + 1, node.y - 1))
					EndIf
					
					' Southwest
					If node.x > 0 And node.y < gsEditor.map.height - 1 And gsEditor.map.tiles[node.layer, node.x - 1, node.y + 1] = old And worldCopy[node.x - 1, node.y + 1] = False
						worldCopy[node.x - 1, node.y + 1] = True
						queue.AddLast(TTileNode.Create(node.layer, node.x - 1, node.y + 1))
					EndIf
					
					' Southeast
					If node.x < gsEditor.map.width - 1 And node.y < gsEditor.map.height - 1 And gsEditor.map.tiles[node.layer, node.x + 1, node.y + 1] = old And worldCopy[node.x + 1, node.y + 1] = False
						worldCopy[node.x + 1, node.y + 1] = True
						queue.AddLast(TTileNode.Create(node.layer, node.x + 1, node.y + 1))
					EndIf
				EndIf
				
				link = link.NextLink()
				'queue.RemoveFirst()
			gsEditor.fillPreviewNodesMutex.Unlock()
			
			runs :+ 1
		Wend
	End Function
	?
	
	' AddEnemySpawnFunc
	Function AddEnemySpawnFunc(widget:TWidget)
		If gsEditor.currentEnemyType = ""
			Return
		EndIf
		
		Local spawn:TEnemySpawn = TEnemySpawn.Create(gsEditor.currentEnemyType, gsEditor.savedX, gsEditor.savedY, gsEditor.savedX * gsEditor.map.realTileSizeX, gsEditor.savedY * gsEditor.map.realTileSizeY)
		'PrintTypeDebug(spawn, gsEditor.loggerEditor)
		gsEditor.map.enemySpawns[gsEditor.savedY].AddLast(spawn)
	End Function
	
	' RemoveEnemySpawnFunc
	Function RemoveEnemySpawnFunc(widget:TWidget)
		For Local spawn:TEnemySpawn = EachIn gsEditor.map.enemySpawns[gsEditor.savedY]
			If spawn.tileX = gsEditor.savedX
				gsEditor.map.enemySpawns[gsEditor.savedY].Remove(spawn)
				Return
			EndIf
		Next
	End Function
	
	' AddScriptFunc
	Function AddScriptFunc(widget:TWidget)
		gsEditor.map.SetScript(gsEditor.scriptsList.GetText(), gsEditor.savedX, gsEditor.savedY)
	End Function
	
	' RemoveScriptFunc
	Function RemoveScriptFunc(widget:TWidget)
		gsEditor.map.SetScript("", gsEditor.savedX, gsEditor.savedY)
	End Function
	
	' ChangeEnemyType
	Function ChangeEnemyType(widget:TWidget)
		gsEditor.currentEnemyType = widget.GetText()
		
		If gsEditor.currentEnemyType <> ""
			gsEditor.tileMenu.SetMenuItemText("popupAddEnemy", "Add <" + gsEditor.currentEnemyType + ">")
			gsEditor.tileMenu.SetMenuItemVisibility("popupAddEnemy", True)
		Else
			' TODO: Hide menu item
			gsEditor.tileMenu.SetMenuItemVisibility("popupAddEnemy", False)
		EndIf
	End Function
	
	' ChangeSkillType
	Function ChangeSkillType(widget:TWidget)
		
	End Function
	
	' ChangeLayer
	Function ChangeLayer(widget:TWidget)
		Local listBox:TListBox = TListBox(widget)
		Local index:Int = listBox.GetSelectedItem()
		If index <> TListBox.ITEM_NONE
			' Change tile container
			If gsEditor.tileWindow <> Null And gsEditor.tileWindow.GetChild("tilesContainer1") <> Null
				gsEditor.tileWindow.GetChild("tilesContainer" + (gsEditor.currentLayer + 1)).SetVisible(False)
				gsEditor.tileWindow.GetChild("tilesContainer" + (index + 1)).SetVisible(True)
			EndIf
			
			gsEditor.currentLayer = index
		Else
			listBox.SelectItem(gsEditor.currentLayer)
		EndIf
	End Function
	
	' PopupMenuFunc
	Function PopupMenuFunc(widget:TWidget)
		gsEditor.tileMenu.SetMenuItemIcon("popupCopy", gsEditor.map.atlasImage[gsEditor.currentLayer], gsEditor.map.Get(gsEditor.currentLayer, gsEditor.savedX, gsEditor.savedY))
		gsEditor.tileMenu.SetMenuItemIcon("popupFill", gsEditor.map.atlasImage[gsEditor.currentLayer], gsEditor.currentTile)
		gsEditor.tileMenu.SetMenuItemIcon("popupFillDiagonally", gsEditor.map.atlasImage[gsEditor.currentLayer], gsEditor.currentTile)
		gsEditor.tileMenu.SetMenuItemIcon("popupErase", gsEditor.map.atlasImage[gsEditor.currentLayer], gsEditor.map.Get(gsEditor.currentLayer, gsEditor.savedX, gsEditor.savedY))
		
		' Script check
		Local scriptOnTile:String = gsEditor.map.GetScript(gsEditor.savedX, gsEditor.savedY)
		Local scriptSelected:String = gsEditor.scriptsList.GetText()
		If scriptOnTile = ""
			gsEditor.tileMenu.SetMenuItemText("popupAddScript", "Add script <" + scriptSelected + ">")
			gsEditor.tileMenu.SetMenuItemVisibility("popupRemoveScript", False)
		Else
			gsEditor.tileMenu.SetMenuItemText("popupAddScript", "Replace with script <" + scriptSelected + ">")
			gsEditor.tileMenu.SetMenuItemText("popupRemoveScript", "Remove script <" + scriptOnTile + ">")
			gsEditor.tileMenu.SetMenuItemVisibility("popupRemoveScript", True)
		EndIf
		If scriptOnTile <> scriptSelected And scriptSelected <> ""
			gsEditor.tileMenu.SetMenuItemVisibility("popupAddScript", True)
		Else
			gsEditor.tileMenu.SetMenuItemVisibility("popupAddScript", False)
		EndIf
		
		' Remove enemy item check
		For Local spawn:TEnemySpawn = EachIn gsEditor.map.enemySpawns[gsEditor.savedY]
			If spawn.tileX = gsEditor.savedX
				gsEditor.tileMenu.SetMenuItemText("popupRemoveEnemy", "Remove '" + spawn.enemyType + "'")
				gsEditor.tileMenu.SetMenuItemVisibility("popupRemoveEnemy", True)
				gsEditor.tileMenu.SetMenuItemVisibility("popupAddEnemy", False)
				Return
			EndIf
		Next
		gsEditor.tileMenu.SetMenuItemVisibility("popupRemoveEnemy", False)
		gsEditor.tileMenu.SetMenuItemVisibility("popupAddEnemy", True)
		TGameStateEditor.ChangeEnemyType(gsEditor.enemiesList)
	End Function
	
	' OnMapRow
	Function OnMapRow(row:Int)
		' Enemy walk animation in editor
		If 0
			For Local I:Int = gsEditor.map.tileTop To gsEditor.map.tileBottom
				For Local spawn:TEnemySpawn = EachIn gsEditor.map.enemySpawns[I]
					spawn.enemy.SetAnimation(spawn.enemy.animWalk)
					spawn.enemy.currentAnimation.Play()
				Next
			Next
		EndIf
	End Function
	
	' OnAppSuspended
	Method OnAppSuspended()
		
	End Method
	
	' OnAppReactivated
	Method OnAppReactivated()
		' TODO: Flush events
		'TInputSystem.EraseAllEvents()
	End Method
	
	' ToString
	Method ToString:String()
		Return "Editor"
	End Method
	
	' Create
	Function Create:TGameStateEditor(gameRef:TGame)
		Local gs:TGameStateEditor = New TGameStateEditor
		gameRef.RegisterGameState("Editor", gs)
		Return gs
	End Function
End Type
