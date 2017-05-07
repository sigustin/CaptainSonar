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

   IsTurnByTurn = false

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

   Map = {MakeMap}
      %[[0 0 0 0 0 0 0 0 0 0]
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
   Players = [player034basicai player006updown]
   Colors = [red blue]

%%%% Thinking parameters (only in simultaneous) %%%%

   ThinkMin = 100
   ThinkMax = 500

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
