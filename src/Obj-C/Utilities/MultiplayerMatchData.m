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
		NSData* data = [NSKeyedArchiver archivedDataWithRootObject:game];

		if (!data)
			return nil;

		self.theData = data;
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
			DiceGame* game = [NSKeyedUnarchiver unarchiveObjectWithData:data];

			if (!game)
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

			theGame = game;
		}
		else if (request)
		{
			self.theGame = [[DiceGame alloc] init];

			// New Match
			int AICount = (int)request.playerGroup;
			int humanCount = (int)[match.participants count];
			int currentHumanCount = 0;

			NSLock* lock = [[NSLock alloc] init];

			int totalPlayerCount = AICount + humanCount;

			for (int i = 0;i < totalPlayerCount;i++)
			{
				BOOL isAI = (BOOL)arc4random_uniform(2);

				if ((currentHumanCount > 0 && isAI && AICount > 0) || (currentHumanCount == humanCount))
				{
					[theGame addPlayer:[[SoarPlayer alloc] initWithGame:theGame connentToRemoteDebugger:NO lock:lock withGameKitGameHandler:handler]];

					AICount--;
				}
				else
				{
					GKTurnBasedParticipant* participant = [match.participants objectAtIndex:currentHumanCount];
					currentHumanCount++;

					if ([[[GKLocalPlayer localPlayer] playerID] isEqualToString:[participant playerID]])
						[theGame addPlayer:[[DiceLocalPlayer alloc] initWithName:[[GKLocalPlayer localPlayer] alias] withHandler:handler withParticipant:participant]];
					else
						[theGame addPlayer:[[DiceRemotePlayer alloc] initWithGameKitParticipant:participant withGameKitGameHandler:handler]];
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
}

@end
