' Strict
SuperStrict

' Modules
Import BRL.Map
Import BRL.System
Import BRL.Stream

' TINICategory
Type TINICategory
	Field map:TMap
	
	' Init
	Method Init()
		Self.map = CreateMap()
	End Method
	
	' Remove
	Method Remove()
		
	End Method
	
	' Add
	Method Add(key:String, value:String)
		Self.map.insert key, value
	End Method
	
	' Get
	Method Get:String(key:String)
		Return String(map.ValueForKey(key))
	End Method
	
	' Create
	Function Create:TINICategory()
		Local inic:TINICategory = New TINICategory
		inic.Init()
		Return inic
	End Function
End Type

' TINI
Type TINI
	Field file:String
	Field categories:TMap
	
	' Init
	Method Init(nFile:String)
		Self.file = nFile
		Self.categories = CreateMap()
	End Method
	
	' Remove
	Method Remove()
		
	End Method
	
	' Load
	Method Load:Int(nFile:String = "")
		' Replace file name
		If nFile.length > 0
			Self.file = nFile
		EndIf
		
		' Create stream
		Local stream:TStream = ReadFile(Self.file)
		If stream = Null
			Return 0
		EndIf
		
		Local currentCategory:TINICategory
		Local name:String
		Local value:String
		Local line:String
		Local i:Int
		
		While stream.Eof() = 0
			line = stream.ReadLine()
			
			If line.length > 0
				' Category
				If line[0] = "["[0]
					currentCategory = TINICategory.Create()
					name = line[1..line.length-1]
					Self.categories.insert name, currentCategory
				EndIf
				
				' Check each character
				For i = 0 To line.length - 1
					If line[i] = "="[0]
						name = line[..i].Trim()
						value = line[i+1..].Trim()
						currentCategory.Add(name, value)
					EndIf
				Next
			EndIf
		Wend
		
		stream.Close()
		
		Return 1
	End Method
	
	' Save
	Method Save:Int(nFile:String = "")
		' Replace file name
		If nFile.length > 0
			Self.file = nFile
		EndIf
		
		' Create stream
		Local stream:TStream = WriteFile(Self.file)
		If stream = Null
			Return 0
		EndIf
		
		'
		For Local cat:String = EachIn Self.categories.Keys()
			Local iniCat:TINICategory = TINICategory(Self.categories.ValueForKey(cat))
			
			stream.WriteLine "[" + cat + "]"
			For Local k:String = EachIn iniCat.map.Keys()
				stream.WriteLine k + " = " + String(iniCat.map.ValueForKey(k))
			Next
			stream.WriteLine ""
		Next
		
		stream.Close()
		
		Return 1
	End Method
	
	' Get
	Method Get:String(category:String, key:String)
		Local iniCat:TINICategory = TINICategory(Self.categories.ValueForKey(category))
		Return String(iniCat.Get(key))
	End Method
	
	' GetCategory
	Method GetCategory:TINICategory(category:String)
		Return TINICategory(Self.categories.ValueForKey(category))
	End Method
	
	' CategoryExists
	Method CategoryExists:Int(category:String)
		Return Self.categories.Contains(category)
	End Method
	
	' AddCategory
	Method AddCategory(name:String)
		Self.categories.insert name, TINICategory.Create()
	End Method
	
	' Create
	Function Create:TINI(file:String = "")
		Local ini:TINI = New TINI
		ini.Init(file)
		Return ini
	End Function
End Type

