%% PlayerManager.oz %%
%% Selection of the player following the type of players given  in the input file

functor
import
	Player000RandomAI
   Player000BasicRandom
   %%add player here and in the port generation
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun {PlayerGenerator Kind Color ID}
      case Kind
      of player000basicrandom then
	 		{Player000BasicRandom.portPlayer Color ID}
	 	[] player000randomai then 
	 		{Player000RandomAI.portPlayer Color ID}
	 	else null
      end
   end
end
