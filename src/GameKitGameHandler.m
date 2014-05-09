//
//  GameKitGameHandler.m
//  UM Liars Dice
//
//  Created by Alex Turner on 5/8/14.
//
//

#import "GameKitGameHandler.h"
#import "SoarPlayer.h"
#import "MultiplayerMatchData.h"

@implementation GameKitGameHandler

@synthesize localPlayer, remotePlayers;

- (id)initWithDiceGame:(DiceGame*)lGame withLocalPlayer:(DiceLocalPlayer*)lPlayer withRemotePlayers:(NSArray*)rPlayers
{
	self = [super init];

	if (self)
	{
		localGame = lGame;
		self.localPlayer = lPlayer;
		self.remotePlayers = rPlayers;
		matchHasEnded = NO;
	}

	return self;
}

- (void) saveMatchData
{
	if (matchHasEnded)
		return;

	NSData* updatedMatchData = [NSKeyedArchiver archivedDataWithRootObject:localGame];

	[match saveCurrentTurnWithMatchData:updatedMatchData completionHandler:^(NSError* error)
	{
		if (error)
			NSLog(@"Error upon saving match data: %@", error.description);
	}];
}

- (void) updateMatchData
{
	if (matchHasEnded)
		return;

	[match loadMatchDataWithCompletionHandler:^(NSData* matchData, NSError* error)
	 {
		 if (!error)
		 {
			 DiceGame* updatedGame = [NSKeyedUnarchiver unarchiveObjectWithData:matchData];

			 [localGame updateGame:updatedGame];
		 }
		 else
			 NSLog(@"Error upon loading match data: %@", error.description);
	 }];
}

- (void) matchHasEnded
{
	matchHasEnded = YES;
}

- (void) getMultiplayerMatchData:(MultiplayerMatchData**)data
{
	[match loadMatchDataWithCompletionHandler:^(NSData* matchData, NSError* error)
	 {
		 if (!error)
		 {
			 *data = [[MultiplayerMatchData alloc] initWithData:matchData];
		 }
		 else
			 NSLog(@"Error upon loading match data: %@", error.description);
	 }];
}

- (void) advanceToRemotePlayer:(DiceRemotePlayer*)player
{
	if (matchHasEnded)
		return;

	NSData* updatedMatchData = [NSKeyedArchiver archivedDataWithRootObject:localGame];
	NSMutableArray* nextPlayers = [NSMutableArray arrayWithArray:[match participants]];

	while (![[((GKTurnBasedParticipant*)[nextPlayers objectAtIndex:0]) playerID] isEqualToString:[player getName]])
	{
		GKTurnBasedParticipant* gktbp = [nextPlayers objectAtIndex:0];
		[nextPlayers removeObjectAtIndex:0];
		[nextPlayers insertObject:gktbp atIndex:[nextPlayers count]];
	}

	[match endTurnWithNextParticipants:nextPlayers turnTimeout:GKTurnTimeoutDefault matchData:updatedMatchData completionHandler:^(NSError* error)
	 {
		 if (error)
			 NSLog(@"Error advancing to next player: %@", error.description);
	 }];
}


- (void) playerQuitMatch:(id<Player>)player
{
	if (matchHasEnded)
		return;

	if ([player isKindOfClass:SoarPlayer.class])
		[self saveMatchData];
	else
	{
		void (^quitHandler)(NSError*) =^ (NSError* error)
		{
			if (error)
				NSLog(@"Error when player quit: %@", error.description);
		};

		GKTurnBasedMatchOutcome outcome;

		PlayerState* state = [[localGame gameState] getPlayerState:[player getID]];

		if ([state hasLost])
			outcome = GKTurnBasedMatchOutcomeLost;
		else
			outcome = GKTurnBasedMatchOutcomeQuit;

		[match participantQuitOutOfTurnWithOutcome:outcome withCompletionHandler:quitHandler];
	}
}

- (BOOL) endMatchForAllParticipants
{
	if (matchHasEnded)
		return YES;

	NSArray* participants = [match participants];

	for (GKTurnBasedParticipant* gktbp in participants)
	{
		PlayerState* state = nil;

		for (PlayerState* other in [[localGame gameState] playerStates])
		{
			if ([[other playerName] isEqualToString:[gktbp playerID]])
			{
				state = other;
				break;
			}
		}

		if ([state hasLost])
			gktbp.matchOutcome = GKTurnBasedMatchOutcomeLost;
		else if ([state hasWon])
			gktbp.matchOutcome = GKTurnBasedMatchOutcomeWon;
		else if (![state hasWon] && ![state hasLost])
			gktbp.matchOutcome = GKTurnBasedMatchOutcomeQuit;
	}

	[match endMatchInTurnWithMatchData:[NSKeyedArchiver archivedDataWithRootObject:localGame] completionHandler:^(NSError* error)
	 {
		 if (error)
			 NSLog(@"Error ending match: %@", error.description);
	 }];

	return YES;
}


- (DiceGame*)getDiceGame
{
	return localGame;
}

- (GKTurnBasedMatch*)getMatch
{
	return match;
}

@end
