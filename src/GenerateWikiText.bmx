SuperStrict

Local wiki:String = ""

For Local L:Int = 1 To 2
	wiki :+ "= Ebene " + L + " =~n~n"
	For Local I:Int = 1 To 255
		If I Mod 10 = 0
			wiki :+ "||~n"
		EndIf
		
		wiki :+ "||<img src='http://lyphia.googlecode.com/svn/trunk/data/layer-" + L + "/" + I + ".png'></img>"
		wiki :+ "<img src='http://lyphia.googlecode.com/svn/trunk/data/layer-" + L + "/" + I + ".png'></img><br />"
		wiki :+ "<img src='http://lyphia.googlecode.com/svn/trunk/data/layer-" + L + "/" + I + ".png'></img>"
		wiki :+ "<img src='http://lyphia.googlecode.com/svn/trunk/data/layer-" + L + "/" + I + ".png'></img>"
	Next
	wiki :+ "||~n~n"
Next

Print wiki