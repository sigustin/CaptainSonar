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
	PlayersPorts %List of all the players ports => size == Input.nbPlayer
	PlayersPositions %List of all the players positions
	PlayersAtSurface %List of lists of the surface state of each player (true/false)
	PlayersAtSurfaceWaitingTurn %List of lists of number of turn the players as to wait to play again
	NTurnMax = 4 %Maximal number of turn for the game (set high for normal game)

	%========== Functions and procedures =====================
	CreatePlayers
	GenerateColor %unused
	SetUpAndShow
	CreatePlayersAtSurface
	CreatePlayersAtSurfaceWaitingTurn
	OneTurn
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

	% @CreatePlayersAtSurface : create the initial list
	fun {CreatePlayersAtSurface I}
		if I==0 then
			nil
		else
			true|{CreatePlayersAtSurface I-1}
		end
	end

	% @CreatePlayersAtSurfaceWaitingTurn : create the initial list
	fun {CreatePlayersAtSurfaceWaitingTurn I}
		if I==0 then
			nil
		else
			0|{CreatePlayersAtSurfaceWaitingTurn I-1}
		end
	end

	% @OneTurn : make one turn in TurnByTurn mode
	proc {OneTurn PlayersAtSurface PlayersAtSurfaceWaitingTurn NewPlayersAtSurface NewPlayersAtSurfaceWaitingTurn}
		%if this player is not dead then set up variable in
		%	if is at surface and turn to wait not at zero then
		%		decrease turn to wait
		%	else
		%		if is at surface then
		%			send dive
		%		end
		%		ask direction
		%		if direction is surface then
		%			setup wait to turn and surace state
		%			broadcast information to other players
		%			send information to GUI
		%		else
		%			broadcast to other players the direction
		%			send information to GUI
		%			charge item?
		%			if charge item then
		%				broadcast it
		%			end
		%			fire?
		%			if fire then
		%				broadcast it
		%			end
		%			explode mine?
		%			if explode mine then
		%				broadcast it
		%			end
		%		end
		%	end
		%end
		{Browser.browse 'OneTurn will be implemented in a short future'}
		
		%Tests of the messages
		local
			ID Position Direction
		in
			{Send PlayersPorts.1 dive}
			{Send PlayersPorts.1 move(ID Position Direction)}
			{Browser.browse ID#Position#Direction}
		end
		%End of tests
	end

	% @TurnByTurn : run the game in turn by turn mode
	proc {TurnByTurn NTurn PlayersAtSurface PlayersAtSurfaceWaitingTurn}
		%if NTurnMax is reached stop
		if NTurn<NTurnMax then NewPlayersAtSurface NewPlayersAtSurfaceWaitingTurn in
			%TODO check if all dead

			%display information
		   {Browser.browse 'Turn number : '#NTurn}

		   %Simulate One Turn
		   {OneTurn PlayersAtSurface.1 PlayersAtSurfaceWaitingTurn.1 NewPlayersAtSurface NewPlayersAtSurfaceWaitingTurn}

		   %update state
		   PlayersAtSurface.2 = NewPlayersAtSurface|_
		   PlayersAtSurfaceWaitingTurn.2 = NewPlayersAtSurfaceWaitingTurn|_

		   %delay to see whats happening
		   {Delay 1000}

		   % next turn
		   {TurnByTurn NTurn+1 PlayersAtSurface.2 PlayersAtSurfaceWaitingTurn.2}
   		end
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

	%setup players dive state lists
	PlayersAtSurface = {CreatePlayersAtSurface Input.nbPlayer}|_
	PlayersAtSurfaceWaitingTurn = {CreatePlayersAtSurfaceWaitingTurn Input.nbPlayer}|_

	%============== Run the game ==================
	if Input.isTurnByTurn then
		%--------- Turn by turn game ----------------
		{Browser.browse 'coucou'}
		{TurnByTurn 0 PlayersAtSurface PlayersAtSurfaceWaitingTurn}
	else
		%--------- Simultaneous game ----------------
		{Simultaneous}
	end
end
