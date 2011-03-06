' Strict
SuperStrict

' Modules
Import BRL.Max2D
'Import BtbN.GLDraw2D

' Files
Import "TINILoader.bmx"
Import "TEnemy.bmx"
Import "AStar.bmx"

' TTileMap
Type TTileMap
	Const MAX_TILES:Int = 256
	
	' AutoTile directions
	Const AT_NORTH:Int = 0
	Const AT_EAST:Int = 1
	Const AT_SOUTH:Int = 2
	Const AT_WEST:Int = 3
	Const AT_NORTHEAST:Int = 4
	Const AT_NORTHWEST:Int = 5
	Const AT_SOUTHEAST:Int = 6
	Const AT_SOUTHWEST:Int = 7
	Const AT_NORTHEAST_INVERTED:Int = 8
	Const AT_NORTHWEST_INVERTED:Int = 9
	Const AT_SOUTHEAST_INVERTED:Int = 10
	Const AT_SOUTHWEST_INVERTED:Int = 11
	Const AT_NORTHEAST_DIAGONAL:Int = 12
	Const AT_NORTHWEST_DIAGONAL:Int = 13
	Const AT_SOUTHEAST_DIAGONAL:Int = 14
	Const AT_SOUTHWEST_DIAGONAL:Int = 15
	
	Field name:String
	
	Field atlas:TTextureAtlas[]
	Field atlasImage:TImage[]
	
	Field scaleX:Float, scaleY:Float
	Field tileSizeX:Float, tileSizeY:Float
	Field realTileSizeX:Int, realTileSizeY:Int
	Field screenSizeX:Int, screenSizeY:Int
	Field layers:Byte, width:Int, height:Int
	Field tiles:Byte[,,]
	Field autoTiles:TList[,]
	Field cost:TGameMap
	Field scripts:String[,]
	Field enemySpawns:TList[]
	Field byteToTile:TTileType[,]
	Field originX:Float, originY:Float
	Field screenTilesX:Int, screenTilesY:Int
	Field widthInPixels:Int, heightInPixels:Int
	
	Field tileLeft:Int
	Field tileRight:Int
	Field tileTop:Int
	Field tileBottom:Int
	
	Field reduceZoomArtifacts:Int
	
	' Starting point for the player
	Field startX:Int[], startY:Int[]
	
	' TODO: Remove hardcoded stuff
	'Field topLeft:TImage
	
	' Init
	Method Init(nLayers:Int, nWidth:Int, nHeight:Int)
		Self.name = ""
		Self.layers = nLayers
		Self.width = nWidth
		Self.height = nHeight
		Self.tiles = New Byte[Self.layers, Self.width, Self.height]
		Self.scripts = New String[Self.width, Self.height]
		Self.autoTiles = New TList[Self.width, Self.height]
		Self.cost = TGameMap.Create(Self.width, Self.height, 1)
		Self.byteToTile = New TTileType[Self.layers, MAX_TILES]
		Self.enemySpawns = New TList[Self.height]
		Self.startX = New Int[4]
		Self.startY = New Int[4]
		Self.originX = 0
		Self.originY = 0
		Self.scaleX = 1.0
		Self.scaleY = 1.0
		
		Self.reduceZoomArtifacts = True
		
		' Reset byteToTile
		For Local l:Int = 0 Until Self.layers
			For Local bc:Int = 0 Until MAX_TILES
				Self.byteToTile[l, bc] = TTileType.NullTile
			Next
		Next
		
		' Create lists
		For Local I:Int = 0 Until Self.height
			Self.enemySpawns[I] = CreateList()
		Next
		
		' TODO: Remove hardcoded stuff
		'Self.topLeft = LoadImage(FS_ROOT + "data/layer-1/top-left.png")
	End Method
	
	' InitTextureAtlas
	Method InitTextureAtlas()
		Self.atlas = New TTextureAtlas[Self.layers]
		Self.atlasImage = New TImage[Self.layers]
		
		' Init layers
		For Local I:Int = 0 Until Self.layers
			Self.atlas[I] = New TTextureAtlas
			Self.atlas[I].Init(24 * 42, 24 * 42, Self.tileSizeX, Self.tileSizeY) 
		Next
	End Method
	
	' LoadINI
	Method LoadINI(iniFile:String)
		' Read engine config file
		Local ini:TINI = TINI.Create(iniFile)
		ini.Load()
		
		Self.Init(Int(ini.Get("TileMap", "MaxLayers")), 0, 0)
		Self.SetTileSize(Int(ini.Get("TileMap", "TileWidth")), Int(ini.Get("TileMap", "TileHeight")))
		Self.realTileSizeX = Self.tileSizeX
		Self.realTileSizeY = Self.tileSizeY
	End Method
	
	' LoadLayers
	Method LoadLayers(dirPrefix:String)
		' Load all layers
		Local files:String[]
		Local filesList:TList
		Local file:String
		Local fileClean:String
		Local byteCode:Byte
		Local byteCodeLen:Int
		Local tileImg:TPixmap
		
		' TODO: Optimize file loading routine (store in TList automatically)
		For Local layer:Int = 1 To Self.layers
			files = LoadDir(dirPrefix + layer)
			
			' Sort
			filesList = ListFromArray(files)
			filesList.Sort(True, CompareStringsByNumericValue)
			
			' Load
			For file = EachIn filesList
				fileClean = StripAll(file)
				byteCode = Byte(fileClean)
				byteCodeLen = String(byteCode).length
				
				' Find
				If fileClean.length > byteCodeLen And fileClean[byteCodeLen] = "-"[0]
					'Print fileClean
					Continue
				EndIf
				
				If ExtractExt(file).ToLower() = "png" And String(byteCode) = StripAll(file)
					If byteCode < TTileMap.MAX_TILES
						' Load pixmap
						tileImg = LoadPixmap(dirPrefix + layer + "/" + file) 
						
						Local tilesX:Int = Ceil(tileImg.width / Float(Self.realTileSizeX))
						Local tilesY:Int = Ceil(tileImg.height / Float(Self.realTileSizeY))
						
						Local newTileImg:TPixmap = CreatePixmap(tilesX * Self.realTileSizeX, tilesY * Self.realTileSizeX, tileImg.format)
						newTileImg.ClearPixels(0)
						newTileImg.Paste(tileImg, newTileImg.width / 2 - tileImg.width / 2, newTileImg.height / 2 - tileImg.height / 2)
						
						' Divide into smaller tiles
						For Local h:Int = 0 Until tilesY
							For Local i:Int = 0 Until tilesX
								tileImg = PixmapWindow(newTileImg, i * Self.realTileSizeX, h * Self.realTileSizeX, Self.realTileSizeX, Self.realTileSizeY)
								
								' Create tile information
								Self.byteToTile[layer - 1, byteCode] = TTileType.Create(byteCode)
								If layer = 1
									Self.byteToTile[layer - 1, byteCode].LoadAutoTile()
								EndIf
								
								' Load tile information
								If FileType(dirPrefix + layer + "/" + byteCode + ".ini") = 1
									Self.byteToTile[layer - 1, byteCode].LoadINI(dirPrefix + layer + "/" + byteCode + ".ini")
								Else
									Self.byteToTile[layer - 1, byteCode].LoadINI(dirPrefix + layer + "/" + fileClean + ".ini")
								EndIf
								
								' Paste into texture atlas
								Self.atlas[layer - 1].Insert(tileImg, byteCode)
								
								byteCode :+ 1
							Next
						Next
					EndIf
				EndIf
			Next
			Self.atlasImage[layer - 1] = Self.atlas[layer - 1].CreateImage()
		Next
	End Method
	
	' SetTileSize
	Method SetTileSize(sizeX:Float, sizeY:Float)
		Self.tileSizeX = sizeX
		Self.tileSizeY = sizeY
	End Method
	
	' SetScreenSize
	Method SetScreenSize(sizeX:Int, sizeY:Int)
		Self.screenSizeX = sizeX
		Self.screenSizeY = sizeY
		If Self.tileSizeX <> 0 And Self.tileSizeY <> 0
			Self.screenTilesX = sizeX / Self.tileSizeX
			Self.screenTilesY = sizeY / Self.tileSizeY
		EndIf
	End Method
	
	' SetZoom
	Method SetZoom(factor:Float) 
		Self.SetTileSize(Self.realTileSizeX * factor, Self.realTileSizeY * factor)
		Self.SetScreenSize(Self.screenSizeX, Self.screenSizeY) 
		
		Self.originX :- Self.screenSizeX / 2
		Self.originY :- Self.screenSizeY / 2
		
		Self.originX :/ Self.scaleX
		Self.originY :/ Self.scaleY
		
		Self.originX :* factor
		Self.originY :* factor
		
		Self.originX :+ Self.screenSizeX / 2
		Self.originY :+ Self.screenSizeY / 2
		
		Self.scaleX = factor
		Self.scaleY = factor
	End Method
	
	' Load
	Method Load(file:String)
		Local layer:Int
		Local i:Int
		Local h:Int
		Local enemySpawn:TEnemySpawn
		Local esTileX:Int
		Local esTileY:Int
		Local esType:String
		Local startPoints:Byte
		Local stream:TStream
		
		Self.name = StripAll(file)
		
		stream = ReadFile(file)
		
		Self.layers = stream.ReadByte()
		Self.width = stream.ReadInt()
		Self.height = stream.ReadInt() 
		
		startPoints = stream.ReadByte()
		
		Self.startX = New Int[startPoints]
		Self.startY = New Int[startPoints]
		
		For Local I:Int = 0 Until startPoints
			Self.startX[I] = stream.ReadInt()
			Self.startY[I] = stream.ReadInt()
		Next
		
		Self.widthInPixels = Self.width * Self.tileSizeX
		Self.heightInPixels = Self.height * Self.tileSizeY
		Self.tiles = New Byte[Self.layers, Self.width, Self.height]
		Self.scripts = New String[Self.width, Self.height]
		Self.autoTiles = New TList[Self.width, Self.height]
		Self.cost = TGameMap.Create(Self.width, Self.height, 1)
		Self.enemySpawns = New TList[Self.height]
		
		' Load each tile
		For layer = 0 Until Self.layers
			For i = 0 Until Self.width
				For h = 0 Until Self.height
					Self.tiles[layer, i, h] = stream.ReadByte() 
				Next
			Next
		Next
		
		' Scripts
		For i = 0 Until Self.width
			For h = 0 Until Self.height
				Self.scripts[i, h] = stream.ReadString(stream.ReadByte())
			Next
		Next
		
		' Create lists
		For Local I:Int = 0 Until Self.height
			Self.enemySpawns[I] = CreateList()
		Next
		
		' Add enemy spawn point
		For h = 0 Until Self.height
			' AStar map
			For i = 0 Until Self.width
				If Self.byteToTile[0, Self.tiles[0, i, h] ].mTop = False Or ..
						Self.byteToTile[0, Self.tiles[0, i, h] ].mBottom = False Or ..
						Self.byteToTile[0, Self.tiles[0, i, h] ].mLeft = False Or ..
						Self.byteToTile[0, Self.tiles[0, i, h] ].mRight = False
					Self.cost.setvalue(i, h, 0, - 1)
				EndIf
			Next
			
			For i = 0 Until stream.ReadInt()
				esType = stream.ReadString(stream.ReadByte())
				esTileX = stream.ReadInt()
				esTileY = stream.ReadInt()
				enemySpawn = TEnemySpawn.Create(esType, esTileX, esTileY, esTileX * Self.realTileSizeX, esTileY * Self.realTileSizeY)
				Self.enemySpawns[h].AddLast(enemySpawn)
			Next
		Next
		
		stream.Close()
		
		' Generate auto tile information - REQUIRES THE MAP TO BE LOADED COMPLETELY
		Self.RegenerateAutoTileInformation()
	End Method
	
	' Save
	Method Save(file:String)
		Local layer:Int
		Local i:Int
		Local h:Int
		Local enemySpawn:TEnemySpawn
		Local stream:TStream = WriteFile(file)
	
		stream.WriteByte Self.layers
		stream.WriteInt Self.width
		stream.WriteInt Self.height
		
		stream.WriteByte Self.startX.length
		
		For Local I:Int = 0 Until Self.startX.length
			stream.WriteInt Self.startX[I]
			stream.WriteInt Self.startY[I]
		Next
		
		' Tiles
		For layer = 0 Until Self.layers
			For i = 0 Until Self.width
				For h = 0 Until Self.height
					stream.WriteByte Self.tiles[layer, i, h]
				Next
			Next
		Next
		
		' Scripts
		For i = 0 Until Self.width
			For h = 0 Until Self.height
				stream.WriteByte Self.scripts[i, h].length
				stream.WriteString Self.scripts[i, h]
			Next
		Next
		
		' Enemy spawns
		For h = 0 Until Self.height
			' Enemy spawns
			stream.WriteInt Self.enemySpawns[h].Count()
			
			For enemySpawn = EachIn Self.enemySpawns[h]
				stream.WriteByte enemySpawn.enemyType.length
				stream.WriteString enemySpawn.enemyType
				stream.WriteInt enemySpawn.tileX
				stream.WriteInt enemySpawn.tileY
			Next
		Next
		
		stream.Close()
	End Method
	
	' Draw
	Method Draw(onRowFunc(row:Int) = Null, drawAutoTiles:Int = True, drawOpaqueUntilLayer:Int = -1, transparentLayerAlpha:Float = 0.25)
		Local oldBlend:Int = GetBlend()
		Local layer:Int
		Local i:Int
		Local h:Int
		Local oldScaleX:Float, oldScaleY:Float
		Local oldOriginX:Float, oldOriginY:Float
		Local originXInt:Int = Int(Self.originX)
		Local originYInt:Int = Int(Self.originY)
		Local currentAtlas:TImage
		Local enemySpawn:TEnemySpawn
		Local nTileSizeX:Float = Self.tileSizeX
		Local nTileSizeY:Float = Self.tileSizeY
		
		'Left
		Self.tileLeft = -Self.originX / nTileSizeX
		If Self.tileLeft < 0
			Self.tileLeft = 0
		EndIf
		
		' Right
		Self.tileRight = Self.tileLeft + Self.screenTilesX + 1
		If Self.tileRight >= Self.width
			Self.tileRight = Self.width - 1
		EndIf
		
		' Top
		Self.tileTop = -Self.originY / nTileSizeY
		If Self.tileTop < 0
			Self.tileTop = 0
		EndIf
		
		' Bottom
		Self.tileBottom = Self.tileTop + Self.screenTilesY + 1
		If Self.tileBottom >= Self.height
			Self.tileBottom = Self.height - 1
		EndIf
		
		' Debug
		'Self.tileLeft = 0
		'Self.tileRight = Self.width - 1
		'Self.tileTop = 0
		'Self.tileBottom = Self.height - 1
		
		GetScale(oldScaleX, oldScaleY)
		SetScale Self.scaleX, Self.scaleY
		
		GetOrigin(oldOriginX, oldOriginY)
		SetOrigin oldOriginX + originXInt, oldOriginY + originYInt
		
		' TODO: Optimize this
		
		' Ground layer
		SetBlend SOLIDBLEND
		currentAtlas = Self.atlasImage[layer]
		For i = Self.tileLeft To Self.tileRight
			For h = tileTop To tileBottom
				DrawImage currentAtlas, i * nTileSizeX, h * nTileSizeY, Self.tiles[0, i, h]
			Next
		Next
		
		' AutoTiles
		'Print tileTop + ", " + tileBottom + ", " + tileLeft + ", " + tileRight
		SetBlend ALPHABLEND
		If drawAutoTiles
			For h = tileTop To tileBottom
				For i = Self.tileLeft To Self.tileRight
					If Self.autoTiles[i, h] = Null
						Self.GenerateAutoTileInformation(i, h)
					End If
					For Local at:TAutoTile = EachIn Self.autoTiles[i, h]
						DrawImage at.tt.autotile, i * nTileSizeX, h * nTileSizeY, at.direction
					Next
				Next
			Next
		EndIf
		
		' Other layers
		For h = Self.tileTop To Self.tileBottom
			' Layer 1
			layer = 1
			currentAtlas = Self.atlasImage[layer]
			For i = Self.tileLeft To Self.tileRight
				If Self.tiles[layer, i, h] = 0
					Continue
				EndIf
				
				DrawImage currentAtlas, i * nTileSizeX, h * nTileSizeY, Self.tiles[layer, i, h]
			Next
			
			' Call custom function
			If onRowFunc <> Null
					' Draw player and particles
					onRowFunc(h)
			EndIf
			
			' Layer 2-X
			For i = Self.tileLeft To Self.tileRight
				For layer = 2 To Self.layers - 1
					If Self.tiles[layer, i, h] = 0
						Continue
					EndIf
					
					DrawImage Self.atlasImage[layer], i * nTileSizeX, h * nTileSizeY, Self.tiles[layer, i, h]
				Next
			Next
		Next
		Rem
		For layer = 1 To Self.layers - 1
			currentAtlas = Self.atlasImage[layer]
			
			If drawOpaqueUntilLayer <> -1 And layer >= drawOpaqueUntilLayer
				SetAlpha transparentLayerAlpha
			EndIf
			
			For h = Self.tileTop To Self.tileBottom
				' Call custom function
				' TODO: Remove hardcoded
				If layer = 2 And onRowFunc <> Null
						' Draw player and particles
						onRowFunc(h)
				EndIf
				
				For i = Self.tileLeft To Self.tileRight
					If Self.tiles[layer, i, h] = 0
						Continue
					EndIf
					
					DrawImage currentAtlas, i * nTileSizeX, h * nTileSizeY, Self.tiles[layer, i, h]
				Next
			Next
		Next
		End Rem
		
		SetOrigin oldOriginX, oldOriginY
		SetScale oldScaleX, oldScaleY
		SetBlend oldBlend
		
		'SetColor 255, 255, 255
		'DrawText "Info: " + tileLeft + ", " + tileRight + ", " + tileTop + ", " + tileBottom, 5, 5
		'DrawText "" + Int(originX) + ", " + Int(originY), 5, 25
	End Method
	
	' DrawGrid
	Method DrawGrid()
		Local i:Int
		Local h:Int
		
		' Map outline
		' TODO: Optimize: Only south-east edges are needed
		DrawRectOutline 0, 0, Self.width * Self.tileSizeX, Self.height * Self.tileSizeY
		
		' Vertical lines
		For i = Self.tileLeft To Self.tileRight
			DrawRect i * Self.tileSizeX, tileTop * Self.tileSizeY, 1, (tileBottom - tileTop + 1) * Self.tileSizeY
		Next
		
		' Horizontal lines
		For h = Self.tileTop To Self.tileBottom
			DrawRect Self.tileLeft * Self.tileSizeX, h * Self.tileSizeY, (tileRight - tileLeft + 1) * Self.tileSizeX, 1
		Next
		
		'SetColor 255, 255, 255
		'DrawText "Info: " + tileLeft + ", " + tileRight + ", " + tileTop + ", " + tileBottom, 5, 5
		'DrawText "" + originXInt + ", " + originYInt, 5, 25
	End Method
	
	' DrawMovement
	Method DrawMovement(layer:Int, img:TImage)
		Local oldBlend:Int = GetBlend() 
		Local oldRotation:Float = GetRotation()
		Local oldScaleX:Float, oldScaleY:Float
		Local i:Int
		Local h:Int
		Local tile:TTileType
		
		' Alpha blend
		SetBlend ALPHABLEND
		
		' Scale
		GetScale(oldScaleX, oldScaleY)
		SetScale Self.scaleX, Self.scaleY
		
		' TODO: Optimise, e.g. caching
		For i = Self.tileLeft To Self.tileRight
			For h = Self.tileTop To Self.tileBottom
				tile = Self.GetTileType(layer, i, h)
				
				If tile.mTop = 0
					SetRotation 0
					DrawImage img, i * Self.tileSizeX + Self.tileSizeX / 2, h * Self.tileSizeY + Self.tileSizeY / 2
				End If
				
				If tile.mRight = 0
					SetRotation 90
					DrawImage img, i * Self.tileSizeX + Self.tileSizeX / 2, h * Self.tileSizeY + Self.tileSizeY / 2
				End If
				
				If tile.mBottom = 0
					SetRotation 180
					DrawImage img, i * Self.tileSizeX + Self.tileSizeX / 2, h * Self.tileSizeY + Self.tileSizeY / 2
				End If
				
				If tile.mLeft = 0
					SetRotation 270
					DrawImage img, i * Self.tileSizeX + Self.tileSizeX / 2, h * Self.tileSizeY + Self.tileSizeY / 2
				End If
			Next
		Next
		
		SetScale oldScaleX, oldScaleY
		SetBlend oldBlend
		SetRotation oldRotation
	End Method
	
	' DrawByteCode
	Method DrawByteCode(layer:Int)
		Local oldScaleX:Float, oldScaleY:Float
		Local i:Int
		Local h:Int
		Local code:Byte
		
		' Scale
		GetScale(oldScaleX, oldScaleY)
		SetScale Self.scaleX, Self.scaleY
		
		For i = Self.tileLeft To Self.tileRight
			For h = Self.tileTop To Self.tileBottom
				code = Self.tiles[layer, i, h]
				If code <> 0
					DrawTextCentered code, i * Self.tileSizeX + Self.tileSizeX / 2, h * Self.tileSizeY + Self.tileSizeY / 2
				EndIf
			Next
		Next
		
		SetScale oldScaleX, oldScaleY
	End Method
	
	' DrawScripts
	Method DrawScripts(img:TImage)
		Local oldScaleX:Float, oldScaleY:Float
		Local i:Int
		Local h:Int
		Local script:String
		
		' Scale
		GetScale(oldScaleX, oldScaleY)
		SetScale Self.scaleX, Self.scaleY
		
		For i = Self.tileLeft To Self.tileRight
			For h = Self.tileTop To Self.tileBottom
				script = Self.scripts[i, h]
				If script.length > 0
					DrawImage img, i * Self.tileSizeX, h * Self.tileSizeY
				EndIf
			Next
		Next
		
		SetScale oldScaleX, oldScaleY
	End Method
	
	' DrawEnemySpawns
	Method DrawEnemySpawns()
		Local h:Int
		Local enemySpawn:TEnemySpawn
		Local oldScaleX:Float, oldScaleY:Float
		
		' Alpha blend
		'SetBlend ALPHABLEND
		
		' Scale
		GetScale(oldScaleX, oldScaleY)
		SetScale Self.scaleX, Self.scaleY
		
		For h = Self.tileTop To Self.tileBottom
			' Draw enemy spawns
			For enemySpawn = EachIn Self.enemySpawns[h]
				'DrawRectOutline enemySpawn.tileX * Self.tileSizeX, enemySpawn.tileY * Self.tileSizeY, Self.tileSizeX, Self.tileSizeY
				If enemySpawn.enemy <> Null
					enemySpawn.enemy.DrawInEditor(Self.scaleX, Self.scaleY)
				EndIf
			Next
		Next
		
		SetScale oldScaleX, oldScaleY
	End Method
	
	' DrawStartTile
	Method DrawStartTiles(r:Int = 255, g:Int = 255, b:Int = 0, a:Float = 0.75)
		For Local index:Int = 0 Until Self.startX.length
			SetColor r, g, b
			SetAlpha a
			DrawRect Self.startX[index] * Self.tileSizeX, Self.startY[index] * Self.tileSizeY, Self.tileSizeX, Self.tileSizeY
		Next
	End Method
	
	' DrawPath
	' TODO: Don't draw outside the screen
	Method DrawPath(nodes:TList, r:Int = 255, g:Int = 0, b:Int = 0, a:Float = 0.75) 
		SetColor r, g, b
		SetAlpha a
		For Local node:TTileNode = EachIn nodes
			DrawRect node.x * Self.tileSizeX, node.y * Self.tileSizeY, Self.tileSizeX, Self.tileSizeY
		Next
	End Method
	
	' DrawPathWithTile
	' TODO: Don't draw outside the screen
	Method DrawPathWithTile(nodes:TList, nLayer:Int, nTile:Byte) 
		For Local node:TTileNode = EachIn nodes
			DrawImage Self.atlasImage[nLayer], node.x * Self.tileSizeX, node.y * Self.tileSizeY, nTile
		Next
	End Method
	
	' DrawAStarPath
	Method DrawAStarPath(pathToDraw:TList)
		SetColor 0, 0, 200
		
		If pathToDraw = Null
			Return
		EndIf
		
		For Local node:TNode = EachIn pathToDraw
			DrawRect node.x * Self.tileSizeX, node.y * Self.tileSizeY, Self.tileSizeX, Self.tileSizeY
		Next
	End Method
	
	' GenerateAutoTileInformation
	Method GenerateAutoTileInformation(i:Int, h:Int) 
		' Create list
		If Self.autoTiles[i, h] = Null
			Self.autoTiles[i, h] = CreateList() 
		Else
			Self.autoTiles[i, h].Clear()
		EndIf
		
		' Get surrounding tiles
		Local stiles:TTileType[5, 5]
		For Local a:Int = -2 To 2
			For Local b:Int = -2 To 2
				If i + a >= 0 And h + b >= 0 And i + a <= Self.width - 1 And h + b <= Self.height - 1
					stiles[a + 2, b + 2] = byteToTile[0, Self.tiles[0, i + a, h + b] ]
					
					' TODO: Reset byteToTile to NullTile
					If stiles[a + 2, b + 2] = Null
						stiles[a + 2, b + 2] = TTileType.NullTile
					End If
				Else
					stiles[a + 2, b + 2] = TTileType.NullTile
				EndIf
			Next
		Next
		
		' TODO: Is 5 x 5 really needed?
		' Surrounding tiles 5 x 5
		'|------|------|------|------|------|
		'|      |      |      |      |      |
		'| 0, 0 | 1, 0 | 2, 0 | 3, 0 | 4, 0 |
		'|      |      |      |      |      |
		'|------|------|------|------|------|
		'|      |      |      |      |      |
		'| 0, 1 | 1, 1 | 2, 1 | 3, 1 | 4, 1 |
		'|      |      |      |      |      |
		'|------|------********------|------|
		'|      |      *      *      |      |
		'| 0, 2 | 1, 2 * 2, 2 * 3, 2 | 4, 2 |
		'|      |      *      *      |      |
		'|------|------********------|------|
		'|      |      |      |      |      |
		'| 0, 3 | 1, 3 | 2, 3 | 3, 3 | 4, 3 |
		'|      |      |      |      |      |
		'|------|------|------|------|------|
		'|      |      |      |      |      |
		'| 0, 4 | 1, 4 | 2, 4 | 3, 4 | 4, 4 |
		'|      |      |      |      |      |
		'|------|------|------|------|------|
		
		' Height information
		Local ownHeight:Int = stiles[2, 2].height
		
		' North
		If stiles[2, 1].height > ownHeight
			' Check clockwise
			If stiles[2, 1] = stiles[3, 2]
				If stiles[1, 2].height <= ownHeight And stiles[2, 3].height <= ownHeight And (stiles[2, 1] <> stiles[3, 3] Or stiles[2, 1] <> stiles[1, 1])
					Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[2, 1], AT_NORTHEAST_DIAGONAL))
				Else
					Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[2, 1], AT_NORTHEAST_INVERTED))
				EndIf
				'If stiles[2, 1] = stiles[3, 3] And stiles[2, 1] = stiles[1, 1]
				'	Self.autotiles[i, h].AddLast(TAutoTile.Create(stiles[2, 1], AT_NORTHEAST_INVERTED)) 
				'Else
				'	Self.autotiles[i, h].AddLast(TAutoTile.Create(stiles[2, 1], AT_NORTHEAST_DIAGONAL)) 
				'EndIf
			Else
				Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[2, 1], AT_NORTH))
			EndIf
		EndIf
		
		' East
		If stiles[3, 2].height > ownHeight
			' Check clockwise
			If stiles[3, 2] = stiles[2, 3]
				If stiles[1, 2].height <= ownHeight And stiles[2, 1].height <= ownHeight And (stiles[3, 2] <> stiles[3, 1] Or stiles[3, 2] <> stiles[1, 3])
					Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[3, 2], AT_SOUTHEAST_DIAGONAL))
				Else
					Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[3, 2], AT_SOUTHEAST_INVERTED)) 
				EndIf
				'If stiles[3, 2] = stiles[3, 1] And stiles[3, 2] = stiles[1, 3]
				'	Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[3, 2], AT_SOUTHEAST_INVERTED))
				'Else
				'	Self.autoTiles[i, h].AddLast(TAutoTile.Create(tiles[3, 2], AT_SOUTHEAST_DIAGONAL)) 
				'EndIf
			Else
				Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[3, 2], AT_EAST))
			EndIf
		EndIf
		
		' South
		If stiles[2, 3].height > ownHeight
			' Check clockwise
			If stiles[2, 3] = stiles[1, 2]
				If stiles[2, 1].height <= ownHeight And stiles[3, 2].height <= ownHeight And (stiles[2, 3] <> stiles[3, 3] Or stiles[2, 3] <> stiles[1, 1])
					Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[2, 3], AT_SOUTHWEST_DIAGONAL))
				Else
					Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[2, 3], AT_SOUTHWEST_INVERTED)) 
				EndIf
				'If stiles[2, 3] = stiles[3, 3] And stiles[2, 3] = stiles[1, 1]
				'	Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[2, 3], AT_SOUTHWEST_INVERTED))
				'Else
				'	Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[2, 3], AT_SOUTHWEST_DIAGONAL)) 
				'EndIf
			Else
				Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[2, 3], AT_SOUTH))
			EndIf
		EndIf
		
		' West
		If stiles[1, 2].height > ownHeight
			' Check clockwise
			If stiles[1, 2] = stiles[2, 1]
				If stiles[3, 2].height <= ownHeight And stiles[2, 3].height <= ownHeight And (stiles[1, 2] <> stiles[1, 3] Or stiles[1, 2] <> stiles[3, 1])
					Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[1, 2], AT_NORTHWEST_DIAGONAL))
				Else
					Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[1, 2], AT_NORTHWEST_INVERTED)) 
				EndIf
				'If tiles[1, 2] = stiles[1, 3] And stiles[1, 2] = stiles[3, 1]
				'	Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[1, 2], AT_NORTHWEST_INVERTED))
				'Else
				'	Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[1, 2], AT_NORTHWEST_DIAGONAL)) 
				'EndIf
			Else
				Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[1, 2], AT_WEST))
			EndIf
		EndIf
		
		' South + East corner
		If stiles[3, 3].height > ownHeight And stiles[3, 3] <> stiles[3, 2] And stiles[3, 3] <> stiles[2, 3] And stiles[3, 2].height <= stiles[3, 3].height And stiles[2, 3].height <= stiles[3, 3].height
			Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[3, 3], AT_SOUTHEAST))
		EndIf
		
		' South + West corner
		If stiles[1, 3].height > ownHeight And stiles[1, 3] <> stiles[1, 2] And stiles[1, 3] <> stiles[2, 3] And stiles[1, 2].height <= stiles[1, 3].height And stiles[2, 3].height <= stiles[1, 3].height
			Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[1, 3], AT_SOUTHWEST))
		EndIf
		
		' North + West corner
		If stiles[1, 1].height > ownHeight And stiles[1, 1] <> stiles[1, 2] And stiles[1, 1] <> stiles[2, 1] And stiles[1, 2].height <= stiles[1, 1].height And stiles[2, 1].height <= stiles[1, 1].height
			Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[1, 1], AT_NORTHWEST))
		EndIf
		
		' North + East corner
		If stiles[3, 1].height > ownHeight And stiles[3, 1] <> stiles[2, 1] And stiles[3, 1] <> stiles[3, 2] And stiles[2, 1].height <= stiles[3, 1].height And stiles[3, 2].height <= stiles[2, 1].height
			Self.autoTiles[i, h].AddLast(TAutoTile.Create(stiles[3, 1], AT_NORTHEAST))
		EndIf
		
		' Sort
		Self.autoTiles[i, h].Sort(True, TAutoTile.CompareFunc)
	End Method
	
	' RegenerateAutoTileInformation
	Method RegenerateAutoTileInformation()
		For Local i:Int = 0 Until Self.width
			For Local h:Int = 0 Until Self.height
				'Self.GenerateAutoTileInformation(i, h)
				Self.autoTiles[i, h] = Null
			Next
		Next
	End Method
	
	' UpdateAutoTileInformation
	' Updates the tile itself and the surrounding tiles
	Method UpdateAutoTileInformation(i:Int, h:Int)
		For Local a:Int = 0 To 2
			For Local b:Int = 0 To 2
				If i + a > 0 And h + b > 0 And i + a <= Self.width And h + b <= Self.height
					'Self.GenerateAutoTileInformation(i + a - 1, h + b - 1)
					Self.autoTiles[i + a - 1, h + b - 1] = Null
				EndIf
			Next
		Next
	End Method
	
	' Resize
	Method Resize(newWidth:Int, newHeight:Int, newLayers:Int = -1)
		If newWidth = -1
			newWidth = Self.width
		EndIf
		If newHeight = -1
			newHeight = Self.height
		EndIf
		If newLayers = -1
			newLayers = Self.layers
		EndIf
		
		Local copyX:Int = Min(newWidth, Self.width)
		Local copyY:Int = Min(newHeight, Self.height)
		Local copyL:Int = Min(newLayers, Self.layers)
		
		Local tmp:Byte[copyL, copyX, copyY]
		Local tmpScripts:String[copyX, copyY]
		
		For Local l:Int = 0 Until copyL
			For Local i:Int = 0 Until copyX
				For Local h:Int = 0 Until copyY
					tmp[l, i, h] = Self.tiles[l, i, h]
				Next
			Next
		Next
		
		For Local i:Int = 0 Until copyX
			For Local h:Int = 0 Until copyY
				tmpScripts[i, h] = Self.scripts[i, h]
			Next
		Next
		
		Self.layers = newLayers
		Self.width = newWidth
		Self.height = newHeight
		
		Self.widthInPixels = Self.width * Self.tileSizeX
		Self.heightInPixels = Self.height * Self.tileSizeY
		Self.tiles = New Byte[Self.layers, Self.width, Self.height]
		Self.scripts = New String[Self.width, Self.height]
		Self.autoTiles = New TList[Self.width, Self.height]
		Self.cost = TGameMap.Create(Self.width, Self.height, 1)
		Self.enemySpawns = New TList[Self.height]
		
		For Local l:Int = 0 Until copyL
			For Local i:Int = 0 Until copyX
				For Local h:Int = 0 Until copyY
					Self.tiles[l, i, h] = tmp[l, i, h]
				Next
			Next
		Next
		
		For Local i:Int = 0 Until copyX
			For Local h:Int = 0 Until copyY
				Self.scripts[i, h] = tmpScripts[i, h]
			Next
		Next
		
		' TODO: Remove enemy spawns which are not on the map
		
		' Create lists
		For Local I:Int = 0 Until Self.height
			Self.enemySpawns[I] = CreateList()
		Next
		
		'Self.cost.resize(width, Self.height, Self.layers)
		
		Self.RegenerateAutoTileInformation()
	End Method
	
	' Scroll
	Method Scroll(scrollX:Float, scrollY:Float)
		Self.originX :- scrollX
		Self.originY :- scrollY
	End Method
	
	' SetOffset
	Method SetOffset(scrollX:Float, scrollY:Float)
		Self.originX = -scrollX
		Self.originY = -scrollY
	End Method
	
	' SetOffsetToTileCentered
	Method SetOffsetToTileCentered(nTileX:Int, nTileY:Int)
		Self.SetOffset(nTileX * Self.tileSizeX - Self.screenSizeX / 2 + Self.tileSizeX / 2, nTileY * Self.tileSizeY - Self.screenSizeY / 2 + Self.tileSizeY / 2)
	End Method
	
	' LimitOffset
	Method LimitOffset()
		Local mapWidthNormal:Int = Self.width >= Self.screenTilesX
		Local mapHeightNormal:Int = Self.height >= Self.screenTilesY
		
		' Top Left corner
		If mapWidthNormal And Self.originX > 0
			Self.originX = 0
		EndIf
		If mapHeightNormal And Self.originY > 0
			Self.originY = 0
		EndIf
		
		' Bottom Right corner
		If mapWidthNormal And Self.originX < -(Self.widthInPixels - Self.screenSizeX)
			Self.originX = -(Self.widthInPixels - Self.screenSizeX)
		EndIf
		If mapHeightNormal And Self.originY < -(Self.heightInPixels - Self.screenSizeY)
			Self.originY = -(Self.heightInPixels - Self.screenSizeY)
		EndIf
	End Method
	
	' GetRealOffsetX
	Method GetRealOffsetX:Int()
		Return -Self.originX
	End Method
	
	' GetRealOffsetY
	Method GetRealOffsetY:Int()
		Return -Self.originY
	End Method
	
	' GetStartX
	Method GetStartTileX:Int(index:Int = 0)
		Return Self.startX[index]
	End Method
	
	' GetStartY
	Method GetStartTileY:Int(index:Int = 0)
		Return Self.startY[index]
	End Method
	
	' GetTileSizeX
	Method GetTileSizeX:Int()
		Return Self.tileSizeX
	End Method
	
	' GetTileSizeY
	Method GetTileSizeY:Int()
		Return Self.tileSizeY
	End Method
	
	' GetWidth
	Method GetWidth:Int()
		Return Self.width
	End Method
	
	' GetHeight
	Method GetHeight:Int()
		Return Self.height
	End Method
	
	' GetLayers
	Method GetLayers:Int()
		Return Self.layers
	End Method
	
	' GetName
	Method GetName:String()
		Return Self.name
	End Method
	
	' Set
	Method Set(nLayer:Byte, nX:Int, nY:Int, value:Byte)
		Self.tiles[nLayer, nX, nY] = value
		
		If nLayer = 0
			Self.UpdateAutoTileInformation(nX, nY)
		EndIf
	End Method
	
	' Get
	Method Get:Byte(nLayer:Byte, nX:Int, nY:Int)
		Return Self.tiles[nLayer, nX, nY]
	End Method
	
	' SetScript
	Method SetScript(nScriptName:String, nX:Int, nY:Int)
		Self.scripts[nX, nY] = nScriptName
	End Method
	
	' GetScript
	Method GetScript:String(nX:Int, nY:Int)
		Return Self.scripts[nX, nY]
	End Method
	
	' GetTileCoords
	Method GetTileCoords:Int(screenX:Int, screenY:Int, x:Int Var, y:Int Var)
		x = (screenX - Self.originX) / Self.tileSizeX
		y = (screenY - Self.originY) / Self.tileSizeY
		
		If x >= 0 And x < Self.width And y >= 0 And y < Self.height
			Return 1
		EndIf
		
		Return 0
	End Method
	
	' GetTileCoordsDirect
	Method GetTileCoordsDirect:Int(mapX:Int, mapY:Int, x:Int Var, y:Int Var)
		x = mapX / Self.tileSizeX
		y = mapY / Self.tileSizeY
		
		' TODO: Correct mapX/Y
		If mapX < 0
			x = -1
		EndIf
		If mapY < 0
			y = -1
		EndIf
		
		If x >= 0 And x < Self.width And y >= 0 And y < Self.height
			Return 1
		EndIf
		
		Return 0
	End Method
	
	' GetTileType
	Method GetTileType:TTileType(nLayer:Byte, nX:Int, nY:Int) 
		If nX >= 0 And nX < Self.width And nY >= 0 And nY < Self.height And nLayer >= 0 And nLayer < Self.layers
			Return Self.byteToTile[nLayer, Self.tiles[nLayer, nX, nY] ]
		EndIf
		
		Return TTileType.NullTile
	End Method
	
	' GetNumberOfTilesOnScreen
	Method GetNumberOfTilesOnScreen:Int()
		Return Self.screenTilesX * Self.screenTilesY
	End Method
	
	' FillAt
	Method FillAt(nLayer:Byte, nX:Int, nY:Int, value:Byte, goDiagonal:Int = False)
		' Check parameters
		If nLayer < 0 Or nLayer >= Self.layers Or nX < 0 Or nX >= Self.width Or nY < 0 Or nY >= Self.height
			Return
		EndIf
		
		' Check tile
		If Self.tiles[nLayer, nX, nY] = value
			Return
		EndIf
		
		Local queue:TList = CreateList()
		Local old:Byte = Self.tiles[nLayer, nX, nY]
		Local link:TLink
		Local node:TTileNode
		
		Self.tiles[nLayer, nX, nY] = value
		Self.UpdateAutoTileInformation(nX, nY)
		
		link = queue.AddLast(TTileNode.Create(nLayer, nX, nY))
		
		While link <> Null
			node = TTileNode(link.Value())
			
			'DebugLog node.x + " : " + node.y
			
			' West
			If node.x > 0 And Self.tiles[node.layer, node.x - 1, node.y] = old
				Self.tiles[node.layer, node.x - 1, node.y] = value
				If nLayer = 0
					Self.UpdateAutoTileInformation(node.x - 1, node.y) 
				EndIf
				queue.AddLast(TTileNode.Create(node.layer, node.x - 1, node.y))
			EndIf
			
			' East
			If node.x < Self.width - 1 And Self.tiles[node.layer, node.x + 1, node.y] = old
				Self.tiles[node.layer, node.x + 1, node.y] = value
				If nLayer = 0
					Self.UpdateAutoTileInformation(node.x + 1, node.y) 
				EndIf
				queue.AddLast(TTileNode.Create(node.layer, node.x + 1, node.y))
			EndIf
			
			' North
			If node.y > 0 And Self.tiles[node.layer, node.x, node.y - 1] = old
				Self.tiles[node.layer, node.x, node.y - 1] = value
				If nLayer = 0
					Self.UpdateAutoTileInformation(node.x, node.y - 1) 
				EndIf
				queue.AddLast(TTileNode.Create(node.layer, node.x, node.y - 1))
			EndIf
			
			' South
			If node.y < Self.height - 1 And Self.tiles[node.layer, node.x, node.y + 1] = old
				Self.tiles[node.layer, node.x, node.y + 1] = value
				If nLayer = 0
					Self.UpdateAutoTileInformation(node.x, node.y + 1) 
				EndIf
				queue.AddLast(TTileNode.Create(node.layer, node.x, node.y + 1))
			EndIf
			
			If goDiagonal
				' Northwest
				If node.x > 0 And node.y > 0 And Self.tiles[node.layer, node.x - 1, node.y - 1] = old
					Self.tiles[node.layer, node.x - 1, node.y - 1] = value
					If nLayer = 0
						Self.UpdateAutoTileInformation(node.x - 1, node.y - 1) 
					EndIf
					queue.AddLast(TTileNode.Create(node.layer, node.x - 1, node.y - 1))
				EndIf
				
				' Northeast
				If node.x < Self.width - 1 And node.y > 0 And Self.tiles[node.layer, node.x + 1, node.y - 1] = old
					Self.tiles[node.layer, node.x + 1, node.y - 1] = value
					If nLayer = 0
						Self.UpdateAutoTileInformation(node.x + 1, node.y - 1) 
					EndIf
					queue.AddLast(TTileNode.Create(node.layer, node.x + 1, node.y - 1))
				EndIf
				
				' Southwest
				If node.x > 0 And node.y < Self.height - 1 And Self.tiles[node.layer, node.x - 1, node.y + 1] = old
					Self.tiles[node.layer, node.x - 1, node.y + 1] = value
					If nLayer = 0
						Self.UpdateAutoTileInformation(node.x - 1, node.y + 1) 
					EndIf
					queue.AddLast(TTileNode.Create(node.layer, node.x - 1, node.y + 1))
				EndIf
				
				' Southeast
				If node.x < Self.width - 1 And node.y < Self.height - 1 And Self.tiles[node.layer, node.x + 1, node.y + 1] = old
					Self.tiles[node.layer, node.x + 1, node.y + 1] = value
					If nLayer = 0
						Self.UpdateAutoTileInformation(node.x + 1, node.y + 1) 
					EndIf
					queue.AddLast(TTileNode.Create(node.layer, node.x + 1, node.y + 1))
				EndIf
			EndIf
			
			link = link.NextLink()
			queue.RemoveFirst()
		Wend
	End Method
	
	' FillAll
	Method FillAll(nLayer:Byte, value:Byte)
		Local i:Int
		Local h:Int
		
		For i = 0 To Self.width - 1
			For h = 0 To Self.height - 1
				Self.tiles[nLayer, i, h] = value
			Next
		Next
		
		If nLayer = 0
			Self.RegenerateAutoTileInformation()
		EndIf
	End Method
	
	' SetStartTile
	Method SetStartTile(index:Int, x:Int, y:Int)
		Self.startX[index] = x
		Self.startY[index] = y
	End Method
	
	' Create
	Function Create:TTileMap(nLayers:Int = 1, nWidth:Int = 0, nHeight:Int = 0)
		Local tmap:TTileMap = New TTileMap
		tmap.Init(nLayers, nWidth, nHeight)
		Return tmap
	End Function
End Type

'TAutoTile
Type TAutoTile
	Field tt:TTileType
	Field direction:Int
	
	' CompareFunc
	Function CompareFunc:Int(a:Object, b:Object)
		Return TAutoTile(a).tt.height > TAutoTile(b).tt.height
	End Function
	
	' Create
	Function Create:TAutoTile(nTT:TTileType, nDirection:Int)
		Local autoTile:TAutoTile = New TAutoTile
		autoTile.tt = nTT
		autoTile.direction = nDirection
		Return autoTile
	End Function
End Type

' TTileType
Type TTileType
	Global NullTile:TTileType = TTileType.Create(0)
	
	Field byteCode:Byte
	
	Field mTop:Byte
	Field mBottom:Byte
	Field mLeft:Byte
	Field mRight:Byte
	
	Field autotile:TImage
	Field height:Int
	
	' Init
	Method Init(nBC:Byte) 
		Self.byteCode = nBC
		
		Self.mTop = False
		Self.mBottom = False
		Self.mLeft = False
		Self.mRight = False
		
		Self.autotile = Null
		Self.height = 0
	End Method
	
	' LoadAutoTile
	Method LoadAutoTile()
		SetMaskColor 0, 0, 0
		Self.autotile = LoadAnimImage(FS_ROOT + "data/layers/layer-1/autotiles/" + Self.byteCode + ".png", 32, 32, 0, 16, MASKEDIMAGE)
	End Method
	
	' SetMovement
	Method SetMovement(nTop:Byte, nBottom:Byte, nLeft:Byte, nRight:Byte) 
		Self.mTop = nTop
		Self.mBottom = nBottom
		Self.mLeft = nLeft
		Self.mRight = nRight
	End Method
	
	' LoadINI
	Method LoadINI(iniFile:String) 
		' Create default file if ini does not exist
		If FileType(iniFile) = 0
			CopyFile ExtractDir(iniFile) + "/" + "default.ini", iniFile
		EndIf
		
		' Read tile config file
		Local ini:TINI = TINI.Create(iniFile)
		ini.Load()
		
		If ini.CategoryExists("AutoTile")
			Self.height = Int(ini.Get("AutoTile", "Height") ) 
		EndIf
		
		Self.SetMovement	(..
							Byte(ini.Get("Movement", "Top")),..
							Byte(ini.Get("Movement", "Bottom")),..
							Byte(ini.Get("Movement", "Left")),..
							Byte(ini.Get("Movement", "Right"))..
						)
	End Method
	
	' Create
	Function Create:TTileType(nBC:Byte)
		Local tile:TTileType = New TTileType
		tile.Init(nBC)
		Return tile
	End Function
End Type

' TTileNode
' Used for filling
Type TTileNode
	Field layer:Byte
	Field x:Int
	Field y:Int
	
	' Create
	Function Create:TTileNode(nLayer:Byte, nX:Int, nY:Int)
		Local tile:TTileNode = New TTileNode
		tile.layer = nLayer
		tile.x = nX
		tile.y = nY
		Return tile
	End Function
End Type

' TTextureAtlas
Type TTextureAtlas
	Field cursorX:Int
	Field cursorY:Int
	
	Field tileSizeX:Int
	Field tileSizeY:Int
	
	Field format:Int
	
	Field pixmap:TPixmap
	
	' Init
	Method Init(sizeX:Int, sizeY:Int, nTileSizeX:Int, nTileSizeY:Int, useAlpha:Int = 1) 
		If useAlpha
			Self.format = PF_RGBA8888
		Else
			Self.format = PF_RGB888
		EndIf
		Self.pixmap = CreatePixmap(sizeX, sizeY, Self.format)
		Self.pixmap.ClearPixels(0)
		Self.tileSizeX = nTileSizeX
		Self.tileSizeY = nTileSizeY
	End Method
	
	' Add
	' TODO: Test this method
	Method Add(tile:TPixmap)
		Self.pixmap.Paste(tile, Self.cursorX, Self.cursorY)
		Self.cursorX :+ Self.tileSizeX
		
		If Self.cursorX > Self.pixmap.width - Self.tileSizeX
			Self.cursorX = 0
			Self.cursorY :+ Self.tileSizeY
		EndIf
	End Method
	
	' Insert
	Method Insert(tile:TPixmap, byteCode:Int)
		Local tilesPerRow:Int = Self.pixmap.width / Self.tileSizeX
		Local y:Int = byteCode / tilesPerRow
		Local x:Int = byteCode Mod tilesPerRow
		
		'Print x + ", " + y
		Self.pixmap.Paste(tile, x * Self.tileSizeX, y * Self.tileSizeY)
	End Method
	
	' CreateImage
	Method CreateImage:TImage(flags:Int = MIPMAPPEDIMAGE)
		'Return LoadImage(Self.pixmap, 0)
		Return LoadAnimImage(Self.pixmap, Self.tileSizeX, Self.tileSizeY, 0, (Self.pixmap.width / Self.tileSizeX) * (Self.pixmap.height / Self.tileSizeY), flags)
	End Method
	
	' Create
	Function Create:TTextureAtlas(sizeX:Int, sizeY:Int, nTileSizeX:Int, nTileSizeY:Int)
		Local atlas:TTextureAtlas = New TTextureAtlas
		atlas.Init(sizeX, sizeY, nTileSizeX, nTileSizeY)
		Return atlas
	End Function
End Type

Rem
' ActivateTextureSplatting_D3D
Function ActivateTextureSplatting_D3D(r_image1:TImage , r_image2:TImage)
        Local frame1:TD3D7ImageFrame=TD3D7ImageFrame(r_image1.frame(0))
        Local frame2:TD3D7ImageFrame=TD3D7ImageFrame(r_image2.frame(0))
'		If TD3D7Max2DDriver(D3D7Max2DDriver.SetActiveFrame(frame1))
	 		D3D7GraphicsDriver().Direct3DDevice7().SetTexture 0,frame1.surface
	   		D3D7GraphicsDriver().Direct3DDevice7().SetTextureStageState( 0, D3DTSS_COLORARG1, D3DTA_TEXTURE );
	   		D3D7GraphicsDriver().Direct3DDevice7().SetTextureStageState( 0, D3DTSS_COLOROP,   D3DTOP_SELECTARG1);
	   		D3D7GraphicsDriver().Direct3DDevice7().SetTextureStageState( 0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
 	  		D3D7GraphicsDriver().Direct3DDevice7().SetTextureStageState( 0, D3DTSS_ALPHAOP,   D3DTOP_SELECTARG1 );
	 		D3D7GraphicsDriver().Direct3DDevice7().SetTexture 1 , frame2.surface
	   		D3D7GraphicsDriver().Direct3DDevice7().SetTextureStageState( 1, D3DTSS_COLORARG1, D3DTA_TEXTURE);
	   		D3D7GraphicsDriver().Direct3DDevice7().SetTextureStageState( 1, D3DTSS_COLOROP,   D3DTOP_SELECTARG2);
	   		D3D7GraphicsDriver().Direct3DDevice7().SetTextureStageState( 1, D3DTSS_COLORARG2, D3DTA_CURRENT);
 	  		D3D7GraphicsDriver().Direct3DDevice7().SetTextureStageState( 1, D3DTSS_ALPHAOP,   D3DTOP_SELECTARG1 );
 	 		D3D7GraphicsDriver().Direct3DDevice7().SetTextureStageState( 1 , D3DTSS_ALPHAARG1 , D3DTA_TEXTURE ) ; 
'		EndIf
End Function

' SetModNormal_D3D
Function SetModNormal_D3D()
  	D3D7GraphicsDriver().Direct3DDevice7().SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE)
	D3D7GraphicsDriver().Direct3DDevice7().SetRenderState D3DRS_ALPHATESTENABLE, True
	D3D7GraphicsDriver().Direct3DDevice7().SetRenderState D3DRS_ALPHABLENDENABLE, False
End Function 
End Rem
