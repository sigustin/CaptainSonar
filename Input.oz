%% Input.oz %%
%% All the variables to set up the game

functor
import
   OS
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

   IsTurnByTurn = true

%%%% Description of the map %%%%

   NRow = 10
   NColumn = 10

   fun {MakeMap}
      fun {MakeRow I}
         fun {MakeColumn I}
            if I==0 then
               nil
            else
               if ({OS.rand} mod 30)=<4 then
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

   in
      {MakeRow NRow}
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

   NbPlayer = 2
   %Players = [player000randomai player000randomai player000randomai player000randomai]
   %Players = [player000basicai player000basicai player000basicai player000basicai]
   %Colors = [green yellow red blue]
   %Players = [player034randomai player034randomai player034randomai player034randomai]
   
   %Players = [player034basicai player034basicai player034randomai player034randomai]
   %Colors = [green green red red]
   %Colors = [green yellow red blue]
   %NbPlayer = 2
   Players = [player034basicai player034randomai]
   Colors = [green blue]
   
   %NbPlayer = 3
   %Players = [player000basicai player000randomai]
   %Colors = [green blue]
   %NbPlayer = 3
   %Players = [basicAI basicAI basicAI]
   %Players = [player034basicAI2 player034basicAI2 player034basicAI2]
   %Colors = [red blue yellow]

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
