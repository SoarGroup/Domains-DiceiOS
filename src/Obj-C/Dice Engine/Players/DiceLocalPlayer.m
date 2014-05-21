//
//  DiceLocalPlayer.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceLocalPlayer.h"

#import "PlayerState.h"
#import "PlayGame.h"
#import "GameKitGameHandler.h"
#import "PlayGameView.h"

@implementation DiceLocalPlayer

@synthesize name, playerState, gameView, handler, participant;

- (id)initWithName:(NSString*)aName withHandler:(GameKitGameHandler *)newHandler withParticipant:(GKTurnBasedParticipant *)localPlayer
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.name = aName;
        playerID = -1;
		handler = newHandler;
		participant = localPlayer;
    }
    
    return self;
}


- (void)dealloc
{
	NSLog(@"Dice Local Player deallocated\n");
}

- (NSString*) getName
{
    return self.name;
}

- (void) updateState:(PlayerState*)state
{
    self.playerState = state;
	PlayGameView* gameViewLocal = self.gameView;
	PlayerState* playerStateLocal = self.playerState;
    [gameViewLocal updateState:playerStateLocal];
}

- (int) getID
{
    return playerID;
}

- (void) setID:(int)anID
{
    playerID = anID;
}

- (void) itsYourTurn
{
	PlayGameView* gameViewLocal = self.gameView;
	[gameViewLocal updateUI];

	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,
									gameViewLocal.gameStateLabel);
}

- (void)notifyHasLost
{
	GameKitGameHandler* handlerLocal = self.handler;
	if (handlerLocal)
		[handlerLocal playerQuitMatch:self withRemoval:NO];
}

- (void)notifyHasWon
{
	GameKitGameHandler* handlerLocal = self.handler;

	if (handlerLocal)
		[handlerLocal endMatchForAllParticipants];
}

- (void) end { }

- (void)removeHandler
{
	self.handler = nil;
}

@end
