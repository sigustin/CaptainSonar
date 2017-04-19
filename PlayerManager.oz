%% PlayerManager.oz %%
%% Selection of the player following the type of players given  in the input file

functor
import
	Player000RandomAI
   Player000BasicRandom
   Player000BasicAI
   %%add player here and in the port generation
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun {PlayerGenerator Kind Color ID} %@Kind must contain something only with minuscules
      case Kind
      of player000basicrandom then
	 		{Player000BasicRandom.portPlayer Color ID}
	 	[] player000randomai then 
	 		{Player000RandomAI.portPlayer Color ID}
	 	[] player000basicai then
	 		{Player000BasicAI.portPlayer Color ID}
	 	else null
      end
   end
end
