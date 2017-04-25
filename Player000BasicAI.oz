%% Player000BasicAI.oz %%
%% An basic AI that tries to find other players and shoot them
%% and doesn't shoot itself

functor
import
	OS %for random number generation
	Browser %for displaying debug information
	
	Input
export
	portPlayer:StartPlayer
define
	proc {ERR Msg}
		{Browser.browse 'There was a problem in Player000BasicAI'#Msg}
	end
	proc {Browse Msg}
		{Browser.browse Msg}
	end
	
	StartPlayer
	TreatStream
	Behavior
	
	InitPosition
	Move
	NoSquareAvailable
	RandomStep
	SquareNotVisited
	
	LoadWeapon
	
	ChooseWhichToFire
	FireWeapon
	UpdateWeaponsState
	PlaceMine
	FireMissile
	FireDrone
	FireSonar
	
	ExplodeMine
	
	PositionIsValid
	
	DefaultWeaponsState = stateWeapons(minesLoading:0 minesPlaced:nil missilesLoading:0 dronesLoading:0 sonarsLoading:0)
	DefaultTrackingState = wip
in
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% This port object uses a state record of this type :
	% @stateBasicAI(life:Life locationState:LocationState weaponsState:WeaponsState tracking:TrackingInfo)
	%		@LocationState is a record of type @stateLocation (defined hereafter)
	%		@WeaponsState is a record of type @stateWeapons (defined hereafter)
	%		@TrackingInfo is a record of type @stateTracking (defined hereafter)
	%
	% @stateLocation(pos:Position dir:Direction visited:VisitedSquares)
	% @stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading sonarsLoading:SonarsLoading)
	%		@XLoading is the loading of the weapon of type X
	%						it can also be used to know 
	%						how much of this weapon is currently available (using mod)
	%		@MinesPlaced is a list of all the mines this player has placed
	%							and that haven't exploded yet (with ther position)
	% @stateTracking (WORK IN PROGRESS)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	%============ Make the port object ===================
	% @StartPlayer : Initializes the player (ID, position, weapons, tracking of others, etc.)
	%                and creates the port object
	fun {StartPlayer Color Num}
		Stream
		Port
		ID = id(id:Num color:Color name:'basicAI'#{OS.rand})
	in
		{NewPort Stream Port}
		thread
			{TreatStream Stream ID stateBasicAI(life:Input.maxDamage locationState:stateLocation(pos:{InitPosition} dir:surface visited:nil) weaponsState:DefaultWeaponsState tracking:DefaultTrackingState)}
		end
		Port
	end
	
	% @TreatStream : Loop that checks if some new messages are sent to the port
	%                and treats them
	%                The parameters of this procedure keep track of the state of this port object
	%                @ID (contains an ID number, a color and a name) should never be changed
	%                @State contains every attribute of the current port object that could change
	%                       (thus here : position, direction, life, etc)
	proc {TreatStream Stream ID State}
		case Stream
		of Msg|S2 then
			{TreatStream S2 ID {Behavior Msg ID State}}
		else skip %something went wrong
		end
	end
	
	%=============== Manage the messages ====================================
	% @Behavior : Behavior for every type of message sent on the port
	%             Returns the new state
	fun {Behavior Msg PlayerID State}
		ReturnedState
	in
		case State
		of stateBasicAI(life:PlayerLife locationState:LocationState weaponsState:WeaponsState tracking:TrackingInfo) then
			case Msg
			%------------ Initialize position ---------------
			of initPosition(?ID ?Position) then
				if PlayerLife =< 0 then
					ID = null
				else
					case LocationState
					of stateLocation(pos:PlayerPosition dir:_ visited:_) then
						ID = PlayerID
						Position = PlayerPosition
					else %something went wrong
						{ERR 'LocationState has an invalid format'#LocationState}
					end
				end
				ReturnedState = State
			%------- Move player -----------------------
			[] move(?ID ?Position ?Direction) then
				if PlayerLife =< 0 then
					ID = null
					ReturnedState = State
				else
					case {Move LocationState TrackingInfo}
					of stateLocation(pos:NewPosition dir:NewDirection visited:NewVisitedSquares) then
						ID = PlayerID
						Position = NewPosition
						Direction = NewDirection
						
						ReturnedState = stateBasicAI(life:PlayerLife locationState:stateLocation(pos:NewPosition dir:NewDirection visited:NewVisitedSquares) weaponsState:WeaponsState tracking:TrackingInfo)
					else %something went wrong
						{ERR 'Move returned something with an invalid format'}
						%return the same state as before
						ReturnedState = State
					end
				end
			%-------- Permission to dive ----------------------
			[] dive then
				if PlayerLife =< 0 then
					ReturnedState = State
				else
					case LocationState
					of stateLocation(pos:PlayerPosition dir:PlayerDirection visited:VisitedSquares) then
						if PlayerDirection =< surface then
							% Ignore
							ReturnedState = State
						else
							ReturnedState = stateBasicAI(life:PlayerLife locationState:stateLocation(pos:PlayerPosition dir:north visited:nil) wepaonsState:WeaponsState tracking:TrackingInfo)
						end
					else %something went wrong
						{ERR 'LocationState has an invalid format'#LocationState}
						ReturnedState = State
					end
				end
			%------- Increase the loading of an item ---------------
			[] chargeItem(?ID ?KindItem) then
				if PlayerLife =< 0 then
					ID = null
					ReturnedState = State
				else
					NewWeaponsState
				in
					ID = PlayerID
					%Load one of the weapons's loading charge
					KindItem#NewWeaponsState = {LoadWeapon WeaponsState}
					
					ReturnedState = stateBasicAI(life:PlayerLife locationState:LocationState weaponsState:NewWeaponsState tracking:TrackingInfo)
				end
			%------- Fire a weapon -------------------
			%TODO for the moment it's random
			[] fireItem(?ID ?KindFire) then
				if PlayerLife =< 0 then
					ID = null
					ReturnedState = State
				else
					FiredWeaponType = {ChooseWhichToFire WeaponsState TrackingInfo}
					NewWeaponsState
				in
					ID = PlayerID
					if FiredWeaponType \= null then
						% Fire a weapon of type @FiredWeaponType
						case LocationState
						of stateLocation(pos:PlayerPosition dir:_ visited:_) then
							KindFire#NewWeaponsState = {FireWeapon FiredWeaponType State}
						else %something went wrong
							{ERR 'LocationState has an invalid format'#LocationState}
						end
					end
				end
			%------- Choose to explode a placed mine ---------------
			[] fireMine(?ID ?Mine) then
				if PlayerLife =< 0 then
					ID = null
					ReturnedState = State
				else
					ID = PlayerID
					case {ExplodeMine WeaponsState TrackingInfo}
					of MineExploding#NewWeaponsState then
						Mine = MineExploding
						ReturnedState = stateRandomAI(life:PlayerLife locationState:LocationState weaponsState:NewWeaponsState tracking::TrackingInfo)
					else %something went wrong
						{ERR 'ExplodeMine did not return a record correctly formatted'}
						ReturnedState = State
					end
				end
			%------- Is this player at the surface? ---------------
			[] isSurface(?ID ?Answer) then
				if PlayerLife =< 0 then
					ID = null
					ReturnedState = State
				else
					ID = PlayerID
					case LocationState
					of stateLocation(pos:_ dir:Direction visited:_) then
						if Direction == surface then Answer = true
						else Answer = false
						end
					else  %something went wrong
						{ERR 'LocationState has an invalid format'#LocationState}
					end
					ReturnedState = State
				end
			%------- DEBUG : print yourself ------------------------
			[] print then
				{Browse PlayerID#State}
				ReturnedState = State
			else %Unknown message => don't do anything
				ReturnedState = State
			end
		else %something went wrong
			{ERR 'State has an invalid format'#State}
			% reset the state
			ReturnedState = stateBasicAI(life:Input.maxDamage locationState:stateLocation(pos:{InitPosition} dir:surface visited:nil) weaponsState:DefaultWeaponsState tracking:DefaultTrackingState)
		end
		%return
		ReturnedState
	end
	
	%============ Procedures to generate the initial position ===============
	% @InitPosition : generates the initial position of this player
	%                 here, it is random (but not on an island)
	fun {InitPosition}
		CurrentPosition = pt(x:({OS.rand} mod Input.nRow)+1 y:({OS.rand} mod Input.nColumn)+1)
	in
		if {PositionIsValid CurrentPosition} then CurrentPosition
		else {InitPosition}
		end
	end
	
	%=========== Procedures related to movement ========================
	% @Move : knowing that @this is at position @LocationState 
	%         and the tracking info @TrackingInfo of other players,
	%         decides where the player should move next
	%         Returns the new position
	fun {Move LocationState TrackingInfo}
		case LocationState
		of stateLocation(pos:Position dir:Direction visited:VisitedSquares) then
			%---------- Player is at the surface => cannot move ------------
			if Direction == surface then
				% You will dive when you get the message @dive
				%return
				LocationState
			%---------- Player is underwater => move to another position ---------
			else %Direction \= surface
				%Check if there is at least one square around that is available
				if {NoSquareAvailable Position VisitedSquares} then %go to the surface
					%return
					stateLocation(pos:Position dir:surface visited:nil)
				%Never go to the surface if another square is available
				else
					%TODO for the moment this is random
					NewPosition
					Movement = {RandomStep} % can be either 1 or -1 (following an axis) => not 0 since we already visited here
					DirectionTravelled %the direction towards which this player went
				in
					%Choose which axis to follow
					if {OS.rand} mod 2 == 0 then % X-axis (vertically)
						NewPosition = pt(x:Position.x+Movement y:Position.y)
						if Movement == 1 then DirectionTravelled = south
						else DirectionTravelled = north
						end
					else % Y-axis (horizontally)
						NewPosition = pt(x:Position.x y:Position.y+Movement)
						if Movement == 1 then DirectionTravelled = east
						else DirectionTravelled = west
						end
					end
					if {PositionIsValid NewPosition} andthen {SquareNotVisited NewPosition VisitedSquares} then
						%return
						stateLocation(pos:NewPosition dir:DirectionTravelled visited:NewPosition|VisitedSquares)
					else {Move LocationState TrackingInfo} %Choose another new position
					end
				end
			end
		else null
		end
	end
	
	% @NoSquareAvailable : Checks if there is at least one square around @PlayerPosition
	%                      that is available
	%                      Returns @true if no square is available, @false otherwise
	fun {NoSquareAvailable PlayerPosition VisitedSquares}
		PosNorth = pt(x:PlayerPosition.x-1 y:PlayerPosition.y)
		PosSouth = pt(x:PlayerPosition.x+1 y:PlayerPosition.y)
		PosEast = pt(x:PlayerPosition.x y:PlayerPosition.y+1)
		PosWest = pt(x:PlayerPosition.x y:PlayerPosition.y-1)
	in
		if {PositionIsValid PosNorth} andthen {SquareNotVisited PosNorth VisitedSquares} then
			false
		elseif {PositionIsValid PosSouth} andthen {SquareNotVisited PosSouth VisitedSquares} then
			false
		elseif {PositionIsValid PosEast} andthen {SquareNotVisited PosEast VisitedSquares} then
			false
		elseif {PositionIsValid PosWest} andthen {SquareNotVisited PosWest VisitedSquares} then
			false
		else
			true			
		end
	end
	
	%@RandomStep : returns either 1 or -1 (one-in-two chance)
	fun {RandomStep}
		if ({OS.rand} mod 2) == 0 then 1
		else ~1
		end
	end
	
	% @SquareNotVisited : returns true if the squares hasn't been visited in this diving phase
	fun {SquareNotVisited Position VisitedSquares}
		case VisitedSquares
		of nil then true
		[] Square|Remainder then
			if Position == Square then false
			else {SquareNotVisited Position Remainder}
			end
		else %something went wrong
			{ERR 'VisitedSquares has an invalid format'#VisitedSquares}
			true %Prevents looping forever
		end
	end
	
	%============== Procedures regarding weapons ===================
	% @LoadWeapon : Add a loading charge to one type of weapon
	%               Returns the new weapons state and a weapon type if a new weapon is available
	fun {LoadWeapon WeaponsState}
		case WeaponsState
		of stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading sonarsLoading:SonarsLoading) then
			%TODO for the moment random
			NewWeaponsState
			NewWeaponAvailable
		in
			case {OS.rand} mod 4
			of 0 then
				NewWeaponsState = stateWeapons(minesLoading:MinesLoading+1 minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading sonarsLoading:SonarsLoading)
				if (MinesLoading+1) mod Input.mine == 0 then
					NewWeaponAvailable = mine
				else
					NewWeaponAvailable = null
				end
			[] 1 then
				NewWeaponsState = stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading+1 dronesLoading:DronesLoading sonarsLoading:SonarsLoading)
				if (MissilesLoading+1) mod Input.missile == 0 then
					NewWeaponAvailable = missile
				else
					NewWeaponAvailable = null
				end
			[] 2 then
				NewWeaponsState = stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading+1 sonarsLoading:SonarsLoading)
				if (DronesLoading+1) mod Input.drone then
					NewWeaponAvailable = drone
				else
					NewWeaponAvailable = null
				end
			[] 3 then
				NewWeaponsState = stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading sonarsLoading:SonarsLoading+1)
				if (SonarsLoading+1) mod Input.sonar then
					NewWeaponAvailable = sonar
				else
					NewWeaponAvailable = null
				end
			else %something went wrong
				{ERR 'Randomized out-of-bound'}
				NewWeaponAvailable = null %because we have to return something
				NewWeaponsState = WeaponsState %idem
			end
			
			%return
			NewWeaponAvailable#NewWeaponsState
		else %something went wrong
			{ERR 'WeaponsState has an invalid format'#WeaponsState}
			null#WeaponsState %because we have to return something
		end
	end
	
	% @ChooseWhichToFire : If a weapon is available and @this wants to shoot
	%                      somewhere, decides which weapon to use and
	%                      returns it
	% TODO for the moment this is random
	fun {ChooseWhichToFire WeaponsState TrackingInfo}
		case WeaponsState
		of stateWeapons(minesLoading:MinesLoading minesPlaced_ missilesLoading:MissilesLoading dronesLoading:DronesLoading sonarsLoading:SonarsLoading) then
			% Choose a type of weapon to try and fire
			case {OS.rand} mod 4
			% If this type od weapon is available, fire it with a one-in-two chance
			of 0 then if MinesLoading div Input.mine > 0 then mine else null end
			[] 1 then if MissilesLoading div Input.mine > 0 then missile else null end
			[] 2 then if DronesLoading div Input.drone > 0 then drone else null end
			[] 3 then if SonarsLoading div Input.sonar > 0 then sonar else null end
			else null
			end
		else %something went wrong
			{ERR 'WeaponsState has an invlaid format'#WeaponsState}
			null %because we have to return something
		end
	end
	
	% @FireWeapon : Fires a weapon of type @WeaponType
	%               Returns the weapon fired (with parameters) and
	%               the new weapons's state
	fun {FireWeapon WeaponType PlayerState}
		case PlayerState
		of stateBacisAI(life:_ locationState:stateLocation(pos:PlayerPosition dir:_ visited:_) weaponsState:WeaponsState tracking:TrackingInfo) then
			case WeaponType
			of mine then
				NewMine = {PlaceMine PlayerPosition TrackingInfo}
			in
				NewMine#{UpdateWeaponsState WeaponsState NewMine}
			[] missile then
				{FireMissile PlayerPosition TrackingInfo}#{UpdateWeaponsState WeaponsState WeaponType}
			[] drone then
				{FireDrone TrackingInfo}#{UpdateWeaponsState WeaponsState WeaponType}
			[] sonar then
				{FireSonar TrackingInfo}#{UpdateWeaponsState WeaponsState WeaponType}
			else null#WeaponsState
			end
		else %something went wrong
			{ERR 'PlayerState has an invalid format'#PlayerState}
			null %because we have to return something
		end
	end
	
	% @UpdateWeaponsState : Returns the updated weapons's state after firing
	%                       a weapon of type @WeaponFired
	%                       (for a mine it is the mine fired)
	fun {UpdateWeaponsState WeaponsState WeaponFired}
		case WeaponsState
		of stateWeapons(miensLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading sonarsLoading:SonarsLoading) then
			case WeaponFired
			of mine(_) then stateWeapons(minesLoading:MinesLoading-Input.mine minesPlaced:WeaponFired|MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading sonarsLoading:SonarsLoading)
			[] missile then stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading-Input.missile dronesLoading:DronesLoading sonarsLoading:SonarsLoading)
			[] drone then stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading-Input.drone sonarsLoading:SonarsLoading)
			[] sonar then stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading sonarsLoading:SonarsLoading-Input.sonar)
			else WeaponsState
			end
		else %something went wrong
			{ERR 'WeaponsState has an invalid format'#WeaponsState}
			WeaponsState %because we have to return something
		end
	end
	
	% @PlaceMine : Creates a mine at a random position on the grid
	%              but in the range from the player where it is allowed to place mines
	%              and if it know where another player is
	%              Returns the created mine (with the position of setup as a parameter)
	% TODO for the moment this is random
	fun {PlaceMine PlayerPosition TrackingInfo}
		RandomPosition = pt(x:({OS.rand} mod Input.nRow)+1 y:({OS.rand} mod Input.nColumn)+1)
		DistanceFromPlayer = {Abs (PlayerPosition.x-RandomPosition.x)}+{Abs (PlayerPosition.y-RandomPosition.y)}
	in
		% Check the distances
		if DistanceFromPlayer >= Input.minDistanceMins andthen DistanceFromPlayer =< Input.maxDistanceMine then mine(RandomPosition)
		else {PlaceMine PlayerPosition TrackingInfo}
		end
	end
	
	% @ExplodeMine : Checks if there is a mine in the list of mines placed (contained in @WeaponsState)
	%                Chooses if one of those mine should explode and which one.
	%                Returns the mine exploding and the new weapons' state (with the new list of mines remaining)
	% TODO for the moment this is random
	fun {ExplodeMine WeaponsState TrackingInfo}
		fun {Loop MinesPlaced MinesAccumulator}
			case MinesPlaced
			of Mine|Remainder then
				%Choose to explode this mine (one-in-two chances)
				if {OS.rand} mod 2 then Mine#{Append MinesAccumulator Remainder}
				else {Loop Remainder {Append MinesAccumulator Mine}}
				end
			[] nil then %No mine has exploded
				null#MinesAccumulator
			else %something went wrong
				{ERR 'MinesPlaced has an invalid format'#MinesPlaced}
				null#MinesPlaced %because we have to return something
			end
		end
	in
		case WeaponsState
		of stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading sonarsLoading:SonarsLoading) then
			case {Loop MinesPlaced nil}
			of Mine#RemainingMines then
				Mine#stateWeapons(minesLoading:MinesLoading minesPlaced:RemainingMines missilesLoading:MissilesLoading dronesLoading:DronesLoading sonarsLoading:SonarsLoading)
			end
		else %something went wrong
			{ERR 'WeaponsState has an invalid format'#WeaponsState}
			null#WeaponsState %because we have to return something
		end
	end
	
	%============== Useful procedures and functions ================
	% @PositionIsValid : checks if @Position is not on an island
	%                    returns @true if it is valid and @false otherwise
	%                    !!! pt(x:1 y:1) is the first cell in the grid (not 0;0) !!!
	%                           => be careful when randomizing positions
	fun {PositionIsValid Position}
		case Position
		of pt(x:X y:Y) then
			if X =< 0 orelse X > Input.nRow orelse Y >= 0 orelse Y > Input.nColumn then false
			elseif {Nth {Nth Input.map X} Y} then true
			else false
			end
		else false
		end
	end
end
