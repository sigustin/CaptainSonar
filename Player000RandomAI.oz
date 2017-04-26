%% Player000RandomAI.oz %%
%% An AI that behaves in a random manner
%% It doesn't care about what other players do and thus ignores the informative messages it gets

functor
import
	OS %for random number generation
	Browser %for displaying debug information
	
	Input
export
	portPlayer:StartPlayer
define
	proc {ERR Msg}
		{Browser.browse 'There was a problem in Player000RandomAI'#Msg}
	end
	proc {Browse Msg}
		{Browser.browse 'Player000RandomAI'#Msg}
	end

	StartPlayer
	TreatStream
	Behavior
	
	InitPosition
	Move
	RandomStep
	SquareNotVisited
	ChooseRandomDirection
	NoSquareAvailable
	
	LoadRandomWeapon
	NewWeaponAvailable
	SimplifyWeaponsState
	
	ChooseWhichToFire
	FireWeapon
	PlaceMine
	FireMissile
	FireDrone
	FireSonar
	UpdateWeaponsState
	
	ExplodeMine
	
	ExplosionHappened
	ComputeDamage
	
	FakeCoordForSonars
	
	PositionIsValid
	
	DefaultWeaponsState = stateWeapons(nbMines:0 minesLoading:0 minesPlaced:nil nbMissiles:0 missilesLoading:0 nbDrones:0 dronesLoading:0 nbSonars:0 sonarsLoading:0)
in
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% This port object has an @ID containing the ID number, the color and the name of the object
	% This port object uses the states
	% @stateRandomAI(life:Life locationState:LocationState weaponsState:WeaponsState)
	%     @LocationState is a record of type @stateLocation (defined hereafter)
	%     @WeaponsState is a record of type @stateWeapons (defined hereafter)
	% @stateLocation(pos:Position dir:Direction visited:VisitedSquares)
	%     @VisitedSquares is a list of all the positions visited since the last surface phase
	%                     Those cannot be visited again on the same diving phase
	% @stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
	%    @nbX is the number of X available to the player
	%    @XLoading is the number of loading charges for the weapon X currently loaded by the player
	%              Input.X being the number of loading charges needed to charge one item of this type
	%    @MinesPlaced is a list of all the mines that have been placed by the player
	%              but haven't exploded yet
	%
	% If something goes wrong, it is possible that a variable that should get bound, does not
	%                          making the program wait
	%                          Though, an error message should be displayed
	%                          (using the debug porcedure @ERR)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	%============== Make the port object ========================
	% @StartPlayer : Initializes the player (ID, position, weapons, etc.)
	%                and creates the port object
	fun {StartPlayer Color Num}
		Stream
		Port
		ID = id(id:Num color:Color name:'randomAI'#{OS.rand})
	in		
		{NewPort Stream Port}
		thread
			{TreatStream Stream ID stateRandomAI(life:Input.maxDamage locationState:stateLocation(pos:{InitPosition} dir:surface visited:nil) weaponsState:DefaultWeaponsState)}
		end
		Port
	end
	
	% @TreatStream : Loop that checks if some new messages are sent to the port 
	%                and treats them
	%                The parameters of this procedure keep track of the state of this port object
	%                @ID (contains an ID number, a color and a name) should never be changed
	%                @State contains every attribute of the current port object that could change
	%                       (thus here : position, direction, life of the player, etc.)
	proc {TreatStream Stream ID State}
		case Stream
		of Msg|S2 then
			{TreatStream S2 ID {Behavior Msg ID State}}
		else skip %something went wrong
		end
	end
	
	%=============== Manage the messages ========================
	% @Behavior : Behavior for every type of message sent on the port
	%             Returns the new state
	fun {Behavior Msg PlayerID State}
		ReturnedState
	in
		case State
		of stateRandomAI(life:PlayerLife locationState:LocationState weaponsState:WeaponsState) then
			case Msg
			%---------- Initialize position -------------
			of initPosition(?ID ?Position) then
				if PlayerLife =< 0 then
					ID = null
					ReturnedState = State
				else
					case LocationState
					of stateLocation(pos:PlayerPosition dir:_ visited:_) then
						ID = PlayerID
						Position = PlayerPosition
					else %something went wrong
						{ERR 'LocationState has an invalid format'#LocationState}
					end
					%return
					ReturnedState = State
				end
			%---------- Move player -------------------
			[] move(?ID ?Position ?Direction) then
				if PlayerLife =< 0 then
					ID = null
					ReturnedState = State
				else
					case {Move LocationState}
					of stateLocation(pos:NewPosition dir:NewDirection visited:NewVisitedSquares) then
						ID = PlayerID
						Position = NewPosition
						Direction = NewDirection
						%return
						ReturnedState = stateRandomAI(life:PlayerLife locationState:stateLocation(pos:NewPosition dir:NewDirection visited:NewVisitedSquares) weaponsState:WeaponsState)
					else %something went wrong
						{ERR 'Move returned something with an invalid format'}
						%return the same state as before
						ReturnedState = State
					end
				end
			%---------- Provide the permission to dive -------------
			[] dive then
				if PlayerLife =< 0 then
					ReturnedState = State
				else
					case LocationState
					of stateLocation(pos:PlayerPosition dir:PlayerDirection visited:VisitedSquares) then
						if PlayerDirection \= surface then
							% Ignore
							ReturnedState = State
						else
							ReturnedState = stateRandomAI(life:PlayerLife locationState:stateLocation(pos:PlayerPosition dir:{ChooseRandomDirection} visited:nil) weaponsState:WeaponsState)
						end
					else %something went wrong
						{ERR 'LocationState has an invalid format'#LocationState}
						ReturnedState = State
					end
				end
			%------- Increase the loading charge of an item ------------
			[] chargeItem(?ID ?KindItem) then
				if PlayerLife =< 0 then
					ID = null
					ReturnedState = State
				else
					NewWeaponsState
					SimplifiedWeaponsState
				in
					ID = PlayerID
					% Load one of the weapons's loading charge
					NewWeaponsState = {LoadRandomWeapon WeaponsState}
					% Check if a new weapon can be created
					KindItem#SimplifiedWeaponsState = {NewWeaponAvailable NewWeaponsState}
					%return
					ReturnedState = stateRandomAI(life:PlayerLife locationState:LocationState weaponsState:SimplifiedWeaponsState)
				end
			%------- Fire a weapon -------------
			% If a weapon is available, randomly choose to use one
			[] fireItem(?ID ?KindFire) then
				if PlayerLife =< 0 then
					ID = null
					ReturnedState = State
				else
					FiredWeaponType = {ChooseWhichToFire WeaponsState}
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
						%return
						ReturnedState = stateRandomAI(life:PlayerLife locationState:LocationState weaponsState:NewWeaponsState)
					else
						KindFire = null
						ReturnedState = stateRandomAI(life:PlayerLife locationState:LocationState weaponsState:WeaponsState)
					end
				end
			%-------- Choose to explode a placed mine -----------------
			[] fireMine(?ID ?Mine) then
				if PlayerLife =< 0 then
					ID = null
					ReturnedState = State
				else
					ID = PlayerID
					case {ExplodeMine WeaponsState}
					of MineExploding#NewWeaponsState then
						Mine = MineExploding
						ReturnedState = stateRandomAI(life:PlayerLife locationState:LocationState weaponsState:NewWeaponsState)
					else %something went wrong
						{ERR 'ExplodeMine did not return a record correctly formatted'}
						ReturnedState = State
					end
				end
			%-------- Is this player at the surface? ------------------
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
					else %something went wrong
						{ERR 'LocationState has an invalid format'#LocationState}
					end
					ReturnedState = State
				end
			%----- Flash info : player @ID has moved in the direction @Direction -----------
			[] sayMove(ID Direction) then
				%Ignore
				ReturnedState = State
			%----- Flash info : player @ID has made surface -----------------
			[] saySurface(ID) then
				%Ignore
				ReturnedState = State
			%------ Flash info : player @ID has the item @KindItem ------------
			[] sayCharge(ID KindItem) then
				%Ignore
				ReturnedState = State
			%------ Flash info : player @ID has placed a mine ----------------
			[] sayMinePlaced(ID) then
				%Ignore
				ReturnedState = State
			%------------- A missile exploded (is this player damaged?) -----------------
			[] sayMissileExplode(ID Position ?Message) then
				if PlayerLife =< 0 then
					Message = sayDeath(PlayerID)
					ReturnedState = State
				else
					case {ExplosionHappened Position PlayerID State}
					of Msg#NewState then
						Message = Msg
						ReturnedState = NewState
					else %something went wrong
						{ERR 'ExplosionHappened did not return a record correctly formatted'}
						ReturnedState = State
					end
				end
			%--------- A mine exploded (is this player damaged?) -----------------
			[] sayMineExplode(ID Position ?Message) then
				if PlayerLife =< 0 then
					Message = sayDeath(PlayerID)
					ReturnedState = State
				else
					case {ExplosionHappened Position PlayerID State}
					of Msg#NewState then
						Message = Msg
						ReturnedState = NewState
					else %something went wrong
						{ERR 'ExplosionHappened did not return a record correctly formatted'}
						ReturnedState = State
					end
				end
			%------- A drone is asking if this player is on a certain row/column ---------
			[] sayPassingDrone(Drone ?ID ?Answer) then
				if PlayerLife =< 0 then
					ID = null
					ReturnedState = State
				else
					ID = PlayerID
					case LocationState
					of stateLocation(pos:PlayerPosition dir:_ visited:_) then
						case Drone
						of drone(row:Row) then
							if PlayerPosition.y == Row then Answer = true
							else Answer = false
							end
						[] drone(column:Column) then
							if PlayerPosition.x == Column then Answer = true
							else Answer = false
							end
						else %something went wrong
							{ERR 'Drone has an invalid format'#Drone}
						end
					else %something went wrong
						{ERR 'LocationState has an invalid format'#LocationState}
					end
					ReturnedState = State
				end
			%--------- This player's drone came back with answers -----------
			[] sayAnswerDrone(Drone ID Answer) then
				%Ignore
				ReturnedState = State
			%---- A sonar is detecting => this player gives coordinates (one right, one wrong) --------
			[] sayPassingSonar(?ID ?Answer) then
				if PlayerLife =< 0 then
					ID = null
					ReturnedState = State
				else
					ID = PlayerID
					Answer = {FakeCoordForSonars State}
				
					ReturnedState = State
				end
			%--------- This player's sonar probing answers ----------------
			[] sayAnswerSonar(ID Answer) then
				%Ignore
				ReturnedState = State
			%------- Flash info : player @ID is dead --------------------
			[] sayDeath(ID) then
				%Ignore
				ReturnedState = State
			%--------- Flash info : player @ID has taken @Damage damages -------------
			[] sayDamageTaken(ID Damage LifeLeft) then
				%Ignore
				ReturnedState = State
			%--------- DEBUG : print yourself -------------------------
			[] print then
				{Browse PlayerID#State}
				ReturnedState = State
			else %Unknown message => don't do anything
				ReturnedState = State
			end
		else %something went wrong => State not in the right format => we reset the state
			{ERR 'State has an invalid format'#State}
			ReturnedState = stateRandomAI(life:Input.maxDamage locationState:stateLocation(pos:{InitPosition} dir:surface visited:nil) weaponsState:DefaultWeaponsState)
		end
		ReturnedState
	end
	
	%======== Procedures to generate the initial position ================
	% @InitPosition : generates the initial position of this player
	%                 here, it is random (but not on an island)
	fun {InitPosition}
		CurrentPosition = pt(x:({OS.rand} mod Input.nRow)+1 y:({OS.rand} mod Input.nColumn)+1)
	in
		if {PositionIsValid CurrentPosition} then CurrentPosition
		else {InitPosition}
		end
	end
	
	%======= Procedures to move randomly ========================
	% @Move : move randomly one square in any direction or go to the surface
	%         except if the current player is at the surface
	%         We cannot move twice on the same square in the same diving phase
	%         (we keep track of the visited squares with @SquareVisited)
	fun {Move LocationState}
		case LocationState
		of stateLocation(pos:Position dir:Direction visited:VisitedSquares) then
			%-------- Player is at the surface => you can't move ----------
			if Direction == surface then
				% You will dive when you get the message @dive
				%return
				LocationState
			%--------- Player is underwater => move to another position ---------------
			else %Direction \= surface
				%Check if there is at least one position available around this player
				if {NoSquareAvailable Position VisitedSquares} then %go to the surface
					%return
					stateLocation(pos:Position dir:surface visited:nil)
				%Choose if we should go to the surface or move
				elseif {OS.rand} mod 20 == 0 then %surface
					%return
					stateLocation(pos:Position dir:surface visited:nil)
				else
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
					else {Move LocationState} %Choose another new position
					end
				end
			end
		else null
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
	
	% @ChooseRandomDirection : returns one of the 4 directions randomly chosen (north, south, west or east)
	fun {ChooseRandomDirection}
		case {OS.rand} mod 4
		of 0 then north
		[] 1 then south
		[] 2 then west
		[] 3 then east
		else %something went wrong
			{ERR 'Randomized out-of-bounds'}
			north %because we have to return something
		end
	end
	
	% @NoSquareAvailable : checks if there is at least one square around @PlayerPosition
	%                      that is available
	%                      returns @true if no square is available, @false otherwise
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
	
	%======== Procedures for loading weapons =================================
	% @LoadRandomWeapon : Randomly chooses a weapon to load and increment its loading charge
	%                     Returns the updated weapons's state
	fun {LoadRandomWeapon WeaponsState}
		case WeaponsState
		of stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading) then
			case {OS.rand} mod 4
			of 0 then stateWeapons(nbMines:NbMines minesLoading:MinesLoading+1 minesPlaced:MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			[] 1 then stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading+1 nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			[] 2 then stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading+1 nbSonars:NbSonars sonarsLoading:SonarsLoading)
			[] 3 then stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading+1)
			else %something went wrong
				{ERR 'Randomized out-of-bounds'}
				WeaponsState %because we have to return something
			end
		else %something went wrong
			{ERR 'WeaponsState has an invalid format'#WeaponsState}
			WeaponsState %because we have to return something
		end
	end
	
	% @NewWeaponAvailable : Check if @WeaponsState has one of its loading
	%                       that allows one weapon to be created
	%                       Returns the type of weapon created or @null if no weapon can be created
	%                       and the new weapons state
	%                       Called everytime a loading charge is increased
	fun {NewWeaponAvailable WeaponsState}
		case WeaponsState
		of stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading) then
			if MinesLoading == Input.mine then
				mine#stateWeapons(nbMines:NbMines+1 minesLoading:0 minesPlaced:MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			elseif MissilesLoading == Input.missile then
				missile#stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:MinesPlaced nbMissiles:NbMissiles+1 missilesLoading:0 nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			elseif DronesLoading == Input.drone then
				drone#stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones+1 dronesLoading:0 nbSonars:NbSonars sonarsLoading:SonarsLoading)
			elseif SonarsLoading == Input.sonar then
				sonar#stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars+1 sonarsLoading:0)
			else null#WeaponsState
			end
		else %something went wrong
			{ERR 'WeaponsState has an invalid format'#WeaponsState}
			null#WeaponsState %because we have to return something
		end
	end
	
	%========== Procedures for firing weapons ==============
	% @ChooseWhichToFire : If a weapon is available, randomly decides which weapon to fire
	%                      Returns one of the following : @null, @mine, @missile, @drone, @sonar
	fun {ChooseWhichToFire WeaponsState}
		case WeaponsState
		of stateWeapons(nbMines:NbMines minesLoading:_ minesPlaced:_ nbMissiles:NbMissiles missilesLoading:_ nbDrones:NbDrones dronesLoading:_ nbSonars:NbSonars sonarsLoading:_) then
			% Choose a type of weapon to try and fire
			case {OS.rand} mod 4
			% If a weapon is available, fire it with a one-in-two chance
			of 0 then if NbMines > 0 andthen ({OS.rand} mod 2)==1 then mine else null end
			[] 1 then if NbMissiles > 0 andthen ({OS.rand} mod 2)==1 then missile else null end
			[] 2 then if NbDrones > 0 andthen ({OS.rand} mod 2)==1 then drone else null end
			[] 3 then if NbSonars > 0 andthen ({OS.rand} mod 2)==1 then sonar else null end
			else null
			end
		else %something went wrong
			{ERR 'WeaponsState has an invalid format'#WeaponsState}
			null %because we have to return something
		end
	end
	
	% @FireWeapon : Creates the weapon of type @WeaponType that is going to be fired
	%               (with all the necssary parameters to this weapon)
	%               Returns it and the new weapons state with decremented count for this weapon
	%               Call one of the following : @PlaceMine, @FireMissile, @FireDrone or @FireSonar
	fun {FireWeapon WeaponType PlayerState}
		case PlayerState
		of stateRandomAI(life:_ locationState:stateLocation(pos:PlayerPosition dir:Direction visited:Visited) weaponsState:WeaponsState) then
			case WeaponType
			of mine then
				NewMine = {PlaceMine PlayerPosition}
			in
				NewMine#{UpdateWeaponsState WeaponsState NewMine}
			[] missile then
				{FireMissile PlayerPosition}#{UpdateWeaponsState WeaponsState WeaponType}
			[] drone then
				{FireDrone}#{UpdateWeaponsState WeaponsState WeaponType}
			[] sonar then
				{FireSonar}#{UpdateWeaponsState WeaponsState WeaponType}
			else null#WeaponsState
			end
		else %something went wrong
			{ERR 'PlayerState has an invalid format'#PlayerState}
			null %because we have to return something
		end
	end
	
	% @PlaceMine : Creates a mine at a random position on the grid
	%              but in the range from the player where it is allowed to place mines
	%              Returns the created mine (with the position of setup as a parameter)
	fun {PlaceMine PlayerPosition}
		RandomPosition = pt(x:({OS.rand} mod Input.nRow)+1 y:({OS.rand} mod Input.nColumn)+1)
		DistanceFromPlayer = {Abs (PlayerPosition.x-RandomPosition.x)}+{Abs (PlayerPosition.y-RandomPosition.y)}
	in
		% Check the distances
		if DistanceFromPlayer >= Input.minDistanceMine andthen DistanceFromPlayer =< Input.maxDistanceMine then mine(RandomPosition)
		else {PlaceMine PlayerPosition}
		end
	end
	
	% @FireMissile : Creates a missile set to explode at a random position on the grid
	%                but in the range from the player where it is allowed to make it explode
	%                Returns the created missile (with the position of explosion as a parameter)
	fun {FireMissile PlayerPosition}
		RandomPosition = pt(x:({OS.rand} mod Input.nRow)+1 y:({OS.rand} mod Input.nColumn)+1)
		DistanceFromPlayer = {Abs (PlayerPosition.x-RandomPosition.x)}+{Abs (PlayerPosition.y-RandomPosition.y)}
	in
		% Check the distances
		if DistanceFromPlayer >= Input.minDistanceMissile andthen DistanceFromPlayer =< Input.maxDistanceMissile then missile(RandomPosition)
		else {FireMissile PlayerPosition}
		end
	end
	
	% @FireDrone : Creates a drone looking at a row or a column (one-in-two chance to be one or the other)
	%              Returns this drone (with which row or column it is watching as a parameter)
	fun {FireDrone}
		case {OS.rand} mod 2
		of 0 then %row
			drone(row:({OS.rand} mod Input.nColumn)+1)
		[] 1 then %column
			drone(column:({OS.rand} mod Input.nRow)+1)
		else %something went wrong
			{ERR 'Randomized out-of-bounds'}
			drone(row:({OS.rand} mod Input.nRow)+1) %because we have to return something valid
		end
	end
	
	% @FireSonar : Creates a sonar and returns it
	fun {FireSonar}
		sonar
	end
	
	% @UpdateWeaponsState : Called when a weapon is fired (from @FireWeapon)
	%                       Returns a new weapons' state with a decremented count
	%                       of the weapon type fired and an updated list of mines placed
	%                       if a mine was placed
	%                       ! @WeaponFired is a the weapon fired in case of a mine
	%                         but the type of the weapon in any other case !
	% This should never be called for a weapon type that has already reached 0
	fun {UpdateWeaponsState WeaponsState WeaponFired}
		case WeaponsState
		of stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading) then
			case WeaponFired
			of mine(_) then stateWeapons(nbMines:NbMines-1 minesLoading:MinesLoading minesPlaced:WeaponFired|MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			[] missile then stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:MinesPlaced nbMissiles:NbMissiles-1 missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			[] drone then stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones-1 dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			[] sonar then stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars-1 sonarsLoading:SonarsLoading)
			else WeaponsState
			end
		else %something went wrong
			{ERR 'WeaponsState has an invalid format'#WeaponsState}
			WeaponsState %because we have to return something
		end
	end
	
	% @ExplodeMine : Checks if there is a mine in the list of mines placed (contained in @WeaponsState)
	%                Chooses if one of those mine should explode and which one (randomly)
	%                Returns the mine exploding and the new weapons' state (with the new list of mines placed)
	fun {ExplodeMine WeaponsState}
		fun {Loop MinesPlaced MinesAccumulator}
			case MinesPlaced
			of Mine|Remainder then
				%Choose to explode this mine (one-in-two chances)
				if (({OS.rand} mod 2)==1) then Mine#{Append MinesAccumulator Remainder}
				else {Loop Remainder {Append MinesAccumulator Mine|nil}}
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
		of stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:MinesPlaced nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading) then
			case {Loop MinesPlaced nil}
			of Mine#RemainingMines then
				Mine#stateWeapons(nbMines:NbMines minesLoading:MinesLoading minesPlaced:RemainingMines nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			end
		else %something went wrong
			{ERR 'WeaponsState has an invalid format'#WeaponsState}
			null#WeaponsState %because we have to return something
		end
	end
	
	%========= Procedures about taking damages ===============
	% @ExplosionHappened : Computes the message to send to the game controller when something explode
	%                      at position @ExplodePosition and updates the player's state
	fun {ExplosionHappened ExplosionPosition PlayerID State}
		Message
		UpdatedState
	in
		case {ComputeDamage ExplosionPosition State}
		of DamageTaken#NewState then
			if DamageTaken == 0 then
				% No damage => no changes
				Message = null
				UpdatedState = State
			else
				% Damage taken => change state and send message
				case NewState
				of stateRandomAI(life:CurrentLife locationState:LocationState weaponsState:WeaponsState) then
					if CurrentLife =< 0 then %dead
						Message = sayDeath(PlayerID)
						UpdatedState = stateRandomAI(life:0 locationState:LocationState weaponsState:WeaponsState)
					else
						Message = sayDamageTaken(PlayerID DamageTaken CurrentLife)
						UpdatedState = stateRandomAI(life:CurrentLife locationState:LocationState weaponsState:WeaponsState)
					end
				else %something went wrong
					{ERR 'ComputeDamage returned a state with invalid format'#NewState}
					%don't take damages
					Message = null
					UpdatedState = State
				end
			end
		else %something went wrong
			{ERR 'ComputeDamage returned something with an invalid syntax'}
			%don't take damages
			Message = null
			UpdatedState = State
		end
		%return
		Message#UpdatedState
	end
	
	% @ComputeDamage : Computes the damages taken as something (mine or missile) explode
	%                      at position @ExplosionPosition
	%                      Returns the number of damages taken and the new state (with the life left)
	fun {ComputeDamage ExplosionPosition State}
		case State
		of stateRandomAI(life:Life locationState:stateLocation(pos:PlayerPosition dir:Direction visited:Visited) weaponsState:WeaponsState) then
			Distance = {Abs (PlayerPosition.x-ExplosionPosition.x)}+{Abs (PlayerPosition.y-ExplosionPosition.y)}
		in
			if Distance >= 2 then %Too far => no damage
				0#State
			elseif Distance == 1 then %1 damage
				1#stateRandomAI(life:Life-1 locationState:stateLocation(pos:PlayerPosition dir:Direction visited:Visited) weaponsState:WeaponsState)
			else %Distance == 0 => 2 damages
				2#stateRandomAI(life:Life-2 locationState:stateLocation(pos:PlayerPosition dir:Direction visited:Visited) weaponsState:WeaponsState)
			end
		else %something went wrong
			{ERR 'PlayerState has an invalid format'#State}
			%don't take damages (because we have to return something valid)
			0#State
		end
	end
	
	%========= Procedures about other players' detections ===============
	% @FakeCoordForSonars : Generates coordinates that will be sent
	%                       to another player's sonar detection
	%                       These coordinates will have one coordinate right
	%                       and the other wrong (randomly chosen)
	fun {FakeCoordForSonars State}
		case State
		of stateRandomAI(life:_ locationState:stateLocation(pos:PlayerPosition dir:_ visited:_) weaponsState:_) then
			%Choose which coordinate to fake
			case {OS.rand} mod 2
			of 0 then
				pt(x:PlayerPosition.x y:({OS.rand} mod Input.nColumn)+1)
			[] 1 then
				pt(x:({OS.rand} mod Input.nRow)+1 y:PlayerPosition.y)
			else %something went wrong
				{ERR 'Randomized out-of-bounds'}
				pt(x:({OS.rand} mod Input.nRow)+1 y:PlayerPosition.y) %because we have to return something valid
			end
		else %something went wrong
			{ERR 'PlayerState has an invalid format'#State}
			pt(x:0 y:0) %because we have to return something with a valid format
		end
	end
	
	%========= Useful procedures and functions =====================================
	% @PositionIsValid : checks if @Position represents a position in the water or not
	%                    !!! pt(x:1 y:1) is the first cell in the grid (not 0;0) !!!
	%                           => be careful when randomizing positions
	fun {PositionIsValid Position}
		case Position
		of pt(x:X y:Y) then
			if X =< 0 orelse X > Input.nRow orelse Y =< 0 orelse Y > Input.nColumn then false
			elseif {Nth {Nth Input.map X} Y} == 0 then true
			else false
			end
		else false
		end
	end
end
