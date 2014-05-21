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

@synthesize playerID, handler, participant, displayName;

- (id) initWithGameKitParticipant:(GKTurnBasedParticipant*)remotePlayer withGameKitGameHandler:(GameKitGameHandler *)newHandler
{
	self = [super init];

	if (self)
	{
		participant = remotePlayer;
		self.handler = newHandler;
		self.playerID = -2;
		self.displayName = participant.playerID;

		if (self.displayName)
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
	if (!self.displayName)
		return @"Player";

	return self.displayName;
}

- (void) updateState:(PlayerState*)state
{}

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
	participant.matchOutcome = GKTurnBasedMatchOutcomeLost;
}

- (void)notifyHasWon
{
	participant.matchOutcome = GKTurnBasedMatchOutcomeWon;
}

- (void) end
{}

- (void)removeHandler
{
	self.handler = nil;
}

@end
