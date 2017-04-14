%% PlayerManager.oz %%
%% Selection of the player following the type of players given  in the input file

functor
import
	Player000RandomAI
   Player001BasicRandom
   Player002BasicRandom
   %%add player here and in the port generation
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun {PlayerGenerator Kind Color ID}
      case Kind
      of player000basicrandom then
	 		{Player001BasicRandom.portPlayer Color ID}
	 	[] player000randomai then 
	 		{Player000RandomAI.portPlayer Color ID}
	 	else null
      end
   end
end
