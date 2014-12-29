//
//  MultiplayerMatchData.m
//  UM Liars Dice
//
//  Created by Alex Turner on 5/7/14.
//
//

#import "MultiplayerMatchData.h"
#import "SoarPlayer.h"
#import "ApplicationDelegate.h"

const int kNo_AIs = 0x10;
const int kAI_Only = 0x20;
const int kAI_Human = 0x30;
const int kAI_1 = 0x40;
const int kAI_2 = 0x41;
const int kAI_3 = 0x42;
const int kAI_4 = 0x43;
const int kAI_5 = 0x44;
const int kAI_6 = 0x45;
const int kAI_7 = 0x46;
const int kAI_8 = 0x47;

@implementation MultiplayerMatchData

@synthesize theData, theGame;

-(id)initWithGame:(DiceGame*)game
{
	self = [super init];

	if (self)
	{
		NSData* data = [GameKitGameHandler archiveAndCompressObject:game];

		ApplicationDelegate* delegate = [UIApplication sharedApplication].delegate;
		DDLogGameKit(@"Updated Match Data SHA1 Hash: %@", [delegate sha1HashFromData:data]);

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
			DiceGame* game = (DiceGame*)[GameKitGameHandler uncompressAndUnarchiveObject:data];

			if (!game || game->compatibility_build != COMPATIBILITY_BUILD)
			{
				// Invalid match so delete it
				for (GKTurnBasedParticipant* participant in match.participants)
					participant.matchOutcome = GKTurnBasedMatchOutcomeQuit;

				[match removeWithCompletionHandler:^(NSError* error)
				 {
					 if (error)
						 DDLogError(@"Error Removing Invalid Match: %@", error.description);
				 }];

				return nil;
			}

			self.theGame = game;
		}
		else if (data && request)
		{
			// Just joined but there is a game already in progress!

			DiceGame* game = (DiceGame*)[GameKitGameHandler uncompressAndUnarchiveObject:data];

			if (game.gameState)
			{
				[game.gameState decodePlayers:match withHandler:handler];
				game.players = [NSArray arrayWithArray:game.gameState.players];
				game.gameState.players = game.players;
			}
			else
				goto request;

			self.theGame = game;
		}
		else if (request)
		{
		request:
			self.theGame = [[DiceGame alloc] init];

			// New Match
			int AICount = 0;

			switch (request.playerGroup)
			{
				case kNo_AIs: AICount = 0;
					break;
				case kAI_Human | kAI_1: AICount = 1;
					break;
				case kAI_Human | kAI_2: AICount = 2;
					break;
				case kAI_Human | kAI_3: AICount = 3;
					break;
				case kAI_Human | kAI_4: AICount = 4;
					break;
				case kAI_Human | kAI_5: AICount = 5;
					break;
				case kAI_Human | kAI_6: AICount = 6;
					break;
				case kAI_Human | kAI_7: AICount = 7;
					break;
			}

			int humanCount = (int)[match.participants count];
			int currentHumanCount = 0;

			NSLock* lock = [[NSLock alloc] init];

			int totalPlayerCount = AICount + humanCount;

			for (int i = 0;i < totalPlayerCount;i++)
			{
				BOOL isAI = (BOOL)([self.theGame.randomGenerator randomNumber] % 2);

				if ((currentHumanCount > 0 && isAI && AICount > 0) || (currentHumanCount == humanCount))
				{
					[theGame addPlayer:[[SoarPlayer alloc] initWithGame:theGame connentToRemoteDebugger:NO lock:lock withGameKitGameHandler:handler difficulty:-1]];

					AICount--;
				}
				else
				{
					GKTurnBasedParticipant* participant = [match.participants objectAtIndex:currentHumanCount];
					currentHumanCount++;

					if ([[[GKLocalPlayer localPlayer] playerID] isEqualToString:[participant player].playerID])
						[theGame addPlayer:[[DiceLocalPlayer alloc] initWithName:[[GKLocalPlayer localPlayer] alias] withHandler:handler withParticipant:participant]];
					else
						[theGame addPlayer:[[DiceRemotePlayer alloc] initWithGameKitParticipant:participant withGameKitGameHandler:handler]];
				}
			}
			
			theGame.gameLock = lock;

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
					DDLogError(@"Error Removing Invalid Match: %@", error.description);
			}];
		}
	}

	return self;
}

@end
