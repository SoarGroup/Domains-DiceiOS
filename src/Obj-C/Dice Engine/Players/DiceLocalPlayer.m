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

@synthesize name, playerState, gameViews, handler, participant;

- (id)initWithName:(NSString*)aName withHandler:(GameKitGameHandler *)newHandler withParticipant:(GKTurnBasedParticipant *)localPlayer
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.name = aName;
        playerID = -1;
		handler = newHandler;
		participant = localPlayer;
		gameViews = [[NSMutableArray alloc] init];
    }
    
    return self;
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
	if (!participant)
	{
		GameKitGameHandler* gkh = handler;
		for (GKTurnBasedParticipant* p in gkh.match.participants)
			if ([p.playerID isEqualToString:[[GKLocalPlayer localPlayer] playerID]])
			{
				participant = p;
				break;
			}
	}

    self.playerState = state;
	PlayerState* playerStateLocal = self.playerState;
	for (PlayGameView* view in self.gameViews)
		[view updateState:playerStateLocal];
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
	for (PlayGameView* view in self.gameViews)
	{
		[view updateUI];

		UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,
									view.gameStateLabel);
	}
}

- (void)notifyHasLost
{
	GameKitGameHandler* handlerLocal = self.handler;

	if (handlerLocal)
		handlerLocal.match.currentParticipant.matchOutcome = GKTurnBasedMatchOutcomeLost;
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

	for (PlayGameView* localView in self.gameViews)
	{
		if (localView == nil || localView.navigationController.visibleViewController != localView)
			return;

		id<Player> gameWinner = localView.game.gameState.gameWinner;
		NSString* winner = [gameWinner getDisplayName];
		NSString* winString = @"Wins";

		if ([winner isEqualToString:@"You"])
			winString = @"Win";

		NSString *title = [NSString stringWithFormat:@"%@ %@!", winner, winString];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
														message:nil
													   delegate:self
											  cancelButtonTitle:nil
											  otherButtonTitles:@"Okay", nil];
		[alert show];
	}
}

- (void)removeHandler
{
	self.handler = nil;
}

@end
