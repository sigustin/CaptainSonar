# Captain Sonar
An implementation of the board game "Captain Sonar", in which **players control a submarine on a grid with a limited view** of the environment and of the position of other players. The objective is to stay alive and shoot other players dead as fast as possible. A more precise description of the game is available in [the instructions](https://github.com/sigustin/CaptainSonar/blob/master/Projet2017_v3.pdf).

The point of this project was to **implement the game's logic** and **add several features** to it (a very simple Graphical User Interface was provided by the teaching assistant) and **create AI agents** that would be able to play the game efficiently. The different parts of the system were supposed to interact using **message-passing concurrency**.
Two modes of execution exist: a sequential turn-by-turn mode and a concurrent simultaneous mode.

This project was made in 2017 for the course LINGI1131 &ndash; Computer Languages Concepts.

*Languages used:*
- *Oz*
- *bash (to automate the compilation and execution)*

## Collaborators
This project is a two people project I made with Brieuc Pinon. He made the game logic and improvements to the Graphical User Interface, while I made the agents (namely a random one and another one, called basic AI).

## What I learned
- Make a program whose parts are concurrently executing, and synchronize them using message-passing concurrency
- Understand a game in a way that allows us to create efficient playing agents

## Files worth checking out
- The project instructions: [Projet2017_V3.pdf](https://github.com/sigustin/CaptainSonar/blob/master/Projet2017_v3.pdf)
- Our report explaining what we made: [Group34-Report.pdf](https://github.com/sigustin/CaptainSonar/blob/master/Group34-Report.pdf)
- The main file, with most of the logic of the game: [Main.oz](https://github.com/sigustin/CaptainSonar/blob/master/Main.oz)
- The random and basic AIs: [Player034RandomAI.oz](https://github.com/sigustin/CaptainSonar/blob/master/Player034RandomAI.oz) and [Player034BasicAI.oz](https://github.com/sigustin/CaptainSonar/blob/master/Player034BasicAI.oz)

## Compilation and execution
You will need to install [Mozart](https://mozart.github.io/) to compile and run the code.

Compile and run the project:
```sh
./run.sh
```
*Alternatively*, you can run the following commands:
```sh
ozc -c Input.oz
ozc -c PlayerManeger.oz
ozc -c Player034RandomAI.oz
ozc -c Player034BasicRandom.oz
ozc -c GUI.oz
ozc -c Main.oz
ozengine Main.ozf
```

*Note: the makefile shouldn't be used.*
