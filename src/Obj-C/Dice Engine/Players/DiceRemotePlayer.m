//
//  DiceRemotePlayer.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceRemotePlayer.h"
#import "DiceGame.h"
#import "GameKitGameHandler.h"

@implementation DiceRemotePlayer

@synthesize playerID, handler, displayName, participant;

- (id) initWithGameKitParticipant:(GKTurnBasedParticipant*)remotePlayer withGameKitGameHandler:(GameKitGameHandler *)newHandler
{
	self = [super init];

	if (self)
	{
		self.participant = remotePlayer;
		self.handler = newHandler;
		self.playerID = -2;
		self.displayName = nil;

		if (self.participant.player.playerID != nil)
		{
			[GKPlayer loadPlayersForIdentifiers:[NSArray arrayWithObject:remotePlayer.player.playerID] withCompletionHandler:^(NSArray* array, NSError* error)
			 {
				 if (error)
					 DDLogError(@"Loading player identifiers: %@", error.description);
				 else
					 self.displayName = [(GKPlayer*)[array objectAtIndex:0] displayName];

				 [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateUINotification" object:nil];
			 }];
		}
	}

	return self;
}

- (void)dealloc
{
	DDLogVerbose(@"Dice Remote Player deallocated\n");
}

- (NSString*) getDisplayName
{
	//if (self.participant.status == GKTurnBasedParticipantStatusMatching ||
	//	self.participant.status == GKTurnBasedParticipantStatusUnknown)

	if (self.participant.player.playerID == nil || !self.displayName)
		return @"Player";

	return self.displayName;
}

- (NSString*) getGameCenterName
{
	return self.participant.player.playerID;
}

- (void) updateState:(PlayerState*)state
{
	if (self.participant.player.playerID &&
		!self.displayName)
	{
		[GKPlayer loadPlayersForIdentifiers:[NSArray arrayWithObject:participant.player.playerID] withCompletionHandler:^(NSArray* array, NSError* error)
		 {
			 if (error)
				 DDLogError(@"loading player identifiers: %@", error.description);
			 else
				 self.displayName = [(GKPlayer*)[array objectAtIndex:0] displayName];

			 [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateUINotification" object:nil];
		 }];
	}
	else if (self.displayName)
		[state setPlayerName:self.displayName];
}

- (int) getID
{
	return self.playerID;
}

- (void) setID:(int)anID
{
	self.playerID = anID;
}

- (void) itsYourTurn
{
	GameKitGameHandler* handlerLocal = self.handler;
	DDLogDebug(@"Advanced to next turn! %@", self.participant.player.playerID);
	[handlerLocal advanceToRemotePlayer:self];
}

- (void)notifyHasLost
{
	self.participant.matchOutcome = GKTurnBasedMatchOutcomeLost;
}

- (void)notifyHasWon
{
	self.participant.matchOutcome = GKTurnBasedMatchOutcomeWon;
}

- (void) end
{}

- (void)removeHandler
{
	self.handler = nil;
}

- (void)setParticipant:(GKTurnBasedParticipant *)participant2
{
	if (self.participant == participant2)
		return;

	participant = participant2;

	if (!self.participant.player.playerID)
		return;

	[GKPlayer loadPlayersForIdentifiers:[NSArray arrayWithObject:self.participant.player.playerID] withCompletionHandler:^(NSArray* array, NSError* error)
	 {
		 if (error)
			 DDLogError(@"loading player identifiers: %@", error.description);
		 else
			 self.displayName = [(GKPlayer*)[array objectAtIndex:0] displayName];

		 [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateUINotification" object:nil];
	 }];
}

@end
