functor
import
   Input
export
   portPlayer:StartPlayer
define
   StartPlayer
   TreatStream
in
   fun {StartPlayer Color ID}
      Stream
      Port
   in
      {NewPort StreamPort}
      thread
	 {TreatStream Stream TODO}
      end
      Port
   end

   proc {TreatStream Stream TODO}
      case Stream of
	 M|T then
	 case M of
	    initPosition(ID Position) then
	    %...
	 [] move(ID Position Direction) then
	    %...
	 [] dive then
	    %...
	 [] chargeItem(ID KindItem) then
	    %...
	 [] fireItem(ID KindFire) then
	    %...
	 [] fireMine(ID KindItem) then
	    %...
	 [] isSurface(ID Answer) then
	    %...
	 [] sayMove(ID Direction) then
	    %...
	 [] saySurface(ID) then
	    %...
	 [] sayCharge(ID KindItem) then
	    %...
	 [] sayMinePlaced(ID) then
	    %...
	 [] sayMissileExplode(ID Position Message) then
	    %...
	 [] sayMineExplode(ID Position Message) then
	    %...
	 [] sayPassingDrone(Drone ID Answer) then
	    %...
	 [] sayAnswerDrone (Drone ID Answer) then
	    %...
	 [] sayPassingSonar(ID Answer) then
	    %...
	 [] sayAnswerSonar(ID Answer) then
	    %...
	 [] sayDeath(ID) then
	    %...
	 [] sayDeath(ID) then
	    %...
	 [] sayDamageTaken(ID Damage LifeLeft) then
	    %...
	 end
      end
   end
end
