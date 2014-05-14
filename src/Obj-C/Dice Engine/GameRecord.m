//
//  GameRecord.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/3/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "GameRecord.h"

@implementation GameRecord

@synthesize gameTime, numPlayers, firstPlace, secondPlace, thirdPlace, fourthPlace;

- (id)initWithGameTime:(GameTime)aGameTime
			NumPlayers:(int)aNumPlayers
			firstPlace:(int)aFirstPlace
		   secondPlace:(int)aSecondPlace
			thirdPlace:(int)aThirdPlace
		   fourthPlace:(int)aFourthPlace
{
	self = [super init];

	if (self)
	{
		self.gameTime = aGameTime;
		self.numPlayers = aNumPlayers;
		self.firstPlace = aFirstPlace;
		self.secondPlace = aSecondPlace;
		self.thirdPlace = aThirdPlace;
		self.fourthPlace = aFourthPlace;
	}

	return self;
}

- (id) initWithDictionary:(NSDictionary*)dictionary
{
	self = [super init];

	if (self)
	{
		self.gameTime = [GameRecord DictionaryToGameTime:[dictionary objectForKey:@"GameTime"]];

		self.numPlayers = [(NSNumber*)[dictionary objectForKey:@"NumberOfPlayers"] intValue];

		self.firstPlace = [(NSNumber*)[dictionary objectForKey:@"FirstPlace"] intValue];
		self.secondPlace = [(NSNumber*)[dictionary objectForKey:@"SecondPlace"] intValue];
		self.thirdPlace = [(NSNumber*)[dictionary objectForKey:@"ThirdPlace"] intValue];
		self.fourthPlace = [(NSNumber*)[dictionary objectForKey:@"FourthPlace"] intValue];
	}

	return self;
}

+ (NSDictionary*) GameTimeToDictionary:(GameTime)time
{
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];

	[dictionary setObject:[NSNumber numberWithInt:time.year] forKey:@"Year"];
	[dictionary setObject:[NSNumber numberWithInt:time.month] forKey:@"Month"];
	[dictionary setObject:[NSNumber numberWithInt:time.day] forKey:@"Day"];
	[dictionary setObject:[NSNumber numberWithInt:time.hour] forKey:@"Hour"];
	[dictionary setObject:[NSNumber numberWithInt:time.minute] forKey:@"Minute"];
	[dictionary setObject:[NSNumber numberWithInt:time.second] forKey:@"Second"];

	return dictionary;
}

+ (GameTime) DictionaryToGameTime:(NSDictionary*)dictionary
{
	GameTime time;

	time.year = [(NSNumber*)[dictionary objectForKey:@"Year"] intValue];
	time.month = [(NSNumber*)[dictionary objectForKey:@"Month"] intValue];
	time.day = [(NSNumber*)[dictionary objectForKey:@"Day"] intValue];
	time.hour = [(NSNumber*)[dictionary objectForKey:@"Hour"] intValue];
	time.minute = [(NSNumber*)[dictionary objectForKey:@"Minute"] intValue];
	time.second = [(NSNumber*)[dictionary objectForKey:@"Second"] intValue];

	return time;
}

- (NSDictionary*) dictionaryRepresentation
{
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];

	[dictionary setObject:[GameRecord GameTimeToDictionary:self.gameTime] forKey:@"GameTime"];

	[dictionary setObject:[NSNumber numberWithInt:self.numPlayers] forKey:@"NumberOfPlayers"];
	[dictionary setObject:[NSNumber numberWithInt:self.firstPlace] forKey:@"FirstPlace"];
	[dictionary setObject:[NSNumber numberWithInt:self.secondPlace] forKey:@"SecondPlace"];
	[dictionary setObject:[NSNumber numberWithInt:self.thirdPlace] forKey:@"ThirdPlace"];
	[dictionary setObject:[NSNumber numberWithInt:self.fourthPlace] forKey:@"FourthPlace"];

	return dictionary;
}

@end
