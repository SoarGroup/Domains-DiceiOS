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

		[GKPlayer loadPlayersForIdentifiers:[NSArray arrayWithObject:remotePlayer] withCompletionHandler:^(NSArray* array, NSError* error)
		 {
			 if (error)
				 NSLog(@"Error loading player identifiers: %@", error.description);
			 else
				 self.displayName = [(GKPlayer*)[array objectAtIndex:0] displayName];
		 }];
	}

	return self;
}

- (NSString*) getName
{
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
	[handler advanceToRemotePlayer:self];
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

@end
