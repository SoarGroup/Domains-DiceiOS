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

- (NSString*) getName
{
    return self.name;
}

- (void) updateState:(PlayerState*)state
{
    self.playerState = state;
    [self.gameView updateState:self.playerState];
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
	[self.gameView updateUI];

	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,
									self.gameView.gameStateLabel);
}

- (void)notifyHasLost
{
	if (handler)
		[handler playerQuitMatch:self withRemoval:NO];
}

- (void)notifyHasWon
{
	if (handler)
		[handler endMatchForAllParticipants];
}

- (void) end { }

@end
