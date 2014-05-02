//
//  DiceDatabase.h
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/3/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameRecord.h"

@interface DiceDatabase : NSObject
{
	NSUbiquitousKeyValueStore *defaults;
}

+ (GameTime) getCurrentGameTime;
- (void) addGameRecord:(GameRecord *)gameRecord;
- (NSArray *) getGameRecords;
- (void) reset;
- (void) setPlayerName:(NSString *)name;
- (NSString *) getPlayerName;

- (void) setDifficulty:(NSInteger)difficulty;
- (NSInteger) getDifficulty;

- (void)reload;

@end
