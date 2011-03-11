' Strict
SuperStrict

' Modules
Import BRL.Basic

' Files
Import "../Global.bmx"

' MD5
Function MD5:String(sMessage:String)
	Local nblk:Int					= ((sMessage.length + 8) Shr 6) + 1
	Local MD5_x:Int[(nblk * 16)]
	Local MD5_a:Int 				= 1732584193
	Local MD5_b:Int 				= -271733879
	Local MD5_c:Int 				= -1732584194
	Local MD5_d:Int 				= 271733878
	Local MD5_AA:Int				= 0
	Local MD5_BB:Int				= 0
	Local MD5_CC:Int				= 0
	Local MD5_DD:Int				= 0
	Local i	:Int					= 0
		 
	For i = 0 To nblk * 16 - 1
		MD5_x[i] = 0
	Next
    
	For i = 0 To (sMessage.length - 1)
		MD5_x[(i Shr 2)] = MD5_x[(i Shr 2)] | (sMessage[i] Shl ((i Mod 4) * 8))
	Next 
    
	MD5_x[(i Shr 2)] 		= MD5_x[(i Shr 2)] | (128 Shl (((i) Mod 4) * 8))
	MD5_x[nblk * 16 - 2]	= sMessage.length * 8

	For Local k:Int = 0 To (nblk * 16 - 1) Step 16
		MD5_AA = MD5_a
    	MD5_BB = MD5_b
    	MD5_CC = MD5_c
    	MD5_DD = MD5_d

    'Round 1
        MD5_a = MD5_FF(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 0], 7, -680876936)		'&HD76AA478
        MD5_d = MD5_FF(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 1], 12, -389564586)	'&HE8C7B756
        MD5_c = MD5_FF(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 2], 17, 606105819 )	'&H242070DB
        MD5_b = MD5_FF(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 3], 22, -1044525330)	'&HC1BDCEEE
        MD5_a = MD5_FF(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 4], 7, -176418897)		'&HF57C0FAF
        MD5_d = MD5_FF(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 5], 12, 1200080426 )	'&H4787C62A
        MD5_c = MD5_FF(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 6], 17, -1473231341)	'&HA8304613
        MD5_b = MD5_FF(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 7], 22, -45705983)		'&HFD469501
        MD5_a = MD5_FF(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 8], 7, 1770035416) 	'&H698098D8
        MD5_d = MD5_FF(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 9], 12, -1958414417 )	'&H8B44F7AF
        MD5_c = MD5_FF(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 10], 17, -42063 )		'&HFFFF5BB1
        MD5_b = MD5_FF(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 11], 22, -1990404162)	'&H895CD7BE
        MD5_a = MD5_FF(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 12], 7, 1804603682) 	'&H6B901122
        MD5_d = MD5_FF(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 13], 12, -40341101) 	'&HFD987193
        MD5_c = MD5_FF(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 14], 17, -1502002290)	'&HA679438E
        MD5_b = MD5_FF(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 15], 22, 1236535329)	'&H49B40821

    'Round 2
        MD5_a = MD5_GG(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 1], 5, -165796510)		'&HF61E2562
        MD5_d = MD5_GG(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 6], 9, -1069501632)	'&HC040B340
        MD5_c = MD5_GG(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 11], 14, 643717713)	'&H265E5A51
        MD5_b = MD5_GG(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 0], 20, -373897302)	'&HE9B6C7AA
        MD5_a = MD5_GG(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 5], 5, -701558691) 	'&HD62F105D
        MD5_d = MD5_GG(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 10], 9, 38016083)		'&H2441453
        MD5_c = MD5_GG(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 15], 14, -660478335)	'&HD8A1E681
        MD5_b = MD5_GG(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 4], 20, -405537848)	'&HE7D3FBC8
        MD5_a = MD5_GG(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 9], 5, 568446438)		'&H21E1CDE6
        MD5_d = MD5_GG(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 14], 9, -1019803690)	'&HC33707D6
        MD5_c = MD5_GG(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 3], 14, -187363961)	'&HF4D50D87
        MD5_b = MD5_GG(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 8], 20, 1163531501)	'&H455A14ED
        MD5_a = MD5_GG(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 13], 5, -1444681467)	'&HA9E3E905
        MD5_d = MD5_GG(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 2], 9, -51403784)		'&HFCEFA3F8
        MD5_c = MD5_GG(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 7], 14, 1735328473)	'&H676F02D9
        MD5_b = MD5_GG(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 12], 20, -1926607734)	'&H8D2A4C8A

    'Round 3
        MD5_a = MD5_HH(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 5], 4, -378558)		'&HFFFA3942
        MD5_d = MD5_HH(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 8], 11, -2022574463)	'&H8771F681
        MD5_c = MD5_HH(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 11], 16, 1839030562)	'&H6D9D6122
        MD5_b = MD5_HH(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 14], 23, -35309556)	'&HFDE5380C
        MD5_a = MD5_HH(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 1], 4, -1530992060)	'&HA4BEEA44
        MD5_d = MD5_HH(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 4], 11, 1272893353)	'&H4BDECFA9
        MD5_c = MD5_HH(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 7], 16, -155497632)	'&HF6BB4B60
        MD5_b = MD5_HH(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 10], 23, -1094730640)	'&HBEBFBC70
        MD5_a = MD5_HH(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 13], 4, 681279174)		'&H289B7EC6
        MD5_d = MD5_HH(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 0], 11, -358537222)	'&HEAA127FA
        MD5_c = MD5_HH(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 3], 16, -722521979)	'&HD4EF3085
        MD5_b = MD5_HH(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 6], 23, 76029189)		'&H4881D05
        MD5_a = MD5_HH(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 9], 4, -640364487)		'&HD9D4D039
        MD5_d = MD5_HH(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 12], 11, -421815835)	'&HE6DB99E5
        MD5_c = MD5_HH(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 15], 16, 530742520)	'&H1FA27CF8
        MD5_b = MD5_HH(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 2], 23, -995338651)	'&HC4AC5665

    'Round 4
        MD5_a = MD5_II(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 0], 6, -198630844)		'&HF4292244
        MD5_d = MD5_II(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 7], 10, 1126891415)	'&H432AFF97
        MD5_c = MD5_II(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 14], 15, -1416354905)	'&HAB9423A7
        MD5_b = MD5_II(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 5], 21, -57434055)		'&HFC93A039
        MD5_a = MD5_II(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 12], 6, 1700485571)	'&H655B59C3
        MD5_d = MD5_II(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 3], 10, -1894986606)	'&H8F0CCC92
        MD5_c = MD5_II(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 10], 15, -1051523)		'&HFFEFF47D
        MD5_b = MD5_II(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 1], 21, -2054922799)	'&H85845DD1
        MD5_a = MD5_II(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 8], 6, 1873313359)		'&H6FA87E4F
        MD5_d = MD5_II(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 15], 10, -30611744)	'&HFE2CE6E0
        MD5_c = MD5_II(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 6], 15, -1560198380 )	'&HA3014314
        MD5_b = MD5_II(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 13], 21, 1309151649)	'&H4E0811A1      
        MD5_a = MD5_II(MD5_a, MD5_b, MD5_c, MD5_d, MD5_x[k + 4], 6, -145523070)		'&HF7537E82
        MD5_d = MD5_II(MD5_d, MD5_a, MD5_b, MD5_c, MD5_x[k + 11], 10, -1120210379)	'&HBD3AF235
        MD5_c = MD5_II(MD5_c, MD5_d, MD5_a, MD5_b, MD5_x[k + 2], 15, 718787259)		'&H2AD7D2BB
        MD5_b = MD5_II(MD5_b, MD5_c, MD5_d, MD5_a, MD5_x[k + 9], 21, -343485551)	'&HEB86D391

        MD5_a = MD5_a + MD5_AA
        MD5_b = MD5_b + MD5_BB
        MD5_c = MD5_c + MD5_CC
        MD5_d = MD5_d + MD5_DD
    Next

    Return String(WordToHex$(MD5_a) + WordToHex$(MD5_b) + WordToHex$(MD5_c) + WordToHex$(MD5_d)).tolower()

End Function

Function MD5_F:Int(x:Int, y:Int, z:Int)
	Return ((x & y) | (~(x) & z))
End Function

Function MD5_G:Int(x:Int, y:Int, z:Int)
    Return ((x & z) | (y & (~(z))))
End Function

Function MD5_H:Int(x:Int, y:Int, z:Int)
    Return (x ~ y ~ z)
End Function

Function MD5_I:Int(x:Int, y:Int, z:Int)
    Return (y ~ (x | (~z)))
End Function

Function MD5_FF:Int(a:Int, b:Int, c:Int, d:Int, x:Int, s:Int, ac:Int)
    a = (a + ((MD5_F(b, c, d)+ x)+ ac))
    a = RotateLeft(a, s)
    Return a + b
End Function

Function MD5_GG:Int(a:Int, b:Int, c:Int, d:Int, x:Int, s:Int, ac:Int)
    a = (a + ((MD5_G(b, c, d) + x) + ac))
    a = RotateLeft(a, s)
    Return a + b
End Function

Function MD5_HH:Int(a:Int, b:Int, c:Int, d:Int, x:Int, s:Int, ac:Int)
    a = (a + ((MD5_H(b, c, d) + x) + ac))
    a = RotateLeft(a, s)
    Return a + b
End Function

Function MD5_II:Int(a:Int, b:Int, c:Int, d:Int, x:Int, s:Int, ac:Int)
    a = (a + ((MD5_I(b, c, d) + x) + ac))
    a = RotateLeft(a, s)
    Return a + b
End Function

Function RotateLeft:Int(lValue:Int, iShiftBits:Int)
    Return (lValue Shl iShiftBits) | (lValue Shr (32 - iShiftBits))
End Function

Function WordToHex:String(lValue:Int)
	Local returnString:String
	For Local x:Int = 0 To 7
		Local y:Int = (lValue Shr (x*4)) & $f
		returnString$ = Chr(y+48+(y>9)*39) + returnString$
	Next

	Return returnString$[6..8] + returnString$[4..6] + returnString$[2..4] + returnString$[0..2]
End Function
