//
//  DiceDatabase.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/3/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceDatabase.h"
#import "ApplicationDelegate.h"

@implementation DiceDatabase

- (id)init
{
    self = [super init];
    if (self)
	{
        defaults = [NSUbiquitousKeyValueStore defaultStore];

		[(ApplicationDelegate*)[[UIApplication sharedApplication] delegate] addInstance:self];
	}

    return self;
}

- (void)dealloc
{
	[(ApplicationDelegate*)[[UIApplication sharedApplication] delegate] removeInstance:self];

	[super dealloc];
}

+ (GameTime) getCurrentGameTime {
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    
    [dateFormatter setDateFormat:@"yyyy"];
    int year = [[dateFormatter stringFromDate:date] intValue];
    
    [dateFormatter setDateFormat:@"MM"];
    int month = [[dateFormatter stringFromDate:date] intValue];
    
    [dateFormatter setDateFormat:@"dd"];
    int day = [[dateFormatter stringFromDate:date] intValue];
    
    [dateFormatter setDateFormat:@"HH"];
    int hour = [[dateFormatter stringFromDate: date] intValue];
    
    [dateFormatter setDateFormat:@"mm"];
    int minute = [[dateFormatter stringFromDate:date] intValue];
    
    [dateFormatter setDateFormat:@"ss"];
    int second = [[dateFormatter stringFromDate:date] intValue];
    
    GameTime game_time = {
        year, month, day, hour, minute, second
    };

    return game_time;
}

- (void) addGameRecord:(GameRecord *)gameRecord {
    NSMutableArray* mutableArray = [NSMutableArray arrayWithArray:[defaults objectForKey:@"Games"]];
	[mutableArray addObject:[gameRecord dictionaryRepresentation]];

	[defaults setObject:mutableArray forKey:@"Games"];

	[defaults synchronize];
}

- (void) reset {
    [defaults setObject:[NSArray array] forKey:@"Games"];

	[defaults synchronize];
}

- (NSArray *) getGameRecords {
	NSArray* gameRecordEncodedArray = [defaults objectForKey:@"Games"];

	NSMutableArray* gameRecords = [[NSMutableArray alloc] initWithCapacity:gameRecordEncodedArray.count];

	for (NSDictionary* gameRecordEncodedObject in gameRecordEncodedArray)
		[gameRecords addObject:[[GameRecord alloc] initWithDictionary:gameRecordEncodedObject]];

    return gameRecords;
}

- (void) setPlayerName:(NSString *)playerName
{
	if ([GKLocalPlayer localPlayer].authenticated)
		playerName = [GKLocalPlayer localPlayer].playerID;

	[defaults setObject:playerName forKey:@"PlayerName"];

	[defaults synchronize];
}

- (NSString *) getPlayerName
{
	if ([GKLocalPlayer localPlayer].authenticated)
		return [GKLocalPlayer localPlayer].playerID;

    return [defaults objectForKey:@"PlayerName"];
}

- (void) setDifficulty:(NSInteger)difficulty
{
	[defaults setObject:[NSNumber numberWithLong:difficulty] forKey:@"PlayerDifficulty"];

	[defaults synchronize];
}

- (NSInteger) getDifficulty
{
	return [(NSNumber*)[defaults objectForKey:@"PlayerDifficulty"] integerValue];
}

- (void)reload
{
	[defaults synchronize];
}

@end
