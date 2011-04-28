Rem
	Lyphia
	Started: 9 Nov 2008
	
	(C) Eduard Urbach
	
	Website for developers:
	
	--------------------------------
	https://github.com/blitzprog/lyphia
	--------------------------------
End Rem

' TODO
' * Fix msg list (TListBox)
' * Custom autotiles
' * Fix kill announcements
' * Fix chat function
' * More CC skills
' * Map Hindernisse (beschwören)
' * Fix arena client deleting "by name"

' Strict
SuperStrict

' Framework
Framework BRL.Basic

' Files
Import "GameStates/TGameStateInit.bmx"
Import "GameStates/TGameStateLogIn.bmx"
Import "GameStates/TGameStateMenu.bmx"
Import "GameStates/TGameStateInGame.bmx"
Import "GameStates/TGameStateArena.bmx"
Import "GameStates/TGameStateEditor.bmx"
Import "GameStates/TGameStateExit.bmx"

' Run the main loop
?Not Debug
Try
?
	game = TGame.Create()
	
	gsInit = TGameStateInit.Create(game)
	gsLogIn = TGameStateLogIn.Create(game)
	gsMenu = TGameStateMenu.Create(game)
	gsInGame = TGameStateInGame.Create(game)
	gsArena = TGameStateArena.Create(game)
	gsEditor = TGameStateEditor.Create(game)
	
	game.SetGameState(gsInit)
	game.SetGameState(gsLogIn)
	'game.SetGameState(gsMenu)
	'game.SetGameState(gsInGame)
	'game.SetGameState(gsArena)
	'game.SetGameState(gsEditor)
	
	game.Run()
?Not Debug
Catch exc:Object
	If game.logger <> Null
		game.logger.Write("Runtime error: " + exc.ToString())
	Else
		Print exc.ToString()
	EndIf
End Try
?

' Quit
gsExit = TGameStateExit.Create(game)
game.SetGameState(gsExit)
game.Remove()
End
