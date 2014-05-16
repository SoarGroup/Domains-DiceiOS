//
//  GameKitListener.m
//  UM Liars Dice
//
//  Created by Alex Turner on 5/8/14.
//
//

#import "GameKitListener.h"

@implementation GameKitListener

- (id)init
{
	self = [super init];

	if (self)
	{
		handlers = [[NSMutableArray alloc] init];
	}

	return self;
}

- (void) dealloc
{
	[handlers release];

	[super dealloc];
}

- (void) addGameKitGameHandler:(GameKitGameHandler*)handler
{
	[handlers addObject:handler];
}

- (void) removeGameKitGameHandler:(GameKitGameHandler*)handler
{
	[handlers removeObject:handler];
}

- (GameKitGameHandler*)handlerForMatch:(GKTurnBasedMatch*)match
{
	for (GameKitGameHandler* handler in handlers)
	{
		if ([handler getMatch] == match)
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
}

- (void) player:(GKPlayer *)player issuedChallengeWasCompleted:(GKChallenge *)challenge byFriend:(GKPlayer *)friendPlayer
{} // No Challenges

- (void) player:(GKPlayer *)player matchEnded:(GKTurnBasedMatch *)match
{
	for (GameKitGameHandler* handler in handlers)
	{
		if ([handler getMatch] == match)
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

	for (GameKitGameHandler* handler in handlers)
	{
		if ([handler getMatch] == match)
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
