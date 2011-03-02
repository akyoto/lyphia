SuperStrict

Rem
bbdoc: ParticleEngine
EndRem
Rem
Module BPR.ParticleEngine

ModuleInfo "Version: 1.2.2"
ModuleInfo "Author: Eduard Urbach"
ModuleInfo "Website: www.blitzprog.com"
ModuleInfo "License: Shareware"
ModuleInfo "Modserver: BPR"
ModuleInfo "History: 1.2.2 Release"
ModuleInfo "History: Added File-based effects"
ModuleInfo "History: Added TParticleTemplate"
ModuleInfo "History: Added TParticleWind"
ModuleInfo "History: Added UpdateParticleEngine"
ModuleInfo "History: Optimized speed"
ModuleInfo "History: 1.1.2 Release"
ModuleInfo "History: Added TEmitterTween"
ModuleInfo "History: Added UpdateEmitters"
ModuleInfo "History: Added CreateParticleHermite"
ModuleInfo "History: Optimized speed"
ModuleInfo "History: 1.0.0 Release"
ModuleInfo "History: Added TParticle"
ModuleInfo "History: Added TParticleTween"
ModuleInfo "History: Added TParticleGravityX, TParticleGravityY, TParticleGravityXY"
ModuleInfo "History: Added CreateParticleTween"
ModuleInfo "History: Added CreateParticleGravityX, CreateParticleGravityY, CreateParticleGravityXY"
ModuleInfo "History: Added UpdateParticles"
End Rem

Import BRL.Max2D
Import BRL.LinkedList
Import BRL.Random
Import BRL.Retro
Import BRL.Audio

Const ALMOST_ONE:Float = 0.99

' TParticle - Abstract type 
Rem
bbdoc:   TParticle is the basic type for particles
about:   -
End Rem
Type TParticle Abstract
	Global list:TList = New TList
	Global count:Int = 0
	
	Field link:TLink
	
	Rem
	bbdoc:   Creates a new particle
	about:   -
	End Rem
	Method New()
		Self.link = TParticle.list.AddLast(Self)
		TParticle.count :+ 1 
	End Method 
	
	Rem
	bbdoc:   Removes this particle
	about:   -
	End Rem
	Method Remove() 
		Self.link.Remove()
		TParticle.count :- 1 
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
	
	'Method SetToEnd() Abstract
	
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
	
	'Update
	Rem
	bbdoc:   All particles will be updated
	about:   -
	End Rem
	Function UpdateSystem()
		SetBlend ALPHABLEND
		UpdateParticles()
	End Function
End Type

' TParticleTween
Rem
bbdoc:   TParticleTween is a special type of TParticle
about:   Interpolates between many different values
End Rem
Type TParticleTween Extends TParticle
	Field tween:Float 
	
	Field x:Float,y:Float 'Position
	Field img:TImage 'Image
	Field rotation:Float, scaleX:Float, scaleY:Float, alpha:Float 'Others
	
	Field speed:Float, endSpeed:Float 
	Field endX:Float, endY:Float
	Field endRotation:Float, endScaleX:Float, endScaleY:Float, endAlpha:Float
	Field r:Int,g:Int,b:Int
	Field endR:Int,endG:Int,endB:Int
	
	Field diffX:Float, diffY:Float
	Field diffRotation:Float, diffScaleX:Float, diffScaleY:Float, diffAlpha:Float
	Field diffR:Int,diffG:Int,diffB:Int
	Field diffSpeed:Float
	
	' Init
	Rem
	bbdoc:   Creates a particle and sets up the values
	returns: -
	about:   This method is called by CreateParticleTween()
	End Rem
	Method Init(x:Float,y:Float,endX:Float,endY:Float,img:TImage,..
		rotation:Float,endRotation:Float,scaleX:Float,endScaleX:Float,..
		scaleY:Float,endScaleY:Float,alpha:Float,endAlpha:Float,..
		r:Int=255,g:Int=255,b:Int=255,endR:Int=255,endG:Int=255,endB:Int=255,speed:Float=1,endSpeed:Float=1..
	)
		Self.x = x
		Self.y = y
		Self.endX = endX
		Self.endY = endY
		
		Self.img = img
		
		Self.rotation = rotation
		Self.endRotation = endRotation
		
		Self.scaleX = scaleX
		Self.scaleY = scaleY
		
		Self.endScaleX = endScaleX
		Self.endScaleY = endScaleY
		
		Self.alpha = alpha
		Self.endAlpha = endAlpha
		
		Self.r = r
		Self.g = g
		Self.b = b
		
		Self.endR = endR
		Self.endG = endG
		Self.endB = endB
		
		Self.speed = speed
		Self.endSpeed = endSpeed
		
		' Differences
		Self.diffX = endX - x
		Self.diffY = endY - y
		Self.diffRotation = endRotation - rotation
		Self.diffScaleX = endScaleX - scaleX
		Self.diffScaleY = endScaleY - scaleY
		Self.diffAlpha = endAlpha - alpha
		Self.diffR = endR - r
		Self.diffG = endG - g
		Self.diffB = endB - b
		Self.diffSpeed = endSpeed - speed
	End Method 
	
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
		
		SetAlpha(alpha + diffAlpha * tween)
		SetTransform(rotation:Float + diffRotation * tween,..
						scaleX + diffScaleX * tween,..
						scaleY + diffScaleY * tween)
		SetColor(r + diffR * tween, g + diffG * tween, b + diffB * tween)
		
		Self.Draw()
	End Method 
	
	'Draw
	Rem
	bbdoc:   The particle will be drawn
	about:   This method is called by TParticle.Update()
	End Rem
	Method Draw() 
		DrawImage img, x + diffX * tween, y + diffY * tween
	End Method 
	
	'Move
	Rem
	bbdoc:   The particle will be moved
	about:   This method is called by TParticle.Update()
	End Rem
	Method Move() 
		tween :+ (speed + diffSpeed * tween) * 0.05
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

' Partikel-Engine updaten 
Rem
bbdoc:   Emitters and particles will be drawn
about:   -
End Rem
Function UpdateParticleSystem()
	SetBlend(ALPHABLEND)
	UpdateParticles()
End Function

' Partikel updaten
Rem
bbdoc:   The particles will be moved an drawn
about:   -
End Rem
Function UpdateParticles()
	Local particle:TParticle
	For particle = EachIn TParticle.list 
		particle.Update()
	Next
End Function 

'TweenPartikel erstellen
Rem
bbdoc:   Creates a particle (with interpolation)
about:   -
End Rem
Function CreateParticleTween(x:Float,y:Float,endX:Float,endY:Float,img:TImage,rotation:Float=0,..
	endRotation:Float=0,scaleX:Float=1,endScaleX:Float=1,scaleY:Float=1,endScaleY:Float=1,..
	alpha:Float=1,endAlpha:Float=0,r:Int=255,g:Int=255,b:Int=255,endR:Int=255,endG:Int=255,..
	endB:Int=255,speed:Float=1,endSpeed:Float=1..
)
	Local particle:TParticleTween = New TParticleTween
	particle.Init(x,y,endX,endY,img,rotation,endRotation,scaleX,endScaleX,..
		scaleY,endScaleY,alpha,endAlpha,r,g,b,endR,endG,endB,speed,endSpeed)
End Function

