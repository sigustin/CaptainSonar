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
	
	PositionIsValid
in
	%============== Make the port object ========================
	% @StartPlayer : Initializes the player (ID, color, position, etc.)
	%                and create the port object
	fun {StartPlayer Color ID}
		Stream
		Port
	in		
		{NewPort Stream Port}
		thread
			{TreatStream Stream ID Color stateRandomAI(life:Input.maxDamage pos:{InitPosition} dir:surface)}
		end
		Port
	end
	
	% @TreatStream : Loop that checks if some new messages are sent to the port 
	%                and treats them
	%                The attributes of this procedure keep track of the state of this port object
	%                @ID and @Color should never be changed
	%                @State contains every attribute of the current port object that could change
	%                       (thus here : position, direction, life of the player, etc.)
	proc {TreatStream Stream ID Color State}
		case Stream
		of Msg|S2 then
			{TreatStream S2 ID Color {Behavior Msg ID Color State}}
		else skip %something went wrong
		end
	end
	
	%=============== Manage the messages ========================
	% @Behavior : Behavior for every type of message sent on the port
	%             Returns the new state
	fun {Behavior Msg PlayerID PlayerColor State}
		ReturnedState
	in
		case State
		of stateRandomAI(life:PlayerLife pos:PlayerPosition dir:PlayerDirection) then
			case Msg
			of initPosition(?ID ?Position) then
				ID = PlayerID
				Position = PlayerPosition
				%return
				ReturnedState = stateRandomAI(life:PlayerLife pos:PlayerPosition dir:PlayerDirection)
			[] move(?ID ?Position ?Direction) then
				case {Move posState(pos:PlayerPosition dir:PlayerDirection visited:nil)}
				of posState(pos:NewPosition dir:NewDirection visited:VisitedSquares) then
					ID = PlayerID
					Position = NewPosition
					Direction = NewDirection
					%return
					ReturnedState = stateRandomAI(life:PlayerLife pos:NewPosition dir:NewDirection)
				else
					ID = null
					%return
					ReturnedState = stateRandomAI(life:PlayerLife pos:PlayerPosition dir:PlayerDirection)
				end
			 %[] dive then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] chargeItem(ID KindItem) then
				{Browser.browse 'coucou pas encore implémenté'}
				%...
			 %[] fireItem(ID KindFire) then
			%	{Browser.browse 'coucou pas encore implémenté'}
				%...
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
	% @Move : move randomly of one square in any direction except if the current player is at the surface
	% TODO keep track of all the squares visited since last surface phase (we can't go twice on the same square on the same diving phase)
	fun {Move PositionState}
		case PositionState
		of posState(pos:Position dir:Direction visited:SquaresVisited) then
			%if Direction == surface then
				%return
			%	posState(pos:Position dir:Direction visited:SquaresVisited)%BUG expression at statement position
			%end
			NewPosition = pt(x:Position.x+({OS.rand} mod 2) y:Position.y+({OS.rand} mod 2))
		in
			if {PositionIsValid NewPosition} then
				%return
				posState(pos:NewPosition dir:Direction visited:SquaresVisited)
			else {Move PositionState}
			end
		else null
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
