' Strict
SuperStrict

' Modules
Import BRL.Max2D
'Import BtbN.GLDraw2D
Import BRL.LinkedList
Import BRL.Random

' Float (Ungenauigkeiten beheben)
Const ALMOST_ONE:Float = 0.99

' --------------------
' | By the way:
' --------------------
'	0.99999... = 1
' --------------------
' | ;-)
' --------------------

' TParticle
Rem
bbdoc:   TParticle is the basic type for particles
about:   -
End Rem
Type TParticle Abstract
	Global count:Int = 0
	
	' Link
	Field link:TLink
	
	' New
	Method New()
		TParticle.count :+ 1
	End Method
	
	' Delete
	Method Delete()
		TParticle.count :- 1
	End Method
	
	Rem
	bbdoc:   Removes this particle
	about:   -
	End Rem
	Method Remove()
		If Self.link <> Null
			Self.link.Remove()
			Self.link = Null
		EndIf
	End Method
	
	' SetGroup
	Method SetGroup(group:TParticleGroup)
		If Self.link <> Null
			Self.link.Remove()
		EndIf
		group.Add(Self)
	End Method
	
	'Abstract 
	Rem
	bbdoc:   Moves the particle
	about:   -
	End Rem
	Method Move() Abstract
	
	Rem
	bbdoc:   Resets the particle
	about:   particle.tween will be set to zero
	End Rem
	Method Reset() Abstract
	
	Rem
	bbdoc:   The particle will be moved and drawn
	about:   -
	End Rem
	Method Update() Abstract
	
	Rem
	bbdoc:   The particle will be drawn
	about:   This method is called by TParticle.Update()
	End Rem
	Method Draw() Abstract
	
	' UpdateAndDrawFast
	Method UpdateAndDrawFast() Abstract
End Type

' TParticleGroup
Rem
bbdoc:   TParticleGroup contains a list for particles
about:   -
End Rem
Type TParticleGroup
	Global list:TList = CreateList()
	Global DefaultGroup:TParticleGroup = TParticleGroup.Create()
	
	' Link
	Field link:TLink
	Field particleList:TList
	Field originX:Int
	Field originY:Int
	
	' Init
	Method Init()
		Self.link = TParticleGroup.list.AddLast(Self)
		Self.particleList = CreateList()
		Self.originX = -1
		Self.originY = -1
	End Method
	
	' Add
	Method Add(particle:TParticle)
		particle.link = Self.particleList.AddLast(particle)
	End Method
	
	' Draw
	Rem
	bbdoc:   The particles will be moved an drawn
	about:   -
	End Rem
	Method Draw() 
		' TODO: Optimise
		Local oldOriginX:Float, oldOriginY:Float
		GetOrigin(oldOriginX, oldOriginY)
		
		SetBlend ALPHABLEND
		
		If Self.originX <> - 1 And Self.originY <> - 1
			.SetOrigin oldOriginX + Self.originX, oldOriginY + Self.originY
		End If
		
		Local particle:TParticle
		For particle = EachIn Self.particleList
			particle.UpdateAndDrawFast()
		Next
		
		SetOrigin oldOriginX, oldOriginY
	End Method
	
	' Update
	Method Update()
		Local particle:TParticle
		For particle = EachIn Self.particleList
			particle.Update()
		Next
	End Method
	
	' SetOffset
	Method SetOffset(offX:Int, offY:Int)
		Self.originX = offX
		Self.originY = offY
	End Method
	
	Rem
	bbdoc:   Removes this particle group
	about:   -
	End Rem
	Method Remove() 
		Self.link.Remove()
		' TODO: Remove each particle?
		Self.particleList = Null
	End Method
	
	' DrawAllGroups
	Rem
	bbdoc:   Emitters and particles of each group will be drawn
	about:   -
	End Rem
	Function DrawAllGroups()
		For Local group:TParticleGroup = EachIn TParticleGroup.list
			group.Draw()
		Next
	End Function
	
	' Create
	Function Create:TParticleGroup() 
		Local group:TParticleGroup = New TParticleGroup
		group.Init()
		Return group
	End Function
End Type

' TParticleTween
Rem
bbdoc:   TParticleTween is a special type of TParticle
about:   Interpolates between many different values
End Rem
Type TParticleTween Extends TParticle
	Field tween:Float
	Field lifetimeInv:Float
	Field timeCreated:Int
	
	' Image
	Field img:TImage
	
	' Position
	Field x:Float, endX:Float
	Field y:Float, endY:Float
	
	' Transform
	Field rotation:Float, endRotation:Float
	Field scaleX:Float, endScaleX:Float
	Field scaleY:Float, endScaleY:Float
	Field alpha:Float, endAlpha:Float
	Field r:Int, endR:Int
	Field g:Int, endG:Int
	Field b:Int, endB:Int
	
	Field diffX:Float, diffY:Float
	Field diffRotation:Float, diffScaleX:Float, diffScaleY:Float, diffAlpha:Float
	Field diffR:Int,diffG:Int,diffB:Int
	
	' SetImage
	Method SetImage(_img:TImage)
		Self.img = _img
	End Method
	
	' SetLifeTime
	Method SetLifeTime(_lifetime:Int)
		Self.lifetimeInv = 1.0 / _lifetime
	End Method
	
	' SetPositionStart
	Method SetPositionStart(_x:Float, _y:Float)
		Self.x = _x
		Self.y = _y
		Self.diffX = Self.endX - Self.x
		Self.diffY = Self.endY - Self.y
	End Method
	
	' SetPositionEnd
	Method SetPositionEnd(_x:Float, _y:Float)
		Self.endX = _x
		Self.endY = _y
		Self.diffX = Self.endX - Self.x
		Self.diffY = Self.endY - Self.y
	End Method
	
	' SetColorStart
	Method SetColorStart(_r:Int, _g:Int, _b:Int)
		Self.r = _r
		Self.g = _g
		Self.b = _b
		Self.diffR = Self.endR - Self.r
		Self.diffG = Self.endG - Self.g
		Self.diffB = Self.endB - Self.b
	End Method
	
	' SetColorEnd
	Method SetColorEnd(_r:Int, _g:Int, _b:Int)
		Self.endR = _r
		Self.endG = _g
		Self.endB = _b
		Self.diffR = Self.endR - Self.r
		Self.diffG = Self.endG - Self.g
		Self.diffB = Self.endB - Self.b
	End Method
	
	' SetAlphaStart
	Method SetAlphaStart(_alpha:Float)
		Self.alpha = _alpha
		Self.diffAlpha = Self.endAlpha - Self.alpha
	End Method
	
	' SetAlphaEnd
	Method SetAlphaEnd(_alpha:Float)
		Self.endAlpha = _alpha
		Self.diffAlpha = Self.endAlpha - Self.alpha
	End Method
	
	' SetRotationStart
	Method SetRotationStart(_rotation:Float)
		Self.rotation = _rotation
		Self.diffRotation = Self.endRotation - Self.rotation
	End Method
	
	' SetRotationEnd
	Method SetRotationEnd(_rotation:Float)
		Self.endRotation = _rotation
		Self.diffRotation = Self.endRotation - Self.rotation
	End Method
	
	' SetScaleStart
	Method SetScaleStart(_scaleX:Float, _scaleY:Float)
		Self.scaleX = _scaleX
		Self.scaleY = _scaleY
		Self.diffScaleX = Self.endScaleX - Self.scaleX
		Self.diffScaleY = Self.endScaleY - Self.scaleY
	End Method
	
	' SetScaleEnd
	Method SetScaleEnd(_scaleX:Float, _scaleY:Float)
		Self.endScaleX = _scaleX
		Self.endScaleY = _scaleY
		Self.diffScaleX = Self.endScaleX - Self.scaleX
		Self.diffScaleY = Self.endScaleY - Self.scaleY
	End Method
	
	' Create
	Rem
	bbdoc:   Creates a particle and sets up the values
	returns: -
	about:   
	End Rem
	Function Create:TParticleTween( ..
		_group:TParticleGroup,..
		_lifetime:Int,..
		_img:TImage,..
		_x:Float, _y:Float,..
		_endX:Float, _endY:Float,..
		_alpha:Float = 1.0, _endAlpha:Float = 0.0,..
		_rotation:Float = 0.0, _endRotation:Float = 0.0,..
		_scaleX:Float = 1, _endScaleX:Float = 1, _scaleY:Float = 1, _endScaleY:Float = 1,..
		_r:Int = 255, _g:Int = 255, _b:Int = 255,..
		_endR:Int = 255, _endG:Int = 255, _endB:Int = 255..
	)
		Local particle:TParticleTween = New TParticleTween
		
		' Add to particle group
		If _group = Null
			_group = TParticleGroup.DefaultGroup
		EndIf
		_group.Add(particle)
		
		particle.timeCreated = MilliSecs()
		
		particle.lifetimeInv = 1.0 / _lifetime
		
		particle.img = _img
		
		particle.x = _x
		particle.y = _y
		
		particle.endX = _endX
		particle.endY = _endY
		
		particle.rotation = _rotation
		particle.endRotation = _endRotation
		
		particle.scaleX = _scaleX
		particle.scaleY = _scaleY 
		
		particle.endScaleX = _endScaleX
		particle.endScaleY = _endScaleY
		
		particle.alpha = _alpha
		particle.endAlpha = _endAlpha
		
		particle.r = _r
		particle.g = _g
		particle.b = _b
		
		particle.endR = _endR
		particle.endG = _endG
		particle.endB = _endB
		
		' Differences
		particle.diffX = _endX - _x
		particle.diffY = _endY - _y
		particle.diffRotation = _endRotation - _rotation
		particle.diffScaleX = _endScaleX - _scaleX
		particle.diffScaleY = _endScaleY - _scaleY
		particle.diffAlpha = _endAlpha - _alpha
		particle.diffR = _endR - _r
		particle.diffG = _endG - _g
		particle.diffB = _endB - _b
		
		Return particle
	End Function
	
	'Update
	Rem
	bbdoc:   Particle will be moved and drawn
	about:   This method is called by UpdateParticles()
	End Rem
	Method Update() 
		Self.Move()
		
		If tween > ALMOST_ONE Then
			Self.Remove()
			Return
		EndIf
	End Method
	
	'Draw
	Rem
	bbdoc:   The particle will be drawn
	about:   This method is called by TParticle.Update()
	End Rem
	Method Draw()
		SetAlpha(alpha + diffAlpha * tween)
		SetTransform(rotation + diffRotation * tween,..
						scaleX + diffScaleX * tween,..
						scaleY + diffScaleY * tween)
		SetColor(r + diffR * tween, g + diffG * tween, b + diffB * tween)
		
		DrawImage img, x + diffX * tween, y + diffY * tween
	End Method
	
	'Move
	Rem
	bbdoc:   The particle will be moved
	about:   This method is called by TParticle.Update()
	End Rem
	Method Move()
		tween = (MilliSecs() - Self.timeCreated) * Self.lifetimeInv
	End Method
	
	' UpdateAndDrawFast
	' NOTE: This function is used internally to speed up particle group rendering
	Method UpdateAndDrawFast()
		'Move
		tween = (MilliSecs() - Self.timeCreated) * Self.lifetimeInv
		
		' Update
		If tween > ALMOST_ONE Then
			Self.Remove()
			Return
		EndIf
		
		' Draw
		SetAlpha(alpha + diffAlpha * tween)
		SetTransform(rotation + diffRotation * tween,..
						scaleX + diffScaleX * tween,..
						scaleY + diffScaleY * tween)
		SetColor(r + diffR * tween, g + diffG * tween, b + diffB * tween)
		
		DrawImage img, x + diffX * tween, y + diffY * tween
	End Method
	
	'Start position
	Rem
	bbdoc:   Resets the particle
	about:   particle.tween will be set to zero
	End Rem
	Method Reset()
		tween = 0
	End Method 
	
	'End of tweening 
	Method SetToEnd() 
		tween = 1 
	End Method
End Type

' TParticleFactory
Type TParticleFactory
	Global instance:TParticleFactory = New TParticleFactory
	
	Rem
	Method CreateParticleTween( ..
		_group:TParticleGroup,..
		_lifetime:Int,..
		_img:TImage,..
		_x:Float, _y:Float,..
		_endX:Float, _endY:Float,..
		_alpha:Float = 1.0, _endAlpha:Float = 0.0,..
		_rotation:Float = 0.0, _endRotation:Float = 0.0,..
		_scaleX:Float = 1, _endScaleX:Float = 1, _scaleY:Float = 1, _endScaleY:Float = 1,..
		_r:Int = 255, _g:Int = 255, _b:Int = 255,..
		_endR:Int = 255, _endG:Int = 255, _endB:Int = 255..
	)
		TParticleTween.Create( ..
			_group,  ..
			_lifetime,  ..
			_img,  ..
			_x, _y,  ..
			_endX, _endY,  ..
			_alpha, _endAlpha,  ..
			_rotation, _endRotation,  ..
			_scaleX, _endScaleX, _scaleY, _endScaleY,  ..
			_r, _g, _b,  ..
			_endR, _endG, _endB ..
		)
	End Method
	End Rem
	
	Field lastTween:TParticleTween
	
	Method CreateParticleTween:TParticleTween( ..
		_group:TParticleGroup ..
	)
		lastTween = TParticleTween.Create(_group, 0, Null, 0, 0, 0, 0)
		Return lastTween
	End Method
	
	' SetImage
	Method SetImage(_img:TImage)
		lastTween.img = _img
	End Method
	
	' SetLifeTime
	Method SetLifeTime(_lifetime:Int)
		lastTween.lifetimeInv = 1.0 / _lifetime
	End Method
	
	' SetPositionStart
	Method SetPositionStart(_x:Float, _y:Float)
		lastTween.x = _x
		lastTween.y = _y
		lastTween.diffX = lastTween.endX - lastTween.x
		lastTween.diffY = lastTween.endY - lastTween.y
	End Method
	
	' SetPositionEnd
	Method SetPositionEnd(_x:Float, _y:Float)
		lastTween.endX = _x
		lastTween.endY = _y
		lastTween.diffX = lastTween.endX - lastTween.x
		lastTween.diffY = lastTween.endY - lastTween.y
	End Method
	
	' SetColorStart
	Method SetColorStart(_r:Int, _g:Int, _b:Int)
		lastTween.r = _r
		lastTween.g = _g
		lastTween.b = _b
		lastTween.diffR = lastTween.endR - lastTween.r
		lastTween.diffG = lastTween.endG - lastTween.g
		lastTween.diffB = lastTween.endB - lastTween.b
	End Method
	
	' SetColorEnd
	Method SetColorEnd(_r:Int, _g:Int, _b:Int)
		lastTween.endR = _r
		lastTween.endG = _g
		lastTween.endB = _b
		lastTween.diffR = lastTween.endR - lastTween.r
		lastTween.diffG = lastTween.endG - lastTween.g
		lastTween.diffB = lastTween.endB - lastTween.b
	End Method
	
	' SetAlphaStart
	Method SetAlphaStart(_alpha:Float)
		lastTween.alpha = _alpha
		lastTween.diffAlpha = lastTween.endAlpha - lastTween.alpha
	End Method
	
	' SetAlphaEnd
	Method SetAlphaEnd(_alpha:Float)
		lastTween.endAlpha = _alpha
		lastTween.diffAlpha = lastTween.endAlpha - lastTween.alpha
	End Method
	
	' SetRotationStart
	Method SetRotationStart(_rotation:Float)
		lastTween.rotation = _rotation
		lastTween.diffRotation = lastTween.endRotation - lastTween.rotation
	End Method
	
	' SetRotationEnd
	Method SetRotationEnd(_rotation:Float)
		lastTween.endRotation = _rotation
		lastTween.diffRotation = lastTween.endRotation - lastTween.rotation
	End Method
	
	' SetScaleStart
	Method SetScaleStart(_scaleX:Float, _scaleY:Float)
		lastTween.scaleX = _scaleX
		lastTween.scaleY = _scaleY
		lastTween.diffScaleX = lastTween.endScaleX - lastTween.scaleX
		lastTween.diffScaleY = lastTween.endScaleY - lastTween.scaleY
	End Method
	
	' SetScaleEnd
	Method SetScaleEnd(_scaleX:Float, _scaleY:Float)
		lastTween.endScaleX = _scaleX
		lastTween.endScaleY = _scaleY
		lastTween.diffScaleX = lastTween.endScaleX - lastTween.scaleX
		lastTween.diffScaleY = lastTween.endScaleY - lastTween.scaleY
	End Method
End Type
