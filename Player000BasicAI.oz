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
