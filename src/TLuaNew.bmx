' Strict
SuperStrict

' Modules
Import PUB.Lua
Import brl.maxlua
Import brl.reflection

' Files
Import "Global.bmx"

Extern
	Function bbRefMethodPtr:Byte Ptr(obj:Object, index:Int)
	Function bbRefPushObject(p:Byte Ptr, obj:Object)
End Extern

' TLuaVM
Type TLuaVM
	' Lua state
	Field state:Byte Ptr
	
	' Init
	Method InitVM()
		Self.state = luaL_newstate()
		luaL_openlibs(Self.state)
	End Method
	
	' Remove
	Method Remove()
		If Self.state
			lua_close(Self.state)
			Self.state = Null
		EndIf
	End Method
	
	' Delete
	Method Delete()
		Self.Remove()
	End Method
	
	' GetLuaState
	Method GetLuaState:Byte Ptr()
		Return Self.state
	End Method
	
	' RegisterObject
	Method RegisterObject(obj:Object, name:String)
		Local tid:TTypeId = TTypeId.ForObject(obj)
		Local methName:String
		
		Self.BeginTable(name)
		For Local meth:TMethod = EachIn tid.Methods()
			methName = meth.Name()
			If methName <> "New" And methName <> "Delete"
				?Debug
					Print "Registering method " + meth.Name()
				?
				Self.AddTableFunction(bbRefMethodPtr(obj, meth._index), meth.Name())
			EndIf
		Next
		Self.AddTableFunction(funcTest, "funcTest")
		Self.EndTable()
	End Method
	
	' BeginTable
	Method BeginTable(tableName:String)
		lua_pushstring(Self.state, tableName)
		lua_createtable(Self.state, 0, 1)
	End Method
	
	' AddTableFunction
	Method AddTableFunction(func:Int(ls:Byte Ptr), funcName:String)
		lua_pushstring(Self.state, funcName)
		lua_pushcfunction(Self.state, func)
		lua_settable(Self.state, -3)
	End Method
	
	' EndTable
	Method EndTable()
		lua_settable(Self.state, LUA_GLOBALSINDEX)
	End Method
	
	Rem
	' Create
	Function Create:TLuaVM()
		Local vm:TLuaVM = New TLuaVM
		vm.InitVM()
		Return vm
	End Function
	End Rem
End Type

' TLuaScript
Type TLuaScript Extends TLuaVM
	Field source:String
	
	' GetSourceCode
	Method GetSourceCode:String()
		Return Self.source
	End Method
	
	' Init
	Method Init(file:String)
		Super.InitVM()
		Self.source = LoadString(file + ".lua")
		
		luaL_loadstring(Self.state, Self.source)
		
		lua_getfield(Self.state, LUA_GLOBALSINDEX, "debug")' get global "debug" 
		lua_getfield(Self.state, -1, "traceback")          ' get "debug.traceback" 
		lua_remove (Self.state, -2)                        ' remove "debug" table from stack
		
		lua_pcall(Self.state, 1, -1, -1)
	End Method
	
	' Invoke
	Method Invoke(funcName:String)
		lua_getfield Self.state, LUA_GLOBALSINDEX, funcName
		lua_pcall Self.state, 0, 1, 0
		lua_pop Self.state, 1
	End Method
	
	' Remove
	Method Remove()
		
	End Method
	
	' Delete
	Method Delete()
		Self.Remove()
	End Method
	
	' Create
	Function Create:TLuaScript(file:String)
		Local scr:TLuaScript = New TLuaScript
		scr.Init(file)
		Return scr
	End Function
End Type

' Rem MODULE TEST
Type ttType
	Method funcTest2:Int()
		Local a:Int = lua_tointeger(ls, -1)
		Local b:Int = lua_tointeger(ls, -2)
		Print "Test Func!"
		Print a
		Print b
	End Method
End Type

Function funcTest(ls:Byte Ptr)
	Local a:Int = lua_tointeger(ls, -1)
	Local b:Int = lua_tointeger(ls, -2)
	Print "funcTest !!!"
	Print a
	Print b
End Function

Local tt:ttType = New ttType

Print "TEST BEGINS"
Local script:TLuaScript = TLuaScript.Create(FS_ROOT + "data/skills/Test")
Local script2:TLuaScript = TLuaScript.Create(FS_ROOT + "data/skills/Test2")

' Invoke
script.RegisterObject(tt, "tt")
script.Invoke("run")

'lua_pop script.state, 1

' End Rem