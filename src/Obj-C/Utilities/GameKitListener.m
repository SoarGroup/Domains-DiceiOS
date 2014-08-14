//
//  GameKitListener.m
//  UM Liars Dice
//
//  Created by Alex Turner on 5/8/14.
//
//

#import "GameKitListener.h"
#import "ApplicationDelegate.h"
#import "MultiplayerView.h"
#import "PlayGameView.h"
#import "RoundOverView.h"

@implementation GameKitListener

@synthesize handlers, delegate;

- (id)init
{
	self = [super init];

	if (self)
		self.handlers = [[NSMutableArray alloc] init];

	return self;
}

- (void) addGameKitGameHandler:(GameKitGameHandler*)handler
{
	[handlers addObject:handler];
}

- (void) removeGameKitGameHandler:(GameKitGameHandler*)handler
{
	for (id<Player> player in handler.localGame.players)
		[player removeHandler];

	[handlers removeObject:handler];
}

- (GameKitGameHandler*)handlerForMatch:(GKTurnBasedMatch*)match
{
	for (GameKitGameHandler* handler in handlers)
	{
		if ([[handler getMatch].matchID isEqualToString:match.matchID])
			return handler;
	}

	return nil;
}

- (GameKitGameHandler*)handlerForGame:(DiceGame*)game
{
	for (GameKitGameHandler* handler in handlers)
	{
		if ([handler localGame] == game)
			return handler;
	}

	return nil;
}

- (void) player:(GKPlayer *)player didAcceptInvite:(GKInvite *)invite
{
	// TODO: Invites
	DDLogGameKit(@"Player accepted invite.");
}

- (void) player:(GKPlayer *)player matchEnded:(GKTurnBasedMatch *)match
{
	for (GameKitGameHandler* handler in handlers)
	{
		if ([[handler getMatch].matchID isEqualToString:match.matchID])
		{
			[handler updateMatchData];
			[handler matchHasEnded];
		}
	}
}

- (void) player:(GKPlayer *)player receivedTurnEventForMatch:(GKTurnBasedMatch *)match didBecomeActive:(BOOL)didBecomeActive
{
	DDLogGameKit(@"Recieved turn event for match: %@", match);
	ApplicationDelegate* localDelegate = self.delegate;

	GameKitGameHandler* gkHandler = nil;

	for (GameKitGameHandler* handler in handlers)
	{
		if ([[handler getMatch].matchID isEqualToString:match.matchID])
		{
			// Found handler for match
			gkHandler = handler;
			break;
		}
	}

	if (!gkHandler && didBecomeActive)
	{
		// New Match, invite
		NSArray* views = localDelegate.mainMenu.navigationController.viewControllers;
		MultiplayerView* mView = nil;
		
		for (UIView* view in views)
		{
			if ([view isKindOfClass:MultiplayerView.class])
			{
				mView = (MultiplayerView*)view;
				break;
			}
		}
		
		if (!mView)
		{
			[localDelegate.mainMenu multiplayerGameButtonPressed:nil];
			
			views = localDelegate.mainMenu.navigationController.viewControllers;
			
			for (UIView* view in views)
			{
				if ([view isKindOfClass:MultiplayerView.class])
				{
					mView = (MultiplayerView*)view;
					break;
				}
			}
		}
		else
			[mView populateScrollView];
	
		NSObject* object = [[NSObject alloc] init];
		[object.LDContext setObject:match forKey:@"Match"];
		[mView playMatchButtonPressed:object withWait:YES];
	}
	else if (gkHandler)
		[gkHandler updateMatchData];
	else
		DDLogError(@"No Handler for match!");
}

@end
