//
//  GameKitAchievementHandler.m
//  UM Liars Dice
//
//  Created by Alex Turner on 7/17/14.
//
//

#import "GameKitAchievementHandler.h"
#import "DiceGame.h"
#import "HistoryItem.h"
#import "SoarPlayer.h"
#import "PlayGameView.h"

@implementation GameKitAchievementHandler

@synthesize achievements;

-(id)init
{
	self = [super init];

	if (self)
	{
		[GKAchievement loadAchievementsWithCompletionHandler:^(NSArray* newAchievements, NSError* error)
		 {
			 if (!error)
				 self->achievements = [GameKitAchievementHandler addMissingAchievements:newAchievements];
			 else
				 DDLogError(@"Error: %@", error.description);
		 }];
	}

	return self;
}

+(NSArray*)addMissingAchievements:(NSArray*)achievements
{
	NSMutableArray* allAchievements = [NSMutableArray arrayWithArray:@[@"BasicThings1",
																	   @"BasicThings2",
																	   @"BasicThings3",
																	   @"BasicThings4",
																	   @"BasicThings5",
																	   @"BasicThings6",
																	   @"BasicThings7",
																	   @"BasicThings8",
																	   @"BasicThings9",
																	   @"BasicThings10",
																	   @"BasicThings11",
																	   @"BasicThings12",
																	   @"BasicThings13",
																	   @"BasicThings14",
																	   @"BasicThings15",
																	   @"ToStriveFor1",
																	   @"ToStriveFor2",
																	   @"ToStriveFor3",
																	   @"ToStriveFor4",
																	   @"ToStriveFor5",
																	   @"Hardest1",
																	   @"Hardest2",
																	   @"Hardest3",
																	   @"Hardest4",
																	   @"Hardest5",
																	   @"Hardest6",
																	   @"Hidden1",
																	   @"Hidden2",
																	   @"Hidden3",
																	   @"Hidden4"]];

	NSMutableArray* finalArray = [NSMutableArray arrayWithArray:achievements];
	
	for (GKAchievement* achievement in achievements)
	{
		NSString* achievementIdentifier = [achievement identifier];

		for (int i = 0;i < [allAchievements count];++i)
		{
			NSString* identifier = [allAchievements objectAtIndex:i];

			if ([identifier isEqualToString:achievementIdentifier])
			{
				[allAchievements removeObject:identifier];
				break;
			}
		}
	}

	for (NSString* identifier in allAchievements)
		[finalArray addObject:[[GKAchievement alloc] initWithIdentifier:identifier]];

	return finalArray;
}

+(BOOL)containsAchievement:(NSString*)identifier achievementList:(NSArray*)achievements
{
	for (GKAchievement* achievement in achievements)
	{
		if ([achievement.identifier isEqualToString:identifier])
			return YES;
	}

	return NO;
}


-(void)resetAchievements
{
	[GKAchievement resetAchievementsWithCompletionHandler:^(NSError* error)
	 {
		 if (error)
			 DDLogError(@"Error: %@", error.description);
	 }];
}

-(void)updateAchievements:(DiceGame*)game
{
	NSMutableArray* updatedAchievements = [NSMutableArray array];

	for (GKAchievement* achievement in achievements)
	{
		achievement.showsCompletionBanner = YES;

		if (achievement.percentComplete == 100)
			continue;

		if ([achievement.identifier isEqualToString:@"Hidden3"] && !game)
		{
			[GameKitAchievementHandler handleHiddenAchievement:achievement game:nil];
			[updatedAchievements addObject:achievement];
		}
		else if (game)
		{
			BOOL updated = NO;
			if ([achievement.identifier rangeOfString:@"BasicThings"].location != NSNotFound)
				updated = [GameKitAchievementHandler handleBasicAchievement:achievement game:game];
			else if ([achievement.identifier rangeOfString:@"ToStriveFor"].location != NSNotFound)
				updated = [GameKitAchievementHandler handleStriveAchievement:achievement game:game];
			else if ([achievement.identifier rangeOfString:@"Hardest"].location != NSNotFound)
				updated = [GameKitAchievementHandler handleHardAchievement:achievement game:game];
			else if ([achievement.identifier rangeOfString:@"Hidden"].location != NSNotFound)
				updated = [GameKitAchievementHandler handleHiddenAchievement:achievement game:game];

			if (updated)
				[updatedAchievements addObject:achievement];
		}
	}

	if ([updatedAchievements count] > 0)
		[GKAchievement reportAchievements:updatedAchievements withCompletionHandler:^(NSError* error)
		 {
			 if (error)
				 DDLogError(@"Error: %@", error.description);
		 }];
}

+(BOOL)handleBasicAchievement:(GKAchievement*)basicAchievement game:(DiceGame*)game
{
	int achievementID = [[basicAchievement.identifier substringFromIndex:11] intValue];

	switch (achievementID)
	{
		case 1:
			// Successful Challenge
			for (HistoryItem* item in game.gameState.flatHistory)
			{
				PlayerState* player = [item player];

				if (![[player playerPtr] isKindOfClass:DiceLocalPlayer.class])
					continue;

				if (([item actionType] == ACTION_CHALLENGE_BID ||
					[item actionType] == ACTION_CHALLENGE_PASS) &&
					[item result] == 1)
				{
					basicAchievement.percentComplete = 100.0;
					return YES;
				}
			}
			break;
		case 2:
			// Win a die back from an exact
			for (HistoryItem* item in game.gameState.flatHistory)
			{
				PlayerState* player = [item player];

				if (![[player playerPtr] isKindOfClass:DiceLocalPlayer.class])
					continue;

				if ([item actionType] == ACTION_EXACT &&
					[item result] == 1)
				{
					basicAchievement.percentComplete = 100.0;
					return YES;
				}
			}
			break;
		case 3:
		{
			// Successfully pass while telling the truth
			NSArray* flatHistory = game.gameState.flatHistory;

			for (int i = 0;i < [flatHistory count];++i)
			{
				if (i == 0)
					continue;

				HistoryItem* item = [flatHistory objectAtIndex:i];
				HistoryItem* previousItem = [flatHistory objectAtIndex:i-1];
				PlayerState* player = [previousItem player];

				if (![[player playerPtr] isKindOfClass:DiceLocalPlayer.class])
					continue;

				if ([item actionType] == ACTION_CHALLENGE_PASS && [item result] == 1)
					continue;

				if ([previousItem actionType] == ACTION_PASS &&
					[previousItem value] == 1)
				{
					basicAchievement.percentComplete = 100.0;
					return YES;
				}
			}
			break;
		}
		case 4:
		{
			// Successfully pass while lying
			NSArray* flatHistory = game.gameState.flatHistory;

			for (int i = 0;i < [flatHistory count];++i)
			{
				if (i == 0)
					continue;

				HistoryItem* item = [flatHistory objectAtIndex:i];
				HistoryItem* previousItem = [flatHistory objectAtIndex:i-1];
				PlayerState* player = [previousItem player];

				if (![[player playerPtr] isKindOfClass:DiceLocalPlayer.class])
					continue;

				if ([item actionType] == ACTION_CHALLENGE_PASS && [item result] == 1)
					continue;

				if ([previousItem actionType] == ACTION_PASS &&
					[previousItem value] == 0)
				{
					basicAchievement.percentComplete = 100.0;
					return YES;
				}
			}
			break;
		}
		case 5:
		{
			// Push at least one die while bidding
			NSArray* flatHistory = game.gameState.flatHistory;

			for (int i = 0;i < [flatHistory count];++i)
			{
				if (i == 0)
					continue;

				HistoryItem* item = [flatHistory objectAtIndex:i];
				HistoryItem* previousItem = [flatHistory objectAtIndex:i-1];
				PlayerState* player = [previousItem player];

				if (player != [item player])
					continue;

				if (![[player playerPtr] isKindOfClass:DiceLocalPlayer.class])
					continue;

				if ([previousItem actionType] == ACTION_BID &&
					[item actionType] == ACTION_PUSH)
				{
					basicAchievement.percentComplete = 100.0;
					return YES;
				}
			}
			break;
		}
		case 6:
		{
			// Push at least one die while passing
			NSArray* flatHistory = game.gameState.flatHistory;

			for (int i = 0;i < [flatHistory count];++i)
			{
				if (i == 0)
					continue;

				HistoryItem* item = [flatHistory objectAtIndex:i];
				HistoryItem* previousItem = [flatHistory objectAtIndex:i-1];
				PlayerState* player = [previousItem player];

				if (player != [item player])
					continue;

				if (![[player playerPtr] isKindOfClass:DiceLocalPlayer.class])
					continue;

				if ([previousItem actionType] == ACTION_PASS &&
					[item actionType] == ACTION_PUSH)
				{
					basicAchievement.percentComplete = 100.0;
					return YES;
				}
			}
			break;
		}
		case 7:
			// Win a match with at least one AI in it
			if (game.gameState.gameWinner != nil &&
				[game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class])
			{
				BOOL hasAI = NO;

				for (id<Player> player in game.players)
				{
					if ([player isKindOfClass:SoarPlayer.class])
					{
						hasAI = YES;
						break;
					}
				}

				if (!hasAI)
					return NO;

				basicAchievement.percentComplete = 100.0;
				return YES;
			}
			break;
		case 8:
			// Win a match that has at least one AI on the hardest difficulty in it.
			if (game.gameState.gameWinner != nil &&
				[game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class])
			{
				BOOL hasAI = NO;

				for (id<Player> player in game.players)
				{
					if ([player isKindOfClass:SoarPlayer.class] &&
						[(SoarPlayer*)player difficulty] == 4)
					{
						hasAI = YES;
						break;
					}
				}

				if (!hasAI)
					return NO;

				basicAchievement.percentComplete = 100.0;
				return YES;
			}
			break;
		case 9:
			// Win a match that has at least one human opponent in it.
			if (game.gameState.gameWinner != nil &&
				[game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class])
			{
				BOOL hasHuman = NO;

				for (id<Player> player in game.players)
				{
					if ([player isKindOfClass:DiceRemotePlayer.class])
					{
						hasHuman = YES;
						break;
					}
				}

				if (!hasHuman)
					return NO;

				basicAchievement.percentComplete = 100.0;
				return YES;
			}
			break;
		case 10:
			// In a match, survive a challenge against you without losing a die.
			for (HistoryItem* item in game.gameState.flatHistory)
			{
				if ([item actionType] != ACTION_CHALLENGE_BID &&
					[item actionType] != ACTION_CHALLENGE_PASS)
					continue;

				id<Player> player = [game.players objectAtIndex:[item value]];

				if (![player isKindOfClass:DiceLocalPlayer.class])
					continue;

				if ([item result] == 0)
				{
					basicAchievement.percentComplete = 100.0;
					return YES;
				}
			}
			break;
		case 11:
		{
			// Win a match that has 7 AI opponents.
			if (game.gameState.gameWinner != nil &&
				[game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class])
			{
				int AIcount = 0;

				for (id<Player> player in game.players)
				{
					if ([player isKindOfClass:SoarPlayer.class])
						AIcount++;
				}

				if (AIcount != 7)
					return NO;

				basicAchievement.percentComplete = 100.0;
				return YES;
			}
		}
			break;
		case 12:
			// Play a multiplayer match with at least one friend.
			for (id<Player> player in game.players)
			{
				if ([player isKindOfClass:DiceRemotePlayer.class])
				{
					DiceRemotePlayer* remote = player;

					BOOL isFriend = NO;

					for (NSString* string in [GKLocalPlayer localPlayer].friends)
						if ([string isEqualToString:remote.participant.playerID])
						{
							isFriend = YES;
							break;
						}

					if (isFriend)
					{
						basicAchievement.percentComplete = 100.0;
						return YES;
					}
				}
			}
			break;
		case 13:
			// Win a multiplayer match that has at least one friend in it.
			if (game.gameState.gameWinner != nil &&
				[game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class])
			{
				BOOL hasFriend = NO;

				for (id<Player> player in game.players)
				{
					BOOL isFriend = NO;

					for (NSString* string in [GKLocalPlayer localPlayer].friends)
						if ([string isEqualToString:((DiceRemotePlayer*)player).participant.playerID])
						{
							isFriend = YES;
							break;
						}

					if ([player isKindOfClass:DiceRemotePlayer.class] &&
						isFriend)
					{
						hasFriend = YES;
						break;
					}
				}

				if (!hasFriend)
					return NO;

				basicAchievement.percentComplete = 100.0;
				return YES;
			}
			break;
		case 14:
			// Play a multiplayer match that has at least one AI and one human opponent.
			{
				BOOL hasHuman = NO;
				BOOL hasAI = NO;

				for (id<Player> player in game.players)
				{
					if ([player isKindOfClass:DiceRemotePlayer.class])
						hasHuman = YES;
					else if ([player isKindOfClass:SoarPlayer.class])
						hasAI = YES;
				}

				if (!hasHuman || !hasAI)
					return NO;

				basicAchievement.percentComplete = 100.0;
				return YES;
			}
			break;
		case 15:
			// Win a multiplayer match that has at least one AI and one human opponent.
			if (game.gameState.gameWinner != nil &&
				[game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class])
			{
				BOOL hasHuman = NO;
				BOOL hasAI = NO;

				for (id<Player> player in game.players)
				{
					if ([player isKindOfClass:DiceRemotePlayer.class])
						hasHuman = YES;
					else if ([player isKindOfClass:SoarPlayer.class])
						hasAI = YES;
				}

				if (!hasHuman || !hasAI)
					return NO;

				basicAchievement.percentComplete = 100.0;
				return YES;
			}
			break;
		default:
			DDLogDebug(@"Unknown achievement ID! %i", achievementID);
			break;
	}

	return NO;
}

+(BOOL)handleStriveAchievement:(GKAchievement*)striveAchievement game:(DiceGame*)game
{
	int achievementID = [[striveAchievement.identifier substringFromIndex:11] intValue];

	switch (achievementID)
	{
		case 1:
			// Win 20 matches either non-consecutively or consecutively.
			if (game.gameState.gameWinner != nil &&
				[game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class])
			{
				striveAchievement.percentComplete += 5.0;
				return YES;
			}
			break;
		case 2:
		{
			int challengeCount = 0;

			// In a match, survive 3 challenges against you without losing a die, in a row.
			for (HistoryItem* item in game.gameState.flatHistory)
			{
				if ([item actionType] != ACTION_CHALLENGE_BID &&
					[item actionType] != ACTION_CHALLENGE_PASS)
					continue;

				id<Player> player = [game.players objectAtIndex:[item value]];

				if (![player isKindOfClass:DiceLocalPlayer.class])
					continue;

				if ([item result] == 0)
					challengeCount++;

				if (challengeCount >= 3)
				{
					striveAchievement.percentComplete = 100.0;
					return YES;
				}
			}
			break;
		}
		case 3:
			// In three consecutive matches, use your exact to win a die each time.
		{
			if (!game.gameState.gameWinner)
				return NO;

			int exactCount = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Achievement-ExactsInARow"] intValue];
			BOOL successfullyUsedExact = NO;

			for (HistoryItem* item in game.gameState.flatHistory)
			{
				if ([item actionType] != ACTION_EXACT)
					continue;

				PlayerState* player = [item player];

				if (![[player playerPtr] isKindOfClass:DiceLocalPlayer.class])
					continue;

				if ([item value] == 1)
				{
					successfullyUsedExact = YES;
					break;
				}
			}

			if (successfullyUsedExact)
				exactCount++;
			else
				exactCount = 0;

			if (exactCount >= 3)
			{
				striveAchievement.percentComplete = 100.0;
				return YES;
			}

			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:exactCount] forKey:@"Achievement-ExactsInARow"];

			break;
		}
		case 4:
			// Win a match without losing a single die.
			if (game.gameState.gameWinner &&
				[game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class])
			{
				for (HistoryItem* item in game.gameState.flatHistory)
				{
					if ([item actionType] != ACTION_CHALLENGE_BID &&
						[item actionType] != ACTION_CHALLENGE_PASS)
						continue;

					id<Player> player = [game.players objectAtIndex:[item value]];

					if (![player isKindOfClass:DiceLocalPlayer.class])
						continue;

					if ([item result] == 1)
						return NO;
				}

				striveAchievement.percentComplete = 100.0;
				return YES;
			}
			break;
		case 5:
			// Win 5 matches in a row.
		{
			if (!game.gameState.gameWinner)
				return NO;

			int matchesWon = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Achievement-Win5Matches"] intValue];

			if ([game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class])
				matchesWon++;
			else
				matchesWon = 0;

			if (matchesWon >= 5)
			{
				striveAchievement.percentComplete = 100.0;
				return YES;
			}

			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:matchesWon] forKey:@"Achievement-Win5Matches"];
			
			break;
		}
		default:
			DDLogDebug(@"Unknown achievement ID! %i", achievementID);
			break;
	}

	return NO;
}

+(BOOL)handleHardAchievement:(GKAchievement*)hardAchievement game:(DiceGame*)game
{
	int achievementID = [[hardAchievement.identifier substringFromIndex:7] intValue];

	switch (achievementID)
	{
		case 1:
			// Win 100 matches, either non-consecutively or consecutively.
			if (game.gameState.gameWinner != nil &&
				[game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class])
			{
				hardAchievement.percentComplete += 1.0;
				return YES;
			}
			break;
		case 2:
		{
			int challengeCount = 0;

			// In a match, survive 10 challenges in a row.
			for (HistoryItem* item in game.gameState.flatHistory)
			{
				if ([item actionType] != ACTION_CHALLENGE_BID &&
					[item actionType] != ACTION_CHALLENGE_PASS)
					continue;

				id<Player> player = [game.players objectAtIndex:[item value]];

				if (![player isKindOfClass:DiceLocalPlayer.class])
					continue;

				if ([item result] == 0)
					challengeCount++;

				if (challengeCount >= 10)
				{
					hardAchievement.percentComplete = 100.0;
					return YES;
				}
			}
			break;
		}
		case 3:
			if (game.gameState.gameWinner &&
				[game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class])
			{
				// In a match, be the only person to eliminate people, either via them challenging you and losing, them exacting your bids and losing, or you challenging them and winning.
				for (HistoryItem* item in game.gameState.flatHistory)
				{
					if ([item actionType] != ACTION_LOST)
						continue;

					if ([item value] != [game.gameState.gameWinner getID])
						return NO;
				}

				hardAchievement.percentComplete = 100.0;
				return YES;
			}
			break;
		case 4:
			// In a match with at least five starting players, until there only four players remaining, only have one turn per round.  This means that the turn will never “get back” to you.
			if ([game.players count] >= 5 &&
				[game.gameState.losers count] == ([game.players count] - 4))
			{
				for (NSArray* roundHistory in game.gameState.roundHistory)
				{
					int count = 0;

					for (HistoryItem* item in roundHistory)
					{
						if ([item actionType] == ACTION_PUSH)
							continue;

						PlayerState* itemState = [item player];
						if ([[itemState playerPtr] isKindOfClass:DiceLocalPlayer.class])
							count++;

						if (count > 1)
							return NO;
					}
				}

				hardAchievement.percentComplete = 100.0;
				return YES;
			}
			break;
		case 5:
			// Win 10 matches in a row against the hardest AI.
		{
			if (!game.gameState.gameWinner)
				return NO;

			int matchesWon = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Achievement-Win10Matches"] intValue];

			BOOL hasHardAI = NO;

			for (id<Player> player in game.players)
				if ([player isKindOfClass:SoarPlayer.class] &&
					((SoarPlayer*)player).difficulty == 4)
					hasHardAI = YES;

			if ([game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class] &&
				hasHardAI)
				matchesWon++;
			else
				matchesWon = 0;

			if (matchesWon >= 10)
			{
				hardAchievement.percentComplete = 100.0;
				return YES;
			}

			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:matchesWon] forKey:@"Achievement-Win10Matches"];

			break;
		}
		case 6:
			// In a match with at least four starting players, never bid ones in the match and still win the match.
			if (game.gameState.gameWinner &&
				[game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class])
			{
				for (HistoryItem* item in game.gameState.flatHistory)
				{
					if ([item actionType] != ACTION_BID)
						continue;

					PlayerState* itemState = [item player];

					if ([itemState playerPtr] != game.gameState.gameWinner)
						continue;

					if ([item bid].rankOfDie == 1)
						return NO;
				}

				hardAchievement.percentComplete = 100.0;
				return YES;
			}
			break;
		default:
			DDLogDebug(@"Unknown achievement ID! %i", achievementID);
			break;
	}

	return NO;
}

+(BOOL)handleHiddenAchievement:(GKAchievement*)hiddenAchievement game:(DiceGame*)game
{
	int achievementID = [[hiddenAchievement.identifier substringFromIndex:6] intValue];

	switch (achievementID)
	{
		case 1:
			// Win a match that has at least one developer playing in it.
			if (game.gameState.gameWinner &&
				[game.gameState.gameWinner isKindOfClass:DiceLocalPlayer.class])
			{
				BOOL hasDeveloper = NO;

				for (id<Player> player in game.players)
				{
					if ([[player getGameCenterName] isEqualToString:@"G:1178810147"] ||
						[[player getGameCenterName] isEqualToString:@"G:1840153818"])
					{
						hasDeveloper = YES;
						break;
					}
				}

				if (hasDeveloper)
				{
					hiddenAchievement.percentComplete = 100.0;
					return YES;
				}
			}
			break;
		case 2:
			// Be a beta tester for Liar’s Dice.
//#ifdef DEBUG
			hiddenAchievement.percentComplete = 100.0;
			return YES;
//#else
//			return NO;
//#endif
			break;
		case 3:
			// In a match, break the AI.
			if (game == nil)
			{
				hiddenAchievement.percentComplete = 100.0;
				return YES;
			}
			break;
		case 4:
			// Play the Michigan Fight Song.
			// Conditions not yet there
			hiddenAchievement.percentComplete = 0.0;
			return NO;
		default:
			DDLogDebug(@"Unknown achievement ID! %i", achievementID);
			break;
	}

	return NO;
}

@end
