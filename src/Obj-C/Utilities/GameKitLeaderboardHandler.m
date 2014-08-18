//
//  GameKitLeaderboardHandler.m
//  UM Liars Dice
//
//  Created by Alex Turner on 7/18/14.
//
//

#import "GameKitLeaderboardHandler.h"
#import <GameKit/GameKit.h>
#import "DiceGame.h"
#import "HistoryItem.h"

#include <libkern/OSAtomic.h>

@implementation GameKitLeaderboardHandler

@synthesize leaderboards;

- (id)init
{
	self = [super init];

	if (self)
	{
		[GKLeaderboard loadLeaderboardsWithCompletionHandler:^(NSArray* newLeaderboards, NSError* error)
		 {
			 self->leaderboards = newLeaderboards;
		 }];
	}

	return self;
}

- (void)updateGame:(DiceGame *)game
{
	if (!game.gameState.gameWinner)
		return;

	if ([NSThread isMainThread])
	{
		[self performSelectorInBackground:@selector(updateGame:) withObject:game];
		return;
	}

	volatile int* leaderboardsCompleted = malloc(sizeof(int));
	*leaderboardsCompleted = 0;

	for (GKLeaderboard* leaderboard in leaderboards)
		[leaderboard loadScoresWithCompletionHandler:^(NSArray* scores, NSError* error)
		 {
			 if (error)
				 DDLogError(@"Error: %@", error.description);

			 OSAtomicIncrement32(leaderboardsCompleted);
		 }];

	while (*leaderboardsCompleted != 9);
	
	free((void*)leaderboardsCompleted);
	
	NSUInteger winsOverall = 0, lossesOverall = 0; // #1
	NSUInteger winsHardestAI = 0, lossesHardestAI = 0; // #2
	NSUInteger winsMultiplayer = 0, lossesMultiplayer = 0; // #3
	NSUInteger challengesSuccess = 0, challengesLoss = 0; // #7
	NSUInteger exactSuccess = 0, exactLoss = 0; // #8
	NSUInteger winChallenges = 0, lossChallenges = 0; // #9

	for (GKLeaderboard* leaderboard in leaderboards)
	{
		GKScore* score = [leaderboard localPlayerScore];

		if ([leaderboard.identifier isEqualToString:@"sheernumbers_overallwins"])
			winsOverall = score.value;
		else if ([leaderboard.identifier isEqualToString:@"sheernumbers_multiplayerwin"])
			winsMultiplayer = score.value;
		else if ([leaderboard.identifier isEqualToString:@"sheernumbers_hardestaionlywins"])
			winsHardestAI = score.value;
	}

	NSUbiquitousKeyValueStore* defaults = [NSUbiquitousKeyValueStore defaultStore];
	lossesOverall = [((NSNumber*)[defaults objectForKey:@"Leaderboards_lossesOverall"]) unsignedIntegerValue];
	lossesHardestAI = [((NSNumber*)[defaults objectForKey:@"Leaderboards_lossesHardestAI"]) unsignedIntegerValue];
	lossesMultiplayer = [((NSNumber*)[defaults objectForKey:@"Leaderboards_lossesMultiplayer"]) unsignedIntegerValue];
	challengesLoss = [((NSNumber*)[defaults objectForKey:@"Leaderboards_challengesLoss"]) unsignedIntegerValue];
	exactLoss = [((NSNumber*)[defaults objectForKey:@"Leaderboards_exactLoss"]) unsignedIntegerValue];
	lossChallenges = [((NSNumber*)[defaults objectForKey:@"Leaderboards_lossChallenges"]) unsignedIntegerValue];
	challengesSuccess = [((NSNumber*)[defaults objectForKey:@"Leaderboards_challengesSuccess"]) unsignedIntegerValue];
	exactSuccess = [((NSNumber*)[defaults objectForKey:@"Leaderboards_exactSuccess"]) unsignedIntegerValue];
	winChallenges = [((NSNumber*)[defaults objectForKey:@"Leaderboards_winChallenges"]) unsignedIntegerValue];

	if ([game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class])
	{
		winsOverall++;

		if ([game isMultiplayer])
			winsMultiplayer++;

		if ([game hasHardestAI])
			winsHardestAI++;
	}
	else
	{
		lossesOverall++;

		if ([game isMultiplayer])
			lossesMultiplayer++;

		if ([game hasHardestAI])
			lossesHardestAI++;
	}

	for (HistoryItem* item in game.gameState.flatHistory)
	{
		PlayerState* player = [item player];

		if ([item actionType] == ACTION_CHALLENGE_BID ||
			[item actionType] == ACTION_CHALLENGE_PASS)
		{
			if ([[player playerPtr] isKindOfClass:DiceLocalPlayer.class])
			{
				// Challenger
				if ([item result] == 1)
					challengesSuccess++;
				else
					challengesLoss++;
			}
			else if ([[game.players objectAtIndex:[item value]] isKindOfClass:DiceLocalPlayer.class])
			{
				// Challengee
				if ([item result] == 0)
					winChallenges++;
				else
					lossChallenges++;
			}
		}
		else if ([item actionType] == ACTION_EXACT &&
				 [[player playerPtr] isKindOfClass:DiceLocalPlayer.class])
		{
			if ([item value] == 1)
				exactSuccess++;
			else
				exactLoss++;
		}
	}

	long double winloss_overall = 0.0;

	if (lossesOverall == 0)
		winloss_overall = winsOverall;
	else
		winloss_overall = ((long double)winsOverall)/((long double)lossesOverall);

	winloss_overall *= 1000;

	if (winsOverall + lossesOverall <= 30)
		winloss_overall = 0;

	long double winloss_hardestai = 0.0;

	if (lossesHardestAI == 0)
		winloss_hardestai = winsHardestAI;
	else
		winloss_hardestai = ((long double)winsHardestAI)/((long double)lossesHardestAI);

	winloss_hardestai *= 1000;

	if (winsHardestAI + lossesHardestAI <= 30)
		winloss_hardestai = 0;

	long double winsloss_multiplayer = 0.0;

	if (lossesMultiplayer == 0)
		winsloss_multiplayer = winsMultiplayer;
	else
		winsloss_multiplayer = ((long double)winsMultiplayer)/((long double)lossesMultiplayer);

	winsloss_multiplayer *= 1000;

	if (winsMultiplayer + lossesMultiplayer <= 30)
		winsloss_multiplayer = 0;



	long double successful_challenges = 0.0;

	if (challengesLoss == 0)
		successful_challenges = challengesSuccess;
	else
		successful_challenges = ((long double)challengesSuccess)/((long double)challengesLoss);

	successful_challenges *= 1000;

	if (challengesSuccess + challengesLoss <= 30)
		successful_challenges = 0;

	long double successful_exacts = 0.0;

	if (exactLoss == 0)
		successful_exacts = exactSuccess;
	else
		successful_exacts = ((long double)exactSuccess)/((long double)exactLoss);

	successful_exacts *= 1000;

	if (exactSuccess + exactLoss <= 30)
		successful_exacts = 0;

	long double survival_challenges = 0.0;

	if (lossChallenges == 0)
		survival_challenges = winChallenges;
	else
		survival_challenges = ((long double)winChallenges)/((long double)lossChallenges);

	survival_challenges *= 1000;

	if (winChallenges + lossChallenges <= 30)
		survival_challenges = 0;

	NSMutableArray* scores = [NSMutableArray array];

	for (GKLeaderboard* leaderboard in leaderboards)
	{
		GKScore* score = [leaderboard localPlayerScore];

		if (!score)
			score = [[GKScore alloc] initWithLeaderboardIdentifier:leaderboard.identifier forPlayer:[GKLocalPlayer localPlayer].playerID];

		if ([leaderboard.identifier isEqualToString:@"winlossratio_overall"])
			score.value = (int64_t)winloss_overall;
		else if ([leaderboard.identifier isEqualToString:@"winlossratio_hardestai"])
			score.value = (int64_t)winloss_hardestai;
		else if ([leaderboard.identifier isEqualToString:@"winlossratio_multiplayer"])
			score.value = (int64_t)winsloss_multiplayer;
		else if ([leaderboard.identifier isEqualToString:@"sheernumbers_overallwins"])
			score.value = winsOverall;
		else if ([leaderboard.identifier isEqualToString:@"sheernumbers_multiplayerwins"])
			score.value = winsMultiplayer;
		else if ([leaderboard.identifier isEqualToString:@"sheernumbers_hardestaionlywins"])
			score.value = winsHardestAI;
		else if ([leaderboard.identifier isEqualToString:@"miscllaneousratios_successfulchallenges"])
			score.value = (int64_t)successful_challenges;
		else if ([leaderboard.identifier isEqualToString:@"miscllaneousratios_successfulexacts"])
			score.value = (int64_t)successful_exacts;
		else if ([leaderboard.identifier isEqualToString:@"miscellaneousratios_sucessfulsurvivalofchallenges"])
			score.value = (int64_t)survival_challenges;

		[scores addObject:score];
	}

	[GKScore reportScores:scores withCompletionHandler:^(NSError* error)
	 {
		 if (error)
			 DDLogError(@"Error: %@", error.description);
	 }];

	[defaults setObject:[NSNumber numberWithUnsignedInteger:lossesOverall]
				 forKey:@"Leaderboards_lossesOverall"];
	[defaults setObject:[NSNumber numberWithUnsignedInteger:lossesHardestAI]
				 forKey:@"Leaderboards_lossesHardestAI"];
	[defaults setObject:[NSNumber numberWithUnsignedInteger:lossesMultiplayer]
				 forKey:@"Leaderboards_lossesMultiplayer"];
	[defaults setObject:[NSNumber numberWithUnsignedInteger:challengesLoss]
				 forKey:@"Leaderboards_challengesLoss"];
	[defaults setObject:[NSNumber numberWithUnsignedInteger:exactLoss]
				 forKey:@"Leaderboards_exactLoss"];
	[defaults setObject:[NSNumber numberWithUnsignedInteger:lossChallenges]
				 forKey:@"Leaderboards_lossChallenges"];
	[defaults setObject:[NSNumber numberWithUnsignedInteger:challengesSuccess]
				 forKey:@"Leaderboards_challengesSuccess"];
	[defaults setObject:[NSNumber numberWithUnsignedInteger:exactSuccess]
				 forKey:@"Leaderboards_exactSuccess"];
	[defaults setObject:[NSNumber numberWithUnsignedInteger:winChallenges]
				 forKey:@"Leaderboards_winChallenges"];
}

@end
