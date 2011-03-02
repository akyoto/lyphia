' Strict
SuperStrict

' Modules
Import BRL.MaxLua
Import BRL.Max2D

' Files
Import "Global.bmx"
Import "Utilities/Math.bmx"

' TLuaScript
Type TLuaScript
	Field script:String
	Field luaClass:TLuaClass
	
	' GetLuaClass
	Method GetLuaClass:TLuaClass()
		Return Self.luaClass
	End Method
	
	' CreateInstance
	Method CreateInstance:TLuaObject(superObject:Object)
		Return TLuaObject.Create(Self.luaClass, superObject)
	End Method
	
	' Init
	Method Init(file:String)
		Self.script = LoadString(file)
		Self.luaClass = TLuaClass.Create(Self.script)
	End Method
	
	' Create
	Function Create:TLuaScript(file:String)
		Local scr:TLuaScript = New TLuaScript
		scr.Init(file)
		Return scr
	End Function
End Type

' TLuaFunctions
Type TLuaFunctions
	Global instance:TLuaFunctions = New TLuaFunctions
	
	Method SeedRnd(seed:Int = -1)
		.SeedRnd(seed)
	End Method
	
	Method Rnd:Double(minVal:Double = 1, maxVal:Double)
		Return .Rnd(minVal, maxVal)
	End Method
	
	Method Rand:Int(minVal:Int, maxVal:Int = 1)
		Return .Rand(minVal, maxVal)
	End Method
	
	Method Sin:Float(degree:Float)
		Return .Sin(degree)
	End Method
	
	Method Cos:Float(degree:Float)
		Return .Cos(degree)
	End Method
	
	Method SinFastSec:Float(degree:Int)
		Return SinFast[degree Mod maxSinCosCache]
	End Method
	
	Method CosFastSec:Float(degree:Int)
		Return CosFast[degree Mod maxSinCosCache]
	End Method
	
	Method GraphicsWidth:Int()
		Return .GraphicsWidth()
	End Method
	
	Method GraphicsHeight:Int()
		Return .GraphicsHeight()
	End Method
	
	Method MilliSecs:Int()
		Return .MilliSecs()
	End Method
	
	Method Print(str:String)
		.Print(str)
	End Method
End Type
LuaRegisterObject(TLuaFunctions.instance, "app")