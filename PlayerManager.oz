%% PlayerManager.oz %%
%% Selection of the player following the type of players given  in the input file

functor
import
	Player034RandomAI
   Player034BasicAI
	PlayerBasicAI
   %%add player here and in the port generation
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun {PlayerGenerator Kind Color ID} %@Kind must contain something only with minuscules
      case Kind
	 	of player034randomai then 
	 		{Player034RandomAI.portPlayer Color ID}
	 	[] player034basicai then
	 		{Player034BasicAI.portPlayer Color ID}
		[] basicAI then
			{PlayerBasicAI.portPlayer Color ID}
	 	else null
      end
   end
end
