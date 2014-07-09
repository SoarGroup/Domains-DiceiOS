//
//  GameKitListener.m
//  UM Liars Dice
//
//  Created by Alex Turner on 5/8/14.
//
//

#import "GameKitListener.h"

@implementation GameKitListener

@synthesize handlers;

- (id)init
{
	self = [super init];

	if (self)
	{
		self.handlers = [[NSMutableArray alloc] init];
	}

	return self;
}

- (void) dealloc
{
	NSLog(@"%@ deallocated", self.class);}

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
}

- (void) player:(GKPlayer *)player didCompleteChallenge:(GKChallenge *)challenge issuedByFriend:(GKPlayer *)friendPlayer
{} // No Challenges

- (void) player:(GKPlayer *)player didReceiveChallenge:(GKChallenge *)challenge
{}

- (void) player:(GKPlayer *)player didRequestMatchWithPlayers:(NSArray *)playerIDsToInvite
{
	// TODO: Implement creating a match from game center
	NSLog(@"Game Center Match Request");
}

- (void) player:(GKPlayer *)player issuedChallengeWasCompleted:(GKChallenge *)challenge byFriend:(GKPlayer *)friendPlayer
{} // No Challenges

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

- (void) player:(GKPlayer *)player receivedExchangeCancellation:(GKTurnBasedExchange *)exchange forMatch:(GKTurnBasedMatch *)match
{} // No Exchanges

- (void) player:(GKPlayer *)player receivedExchangeReplies:(NSArray *)replies forCompletedExchange:(GKTurnBasedExchange *)exchange forMatch:(GKTurnBasedMatch *)match
{} // No Exchanges

- (void) player:(GKPlayer *)player receivedExchangeRequest:(GKTurnBasedExchange *)exchange forMatch:(GKTurnBasedMatch *)match
{} // No Exchanges

- (void) player:(GKPlayer *)player receivedTurnEventForMatch:(GKTurnBasedMatch *)match didBecomeActive:(BOOL)didBecomeActive
{
	// TODO: Handle timeout case
	// TODO: Handle invite case

	NSLog(@"Recieved turn event for match: %@", match);

	for (GameKitGameHandler* handler in handlers)
	{
		if ([[handler getMatch].matchID isEqualToString:match.matchID])
		{
			// Found handler for match
			[handler updateMatchData];

			break;
		}
	}
}

- (void) player:(GKPlayer *)player wantsToPlayChallenge:(GKChallenge *)challenge
{} // No Challenges

@end
