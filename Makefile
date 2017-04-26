CC = ozc
CFLAGS = -c

.PHONY : all clean run

run : all
	ozengine Main.ozf

all : Main.ozf

Main.ozf : Main.oz GUI.ozf
	$(CC) $(CFLAGS) Main.oz

GUI.ozf : GUI.oz Player000RandomAI.ozf Player000BasicAI.ozf
	$(CC) $(CFLAGS) GUI.oz

Player000RandomAI.ozf : Player000RandomAI.oz PlayerManager.ozf
	$(CC$) $(CFLAGS) Player000RandomAI.oz

Player000BasicAI.ozf : Player000BasicAI.oz PlayerManager.ozf
	$(CC) $(CFLAGS) Player000BasicAI.oz

PlayerManager.ozf : PlayerManager.oz Input.ozf
	$(CC) $(CFLAGS) PlayerManager.oz
	
Input.ozf : Input.oz
	$(CC) $(CFLAGS) Input.oz

clean :
	@rm -f *.ozf #-f prevents an error message to be displayed if no file were found to be deleted

