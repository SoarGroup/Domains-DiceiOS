//
//  DiceLocalPlayer.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceReplayPlayer.h"
#import "DiceAction.h"
#import "Die.h"

#import "PlayGame.h"
#import "PlayGameView.h"

#import "DiceGame.h"

@implementation DiceReplayPlayer

@synthesize name, playerState, gameViews, actions, myActions;

- (id)initWithName:(NSString *)replayName withPlayerID:(int)localID withActions:(NSArray*)newActions
{
	self = [super init];
	
	if (self)
	{
		self.name = replayName;
		self->playerID = localID;
		self.actions = newActions;
		
		myActions = [[NSMutableArray alloc] init];
		gameViews = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (NSString*) getDisplayName
{
    return self.name;
}

- (NSString*) getGameCenterName
{
    return self.name;
}

- (void) updateState:(PlayerState*)state
{
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
    
    self.name = [NSString stringWithFormat:@"ReplayPlayer-%i", playerID];
    
    [myActions removeAllObjects];
    
    for (DiceAction* action in actions)
	{
		if (action.playerID == playerID)
			[myActions addObject:action];
	}
}

- (void) itsYourTurn
{
	for (PlayGameView* view in self.gameViews)
	{
		[view updateUI];

		UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,
									view.gameStateLabel);
	}
    
    if (myActions.count == 0)
        return;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        PlayerState* state = self->playerState;
        DiceGameState* gameState = state.gameState;
        DiceGame* localGame = gameState.game;
        
        DiceAction* action = [self->myActions firstObject];
        
        BOOL notify = YES;
        if (action.actionType == ACTION_CHALLENGE_BID ||
            action.actionType == ACTION_CHALLENGE_PASS ||
            action.actionType == ACTION_EXACT)
            localGame.gameState.canContinueGame = notify = NO;
				
        DDLogDebug(@"Action: %@", action);
        
        [localGame handleAction:action notify:notify];
        [self->myActions removeObjectAtIndex:0];
    });
}

- (void)notifyHasLost
{}

- (void)notifyHasWon
{}

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
{}

- (void)setParticipant:(GKTurnBasedParticipant *)participant
{}

- (void)setHandler:(GameKitGameHandler *)handler
{}

- (NSDictionary*)dictionaryValue
{
	return [NSDictionary dictionary];
}

@end
