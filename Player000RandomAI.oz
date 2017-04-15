%% Player000RandomAI.oz %%
%% An AI that behaves in a random manner

functor
import
	OS %for random number generation
	Browser %for displaying debug information
	
	Input
export
	portPlayer:StartPlayer
define
	StartPlayer
	TreatStream
	Behavior
	
	InitPosition
	Move
	SquareNotVisited
	ChooseRandomDirection
	
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
	
	PositionIsValid
	
	DefaultWeaponsState = stateWeapons(nbMines:0 minesLoading:0 nbMissiles:0 missilesLoading:0 nbDrones:0 dronesLoading:0 nbSonars:0 sonarsLoading:0)
in
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% This port object has an @ID containing the ID number, the color and the name of the object
	% This port object uses the states
	% @stateRandomAI(life:Life pos:Position dir:Direction canDive:CanDive visited:SquaresVisited weaponsState:WeaponsState)
	%     @CanDive is a boolean saying if the player has been granted the permission to dive
	%              we consider that this boolean == false when the player is underwater
	%     @SquaresVisited is a list of all the positions visited since the last surface phase
	%                     Those cannot be visited again on the same diving phase
	%                    => Main should NOT allow a player to dive while it's underwater
	%     @WeaponsState is a record of type @stateWeapons (defined hereafter)
	% @stateWeapons(nbMines:NbMines minesLoading:MinesLoading nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
	%    @nbX is the number of X available to the player
	%    @XLoading is the number of loading charges currently loaded by the player
	%              Input.X being the number of loading charges needed to charge one item of this type
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	%============== Make the port object ========================
	% @StartPlayer : Initializes the player (ID, position, weapons, etc.)
	%                and create the port object
	fun {StartPlayer Color Num}
		Stream
		Port
		ID = id(id:Num color:Color name:'randomAI'#{OS.rand})
	in		
		{NewPort Stream Port}
		thread
			{TreatStream Stream ID stateRandomAI(life:Input.maxDamage pos:{InitPosition} dir:surface canDive:false visited:nil weaponsState:DefaultWeaponsState)}
		end
		Port
	end
	
	% @TreatStream : Loop that checks if some new messages are sent to the port 
	%                and treats them
	%                The attributes of this procedure keep track of the state of this port object
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
		of stateRandomAI(life:PlayerLife pos:PlayerPosition dir:PlayerDirection canDive:CanDive visited:VisitedSquares weaponsState:WeaponsState) then
			case Msg
			%---------- Initialize position -------------
			of initPosition(?ID ?Position) then
				ID = PlayerID
				Position = PlayerPosition
				%return
				ReturnedState = State
			%---------- Move player -------------------
			[] move(?ID ?Position ?Direction) then
				case {Move posState(pos:PlayerPosition dir:PlayerDirection canDive:CanDive visited:VisitedSquares)}
				of posState(pos:NewPosition dir:NewDirection canDive:NewCanDive visited:NewVisitedSquares) then
					ID = PlayerID
					Position = NewPosition
					Direction = NewDirection
					%return
					ReturnedState = stateRandomAI(life:PlayerLife pos:NewPosition dir:NewDirection cnaDive:NewCanDive visited:NewVisitedSquares weaponsState:WeaponsState)
				else %something went wrong
					ID = null
					%return the same state as before
					ReturnedState = State
				end
			%---------- Provide the permission to dive -------------
			% This should be called only if PlayerDirection == surface
			[] dive then
				ReturnedState = stateRandomAI(life:PlayerLife pos:PlayerPosition dir:PlayerDirection canDive:true visited:VisitedSquares weaponsState:WeaponsState)
			%------- Increase the loading charge of an item ------------
			[] chargeItem(?ID ?KindItem) then
				NewWeaponsState
				SimplifiedWeaponsState
			in
				ID = PlayerID
				% Load one of the weapons's loading charge
				NewWeaponsState = {LoadRandomWeapon WeaponsState}
				% Check if a new weapon can be created
				KindItem = {NewWeaponAvailable NewWeaponsState}
				% Create the knew weapons state
				SimplifiedWeaponsState = {SimplifyWeaponsState NewWeaponsState}
				%return
				ReturnedState = stateRandomAI(life:PlayerLife pos:PlayerPosition dir:PlayerDirection canDive:CanDive visited:VisitedSquares weaponsState:NewWeaponsState)
			%------- Fire a weapon -------------
			% If a weapon is available, randomly choose to use one
			[] fireItem(ID KindFire) then
				FiredWeaponType = {ChooseWhichToFire WeaponsState}
				NewWeaponsState
			in
				ID = PlayerID
				if FiredWeaponType \= null then
					% Fire a weapon of type @FiredWeaponType
					KindFire = {FireWeapon FiredWeaponType PlayerPosition}
					NewWeaponsState = {UpdateWeaponsState WeaponsState FiredWeaponType}
					%return
					ReturnedState = stateRandomAI(lif:PlayerLife pos:PlayerPosition dir:PlayerDirection canDive:CanDive visited:VisitedSquares weaponsState:NewWeaponsState)
				end
			 %[] fireMine(ID KindItem) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			%[] isSurface(ID Answer) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] sayMove(ID Direction) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] saySurface(ID) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] sayCharge(ID KindItem) then
				%{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] sayMinePlaced(ID) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] sayMissileExplode(ID Position Message) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] sayMineExplode(ID Position Message) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] sayPassingDrone(Drone ID Answer) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] sayAnswerDrone(Drone ID Answer) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] sayPassingSonar(ID Answer) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] sayAnswerSonar(ID Answer) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] sayDeath(ID) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] sayDeath(ID) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] sayDamageTaken(ID Damage LifeLeft) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			end
		end
		ReturnedState
	end
	
	%======== Procedures to generate the initial position ================
	% @InitPosition : generates the initial position of this player
	%                 here, it is random (but not on an island)
	fun {InitPosition}
		CurrentPosition = pt(x:({OS.rand} mod Input.nRow) y:({OS.rand} mod Input.nColumn))
	in
		if {PositionIsValid CurrentPosition} then CurrentPosition
		else {InitPosition}
		end
	end
	
	%======= Procedures to move randomly ========================
	% @Move : move randomly one square in any direction
	%         except if the current player is at the surface
	%         We cannot move twice on the same square in the same diving phase
	%         (we keep track of the visited squares with @SquareVisited
	fun {Move PositionState}
		case PositionState
		of posState(pos:Position dir:Direction canDive:CanDive visited:SquaresVisited) then
			%-------- Player is at the surface => choose to dive if you're allowed to ----------
			if Direction == surface then
				if CanDive then
					% One-in-two chance of diving if you have the permission to dive
					% If you dive, you cannot move at the same time (same turn) ?
					
					% Dive
					if {OS.rand} mod 2 == 1 then
						%return
						posState(pos:Position dir:{ChooseRandomDirection} canDive:false visited:Position|nil)
					% Don't dive
					else
						%return
						PositionState
					end
				else
					%return
					posState(pos:Position dir:Direction canDive:CanDive visited:nil)
				end
			%--------- Player is underwater => move to another position ---------------
			else %Direction \= surface => CanDive = false
				NewPosition = pt(x:Position.x+({OS.rand} mod 2) y:Position.y+({OS.rand} mod 2))
			in
				if {PositionIsValid NewPosition} andthen {SquareNotVisited NewPosition SquaresVisited} then
					%return
					posState(pos:NewPosition dir:Direction visited:NewPosition|SquaresVisited)
				else {Move PositionState} %Choose another new position
				end
			end
		else null
		end
	end
	
	% @SquareNotVisited : returns true if the squares hasn't been visited in this diving phase
	fun {SquareNotVisited Position SquaresVisited}
		case SquaresVisited
		of nil then true
		[] Square|Remainder then
			if Position == Square then false
			else {SquareNotVisited Position Remainder}
			end
		end
	end
	
	% @ChooseRandomDirection : returns one of the 4 directions randomly chosen (north, south, west or east)
	fun {ChooseRandomDirection}
		case {OS.rand} mod 4
		of 0 then north
		[] 1 then south
		[] 2 then west
		[] 3 then east
		end
	end
	
	%======== Procedures for loading weapons =================================
	% @LoadRandomWeapon : Randomly chooses a weapon to load and increment its loading charge
	%                     Returns the updated weapons's state
	fun {LoadRandomWeapon WeaponsState}
		case WeaponsState
		of stateWeapons(nbMines:NbMines minesLoading:MinesLoading nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading) then
			case {OS.rand} mod 4
			of 0 then stateWeapons(nbMines:NbMines minesLoading:MinesLoading+1 nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			[] 1 then stateWeapons(nbMines:NbMines minesLoading:MinesLoading nbMissiles:NbMissiles missilesLoading:MissilesLoading+1 nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			[] 2 then stateWeapons(nbMines:NbMines minesLoading:MinesLoading nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading+1 nbSonars:NbSonars sonarsLoading:SonarsLoading)
			[] 3 then stateWeapons(nbMines:NbMines minesLoading:MinesLoading nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading+1)
			end
		end
	end
	
	% @NewWeaponAvailable : Check if @WeaponsState has one of its loading
	%                       that allows one weapon to be created
	%                       Returns the type of weapon created or @null if no weapon can be created
	%                       Called everytime a loading charge is increased
	fun {NewWeaponAvailable WeaponsState}
		case WeaponsState
		of stateWeapons(nbMines:NbMines minesLoading:MinesLoading nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading) then
			if MinesLoading == Input.mine then mine
			elseif MissilesLoading == Input.missile then missile
			elseif DronesLoading == Input.drone then drone
			elseif SonarsLoading == Input.sonar then sonar
			else null
			end
		end
	end
	
	% @SimplifyWeaponsState : If a weapon can be created, creates the weapon
	%                         and decreases the weapon's loading charge
	%                         Returns the new weapons's state
	%                         Called everytime a loading charge is increased
	%                              => only one weapon can be created on each call
	fun {SimplifyWeaponsState WeaponsState}
		case WeaponsState
		of stateWeapons(nbMines:NbMines minesLoading:MinesLoading nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading) then
			if MinesLoading == Input.mine then
				stateWeapons(nbMines:NbMines+1 minesLoading:0 nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			elseif MissilesLoading == Input.missile then
				stateWeapons(nbMines:NbMines minesLoading:MinesLoading nbMissiles:NbMissiles+1 missilesLoading:0 nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			elseif DronesLoading == Input.drone then
				stateWeapons(nbMines:NbMines minesLoading:MinesLoading nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones+1 dronesLoading:0 nbSonars:NbSonars sonarsLoading:SonarsLoading)
			elseif SonarsLoading == Input.sonar then
				stateWeapons(nbMines:NbMines minesLoading:MinesLoading nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars+1 sonarsLoading:0)
			else WeaponsState
			end
		end
	end
	
	%========== Procedures for firing weapons ==============
	% @ChooseWhichToFire : If a weapon is available, randomly decides which weapon to fire
	%                      Returns one of the following : @null, @mine, @missile, @drone, @sonar
	fun {ChooseWhichToFire WeaponsState}
		case WeaponsState
		of stateWeapons(nbMines:NbMines minesLoading:_ nbMissiles:NbMissiles missilesLoading:_ nbDrones:NbDrones dronesLoading:_ nbSonars:NbSonars sonarsLoading:_) then
			% Choose a type of weapon to try and fire
			case {OS.rand} mod 4
			% If a weapon is available, fire it with a one-in-two chance
			of 0 then if NbMines > 0 andthen ({OS.rand} mod 2) then mine else null end
			[] 1 then if NbMissiles > 0 andthen ({OS.rand} mod 2) then missile else null end
			[] 2 then if NbDrones > 0 andthen ({OS.rand} mod 2) then drone else null end
			[] 3 then if NbSonars > 0 andthen ({OS.rand} mod 2) then sonar else null end
			else null
			end
		end
	end
	
	% @FireWeapon : Creates the weapon of type @WeaponType that is going to be fired
	%               (with all the necssary parameters to this weapon)
	%               Call one of the following : @PlaceMine, @FireMissile, @FireDrone or @FireSonar
	fun {FireWeapon WeaponType PlayerPosition}
		case WeaponType
		of mine then {PlaceMine PlayerPosition}
		[] missile then {FireMissile PlayerPosition}
		[] drone then {FireDrone}
		[] sonar then {FireSonar}
		else null
		end
	end
	
	% @PlaceMine : Creates a mine at a random position on the grid
	%              but in the range from the player where it is allowed to place mines
	%              Returns the created mine (with the position of setup as a parameter)
	fun {PlaceMine PlayerPosition}
		RandomPosition = pt(x:({OS.rand} mod Input.nRow) y:({OS.rand} mod Input.nColumn))
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
		RandomPosition = pt(x:({OS.rand} mod Input.nRow) y:({OS.rand} mod Input.nColumn))
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
			drone(row:({OS.rand} mod Input.nRow))
		[] 1 then %column
			drone(column:({OS.rand} mod Input.nColumn))
		end
	end
	
	% @FireSonar : Creates a sonar and returns it
	fun {FireSonar}
		sonar
	end
	
	% @UpdateWeaponsState : Called when a weapon is fired
	%                       Returns a new weapons' state with a decremented count
	%                       of the weapon type fired
	%                       This should never be called for a weapon type that has already reached 0
	fun {UpdateWeaponsState WeaponsState FiredWeaponType}
		case WeaponsState
		of stateWeapons(nbMines:NbMines minesLoading:MinesLoading nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading) then
			case FiredWeaponType
			of mine then stateWeapons(nbMines:NbMines-1 minesLoading:MinesLoading nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			[] missile then stateWeapons(nbMines:NbMines minesLoading:MinesLoading nbMissiles:NbMissiles-1 missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			[] drone then stateWeapons(nbMines:NbMines minesLoading:MinesLoading nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones-1 dronesLoading:DronesLoading nbSonars:NbSonars sonarsLoading:SonarsLoading)
			[] sonar then stateWeapons(nbMines:NbMines minesLoading:MinesLoading nbMissiles:NbMissiles missilesLoading:MissilesLoading nbDrones:NbDrones dronesLoading:DronesLoading nbSonars:NbSonars-1 sonarsLoading:SonarsLoading)
			else WeaponsState
			end
		end
	end
	
	%========= Useful procedures and functions =====================================
	% @PositionIsValid : checks if @Position represents a position in the water or not
	%                    !!! pt(x:1 y:1) is the first cell in the grid (not 0;0) !!!
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
