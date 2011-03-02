' Strict
SuperStrict

' Files
Import "Global.bmx"

' TWeapon
Type TWeapon
	
	' Init
	Method Init()
		
	End Method
		
	' Create
	Function Create:TWeapon()
		Local weapon:TWeapon = New TWeapon
		weapon.Init()
		Return weapon
	End Function
End Type

