//
//  DiceLocalPlayer.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceSoarReplayPlayer.h"
#import "SoarPlayer.h"
#import "DiceAction.h"
#import "Die.h"

#import "PlayGame.h"
#import "PlayGameView.h"

#import "DiceGame.h"
#import "SettingsView.h"

@implementation DiceSoarReplayPlayer

@synthesize gameViews;

- (id)initWithGame:(DiceGame*)aGame connentToRemoteDebugger:(BOOL)connect lock:(NSLock *)aLock withGameKitGameHandler:(GameKitGameHandler*)gkgHandler difficulty:(int)diff;
{
	self = [super initWithGame:aGame connentToRemoteDebugger:connect lock:aLock withGameKitGameHandler:gkgHandler difficulty:diff];
	
	if (self)
		self.gameViews = [[NSMutableArray alloc] init];
	
	return self;
}

- (void) updateState:(PlayerState*)state
{
	[super updateState:state];
	
    self.playerState = state;
	PlayerState* playerStateLocal = self.playerState;
	for (PlayGameView* view in self.gameViews)
	{
		[view updateState:playerStateLocal];
		view->isSoarOnlyGame = YES;
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
    
	[super itsYourTurn];
}

@end
