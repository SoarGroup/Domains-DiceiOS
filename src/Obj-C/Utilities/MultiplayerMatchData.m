//
//  MultiplayerMatchData.m
//  UM Liars Dice
//
//  Created by Alex Turner on 5/7/14.
//
//

#import "MultiplayerMatchData.h"
#import "SoarPlayer.h"

@implementation MultiplayerMatchData

@synthesize theData, theGame;

-(id)initWithGame:(DiceGame*)game
{
	self = [super init];

	if (self)
	{
		theData = [NSKeyedArchiver archivedDataWithRootObject:game];

		if (!theData)
			return nil;
	}

	return self;
}

-(id)initWithData:(NSData*)data withRequest:(GKMatchRequest*)request withMatch:(GKTurnBasedMatch *)match withHandler:(GameKitGameHandler *)handler;
{
	self = [super init];

	if (self)
	{
		if (data && !request)
		{
			theGame = [NSKeyedUnarchiver unarchiveObjectWithData:data];

			if (!theGame)
			{
				// Invalid match so delete it
				for (GKTurnBasedParticipant* participant in match.participants)
					participant.matchOutcome = GKTurnBasedMatchOutcomeQuit;

				[match removeWithCompletionHandler:^(NSError* error)
				 {
					 if (error)
						 NSLog(@"Error Removing Invalid Match: %@", error.description);
				 }];

				return nil;
			}
		}
		else if (request)
		{
			theGame = [[[DiceGame alloc] init] autorelease];

			// New Match
			int AICount = (int)request.playerGroup;
			int humanCount = (int)[match.participants count];
			int currentHumanCount = 0;

			NSLock* lock = [[[NSLock alloc] init] autorelease];

			int totalPlayerCount = AICount + humanCount;

			for (int i = 0;i < totalPlayerCount;i++)
			{
				BOOL isAI = (BOOL)arc4random_uniform(2);

				if ((currentHumanCount > 0 && isAI && AICount > 0) || (currentHumanCount == humanCount))
				{
					[theGame addPlayer:[[[SoarPlayer alloc] initWithGame:theGame connentToRemoteDebugger:NO lock:lock withGameKitGameHandler:handler] autorelease]];

					AICount--;
				}
				else
				{
					GKTurnBasedParticipant* participant = [match.participants objectAtIndex:currentHumanCount];
					currentHumanCount++;

					if ([[[GKLocalPlayer localPlayer] playerID] isEqualToString:[participant playerID]])
						[theGame addPlayer:[[[DiceLocalPlayer alloc] initWithName:[[GKLocalPlayer localPlayer] alias] withHandler:handler withParticipant:participant] autorelease]];
					else
						[theGame addPlayer:[[[DiceRemotePlayer alloc] initWithGameKitParticipant:participant withGameKitGameHandler:handler] autorelease]];
				}
			}

			theGame.gameState.currentTurn = 0;
		}
		else
		{
			// Invalid match so delete it
			for (GKTurnBasedParticipant* participant in match.participants)
				participant.matchOutcome = GKTurnBasedMatchOutcomeQuit;

			[match removeWithCompletionHandler:^(NSError* error)
			{
				if (error)
					NSLog(@"Error Removing Invalid Match: %@", error.description);
			}];
		}
	}

	return self;
}

- (void) dealloc
{
	NSLog(@"%@ deallocated", self.class);

	[super dealloc];
}

@end
