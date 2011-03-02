
' TWidgetParam
Type TWidgetParam
	Field value:Int
	Field valueOnHover:Int
	
	' GetValueFor
	Method GetValueFor:Int(widget:TWidget)
		If widget.IsHovered()
			Return valueOnHover
		Else
			Return value
		EndIf
	End Method
	
	' Create
	Function Create:TWidgetParam(ini:TINI, category:String, key:String)
		Local widgetParam:TWidgetParam = New TWidgetParam
		widgetParam.value = Int(ini.Get(category, key))
		widgetParam.valueOnHover = Int(ini.Get(category, key + ".onHover"))
		Return widgetParam
	End Function
End Type

