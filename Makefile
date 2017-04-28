CC = ozc
CFLAGS = -c

.PHONY : all clean run

run : all
	ozengine Main.ozf

all : Main.ozf

Main.ozf : Main.oz GUI.ozf
	$(CC) $(CFLAGS) Main.oz

GUI.ozf : GUI.oz Player034RandomAI.ozf Player034BasicAI.ozf
	$(CC) $(CFLAGS) GUI.oz

Player034RandomAI.ozf : Player034RandomAI.oz PlayerManager.ozf
	$(CC$) $(CFLAGS) Player034RandomAI.oz

Player034BasicAI.ozf : Player034BasicAI.oz PlayerManager.ozf
	$(CC) $(CFLAGS) Player034BasicAI.oz

PlayerManager.ozf : PlayerManager.oz Input.ozf
	$(CC) $(CFLAGS) PlayerManager.oz

Input.ozf : Input.oz
	$(CC) $(CFLAGS) Input.oz

clean :
	@rm -f *.ozf #-f prevents an error message to be displayed if no file were found to be deleted

