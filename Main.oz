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
	NTurnMax = 100 %Maximal number of turn for the game (set high for normal game)
	PlayersAlive % List of lists does the players are alive
	LifeStatePort % port-object to store life state of players unused

	%========== Functions and procedures =====================
	CreatePortObject%unused
	CreatePlayers
	GenerateColor %unused
	LifeTreatStream
	SetUpAndShow
	CreatePlayersAtSurface
	CreatePlayersAtSurfaceWaitingTurn
	CreatePlayersAlive
	CreateLifeSte
	NumberAlive
	BroadcastDirection
	BroadcastItemCharged
	BroadcastKilled
	Kill
	BroadcastDamageTaken
	MissileExplode
	SonarActivated
	DroneActivated
	MinePlaced
	MineExploded
	IsAlive
	OneTurn
	TurnByTurn
	CheckEnd
	OnePlayerSimultaneous
	Simultaneous

	%=========== TMP ====================
	TMPTestPlayers

	%=========== DEBUG ====================
	proc {DEBUG}
		{Browser.browse 'debug'}
	end
	proc {Browse Msg}
		{Browser.browse Msg}
	end
in

	%======== Functions and procedures definitions ============
	% @CreatePortObject : F treat the stream
	fun {CreatePortObject F InitialState}
		P
		S
		proc {LoopStream S State}
			case S
			of Msg|S2 then
				{LoopStream S2 {F State Msg}}
			end
		end
	in
		{NewPort S P}
		thread {LoopStream S InitialState} end
		P
	end

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
	      {Browse 'initialize pos'#ID#Position}
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

	% @BroadcastItemCharged : send to all players that KindItem has been charged by player ID
	proc {BroadcastItemCharged ID KindItem}
		for P in PlayersPorts do
			if KindItem==mine then
				{Send P sayMinePlaced(ID)}
			else
				{Send P sayCharge(ID KindItem)}
			end
		end
	end

	% @BroadcastKilled : announce the death of all the players in killed
	proc {BroadcastKilled Killed}
		case Killed
		of ID|T then
			for P in PlayersPorts do
				{Send P sayDeath(ID)}
			end
			{Send PortWindow lifeUpdate(ID 0)}
			{Send PortWindow removePlayer(ID)}
			{BroadcastKilled T}
		[] nil then
			skip
		end
	end

	% @Kill : change the AliveState to kill people with their ID in Killed
	fun {Kill PlayersAlive Killed}
		case PlayersAlive
		of P|PlayersAlive2 then
			case Killed
			of K|Killed2 then
				if P==K then
					false|{Kill PlayersAlive2 Killed2}
				else
					P|{Kill PlayersAlive2 Killed}
				end
			[] nil then
				nil
			end
		[] nil then
			nil
		end
	end

	% @BroadcastDamageTaken : broadcast the damage taken information
	proc {BroadcastDamageTaken ID Damage LifeLeft}
		for P in PlayersPorts do
			{Send P sayDamageTaken(ID Damage LifeLeft)}
		end
		{Send PortWindow lifeUpdate(ID LifeLeft)}
	end

	% @MissileExplode : A missile has exploded broadcast the information broadcast the damage taken, return the Killed
	fun {MissileExplode ID Pos}
		fun {PlayerByPlayer PlayersPorts}
			case PlayersPorts
			of P|T then Message in
				{Send P sayMissileExplode(ID Pos Message)}
				case Message
				of sayDeath(IDDeath) then
					IDDeath|{PlayerByPlayer T}
				[] sayDamageTaken(IDDmg Damage LifeLeft) then
					{BroadcastDamageTaken IDDmg Damage LifeLeft}
					{PlayerByPlayer T}
				[] null then
					{PlayerByPlayer T}
				end
			[] nil then
				nil
			end
		end
	in
		{PlayerByPlayer PlayersPorts}
	end

	% @SonarActivated : A sonar has been Activated broadcast it and return information to PID, return nil
	fun {SonarActivated ID PID}
		for P in PlayersPorts do
			local IDRcv Answer in
				{Send P sayPassingSonar(IDRcv Answer)}
				{Send PID sayAnswerSonar(IDRcv Answer)}
			end
		end
		nil
	end

	% @DroneActivated : A Drone has been Activated broadcast it and return information to PID, return nil
	fun {DroneActivated ID PID Drone}
		for P in PlayersPorts do
			local IDRcv Answer in
				{Send P sayPassingDrone(Drone IDRcv Answer)}
				{Send PID sayAnswerDrone(Drone IDRcv Answer)}
			end
		end
		nil
	end

	% @MinePlaced : A Mine has been placed broadcast information, return nil
	fun {MinePlaced ID}
		for P in PlayersPorts do
			{Send P sayMinePlaced(ID)}
		end
		nil
	end

	% @MineExploded : A Mine has been exploded broacast it and broadcast the damage taken, return the Killed
	fun {MineExploded ID Pos}
		fun {PlayerByPlayer PlayersPorts}
			case PlayersPorts
			of P|T then Message in
				{Send P sayMineExplode(ID Pos Message)}
				case Message
				of sayDeath(IDDeath) then
					IDDeath|{PlayerByPlayer T}
				[] sayDamageTaken(IDDmg Damage LifeLeft) then
					{BroadcastDamageTaken IDDmg Damage LifeLeft}
					{PlayerByPlayer T}
				[] null then
					{PlayerByPlayer T}
				end
			[] nil then
				nil
			end
		end
	in
		{PlayerByPlayer PlayersPorts}
	end

	% @IsAlive : Check if the player that listen to the port is dead
	fun {IsAlive PlayerPort}
		Id
		Dummy
	in
		{Send PlayerPort initPosition(Id Dummy)}
		case Id
		of null then
			false
		else
			true
		end
	end

	% @OneTurn : make one turn in TurnByTurn mode
	%			PlayersPorts ports of the players
	%			PlayersAtSurface & PlayersAtSurfaceWaitingTurn players surface state
	%			NewPlayersAtSurface & NewPlayersAtSurface update the lists
	% TODO set GUI update
	proc {OneTurn PlayersPorts PlayersAtSurface PlayersAtSurfaceWaitingTurn NewPlayersAtSurface NewPlayersAtSurfaceWaitingTurn}

		%{Browser.browse {Length PlayersPorts}}
		%Temporary : needed to turn more than once
		%NewPlayersAlive = {CreatePlayersAlive Input.nbPlayer}

		case PlayersPorts|PlayersAtSurface|PlayersAtSurfaceWaitingTurn
		of (PlayerPort|PlayersPorts2)|(PlayerAtSurface|PlayersAtSurface2)|(PlayerAtSurfaceWaitingTurn|PlayersAtSurfaceWaitingTurn2) then NewPlayersAtSurface2 NewPlayersAtSurfaceWaitingTurn2 in

			if {IsAlive PlayerPort} then
				%our player is alive
				if (PlayerAtSurface andthen (PlayerAtSurfaceWaitingTurn>0)) then
					%player has still to wait before he can dive again
					NewPlayersAtSurface = true|NewPlayersAtSurface2
					NewPlayersAtSurfaceWaitingTurn = (PlayerAtSurfaceWaitingTurn-1)|NewPlayersAtSurfaceWaitingTurn2
				else ID Position Direction in
					%can move again
					if PlayerAtSurface then
						{Send PlayerPort dive}
					end

					%direction?
					{Send PlayerPort move(ID Position Direction)}
					{BroadcastDirection ID Direction}

					case Direction
					of surface then
						NewPlayersAtSurface = true|PlayersAtSurface2
						NewPlayersAtSurfaceWaitingTurn = (Input.turnSurface-1)|PlayersAtSurfaceWaitingTurn2
						{Send PortWindow surface(ID)}
					else KindItem KindFire Mine in
						NewPlayersAtSurface = false|PlayersAtSurface2
						NewPlayersAtSurfaceWaitingTurn = 0|PlayersAtSurfaceWaitingTurn2

						{Send PortWindow movePlayer(ID Position)}

						{Send PlayerPort chargeItem(ID KindItem)}
						case KindItem
						of null then
							skip
						else
							{BroadcastItemCharged ID KindItem}
						end

						{Send PlayerPort fireItem(ID KindFire)}

						case KindFire
						of null then
							skip
						else Killed in
							%broadcast and receive informations, change alive list
							case KindFire
							of missile(Pos) then
								Killed = {MissileExplode ID Pos}
							[] sonar then
								Killed = {SonarActivated ID PlayerPort}
							[] drone(row:X) then
								Killed = {DroneActivated ID PlayerPort KindFire}
							[] drone(column:Y) then
								Killed = {DroneActivated ID PlayerPort KindFire}
							[] mine(pt(x:X y:Y)) then
								{Send PortWindow putMine(ID pt(x:X y:Y))}
								Killed = {MinePlaced ID}
							end
							{BroadcastKilled Killed}
						end

						if {IsAlive PlayerPort} then
							{Send PlayerPort fireMine(ID Mine)}
							case Mine
							of null then
								skip
							else Killed in
								%broadcast and receive informations, change alive list
								Killed = {MineExploded ID Mine.1}
								{BroadcastKilled Killed}
								{Send PortWindow removeMine(ID Mine.1)}
							end
						end
					end
				end
			else
				%our player is dead
				NewPlayersAtSurface = false|NewPlayersAtSurface2
				NewPlayersAtSurfaceWaitingTurn = 0|NewPlayersAtSurfaceWaitingTurn2
			end
			%next player
			%{Browser.browse 'fin'}
			{OneTurn PlayersPorts2 PlayersAtSurface2 PlayersAtSurfaceWaitingTurn2 NewPlayersAtSurface2 NewPlayersAtSurfaceWaitingTurn2}
		[] nil|nil|nil then
			NewPlayersAtSurface = nil
			NewPlayersAtSurfaceWaitingTurn = nil
		end

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
		%{Browser.browse 'OneTurn will be implemented in a short future'}

		%Tests of the messages
		%{TMPTestPlayers PlayersPorts}
		%End of tests
	end

	proc {TMPTestPlayers PlayersPorts}
		case PlayersPorts
		of Player|Remainder then
			{Send Player dive}
			local
				ID Position Direction
			in
				{Send Player dive}
				{Send Player move(ID Position Direction)}
				if Direction == surface then
					{Send PortWindow surface(ID)}
				end
				{Send PortWindow movePlayer(ID Position)}
			end
			local
				ID NewWeapon
			in
				{Send Player chargeItem(ID NewWeapon)}
				%{Send Player print}
			end

			{TMPTestPlayers Remainder}
		[] nil then skip %end
		end
	end

	% @NumberAlive : return the number of players alive
	fun {NumberAlive PlayersPorts Acc}
		case PlayersPorts
		of H|T then
			if {IsAlive H} then
				{NumberAlive T Acc+1}
			else
				{NumberAlive T Acc}
			end
		[] nil then
			Acc
		end
	end

	% @TurnByTurn : run the game in turn by turn mode
	proc {TurnByTurn NTurn PlayersAtSurface PlayersAtSurfaceWaitingTurn}
		%display information
	   {Browser.browse 'Turn number : '#NTurn#'out of'#NTurnMax}
		%if NTurnMax is reached stop
		if NTurn<NTurnMax then
			NumAlive NewPlayersAtSurface NewPlayersAtSurfaceWaitingTurn in

			NumAlive = {NumberAlive PlayersPorts 0}
			if NumAlive==0 then
				{Browser.browse 'Players are all dead'}
			elseif NumAlive==1 then
				{Browser.browse 'One player left, we have a winner!!!'}
			else
			   %Simulate One Turn
			   {OneTurn PlayersPorts PlayersAtSurface.1 PlayersAtSurfaceWaitingTurn.1 NewPlayersAtSurface NewPlayersAtSurfaceWaitingTurn}

			   %update state
			   PlayersAtSurface.2 = NewPlayersAtSurface|_
			   PlayersAtSurfaceWaitingTurn.2 = NewPlayersAtSurfaceWaitingTurn|_

			   %delay to see whats happening
			   {Delay 1}

			   % next turn
		   		{TurnByTurn NTurn+1 PlayersAtSurface.2 PlayersAtSurfaceWaitingTurn.2}
	   		end
   		end
	end

	% @OnePlayerSimultaneous : Handle the play of the player listening to P (launch it inside a thread for each player)
	proc {OnePlayerSimultaneous P}
		ID1
		ID2
		ID3
	in
		if {IsAlive P} andthen {NumberAlive PlayersPorts 0}>1 then ID Position Direction in
			%our player is alive
			{Delay ({OS.rand} mod (Input.thinkMax-Input.thinkMin))+Input.thinkMin}

			%direction?
			{Send P move(ID Position Direction)}  {Browse 'move'#ID#Position#Direction}
			case ID of null then
				skip
			else

				{BroadcastDirection ID Direction}

				case Direction
				of surface then
					{Send PortWindow surface(ID)}
					{Delay Input.turnSurface}
					{Send P dive} {Browse 'dive'}
					{OnePlayerSimultaneous P}
				else KindItem KindFire Mine in

					{Send PortWindow movePlayer(ID Position)}

					{Delay ({OS.rand} mod (Input.thinkMax-Input.thinkMin))+Input.thinkMin}

					{Send P chargeItem(ID1 KindItem)} {Browse 'chargeitem'}
					case ID1 of null then
						skip
					else
						case KindItem
						of null then
							skip
						else
							{BroadcastItemCharged ID KindItem} {Browse 'itemcharged'}
						end

						{Delay ({OS.rand} mod (Input.thinkMax-Input.thinkMin))+Input.thinkMin}

						{Send P fireItem(ID2 KindFire)} {Browse 'fireitem'#ID2#KindFire}
						case ID2 of null then
							skip
						else

							case KindFire
							of null then
								skip
							else Killed in
								%broadcast and receive informations, change alive list
								case KindFire
								of missile(Pos) then
									Killed = {MissileExplode ID Pos}
								[] sonar then
									Killed = {SonarActivated ID P}
								[] drone(column:X) then
									Killed = {DroneActivated ID P KindFire}
								[] drone(row:Y) then
									Killed = {DroneActivated ID P KindFire}
								[] mine(pt(x:X y:Y)) then
									Killed = {MinePlaced ID}
									{Send PortWindow putMine(ID pt(x:X y:Y))}
								end
								{BroadcastKilled Killed} {Browse 'killed'}
							end

							if {IsAlive P} then
								{Delay ({OS.rand} mod (Input.thinkMax-Input.thinkMin))+Input.thinkMin}

								{Send P fireMine(ID3 Mine)} {Browse 'firemine'#ID3#Mine}
								case ID3 of null then
									skip
								else
									case Mine
									of null then
										skip
									else Killed in
										%broadcast and receive informations, change alive list
										Killed = {MineExploded ID Mine.1}
										{BroadcastKilled Killed} {Browse 'killed'}
										{Send PortWindow removeMine(ID Mine.1)}
									end
								end
								
								{Browse 'end of oneplayersimultaneous'}
								{OnePlayerSimultaneous P}
							end
						end
					end
				end
			end
		end
	end

	% @CheckEnd : Bind the variable in argument when the game is finished
	proc {CheckEnd GameFinished}
		if {NumberAlive PlayersPorts 0}>1 then
			{Delay 1000}
			{CheckEnd GameFinished}
		else
			GameFinished = true
		end
	end

	% @Simultaneous : run the game in simultaneous mode
	proc {Simultaneous}
		GameFinished
	in
	   {Browser.browse 'Simultaneous'}

	   %Launch one thread by player that simulate the actions of each one
	   for P in PlayersPorts do
	   	thread
				{Send P dive} {Browse 'dive'}
				{OnePlayerSimultaneous P}
			end
		end

		{CheckEnd GameFinished}

		if GameFinished then
			{Browser.browse 'The game is finished'}
		end

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
		{TurnByTurn 0 PlayersAtSurface PlayersAtSurfaceWaitingTurn}
	else
		%--------- Simultaneous game ----------------
		{Simultaneous}
	end
end
