' Strict
SuperStrict

' Modules
Import BRL.Max2D

' Files
Import "Global.bmx"

' TDamageView
Type TDamageView
	Const lifeTime:Int = 1000
	Const speed:Float = 0.1
	Const dmgNumYOffset:Int = -46
	
	Global list:TList = CreateList()
	
	Field dmg:Int
	Field dmgString:String
	Field txtWidth:Int, txtHeight:Int
	Field x:Int, y:Float	' y has to be float
	Field creationTime:Int
	Field special:Int
	Field link:TLink
	
	' Init
	Method Init(dmgNum:Int, nX:Int, nY:Int, nSpecial:Int = False)
		Self.dmg = dmgNum
		Self.txtWidth = 0
		Self.txtHeight = 0
		Self.x = nX
		Self.y = nY
		Self.creationTime = MilliSecs()
		Self.special = nSpecial
		Self.link = TDamageView.list.AddLast(Self)
		
		If Self.dmg < 0
			Self.dmgString = "+" + String(- Self.dmg)
		Else
			Self.dmgString = String(Self.dmg)
		End If
	End Method
	
	' Draw
	Method Draw(gameSpeed:Float)
		If MilliSecs() - Self.creationTime > TDamageView.lifeTime
			Self.Remove()
			Return
		Else
			SetAlpha 1 - ((MilliSecs() - Self.creationTime) / Float(TDamageView.lifeTime))
		End If
		
		' Has to be updated on first draw call when font is set
		If Self.txtWidth = 0
			Self.txtWidth = TextWidth(Self.dmgString)
		End If
		If Self.txtHeight = 0
			Self.txtHeight = TextHeight(Self.dmgString)
		End If
		
		Self.y:-gameSpeed * TDamageView.speed
		
		' Shadow + Outline
		SetColor 0, 0, 0
		DrawText Self.dmgString, Self.x - Self.txtWidth / 2 - 1, Self.y - Self.txtHeight / 2 - 1
		DrawText Self.dmgString, Self.x - Self.txtWidth / 2 + 1, Self.y - Self.txtHeight / 2 + 1
		
		If Self.special = True
			SetColor 255, 255, 0
		Else
			If dmg < 0
				SetColor 0, 255, 0
			Else
				SetColor 255, 0, 0
			End If
		End If
		
		DrawText Self.dmgString, Self.x - Self.txtWidth / 2, Self.y - Self.txtHeight / 2
	End Method
	
	' Remove
	Method Remove()
		Self.link.Remove()
	End Method
	
	' Create
	Function Create:TDamageView(dmgNum:Int, nX:Int, nY:Int, nSpecial:Int = False)
		Local dmgView:TDamageView = New TDamageView
		dmgView.Init(dmgNum, nX, nY, nSpecial)
		Return dmgView
	End Function
End Type