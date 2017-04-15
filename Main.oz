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
	PlayersPositions %List of all the players' positions
	
	%========== Functions and procedures =====================
	CreatePlayers
	GenerateColor %unused
	SetUpAndShow
	TurnByTurn
	Simultaneous
in

	%======== Functions and procedures definitions ============
	% @CreatePlayers : runs a loop that creates @Input.nbPlayer players (with a color and an ID)
	%                  and puts them in @PortsPlayer (with IDs in descending order)
	proc {CreatePlayers}
		fun {Loop Count PlayersList}
			%{Browser.browse Count}
			if Count > Input.nbPlayer then
				PlayersList
			else
				local
					CurrentPlayer
				in
					CurrentPlayer = {PlayerManager.playerGenerator {Nth Input.players Count} {Nth Input.colors Count} Count}
					{Loop Count+1 CurrentPlayer|PlayersList}
				end
			end
		end
	in
		PlayersPorts = {Loop 1 nil}
	end

	% @GenerateColor : for now, generates a random color that will be used as the color of a player
	%                  TODO it should be changed to generate colors that are always
	%                       different from one another and not too close to one another
	%                       (2 players should easily be differentiable)
	% UNUSED
	fun {GenerateColor}
		c( ({OS.rand} mod 256) 
		   ({OS.rand} mod 256) 
		   ({OS.rand} mod 256) )
	end

	% @SetUpAndShow : ask each Player its initial position (allow multiple boats at the same place? YES cf. pdf)
	%                 Then sends a message to the GUI to display their initial position
	fun {SetUpAndShow PlayersPorts}
	   case PlayersPorts
	   of P|H then ID Position in
	   	% Set up the current player
	      {Send P initPosition(ID Position)}
	      % Show the current player
	      {Send PortWindow initPlayer(ID Position)}
	      %return
	      Position|{SetUpAndShow H}
	   [] nil then
	      nil
	   end
	end
	
	% @TurnByTurn : run the game in turn by turn mode
	proc {TurnByTurn}
	   {Browser.browse 'turn by turn'}
	end

	% @Simultaneous : run the game in simultaneous mode
	proc {Simultaneous}
	   {Browser.browse 'simultaneous'}
	   %TODO
	end

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%=================== Execution ===========================
	
	{Browser.browse 'open the browser'}
	%========= Create the GUI port and run its interface =============
	PortWindow = {GUI.portWindow}
	{Send PortWindow buildWindow}
	
	%======= Create the port for every player and ask them to set up ===================
	{CreatePlayers}
	{Browser.browse 'Input.nbPlayer'#Input.nbPlayer}
	{Browser.browse 'PlayersPorts'#PlayersPorts}

	PlayersPositions = {SetUpAndShow PlayersPorts}
	%for Pos in PlayersPositions do
	%	{Browser.browse Pos}
	%end
	
	%============== Run the game ==================
	if Input.isTurnByTurn then
		%--------- Turn by turn game ----------------
		{TurnByTurn}
	else
		%--------- Simultaneous game ----------------
		{Simultaneous}
	end
	
end
