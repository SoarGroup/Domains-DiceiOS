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

- (NSString*) getDisplayName
{
	NSString* displayName = self.name;

	if ([GKLocalPlayer localPlayer].isAuthenticated)
		displayName = @"You";

    return displayName;
}

- (NSString*) getGameCenterName
{
	if (![GKLocalPlayer localPlayer].isAuthenticated)
		return self.name;
	
	return [[GKLocalPlayer localPlayer] playerID];
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

- (void) end
{}

- (void) end:(BOOL)showAlert
{
	if (![NSThread isMainThread] || !showAlert)
		return;

	PlayGameView* localView = self.gameView;
	NSString *title = [NSString stringWithFormat:@"%@ Wins!", [localView.game.gameState.gameWinner getDisplayName]];
	//NSString *message = @"For this round: 1s aren't wild. Only players with one die may change the bid face."; // (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:nil
												   delegate:self
										  cancelButtonTitle:nil
										  otherButtonTitles:@"Okay", nil];
	alert.tag = ACTION_QUIT;
	[alert show];
}

- (void)removeHandler
{
	self.handler = nil;
}

@end
