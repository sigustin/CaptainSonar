%% Input.oz %%
%% All the variables to set up the game

functor
import
   OS
   Browser
export
   isTurnByTurn:IsTurnByTurn
   nRow:NRow
   nColumn:NColumn
   map:Map
   nbPlayer:NbPlayer
   players:Players
   colors:Colors
   thinkMin:ThinkMin
   thinkMax:ThinkMax
   turnSurface:TurnSurface
   maxDamage:MaxDamage
   missile:Missile
   mine:Mine
   sonar:Sonar
   drone:Drone
   minDistanceMine:MinDistanceMine
   maxDistanceMine:MaxDistanceMine
   minDistanceMissile:MinDistanceMissile
   maxDistanceMissile:MaxDistanceMissile
define
   IsTurnByTurn
   NRow
   NColumn
   Map
   NbPlayer
   Players
   Colors
   ThinkMin
   ThinkMax
   TurnSurface
   MaxDamage
   Missile
   Mine
   Sonar
   Drone
   MinDistanceMine
   MaxDistanceMine
   MinDistanceMissile
   MaxDistanceMissile
   MakeMap
in

%%%% Style of game %%%%

   IsTurnByTurn = false

%%%% Description of the map %%%%

   NRow = 10
   NColumn = 10

   fun {MakeMap}
      Map

      fun {MakeRowN R}
         fun {MakeColumnN C}
            if C==0 then
               nil
            else
               pt(R C)|{MakeColumnN C-1}
            end
         end
      in
         if R==0 then
            nil
         else
            {MakeColumnN NColumn}|{MakeRowN R-1}
         end
      end

      fun {MakeRow I}
         fun {MakeColumn I}
            if I==0 then
               nil
            else
               if ({OS.rand} mod 10)==1 then
                  1|{MakeColumn I-1}
               else
                  0|{MakeColumn I-1}
               end
            end
         end
      in
         if I==0 then
            nil
         else
            {MakeColumn NColumn}|{MakeRow I-1}
         end
      end

      fun {Set Val R C M}
         fun {SetC C Row}
            case Row
            of P|NextRow then
               if C==0 then
                  Val|{SetC C-1 NextRow}
               else
                  P|{SetC C-1 NextRow}
               end
            [] nil then
               nil
            end
         end
      in
         case M
         of Row|NextM then
            if R==0 then
               {SetC C Row}|{Set Val R-1 C NextM}
            else
               Row|{Set Val R-1 C NextM}
            end
         [] nil then
            nil
         end
      end

      fun {Pass R C Passed}
         fun {PassC C Row}
            case Row
            of P|NextRow then
               if C==0 then
                  1|{PassC C-1 NextRow}
               else
                  P|{PassC C-1 NextRow}
               end
            [] nil then
               nil
            end
         end
      in
         case Passed
         of Row|NextPassed then
            if R==0 then
               {PassC C Row}|{Pass R-1 C NextPassed}
            else
               Row|{Pass R-1 C NextPassed}
            end
         [] nil then
            nil
         end
      end
      fun {IsGood R C Passed}
         if R<0 then
            false
         elseif R>=NRow then
            false
         elseif C<0 then
            false
         elseif C>=NColumn then
            false
         else
            {Nth {Nth Map R+1} C+1}==0
         end
      end

      fun {DFS R C Passed}
         Passed1
         Passed2
         Passed3
         Passed4
         Passed5
      in
         Passed1 = {Pass R C Passed}
         if {IsGood R+1 C+1 Passed1} then
            Passed2 = {DFS R+1 C+1 Passed1}
         else
            Passed2 = Passed1
         end
         if {IsGood R C+1 Passed2} then
            Passed3 = {DFS R C+1 Passed2}
         else
            Passed3 = Passed2
         end
         if {IsGood R C-1 Passed3} then
            Passed4 = {DFS R C-1 Passed3}
         else
            Passed4 = Passed3
         end
         if {IsGood R-1 C-1 Passed4} then
            Passed5 = {DFS R-1 C-1 Passed4}
         else
            Passed5 = Passed4
         end
         Passed5
      end

      fun {Union R1 C1 R2 C2 Connection}
         {Set {Nth {Nth Connection R1+1} C1+1} R2 C2 Connection}
      end

      fun {UF R C Map Connection}
         Connection1
         Connection2
         Connection3
         Connection4
      in
         if {IsGood R C Map} then
            if {IsGood R+1 C+1 Map} then
               Connection1 = {Union R C R+1 C+1 Connection}
            else
               Connection1 = Connection
            end
            if {IsGood R C+1 Map} then
               Connection2 = {Union R C R C+1 Connection1}
            else
               Connection2 = Connection1
            end
            if {IsGood R C-1 Map} then
               Connection3 = {Union R C R C-1 Connection2}
            else
               Connection3 = Connection2
            end
            if {IsGood R-1 C-1 Map} then
               Connection4 = {Union R C R-1 C-1 Connection3}
            else
               Connection4 = Connection3
            end
         end
         if R==NRow andthen C==NColumn then
            Connection
         elseif C<NColumn-1 then
            {UF R C+1 Map Connection4}
         else
            {UF R+1 0 Map Connection4}
         end
      end

      fun {OnlyOne M}
         fun {OnlyOneC C}
            case C
            of E|NextC then
               if E==1 then
                  {OnlyOneC NextC}
               else
                  false
               end
            [] nil then
               true
            end
         end
      in
         case M
         of R|NextRow then
            if {OnlyOneC R} then
               {OnlyOne NextRow}
            else
               false
            end
         [] nil then
            true
         end
      end

      fun {IsConnected Map}
         A
      in
         %A = {UF 0 0 Map {MakeRowN NRow}}
         true
         %{OnlyOne {UF 0 0 Map}}
      end
   in
      Map = {MakeRow NRow}
      if {IsConnected Map} then
         Map
      else
         {MakeMap}
      end
   end

   Map = {MakeMap}%[[0 0 0 0 0 0 0 0 0 0]
	  %[0 0 0 0 0 0 0 0 0 0]
	  %[0 0 0 1 1 0 0 0 0 0]
	  %[0 0 1 1 0 0 1 0 0 0]
	  %[0 0 0 0 0 0 0 0 0 0]
	  %[0 0 0 0 0 0 0 0 0 0]
	  %[0 0 0 1 0 0 1 1 0 0]
	  %[0 0 1 1 0 0 1 0 0 0]
	  %[0 0 0 0 0 0 0 0 0 0]
	  %[0 0 0 0 0 0 0 0 0 0]]

%%%% Players description %%%%

   NbPlayer = 4
   %Players = [basicAI basicAI basicAI basicAI]
   Players = [player000randomai player000randomai player000randomai player000randomai]
   Colors = [green yellow red blue]

%%%% Thinking parameters (only in simultaneous) %%%%

   ThinkMin = 1%500
   ThinkMax = 2%3000

%%%% Surface time/turns %%%%

   TurnSurface = 3

%%%% Life %%%%

   MaxDamage = 4

%%%% Number of load for each item %%%%

   Missile = 3
   Mine = 3
   Sonar = 3
   Drone = 3

%%%% Distances of placement %%%%

   MinDistanceMine = 1
   MaxDistanceMine = 2
   MinDistanceMissile = 1
   MaxDistanceMissile = 4

end
