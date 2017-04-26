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
	GetTarget
	MoveTowards
	MoveAway
	PositionGetsYouCloser
	
	LoadWeapon
	ChooseWhichToLoad
	
	ChooseWhichToFire
	FireWeapon
	UpdateWeaponsState
	PlaceMine
	FireMissile
	GetReachableExplosionPosition
	SquareIsReachableForExplosion
	FireDrone
	FireSonar
	
	ExplodeMine
	
	ExplosionHappened
	ComputeDamage
	
	FakeCoordForSonars
	
	PlayerMoved
	PlayerMadeSurface
	DroneAnswered
	SonarAnswered
	PlayerDead
	
	PositionIsValid
	CoordIsOnGrid
	
	DefaultWeaponsState = stateWeapons(minesLoading:0 minesPlaced:nil missilesLoading:0 dronesLoading:0 lastDroneFired:null sonarsLoading:0)
	DefaultTrackingState = nil
in
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% This port object uses a state record of this type :
	% @stateBasicAI(life:Life locationState:LocationState weaponsState:WeaponsState tracking:TrackingInfo)
	%		@LocationState is a record of type @stateLocation (defined hereafter)
	%		@WeaponsState is a record of type @stateWeapons (defined hereafter)
	%		@TrackingInfo is a record of type @stateTracking (defined hereafter)
	%
	% @stateLocation(pos:Position dir:Direction visited:VisitedSquares)
	% @stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading lastDroneFired:Drone sonarsLoading:SonarsLoading)
	%		@XLoading is the loading of the weapon of type X
	%						it can also be used to know 
	%						how much of this weapon is currently available (using mod)
	%		@MinesPlaced is a list of all the mines this player has placed
	%							and that haven't exploded yet (with ther position)
	% @stateTracking(Infos)
	%     @Infos is an array containing records with the following format :
	%            @trackingInfo(id:ID surface:Surface x:X y:Y)
	%                 where @ID is the ID of one player tracked (!!! It should NEVER contain @this!!!)
	%                       @Surface is a boolean (@true if player @ID is
	%                                              at the surface)
	%                       @X and @Y are one of the following records
	%                                 @unknown if we have no idea about this coord
	%                                 @supposed(Coord) if we think it might be the
	%                                                  coordinate of the player
	%                                                  (both coordinates received by
	%                                                   a sonar for example)
	%                                 @certain(Coord) if we know the coordinate is right
	%                                        Computations will be done on those when a player is
	%                                        broadcast to be moving
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
					KindItem#NewWeaponsState = {LoadWeapon WeaponsState TrackingInfo}
					
					ReturnedState = stateBasicAI(life:PlayerLife locationState:LocationState weaponsState:NewWeaponsState tracking:TrackingInfo)
				end
			%------- Fire a weapon -------------------
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
						ReturnedState = stateBasicAI(life:PlayerLife locationState:LocationState weaponsState:NewWeaponsState tracking::TrackingInfo)
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
			%------- Flash info : player @ID has moved in the direction @Direction ----------
			[] sayMove(ID Direction) then
				UpdatedTrackingInfo = {PlayerMoved TrackingInfo ID Direction}
			in
				ReturnedState = stateBasicAI(life:PlayerLife locationState:LocationState weaponsState:WeaponsState tracking:UpdatedTrackingInfo)
			%-------- Flash info : player @ID has made surface --------------
			[] saySurface(ID) then
				UpdatedTrackingInfo = {PlayerMadeSurface TrackingInfo ID}
			in
				ReturnedState = stateBasicAI(life:PlayerLife locationState:LocationState weaponsState:WeaponsState tracking:UpdatedTrackingInfo)
			%------- Flash info : player @ID has the item @KindItem ----------
			[] sayCharge(ID KindItem) then
				%Ignore this
				ReturnedState = State
			%------- Flash info : player @ID has placed a mine --------------
			[] sayMinePlaced(ID) then
				%Ignore this
				ReturnedState = State
			%-------- A missile exploded (is this player damaged?) ---------------
			[] sayMissileExplode(ID Position ?Message) then
				if PlayerLife =< 0 then
					Msg = sayDeath(PlayerID)
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
			%-------- A mine exploded (is this player damaged?) -------------
			[] sayMineExplode(ID Position ?Message) then
				if PlayerLife =< 0 then
					Msg = sayDeath(PlayerID)
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
							if PlayerPosition.x == Row then Answer = true
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
			%------ This player's drone came back with answers ------------
			[] sayAnswerDrone(Drone ID Answer) then
				if ID \= PlayerID andthen Answer then %Not @this and player @Id was detected
					UpdatedTrackingInfo
				in
					case WeaponsState
					of stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading lastDroneFired:Drone sonarsLoading:SonarsLoading) then
						case Drone
						of drone(column:X) then
							UpdatedTrackingInfo = {DroneAnswered TrackingInfo ID column(X)}
							ReturnedState = stateBasicAI(life:PlayerLife locationState:LocationState weaponsState:WeaponsState tracking:UpdatedTrackingInfo)
						[] drone(row:Y) then
							UpdatedTrackingInfo = {DroneAnswered TrackingInfo ID row(Y)}
							ReturnedState = stateBasicAI(life:PlayerLife locationState:LocationState weaponsState:WeaponsState tracking:UpdatedTrackingInfo)
						else %something went wrong
							{ERR 'Drone has an invalid format'#Drone}
							ReturnedState = State
						end
					else %something went wrong
						{ERR 'WeaponsState has an invalid format'#WeaponsState}
						ReturnedState = State
					end
				else
					ReturnedState = State
				end
			%----- A sonar is detecting => this player gives coordinates (one right, one wrong) ------
			[] sayPassingSonar(?ID ?Answer) then
				if PlayerLife =< 0 then
					ID = null
					ReturnedState = State
				else
					ID = PlayerID
					Answer = {FakeCoordForSonars State}
					
					ReturnedState = State
				end
			%-------- This player's sonar probing answers ------------------
			[] sayAnswerSonar(ID Answer) then
				if ID \= PlayerID then
					UpdatedTrackingInfo = {SonarAnswered TrackingInfo ID Answer}
				in
					ReturnedState = stateBasicAI(life:PlayerLife locationState:LocationState weaponsState:WeaponsState tracking:UpdatedTrackingInfo)
				else
					ReturnedState = State
				end
			%-------- Flash info : player @ID is dead -----------------
			[] sayDeath(ID) then
				UpdatedTrackingInfo = {PlayerDead ID TrackingInfo}
			in
				ReturnedState = stateBasicAI(life:PlayerLife locationState:LocationState weaponsState:WeaponsState tracking:UpdatedTrackingInfo)
			%-------- Flash info : player @ID has taken @Damage damages ------------
			[] sayDamageTaken(ID Damage LifeLeft) then
				%TODO
				ReturnedState = State
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
					Target = {GetTarget TrackingInfo}
					DistancePlayerTarget = {Abs (Position.x-Target.x)}+{Abs (Position.y-Target.y)}
				in
					if Target \= null then %Go to target but not too close (in case of explosions)
						NewPosition
						DirectionTravelled
					in
						if DistancePlayerTarget > 2 then
							NewPosition#DirectionTravelled = {MoveTowards Position VisitedSquares Target}
						else
							NewPosition#DirectionTravelled = {MoveAway Position VisitedSquares Target}
						end
						
						if NewPosition == null orelse DirectionTravelled == null then %something went wrong
							%return
							LocationState
						else
							%return
							stateLocation(pos:NewPosition dir:DirectionTravelled visited:NewPosition|VisitedSquares)
						end
					else %No target => Move randomly
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
	
	% @GetTarget : Returns the position of the first player whose position is known
	%              or null if no position is certain
	fun {GetTarget TrackingInfo}
		fun {Loop TrackingInfo}
			case TrackingInfo
			of Track|Remainder then
				case Track
				of trackingInfo(id:_ surface:_ x:XInfo y:YInfo) then
					case XInfo#YInfo
					of certain(X)#certain(Y) then
						pt(x:X y:Y)
					else %not certain => move randomly
						null
					end
				else %something went wrong
					{ERR 'An element in TrackingInfo has an invalid format'#Track}
					{Loop Remainder}
				end
			[] nil then null
			else %something went wrong
				{ERR 'TrackingInfo has an invalid format'#TrackingInfo}
				null
			end
		end
	in
		{Loop TrackingInfo}
	end
	
	% @MoveTowards : Returns a valid position that allows @this to 
	%                move towards @Target (in most cases)
	%                and the direction it makes
	fun {MoveTowards Position VisitedSquares Target}
		case Position#Target
		of pt(x:X y:Y)#pt(x:XTarget y:YTarget) then
			NewPosition
			NewDirection
		in
			% Randomly choose a direction to follow and check if it is valid and
			% gets you closer to the target.
			% One-in-ten chance of moving there anyway (to avoid looping forever),
			% otherwise call recursively this function.
			case {OS.rand} mod 4
			of 0 then %south
				NewDirection = south
				NewPosition = pt(x:X+1 y:Y)
			[] 1 then %north
				NewDirection = north
				NewPosition = pt(x:X-1 y:Y)
			[] 2 then %west
				NewDirection = west
				NewPosition = pt(x:X y:Y+1)
			[] 3 then %east
				NewDirection = east
				NewPosition = pt(x:X y:Y-1)
			else %something went wrong
				{ERR 'Randomized out-of-bound'}
				NewPosition = null
			end
			
			if NewPosition == null then
				{MoveTowards Position VisitedSquares Target}
			else
				if {PositionGetsYouCloser Position NewPosition Target} then
					if {PositionIsValid NewPosition} andthen {SquareNotVisited NewPosition VisitedSquares} then
						%return
						NewPosition#NewDirection
					else
						{MoveTowards Position VisitedSquares Target}
					end
				else
					if {OS.rand} mod 10 == 0 then %use it anyway
						if {PositionIsValid NewPosition} andthen {SquareNotVisited NewPosition VisitedSquares} then
							%return
							NewPosition#NewDirection
						else
							{MoveTowards Position VisitedSquares Target}
						end
					else
						{MoveTowards Position VisitedSquares Target}
					end
				end
			end
		else %something went wrong
			{ERR 'Target or Position has an invalid format'#Target#Position}
			null#null
		end
	end
	
	% @MoveAway : Returns a valid position that allows @this to 
	%             move away from @Target (in most cases)
	%             and the direction it makes
	fun {MoveAway Position VisitedSquares Target}
		case Position#Target
		of pt(x:X y:Y)#pt(x:XTarget y:YTarget) then
			NewPosition
			NewDirection
		in
			% Randomly choose a direction to follow and check if it is valid and
			% gets you further from the target.
			% One-in-ten chance of moving there anyway (to avoid looping forever),
			% otherwise call recursively this function.
			case {OS.rand} mod 4
			of 0 then %south
				NewDirection = south
				NewPosition = pt(x:X+1 y:Y)
			[] 1 then %north
				NewDirection = north
				NewPosition = pt(x:X-1 y:Y)
			[] 2 then %west
				NewDirection = west
				NewPosition = pt(x:X y:Y+1)
			[] 3 then %east
				NewDirection = east
				NewPosition = pt(x:X y:Y-1)
			else %something went wrong
				{ERR 'Randomized out-of-bound'}
				NewPosition = null
			end
			
			if NewPosition == null then
				{MoveAway Position VisitedSquares Target}
			else
				if {Not {PositionGetsYouCloser Position NewPosition Target}} then
					if {PositionIsValid NewPosition} andthen {SquareNotVisited NewPosition VisitedSquares} then
						%return
						NewPosition#NewDirection
					else
						{MoveAway Position VisitedSquares Target}
					end
				else
					if {OS.rand} mod 10 == 0 then %use it anyway
						if {PositionIsValid NewPosition} andthen {SquareNotVisited NewPosition VisitedSquares} then
							%return
							NewPosition#NewDirection
						else
							{MoveAway Position VisitedSquares Target}
						end
					else
						{MoveAway Position VisitedSquares Target}
					end
				end
			end
		else %something went wrong
			{ERR 'Target or Position has an invalid format'#Target#Position}
			null#null
		end
	end
	
	% @PositionGetsYouCloser : Returns @true if @NewPosition gets you closer to @Target
	%                          !!! @NewPosition should ALWAYS be one square next to @Position !!!
	fun {PositionGetsYouCloser Position NewPosition Target}
		case Position#NewPosition#Target
		of pt(x:X y:Y)#pt(x:NewX y:NewY)#pt(x:XTarget y:YTarget) then
			if NewX == X then
				if YTarget > Y then
					if NewY > Y then true
					else false
					end
				else %YTarget < Y
					if NewX < Y then true
					else false
					end
				end
			else %NewY == Y
				if XTarget > X then
					if NewX > X then true
					else false
					end
				else %XTarget < X
					if NewX < X then true
					else false
					end
				end
			end
		else %something went wrong
			{ERR 'Position, NewPosition or Target have an invalid format'#Position#NewPosition#Target}
			true %because we have to return something
		end
	end
	
	%============== Procedures regarding weapons ===================
	% @LoadWeapon : Add a loading charge to one type of weapon
	%               Returns the new weapons state and a weapon type if a new weapon is available
	fun {LoadWeapon WeaponsState TrackingInfo}
		case WeaponsState
		of stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading lastDroneFired:Drone sonarsLoading:SonarsLoading) then
			NewWeaponsState
			NewWeaponAvailable
			WeaponToLoad = {ChooseWhichToLoad TrackingInfo}
		in
			case WeaponToLoad
			of mine then
				NewWeaponsState = stateWeapons(minesLoading:MinesLoading+1 minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading lastDroneFired:Drone sonarsLoading:SonarsLoading)
				if (MinesLoading+1) mod Input.mine == 0 then
					NewWeaponAvailable = mine
				else
					NewWeaponAvailable = null
				end
			[] missile then
				NewWeaponsState = stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading+1 dronesLoading:DronesLoading lastDroneFired:Drone sonarsLoading:SonarsLoading)
				if (MissilesLoading+1) mod Input.missile == 0 then
					NewWeaponAvailable = missile
				else
					NewWeaponAvailable = null
				end
			[] drone then
				NewWeaponsState = stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading+1 lastDroneFired:Drone sonarsLoading:SonarsLoading)
				if (DronesLoading+1) mod Input.drone then
					NewWeaponAvailable = drone
				else
					NewWeaponAvailable = null
				end
			[] sonar then
				NewWeaponsState = stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading lastDroneFired:Drone sonarsLoading:SonarsLoading+1)
				if (SonarsLoading+1) mod Input.sonar then
					NewWeaponAvailable = sonar
				else
					NewWeaponAvailable = null
				end
			else %something went wrong
				{ERR 'WeaponToLoad has an invalid format'#WeaponToLoad}
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
	
	% @ChooseWhichToLoad : Chooses which type of weapon to load on basis of the tracking information
	fun {ChooseWhichToLoad TrackingInfo}
		if TrackingInfo == nil then
			sonar
		else
			fun {Loop TrackingInfo}
				case TrackingInfo
				of trackingInfo(id:ID surface:Surface x:X y:Y)|Remainder then
					case X#Y
					of certain(_)#certain(_) then
						missile
					else
						{Loop Remainder}
					end
				[] nil then drone
				else %something went wrong
					{ERR 'TrackingInfo has an invalid format'#TrackingInfo}
					drone
				end
			end
		in
			{Loop TrackingInfo}
		end
	end
	
	% @ChooseWhichToFire : If a weapon is available and @this wants to shoot
	%                      somewhere, decides which weapon to use and
	%                      returns it
	fun {ChooseWhichToFire WeaponsState TrackingInfo}
		fun {Loop TrackingInfo}
			case TrackingInfo
			of trackingInfo(id:ID surface:Surface x:X y:Y)|Remainder then
				case X#Y
				of certain(_)#certain(_) then
					missile
				else
					{Loop Remainder}
				end
			[] nil then drone
			else %something went wrong
				{ERR 'TrackingInfo has an invalid format'#TrackingInfo}
				drone
			end
		end
	in
		case WeaponsState
		of stateWeapons(minesLoading:MinesLoading minesPlaced_ missilesLoading:MissilesLoading dronesLoading:DronesLoading lastDroneFired:_ sonarsLoading:SonarsLoading) then
			% Choose a type of weapon to try and fire
			WeaponTypeToFire
		in
			if TrackingInfo == nil then
				WeaponTypeToFire = sonar
			else
				WeaponTypeToFire = {Loop TrackingInfo}
			end
			
			case WeaponTypeToFire
			% If this type of weapon is available, fire it
			of mine then if MinesLoading div Input.mine > 0 then mine else null end
			[] missile then 
				if MissilesLoading div Input.missile > 0 then missile
				elseif (DronesLoading div Input.drone) > 0 then drone
				else null
				end
			[] drone then if DronesLoading div Input.drone > 0 then drone else null end
			[] sonar then if SonarsLoading div Input.sonar > 0 then sonar else null end
			else null
			end
		else %something went wrong
			{ERR 'WeaponsState has an invalid format'#WeaponsState}
			null %because we have to return something
		end
	end
	
	% @FireWeapon : Fires a weapon of type @WeaponType
	%               Returns the weapon fired (with parameters) and
	%               the new weapons's state
	fun {FireWeapon WeaponType PlayerState}
		case PlayerState
		of stateBasicAI(life:_ locationState:stateLocation(pos:PlayerPosition dir:_ visited:_) weaponsState:WeaponsState tracking:TrackingInfo) then
			case WeaponType
			of mine then
				NewMine = {PlaceMine PlayerPosition WeaponsState TrackingInfo}
			in
				if NewMine == null then
					null#WeaponsState
				else
					NewMine#{UpdateWeaponsState WeaponsState NewMine}
				end
			[] missile then
				MissileFired = {FireMissile PlayerPosition WeaponsState TrackingInfo}
			in
				if MissileFired == null then
					null#WeaponsState
				else
					MissileFired#{UpdateWeaponsState WeaponsState WeaponType}
				end
			[] drone then
				DroneFired = {FireDrone TrackingInfo}
			in
				DroneFired#{UpdateWeaponsState WeaponsState DroneFired}
			[] sonar then
				{FireSonar}#{UpdateWeaponsState WeaponsState WeaponType}
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
		of stateWeapons(miensLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading lastDroneFired:Drone sonarsLoading:SonarsLoading) then
			case WeaponFired
			of mine(_) then stateWeapons(minesLoading:MinesLoading-Input.mine minesPlaced:WeaponFired|MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading lastDroneFired:Drone sonarsLoading:SonarsLoading)
			[] missile then stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading-Input.missile dronesLoading:DronesLoading lastDroneFired:Drone sonarsLoading:SonarsLoading)
			[] drone(row:_) then stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading-Input.drone lastDroneFired:WeaponFired sonarsLoading:SonarsLoading)
			[] drone(column:_) then stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading-Input.drone lastDroneFired:WeaponFired sonarsLoading:SonarsLoading)
			[] sonar then stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading lastDroneFired:Drone sonarsLoading:SonarsLoading-Input.sonar)
			else WeaponsState
			end
		else %something went wrong
			{ERR 'WeaponsState has an invalid format'#WeaponsState}
			WeaponsState %because we have to return something
		end
	end
	
	% @PlaceMine : Creates a mine at close enough to the target to damage it
	%              but in the range from the player where it is allowed to place mines
	%              and away enough to not damage the player
	%              Returns the created mine (with the position of setup as a parameter)
	fun {PlaceMine PlayerPosition WeaponsState TrackingInfo}
		Target = {GetTarget TrackingInfo}
		DistancePlayerTarget = {Abs (PlayerPosition.x-Target.x)}+{Abs (PlayerPosition.y-Target.y)}
	in
		% If this player is too close to the target, don't fire
		if DistancePlayerTarget < 2 then
			%return
			null
		else
			%Find the square to place the mine on and that will damage the target most heavily
			DistanceExplosionTarget#FiringPosition = {GetReachableExplosionPosition PlayerPosition Target mine}
		in
			if DistanceExplosionTarget == much orelse FiringPosition == null then
				% Too far => don't place the mine
				null
			elseif DistanceExplosionTarget == 0 then
				% Target is reachable => place the mine
				missile(FiringPosition)
			else %DistanceExplosionTarget == 1
				% Target is reachable but may be more damaged if we fire on the next turn
				% => place it only if we will have another mine ready on the next turn
				case WeaponsState
				of stateWeapons(minesLoading:Loading minesPlaced:_ missilesLoading:_ dronesLoading:_ sonarsLoading:_) then
					if (Loading+1) div Input.mine then
						missile(FiringPosition)
					else %wait to be closer to place the mine
						null
					end
				else %something went wrong
					{ERR 'WeaponsState has an invalid format'#WeaponsState}
					missile(FiringPosition)
				end
			end
		end
	end
	
	% @FireMissile : Creates a missile set to explode close enough to the target player
	%                but in the range from the player where it is allowed to make it explode
	%                and away enough to not damage the player
	%                Returns the created missile (with the position of explosion as a parameter)
	%                or @null if it decided not to fire
	fun {FireMissile PlayerPosition WeaponsState TrackingInfo}
		Target = {GetTarget TrackingInfo}
		DistancePlayerTarget = {Abs (PlayerPosition.x-Target.x)}+{Abs (PlayerPosition.y-Target.y)}
	in
		% If this player is too close to the target, don't fire
		if DistancePlayerTarget < 2 then
			%return
			null
		else
			%Find the square to fire the missile to and that will damage the target most heavily
			DistanceExplosionTarget#FiringPosition = {GetReachableExplosionPosition PlayerPosition Target missile}
		in
			if DistanceExplosionTarget == much orelse FiringPosition == null then
				% Too far => don't fire a missile
				null
			elseif DistanceExplosionTarget == 0 then
				% Target is reachable => fire
				missile(FiringPosition)
			else %DistanceExplosionTarget == 1
				% Target is reachable but may be more damaged if we fire on the next turn
				% => fire only if we will have another missile ready on the next turn
				case WeaponsState
				of stateWeapons(minesLoading:_ minesPlaced:_ missilesLoading:Loading dronesLoading:_ sonarsLoading:_) then
					if (Loading+1) div Input.missile then
						missile(FiringPosition)
					else %wait to be closer to fire
						null
					end
				else %something went wrong
					{ERR 'WeaponsState has an invalid format'#WeaponsState}
					missile(FiringPosition)
				end
			end
		end
	end
	
	% @GetReachableExplosionPosition : Returns the square which this player can explode a weapon
	%                                  to make the greatest damage possible to @Target
	%                                  Returns the distance to @Target as well
	%                                  If @Target is too far away, returns much#null
	fun {GetReachableExplosionPosition PlayerPosition Target WeaponType}
		if {SquareIsReachableForExplosion PlayerPosition Target WeaponType} then
			0#Target
		else
			% compute the 2 positions that are a little closer to the player
			CloserPositionAlongX
			CloserPositionAlongY
		in
			if Target.x > PlayerPosition.x then
				CloserPositionAlongX = pt(x:(Target.x)-1 y:Target.y)
			elseif Target.x < PlayerPosition.x then
				CloserPositionAlongX = pt(x:(Target.x)+1 y:Target.y)
			else
				CloserPositionAlongX = Target
			end
			
			if Target.y > PlayerPosition.y then
				CloserPositionAlongY = pt(x:Target.x y:(Target.y)-1)
			elseif Target.y < PlayerPosition.y then
				CloserPositionAlongY = pt(x:Target.x y:(Target.y)+1)
			else
				CloserPositionAlongY = Target
			end
			
			if {SquareIsReachableForExplosion PlayerPosition CloserPositionAlongX WeaponType} then
				1#CloserPositionAlongX
			elseif {SquareIsReachableForExplosion PlayerPosition CloserPositionAlongY WeaponType} then
				1#CloserPositionAlongY
			else
				much#null
			end
		end
	end
	
	% @SquareIsReachableForExplosion : Returns @true if @Target can be reached from @PlayerPosition
	%                                  when firing a weapon of type @WeaponType
	fun {SquareIsReachableForExplosion PlayerPosition Target WeaponType}
		Distance = {Abs (PlayerPosition.x-Target.x)}+{Abs (PlayerPosition.y-Target.y)}
	in
		case WeaponType
		of mine then
			if Distance >= Input.minDistanceMine andthen Distance =< Input.maxDistanceMine then true
			else false
			end
		[] missile then
			if Distance >= Input.minDistanceMissile andthen Distance =< Input.maxDistanceMissile then true
			else false
			end
		else %something went wrong
			{ERR 'WeaponType has an invalid format'#WeaponType}
			false %because we have to return something
		end
	end
	
	% @FireDrone : Creates a drone (looking at a row or a column)
	%              that search for a player whose position is supposed
	%              Returns this drone (with which row or column it is watching as a parameter)
	fun {FireDrone TrackingInfo}
		% The next function returns the first supposed position found in @TrackingInfo
		fun {Loop TrackingInfo}
			case TrackingInfo
			of Track|Remainder then
				case Track
				of trackingInfo(id:_ surface:_ x:X y:Y) then
					case X
					of supposed(_) then
						pos(x:X y:Y)
					else
						case Y
						of supposed(_) then
							pos(x:X y:Y)
						else
							{Loop Remainder}
						end
					end
				else %something went wrong
					{ERR 'An element in TrackingInfo has an invalid format'#TrackingInfo}
					{Loop Remainder}
				end
			[] nil then %no supposed position found
				null
			else %something went wrong
				{ERR 'TrackingInfo has an invalid format'#TrackingInfo}
				null
			end
		end
		
		TargetPosition = {Loop TrackingInfo}
	in
		if TargetPosition == null then %this shouldn't happen, but if it does, fire randomly
			case {OS.rand} mod 2
			of 0 then %row
				drone(row:({OS.rand} mod Input.nColumn)+1)
			[] 1 then %column
				drone(column:({OS.rand} mod Input.nRow)+1)
			else %something went wrong
				{ERR 'Randomized out-of-bounds'}
				drone(row:({OS.rand} mod Input.nRow)+1) %because we have to return something valid
			end
		else
			case TargetPosition
			of pos(x:X y:Y) then
				%Choose randomly between @X and @Y (but fire only if it's a supposed coordinate)
				case {OS.rand} mod 2
				of 0 then
					case X
					of supposed(Column) then
						drone(column:Column)
					else
						case Y
						of supposed(Row) then
							drone(row:Row)
						else %something went wrong
							{ERR 'TargetPosition was returned as an incorrect value'#TargetPosition}
							{FireDrone TrackingInfo}
						end
					end
				[] 1 then
					case Y
					of supposed(Row) then
						drone(row:Row)
					else
						case X
						of supposed(Column) then
							drone(column:Column)
						else %something went wrong
							{ERR 'TargetPosition was returned as an incorrect value'#TargetPosition}
							{FireDrone TrackingInfo}
						end
					end
				else %something went wrong
					{ERR 'Randomized out-of-bound'}
					{FireDrone TrackingInfo}
				end
			else %something went wrong
				{ERR 'TargetPosition returned an invalid formatted value'#TargetPosition}
				drone(column:({OS.rand} mod Input.nColumn)+1) %because we have to return something
			end
		end
	end
	
	% @FireSonar : Creates a sonar and returns it
	fun {FireSonar}
		sonar
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
		of stateWeapons(minesLoading:MinesLoading minesPlaced:MinesPlaced missilesLoading:MissilesLoading dronesLoading:DronesLoading lastDroneFired:Drone sonarsLoading:SonarsLoading) then
			case {Loop MinesPlaced nil}
			of Mine#RemainingMines then
				Mine#stateWeapons(minesLoading:MinesLoading minesPlaced:RemainingMines missilesLoading:MissilesLoading dronesLoading:DronesLoading lastDroneFired:Drone sonarsLoading:SonarsLoading)
			end
		else %something went wrong
			{ERR 'WeaponsState has an invalid format'#WeaponsState}
			null#WeaponsState %because we have to return something
		end
	end
	
	%========== Procedures about taking damages =================
	% @ExplosiongHappened : Computes the message to send to the game controller when something explode
	%                       at position @ExplodePosition and updates the player's state
	fun {ExplosionHappened ExplosionPosition PlayerID State}
		Message
		UpdatedState
	in
		case {ComputeDamage ExplosionPosition State}
		of DamageTaken#NewState then
			if DamageTaken == 0 then
				% No damage => no cchanges
				Message = null
				UpdatedState = State
			else
				% Damage taken => change state and send message
				case NewState
				of stateBasicAI(life:CurrentLife locationState:LocationState weaponsState:WeaponsState tracking:TrackingInfo) then
					if CurrentLife =< 0 then %dead
						Message = sayDeath(PlayerID)
						UpdatedState = stateBasicAI(life:0 locationState:LocationState weaponsState:WeaponsState tracking:TrackingInfo)
					else
						Message = sayDamageTaken(PlayerID DamageTaken CurrentLife)
						UpdatedState = stateBasicAI(life:CurrentLife locationState:LocationState weaponsState:WeaponsState tracking:TrackingInfo)
					end
				else %something went wrong
					{ERR 'ComputeDamage returned a state with invalid format'#NewState}
					%don't take damges
					Message = null
					UpdatedState = State
				end
			end
		else %something went wrong
			{ERR 'ComputeDamage returned somthing with an invalid syntax'}
			%don't take damages
			Message = null
			UpdatedState = State
		end
		%return
		Message#UpdatedState
	end
	
	%======== Procedures about other players' detections ================
	% @FakeCoordForSonars : Generates coordinates that will be sent
	%                       to another player's sonar detection
	%                       These coordinates will have one coordinate right
	%                       and the other wrong (randomly chosen)
	fun {FakeCoordForSonars State}
		case State
		of stateBasicAI(life:_ locationState:stateLocation(pos:PlayerPosition dir:_ visited:_) weaponsState:_ tracking:_) then
			%Choose which coordinate to fake
			case  {OS.rand} mod 2
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
			pt(x:0 y:0) %because we have to return somthing with a valid format
		end
	end
	
	% @PlayerMoved : Updates the information of tracking for the player @ID
	%                when it moves in the direction @Direction
	%
	%                We update when the type of coordinate is @supposed or @certain.
	%                If the update produces an invalid coordinate (out of the grid),
	%                we transform a @supposed in @unknown and a @certain in @supposed.
	fun {PlayerMoved TrackingInfo ID Direction}
		fun {Loop TrackingInfo ID Direction Acc}
			case TrackingInfo
			of Track|Remainder then
				case Track
				of trackingInfo(id:CurrentID surface:Surface x:X y:Y) then
					if CurrentID == ID then % This is the player's info that we have to update
						if Direction == north orelse Direction == south then %moving along X
							case X
							of supposed(Coord) then
								NewCoord
							in
								if Direction == south then NewCoord = Coord+1
								else NewCoord = Coord-1
								end
								
								if {CoordIsOnGrid NewCoord x} then
									%return
									{Append {Append Acc trackingInfo(id:ID surface:false x:supposed(NewCoord) y:Y)|nil} TrackingInfo}
								else
									%return
									{Append {Append Acc trackingInfo(id:ID surface:false x:unknown y:Y)|nil} TrackingInfo}
								end
							[] certain(Coord) then
								NewCoord
							in
								if Direction == south then NewCoord = Coord+1
								else NewCoord = Coord-1
								end
								
								if {CoordIsOnGrid NewCoord x} then
									%return
									{Append {Append Acc trackingInfo(id:ID surface:false x:certain(NewCoord) y:Y)|nil} TrackingInfo}
								else
									%return
									{Append {Append Acc trackingInfo(id:ID surface:false x:supposed(Coord) y:Y)|nil} TrackingInfo}
								end
							else % coord is @unknown => don't do anything
								%return
								{Append {Append Acc Track|nil} TrackingInfo}
							end
						elseif Direction == west orelse Direction == east then%moving along Y
							case Y
							of supposed(Coord) then
								NewCoord
							in
								if Direction == east then NewCoord = Coord+1
								else NewCoord = Coord-1
								end
								
								if {CoordIsOnGrid NewCoord y} then
									%return
									{Append {Append Acc trackingInfo(id:ID surface:false x:X y:supposed(NewCoord))|nil} TrackingInfo}
								else
									%return
									{Append {Append Acc trackingInfo(id:ID surface:false x:X y:unknown)|nil} TrackingInfo}
								end
							[] certain(Coord) then
								NewCoord
							in
								if Direction == east then NewCoord = Coord+1
								else NewCoord = Coord-1
								end
								
								if {CoordIsOnGrid NewCoord y} then
									%return
									{Append {Append Acc trackingInfo(id:ID surface:false x:X y:certain(NewCoord))|nil} TrackingInfo}
								else
									%return
									{Append {Append Acc trackingInfo(id:ID surface:false x:X y:supposed(Coord))|nil} TrackingInfo}
								end
							else %coord is @unknown => don't do anything
								%return
								{Append {Append Acc Track|nil} TrackingInfo}
							end
						elseif Direction == surface then
							%return
							{Append {Append Acc trackingInfo(id:ID surface:true x:X y:Y)} TrackingInfo}
						else %something went wrong
							{ERR 'Direction given is invalid'#Direction}
							{Append {Append Acc Track|nil} TrackingInfo}
						end
					else %Not the current player
						{Loop Remainder ID Direction {Append Acc Track|nil}}
					end
				else %something went wrong
					{ERR 'An element of TrackingInfo has an invalid format'#Track}
					{Loop Remainder ID Direction {Append Acc Track|nil}}
				end
			[] nil then Acc
			else %something went wrong
				{ERR 'TrackingInfo has an invalid format'}
				nil
			end
		end
	in
		{Loop TrackingInfo ID Direction nil}
	end
	
	% @PlayerMadeSurface : Update the tracking info when Player @ID made surface
	fun {PlayerMadeSurface TrackingInfo ID}
		fun {Loop TrackingInfo ID Acc}
			case TrackingInfo
			of Track|Remainder then
				case Track
				of trackingInfo(id:CurrentID surface:Surface x:X y:Y) then
					if CurrentID == ID then %found the player's info to update
						%return
						{Append {Append Acc trackingInfo(id:CurrentID surface:true x:X y:Y)|nil} TrackingInfo}
					else
						{Loop Remainder ID {Append Acc Track|nil}}
					end
				else %something went wrong
					{ERR 'An element in TrackingInfo has an invalid format'#Track}
					{Loop Remainder ID {Append Acc Track|nil}}
				end
			[] nil then %player was not found => add it
				%return
				{Append Acc trackingInfo(id:ID surface:true x:unknown y:unknown)|nil}
			else %something went wrong
				{ERR 'TrackingInfo has an invalid format'#TrackingInfo}
				%return
				TrackingInfo
			end
		end
	in
		{Loop TrackingInfo ID nil}
	end
	
	% @DroneAnswered : A drone came back with the answers @ID and @Answer
	%                  Updates the tracking info and returns it
	fun {DroneAnswered TrackingInfo ID Answer}
		fun {Loop TrackingInfo ID Answer Acc}
			case TrackingInfo
			of Track|Remainder then
				case Track
				of trackingInfo(id:CurrentID surface:Surface x:X y:Y) then
					if CurrentID == ID then %found the player's info to update
						UpdatedX UpdatedY
						UpdatedTrack = trackingInfo(id:ID surface:Surface x:UpdatedX y:UpdatedY)
					in
						case Answer
						of column(XDrone) then
							case X
							of	unknown then
								UpdatedX = certain(XDrone)
							[] supposed(_) then
								UpdatedX = certain(XDrone)
							else %already certain
								UpdatedX = X
							end
							
							UpdatedY = Y
						[] row(YDrone) then
							case Y
							of unknown then
								UpdatedY = certain(YDrone)
							[] supposed(_) then
								UpdatedY = certain(YDrone)
							else %already certain
								UpdatedY = Y
							end
							
							UpdatedX = X
						else %something went wront
							{ERR 'Answer given to drone has an invalid format'#Answer}
							UpdatedX = X
							UpdatedY = Y
						end
						
						%return
						{Append {Append Acc UpdatedTrack|nil} TrackingInfo}
					else
						{Loop Remainder ID Answer {Append Acc Track|nil}}
					end
				else %something went wrong
					{ERR 'An element in TrackingInfo has an invalid format'#Track}
					{Loop Remainder ID Answer {Append Acc Track|nil}}
				end
			[] nil then %Player @ID wasn't found => add it
				case Answer
				of pt(x:X y:Y) then
					%return
					{Append Acc trackingInfo(id:ID surface:unknown x:X y:Y)|nil}
				else %something went wrong
					{ERR 'Answer given to drone has an invalid format'#Answer}
					%return
					Acc
				end
			end
		end
	in
		{Loop TrackingInfo ID Answer nil}
	end
	
	% @SonarAnswered : A sonar came back with the answers @ID and @Answer
	%                  Updates the tracking info and returns it
	fun {SonarAnswered TrackingInfo ID Answer}
		fun {Loop TrackingInfo ID Answer Acc}
			case TrackingInfo
			of Track|Remainder then
				case Track
				of trackingInfo(id:CurrentID surface:Surface x:X y:Y) then
					if CurrentID == ID then %found the player's info to update
						UpdatedX UpdatedY
						UpdatedTrack = trackingInfo(id:ID surface:Surface x:UpdatedX y:UpdatedY)
					in
						case Answer
						of pt(x:XSonar y:YSonar) then
							case X
							of unknown then
								UpdatedX = XSonar
							[] supposed(_) then
								UpdatedX = XSonar %TODO should we really update this?
							else %certain => don't update
								UpdatedX = X
							end
							
							case Y
							of unknown then
								UpdatedY = YSonar
							[] supposed(_) then
								UpdatedY = YSonar %TODO should we really update this?
							else %certain => don't update
								UpdatedY = Y
							end
							
							% Add this new track in the tracking info
							%return
							{Append {Append Acc UpdatedTrack|nil} TrackingInfo}
						else %something went wrong
							{ERR 'Answer given to sonar has an invalid format'#Answer}
							%return
							{Append Acc TrackingInfo}
						end
					else
						{Loop Remainder ID Answer {Append Acc Track|nil}}
					end
				else %something went wrong
					{ERR 'An element of TrackingInfo has an invalid format'#Track}
					{Loop Remainder ID Answer {Append Acc Track|nil}}
				end
			[] nil then %Player @ID was not found => add it
				case Answer
				of pt(x:X y:Y) then
					%return
					{Append Acc trackingInfo(id:ID surface:unknown x:X y:Y)|nil}
				else %something went wrong
					{ERR 'Answer given to sonar has an invalid format'#Answer}
					%return
					Acc
				end
			else %something went wrong
				{ERR 'TrackingInfo has an invalid format'#TrackingInfo}
				nil
			end
		end
	in
		{Loop TrackingInfo ID Answer nil}
	end
	
	% @PlayerDead : Player @ID id dead
	%               Removes the info about it in the tracking info and
	%               returns the updated tracking info
	fun {PlayerDead ID TrackingInfo}
		fun {Loop ID TrackingInfo Acc}
			case TrackingInfo
			of Track|Remainder then
				case Track
				of trackingInfo(id:CurrentID surface:_ x:_ y:_) then
					if CurrentID == ID then %remove this track
						{Loop ID Remainder Acc}
					else
						{Loop ID Remainder {Append Acc Track|nil}}
					end
				else %something went wrong
					{ERR 'An element in TrackingInfo has an invalid format'#Track}
					{Loop ID Remainder {Append Acc Track|nil}}
				end
			[] nil then Acc
			end
		end
	in
		{Loop ID TrackingInfo nil}
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
	
	% @CoordIsOnGrid :checks if @Coord along the axis @Axis is on the grid
	fun {CoordIsOnGrid Coord Axis}
		if Axis == x then
			if Coord =< 0 orelse Coord > Input.nRow then false
			else true
			end
		elseif Axis == y then
			if Coord =< 0 orelse Coord > Input.nColumn then false
			else true
			end
		else %something went wrong
			{ERR 'Tried to check a coordinate in an invalid axis'#Axis}
			false		
		end
	end
end
