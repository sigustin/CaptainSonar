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
	NTurnMax = 200 %Maximal number of turn for the game (set high for normal game)
	PlayersAlive % List of lists does the players are alive

	%========== Functions and procedures =====================
	CreatePlayers
	GenerateColor %unused
	SetUpAndShow
	CreatePlayersAtSurface
	CreatePlayersAtSurfaceWaitingTurn
	CreatePlayersAlive
	NumberAlive
	BroadcastDirection
	OneTurn
	TurnByTurn
	Simultaneous
	
	%=========== TMP ====================
	TMPMovePlayers

	%=========== DEBUG ====================
	proc {DEBUG}
		{Browser.browse 'debug'}
	end
	proc {Browse Msg}
		{Browser.browse Msg}
	end
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

	% @SetUpAndShow : ask each Player its initial position
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

	% @CreatePlayersAlive : create the initial list
	fun {CreatePlayersAlive I}
		if I==0 then
			nil
		else
			true|{CreatePlayersAlive I-1}
		end
	end

	% @BroadcastDirection : send to all players the Direction taken by player ID
	proc {BroadcastDirection ID Direction}
		for P in PlayersPorts do
			if Direction==surface then
				{Send P saySurface(ID)}
			else
				{Send P sayMove(ID Direction)}
			end
		end
	end

	% @OneTurn : make one turn in TurnByTurn mode
	%			PlayersPorts ports of the players
	%			PlayersAliveFull maintain a full list of the alive state of the players
	%			PlayersAtSurface & PlayersAtSurfaceWaitingTurn players surface state
	%			PlayersAlive alive state for the players that still have to play
	%			NewPlayersAtSurface & NewPlayersAtSurface update the lists
	%			NewPlayersAlive contruct newList of the players alive
	%			The alive state will be handled differently in a short future
	proc {OneTurn PlayersPorts PlayersAtSurface PlayersAtSurfaceWaitingTurn PlayersAlive NewPlayersAtSurface NewPlayersAtSurfaceWaitingTurn ?NewPlayersAlive}
		%Temporary : needed to turn more than once
		NewPlayersAlive = {CreatePlayersAlive Input.nbPlayer}

		%case PlayersPorts|PlayersAlive|PlayersAtSurface|PlayersAtSurfaceWaitingTurn
		%of (PlayerPort|PlayersPorts2)|(LiveState|PlayersAlive2)|(PlayerAtSurface|PlayersAtSurface2)|(PlayerAtSurfaceWaitingTurn|PlayersAtSurface2) then NewPlayersAlive2 NewPlayersAtSurface2 NewPlayersAtSurfaceWaitingTurn2 in
		%	if LiveState then
		%		%our player is alive
		%		if PlayerAtSurface and PlayerAtSurfaceWaitingTurn>0 then
		%			%player has still to wait before he can dive again
		%			NewPlayersAlive = true|NewPlayersAlive2
		%			NewPlayersAtSurface = true|NewPlayersAtSurface2
		%			NewPlayersAtSurfaceWaitingTurn = (PlayerAtSurfaceWaitingTurn-1)|NewPlayersAtSurface2
		%		else ID Position Direction then
		%			%can move again
		%			if PlayerAtSurface then
		%				{Send PLayerPort dive}
		%			end
%
		%			%direction?
		%			{Send PlayerPort move(ID Position Direction)}
		%			{BroadcastDirection ID Direction}
		%			if Direction==surface then
		%				NewPlayersAtSurface = true|PlayersAtSurface2
		%				NewPlayersAtSurfaceWaitingTurn = (Input.TurnSurface-1)|PlayersAtSurfaceWaitingTurn2
		%				{Send PortWindow surface(ID)}
		%			else KindItem KindFire Mine in
		%				{Send PortWindow movePlayer(ID Position)}
%
		%				{Send PlayerPort chargeItem(ID KindItem)}
		%				if ~(KindItem==null) then
		%					%TODO broadcast
		%				end
%
		%				{Send PlayerPort fireItem(ID KindFire)}
		%				if ~(KindFire==null) then
		%					%broadcast and receive informations, change alive list
		%
		%				{Send PlayerPort fireMine(ID Mine)}
		%				if ~(Mine==null) then
		%					%broadcast and receive informations, change alive list
		%				end
		%			end
		%		end
		%	else
		%		%our player is dead
		%		NewPlayersAlive = false|NewPlayersAlive2
		%		NewPlayersAtSurface = false|NewPlayersAtSurface2
		%		NewPlayersAtSurfaceWaitingTurn = 0|NewPlayersAtSurface2
		%	end
		%	%next player
		%	{OneTurn PlayersAtSurface2 PlayersAtSurfaceWaitingTurn2 PlayersAlive2 NewPlayersAtSurfaceWaitingTurn2 NewPlayersAtSurface2 NewPlayersAlive2}
		%[] nil|nil|nil then
		%	NewPlayersAtSurface = nil
		%	NewPlayersAtSurfaceWaitingTurn = nil
		%	NewPlayersAlive = nil
		%end
		%if this player is not dead then set up variable in
		%	if is at surface and turn to wait not at zero then
		%		decrease turn to wait
		%	else
		%		if is at surface then
		%			send dive
		%		end
		%		ask direction
		%		if direction is surface then
		%			setup wait to turn and surface state
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
		{TMPMovePlayers PlayersPorts}
		%End of tests
	end
	
	proc {TMPMovePlayers PlayersPorts}
		ID Position Direction
	in
		case PlayersPorts
		of Player|Remainder then
			{Send Player dive}
			{Send Player move(ID Position Direction)}
			if Direction == surface then
				{Send PortWindow surface(ID)}
			end
			{Send PortWindow movePlayer(ID Position)}
			{TMPMovePlayers Remainder}
		[] nil then skip %end
		end
	end

	% @NumberAlive : return the number of players alive
	fun {NumberAlive PlayersAlive Acc}
		case PlayersAlive
		of H|T then
			if H then
				{NumberAlive T Acc+1}
			else
				{NumberAlive T Acc}
			end
		[] nil then
			Acc
		end
	end

	% @TurnByTurn : run the game in turn by turn mode
	proc {TurnByTurn NTurn PlayersAtSurface PlayersAtSurfaceWaitingTurn PlayersAlive}
		%display information
	   {Browser.browse 'Turn number : '#NTurn#'out of'#NTurnMax}
		%if NTurnMax is reached stop
		if NTurn<NTurnMax then
			NumAlive NewPlayersAtSurface NewPlayersAtSurfaceWaitingTurn NewPlayersAlive in

			NumAlive = {NumberAlive PlayersAlive.1 0}
			if NumAlive==0 then
				{Browser.browse 'Players are all dead'}
			elseif NumAlive==1 then
				{Browser.browse 'One player left, we have a winner!!!'}
			else
			   %Simulate One Turn
			   {OneTurn PlayersPorts PlayersAtSurface.1 PlayersAtSurfaceWaitingTurn.1 PlayersAlive.1 NewPlayersAtSurface NewPlayersAtSurfaceWaitingTurn NewPlayersAlive}

			   %update state
			   PlayersAtSurface.2 = NewPlayersAtSurface|_
			   PlayersAtSurfaceWaitingTurn.2 = NewPlayersAtSurfaceWaitingTurn|_
			   PlayersAlive.2 = NewPlayersAlive|_

			   %delay to see whats happening
			   {Delay 1000}

			   % next turn
		   	{TurnByTurn NTurn+1 PlayersAtSurface.2 PlayersAtSurfaceWaitingTurn.2 PlayersAlive.2}
	   	end
   	end
	end

	% @Simultaneous : run the game in simultaneous mode
	proc {Simultaneous}
	   {Browser.browse 'simultaneous'}
	   %TODO
	end

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%=================== Execution ===========================
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
	PlayersAlive = {CreatePlayersAlive Input.nbPlayer}|_

	%============== Run the game ==================
	if Input.isTurnByTurn then
		%--------- Turn by turn game ----------------
		{TurnByTurn 0 PlayersAtSurface PlayersAtSurfaceWaitingTurn PlayersAlive}
	else
		%--------- Simultaneous game ----------------
		{Simultaneous}
	end
end
