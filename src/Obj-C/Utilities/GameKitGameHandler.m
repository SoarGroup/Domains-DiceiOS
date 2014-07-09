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
#import "PlayGameView.h"
#import "ApplicationDelegate.h"

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
	if (matchHasEnded || ![[[match currentParticipant] playerID] isEqualToString:[[GKLocalPlayer localPlayer] playerID]])
		return;

	NSData* updatedMatchData = [NSKeyedArchiver archivedDataWithRootObject:localGame];

	ApplicationDelegate* delegate = [UIApplication sharedApplication].delegate;
	NSLog(@"Updated Match Data SHA1 Hash: %@", [delegate sha1HashFromData:updatedMatchData]);

	[match saveCurrentTurnWithMatchData:updatedMatchData completionHandler:^(NSError* error)
	{
		NSLog(@"Sent match data!");

		if (error)
			NSLog(@"Error upon saving match data: %@\n", error.description);
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
			 for (int i = 0;i < [self->match.participants count];++i)
			 {
				 GKTurnBasedParticipant* p = [self->match.participants objectAtIndex:i];
				 NSString* oldPlayerID = ((GKTurnBasedParticipant*)[self->participants objectAtIndex:i]).playerID;
				 NSString* newPlayerID = p.playerID;

				 if ((oldPlayerID == nil && newPlayerID != nil) ||
					 ![oldPlayerID isEqualToString:newPlayerID])
				 {
					 NSMutableArray* array = [NSMutableArray arrayWithArray:self->participants];

					 [array replaceObjectAtIndex:i withObject:p];

					 self->participants = array;

					 for (DiceRemotePlayer* remote in self->remotePlayers)
					 {
						 NSString* remotePlayerID = [remote getGameCenterName];
						 if ((remotePlayerID == nil && oldPlayerID == nil) ||
							 [remotePlayerID isEqualToString:oldPlayerID])
						 {
							 [remote setParticipant:p];
							 break;
						 }
					 }
				 }
			 }

			 ApplicationDelegate* delegate = [UIApplication sharedApplication].delegate;
			 NSLog(@"Updated Match Data Retrieved SHA1 Hash: %@", [delegate sha1HashFromData:matchData]);

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

	[localGame end];
}

- (void) advanceToRemotePlayer:(DiceRemotePlayer*)player
{
	if (matchHasEnded)
		return;

	NSData* updatedMatchData = [NSKeyedArchiver archivedDataWithRootObject:localGame];

	ApplicationDelegate* delegate = [UIApplication sharedApplication].delegate;
	NSLog(@"Updated Match Data SHA1 Hash: %@", [delegate sha1HashFromData:updatedMatchData]);

	NSMutableArray* nextPlayers = [NSMutableArray arrayWithArray:participants];

	for (int i = localGame.gameState.currentTurn;i > 0;i--)
	{
		if ([[localGame.players objectAtIndex:i] isKindOfClass:SoarPlayer.class])
			continue;

		assert(![[localGame.players objectAtIndex:i] isKindOfClass:DiceLocalPlayer.class]);

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

	if ([player isKindOfClass:SoarPlayer.class])
		[self saveMatchData];
	else if ([player isKindOfClass:DiceLocalPlayer.class])
	{
		NSMutableArray* localParticipants = [[NSMutableArray alloc] init];

		for (GKTurnBasedParticipant* participant in [match participants])
		{
			if (participant != [self myParticipant])
				[localParticipants addObject:participant];
		}

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

				if ([[match currentParticipant].playerID isEqual:[GKLocalPlayer localPlayer].playerID])
				{
					[match participantQuitInTurnWithOutcome:outcome nextParticipants:localParticipants turnTimeout:GKTurnTimeoutDefault matchData:[NSKeyedArchiver archivedDataWithRootObject:localGame] completionHandler:^(NSError* error)
					 {
						 if (error)
							 NSLog(@"Error when player quit: %@\n", error.description);
					 }];
				}
				else
				{
					[match participantQuitOutOfTurnWithOutcome:outcome withCompletionHandler:^(NSError* error)
					 {
						 if (error)
							 NSLog(@"Error when player quit: %@\n", error.description);
					 }];
				}
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

		if ([[match currentParticipant].playerID isEqual:[GKLocalPlayer localPlayer].playerID])
		{
			[match participantQuitInTurnWithOutcome:outcome nextParticipants:localParticipants turnTimeout:GKTurnTimeoutDefault matchData:[NSKeyedArchiver archivedDataWithRootObject:localGame] completionHandler:^(NSError* error)
			 {
				 if (error)
					 NSLog(@"Error when player quit: %@\n", error.description);
			 }];
		}
		else
		{
			[match participantQuitOutOfTurnWithOutcome:outcome withCompletionHandler:^(NSError* error)
			 {
				 if (error)
					 NSLog(@"Error when player quit: %@\n", error.description);
			 }];
		}
	}
}

- (BOOL) endMatchForAllParticipants
{
	if (matchHasEnded)
		return YES;

	for (GKTurnBasedParticipant* gktbp in match.participants)
	{
		PlayerState* state = nil;

		for (PlayerState* other in [[localGame gameState] playerStates])
		{
			if ([[[localGame.players objectAtIndex:other.playerID] getGameCenterName] isEqualToString:[gktbp playerID]])
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
