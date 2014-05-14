//
//  MultiplayerMatchData.m
//  UM Liars Dice
//
//  Created by Alex Turner on 5/7/14.
//
//

#import "MultiplayerMatchData.h"

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

		[theData retain];
	}

	return self;
}

-(id)initWithData:(NSData*)data
{
	self = [super init];

	if (self)
	{
		theGame = [NSKeyedUnarchiver unarchiveObjectWithData:theData];

		if (!theGame)
			return nil;

		[theGame retain];
	}

	return self;
}

-(void)dealloc
{
	if (theGame)
		[theGame release];

	if (theData)
		[theData release];

	[super dealloc];
}

@end
