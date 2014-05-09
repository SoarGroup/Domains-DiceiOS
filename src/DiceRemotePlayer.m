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

@synthesize playerID, handler, participant;

- (id) initWithGameKitParticipant:(GKTurnBasedParticipant*)remotePlayer withGameKitGameHandler:(GameKitGameHandler *)newHandler
{
	self = [super init];

	if (self)
	{
		participant = remotePlayer;
		self.handler = newHandler;
		self.playerID = -2;
	}

	return self;
}

- (NSString*) getName
{
	return [participant playerID];
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
