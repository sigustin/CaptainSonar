%% Main.oz %%
%% Manages the ports => create and run the game

functor
import
	OS %for random number generation
	Browser %for displaying debug information
	
	GUI
	Input
	PlayerManager
define
	%============= Variables ====================
	PortWindow
	PlayersPorts %List of all the players' ports => size == Input.nbPlayer
	
	%========== Functions and procedures =====================
	% They are all defined at the end of this file
	CreatePlayers
	GenerateColor
in
	{Browser.browse 'open the browser'}
	%========= Create the GUI port and run its interface =============
	PortWindow = {GUI.portWindow}
	{Send PortWindow buildWindow}
	
	%======= Create the port for every player and ask them to set up ===================
	thread {CreatePlayers} end %BUG blocks if it is not in a thread
	{Browser.browse 'Input.nbPlayer'#Input.nbPlayer}
	{Browser.browse 'PlayersPorts'#PlayersPorts}
	
	%============== Run the game ==================
	if Input.isTurnByTurn then
		%--------- Turn by turn game ----------------
		{Browser.browse 'turn by turn'}
		%TODO
	else
		%--------- Simultaneous game ----------------
		{Browser.browse 'simultaneous'}
		%TODO
	end
	
	%======== Functions and procedures definitions ============
	% @CreatePlayers : runs a loop that creates @Input.nbPlayer players (with a color and an ID)
	%                  and puts them in @PortsPlayer (with IDs in descending order)
	proc {CreatePlayers}
		fun {Loop Count PlayersList}
			%{Browser.browse Count}
			if Count >= Input.nbPlayer then 
				PlayersList
			else
				local
					CurrentColor = {GenerateColor}
					CurrentPlayer
				in
					CurrentPlayer = {PlayerManager.playerGenerator player000randomai CurrentColor Count}%TODO use @Input.players
					{Loop Count+1 CurrentPlayer|PlayersList}
				end
			end
		end
	in
		PlayersPorts = {Loop 0 nil}
	end
	
	% @GenerateColor : for now, generates a random color that will be used as the color of a player
	%                  TODO it should be changed to generate colors that are always
	%                       different from one another and not too close to one another
	%                       (2 players should easily be differentiable)
	fun {GenerateColor}
		c( ({OS.rand} mod 256) 
		   ({OS.rand} mod 256) 
		   ({OS.rand} mod 256) )
	end
end
