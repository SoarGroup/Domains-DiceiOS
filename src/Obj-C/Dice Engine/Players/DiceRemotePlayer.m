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
		self.displayName = self.participant.playerID;

		if (self.participant.status != GKTurnBasedParticipantStatusMatching &&
			self.participant.status != GKTurnBasedParticipantStatusUnknown)
		{
			[GKPlayer loadPlayersForIdentifiers:[NSArray arrayWithObject:remotePlayer.playerID] withCompletionHandler:^(NSArray* array, NSError* error)
			 {
				 if (error)
					 NSLog(@"Error loading player identifiers: %@", error.description);
				 else
					 self.displayName = [(GKPlayer*)[array objectAtIndex:0] displayName];
			 }];
		}
	}

	return self;
}

- (void)dealloc
{
	NSLog(@"Dice Remote Player deallocated\n");
}

- (NSString*) getName
{
	if (self.participant.status == GKTurnBasedParticipantStatusMatching ||
		self.participant.status == GKTurnBasedParticipantStatusUnknown)
		return @"Player";

	return self.displayName;
}

- (void) updateState:(PlayerState*)state
{
	if (self.participant.status != GKTurnBasedParticipantStatusMatching &&
		self.participant.status != GKTurnBasedParticipantStatusUnknown &&
		self.displayName == self.participant.playerID)
	{
		[GKPlayer loadPlayersForIdentifiers:[NSArray arrayWithObject:participant.playerID] withCompletionHandler:^(NSArray* array, NSError* error)
		 {
			 if (error)
				 NSLog(@"Error loading player identifiers: %@", error.description);
			 else
				 self.displayName = [(GKPlayer*)[array objectAtIndex:0] displayName];
		 }];
	}
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
	if (participant == participant2)
		return;

	participant = participant2;

	if (self.participant.status == GKTurnBasedParticipantStatusMatching ||
		self.participant.status == GKTurnBasedParticipantStatusUnknown)
		return;

	[GKPlayer loadPlayersForIdentifiers:[NSArray arrayWithObject:participant.playerID] withCompletionHandler:^(NSArray* array, NSError* error)
	 {
		 if (error)
			 NSLog(@"Error loading player identifiers: %@", error.description);
		 else
			 self.displayName = [(GKPlayer*)[array objectAtIndex:0] displayName];
	 }];
}

@end
