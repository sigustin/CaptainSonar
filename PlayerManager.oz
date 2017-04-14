functor
import
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
      of player001BasicRandom then
	 {Player001BasicRandom.portPlayer Color ID}
      [] player002BasicRandom then
	 {Player002BasicRandom.portPlayer ColorID}
      end
   end
end