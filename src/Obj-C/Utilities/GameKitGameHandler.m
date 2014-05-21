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

@synthesize localPlayer, remotePlayers, match, participants, localGame;

- (id)initWithDiceGame:(DiceGame*)lGame withLocalPlayer:(DiceLocalPlayer*)lPlayer withRemotePlayers:(NSArray*)rPlayers withMatch:(GKTurnBasedMatch *)gkMatch
{
	self = [super init];

	if (self)
	{
		self.localGame = lGame;
		self.localPlayer = lPlayer;
		self.remotePlayers = rPlayers;
		matchHasEnded = NO;
		match = gkMatch;

		participants = [match participants];
	}

	return self;
}

- (void)dealloc
{
	NSLog(@"Game Kit Game Handler deallocated\n");
}

- (void) saveMatchData
{
	if (matchHasEnded)
		return;

	if (![NSThread isMainThread])
	{
		[self performSelectorOnMainThread:@selector(saveMatchData) withObject:nil waitUntilDone:YES];
		return;
	}
	
	NSData* updatedMatchData = [NSKeyedArchiver archivedDataWithRootObject:localGame];

	[match saveCurrentTurnWithMatchData:updatedMatchData completionHandler:^(NSError* error)
	{
		if (error)
			NSLog(@"Error upon saving match data: %@\n", error.description);
	}];
}

- (void) updateMatchData
{
	if (matchHasEnded)
		return;

	if (![NSThread isMainThread])
	{
		[self performSelectorOnMainThread:@selector(updateMatchData) withObject:nil waitUntilDone:YES];
		return;
	}

	[match loadMatchDataWithCompletionHandler:^(NSData* matchData, NSError* error)
	 {
		 if (!error)
		 {
			 DiceGame* updatedGame = [NSKeyedUnarchiver unarchiveObjectWithData:matchData];

			 [self->localGame updateGame:updatedGame];
		 }
		 else
			 NSLog(@"Error upon loading match data: %@\n", error.description);
	 }];
}

- (void) matchHasEnded
{
	matchHasEnded = YES;
}

- (void) advanceToRemotePlayer:(DiceRemotePlayer*)player
{
	if (matchHasEnded)
		return;

	if (![NSThread isMainThread])
	{
		[self performSelectorOnMainThread:@selector(advanceToRemotePlayer:) withObject:player waitUntilDone:YES];
		return;
	}

	NSData* updatedMatchData = [NSKeyedArchiver archivedDataWithRootObject:localGame];
	NSMutableArray* nextPlayers = [NSMutableArray arrayWithArray:participants];

	for (int i = localGame.gameState.currentTurn;i > 0;i--)
	{
		GKTurnBasedParticipant* gktbp = [nextPlayers objectAtIndex:0];
		[nextPlayers removeObjectAtIndex:0];
		[nextPlayers insertObject:gktbp atIndex:[nextPlayers count]];
	}

	[match endTurnWithNextParticipants:nextPlayers turnTimeout:GKTurnTimeoutDefault matchData:updatedMatchData completionHandler:^(NSError* error)
	 {
		 if (error)
			 NSLog(@"Error advancing to next player: %@\n", error.description);
	 }];
}

- (GKTurnBasedParticipant*)myParticipant
{
	for (GKTurnBasedParticipant* participant in [match participants])
	{
		if ([participant playerID] == [[GKLocalPlayer localPlayer] playerID])
			return participant;
	}

	return nil;
}

- (void) playerQuitMatch:(id<Player>)player withRemoval:(BOOL)remove
{
	if (matchHasEnded)
		return;

	if (![NSThread isMainThread])
	{
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self playerQuitMatch:player withRemoval:remove];
		});
		return;
	}

	if ([player isKindOfClass:SoarPlayer.class])
		[self saveMatchData];
	else if ([player isKindOfClass:DiceLocalPlayer.class])
	{
		if ([self myParticipant].matchOutcome != GKTurnBasedMatchOutcomeNone || remove)
		{
			if ([self myParticipant].matchOutcome == GKTurnBasedMatchOutcomeNone)
			{
				GKTurnBasedMatchOutcome outcome;

				PlayerState* state = [[localGame gameState] getPlayerState:[player getID]];

				if ([state hasLost])
					outcome = GKTurnBasedMatchOutcomeLost;
				else
					outcome = GKTurnBasedMatchOutcomeQuit;

				[match participantQuitOutOfTurnWithOutcome:outcome withCompletionHandler:^(NSError* error)
				 {
					 if (error)
						 NSLog(@"Error when player quit: %@\n", error.description);
				 }];
			}

			[match removeWithCompletionHandler:^(NSError* error)
			 {
				 if (error)
					 NSLog(@"Error Removing Match: %@\n", error.description);
			 }];

			return;
		}

		GKTurnBasedMatchOutcome outcome;

		PlayerState* state = [[localGame gameState] getPlayerState:[player getID]];

		if ([state hasLost])
			outcome = GKTurnBasedMatchOutcomeLost;
		else
			outcome = GKTurnBasedMatchOutcomeQuit;

		[match participantQuitOutOfTurnWithOutcome:outcome withCompletionHandler:^(NSError* error)
		 {
			 if (error)
				 NSLog(@"Error when player quit: %@\n", error.description);
		 }];
	}
}

- (BOOL) endMatchForAllParticipants
{
	if (matchHasEnded)
		return YES;

	if (![NSThread isMainThread])
	{
		[self performSelectorOnMainThread:@selector(endMatchForAllParticipants) withObject:nil waitUntilDone:YES];
		return YES;
	}

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
			 NSLog(@"Error ending match: %@\n", error.description);
	 }];

	return YES;
}

- (GKTurnBasedMatch*)getMatch
{
	return match;
}

@end
