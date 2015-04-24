//
//  Die.m
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "Die.h"
#import <stdlib.h>
#import "DiceGame.h"

@implementation Die

@synthesize dieValue, hasBeenPushed, markedToPush, identifier;

-(id)initWithCoder:(NSCoder*)decoder withCount:(int)count withPrefix:(NSString *)prefix
{
	self = [super init];

	if (self)
	{
		dieValue = [decoder decodeIntForKey:[NSString stringWithFormat:@"%@Die%i:dieValue", prefix, count]];
		hasBeenPushed = [decoder decodeBoolForKey:[NSString stringWithFormat:@"%@Die%i:hasBeenPushed", prefix, count]];
		identifier = [decoder decodeIntForKey:[NSString stringWithFormat:@"%@Die%i:identifier", prefix, count]];
		markedToPush = [decoder decodeBoolForKey:[NSString stringWithFormat:@"%@Die%i:markedToPush", prefix, count]];
	}

	return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder withCount:(int)count withPrefix:(NSString *)prefix
{
	[encoder encodeInt:dieValue forKey:[NSString stringWithFormat:@"%@Die%i:dieValue", prefix, count]];
	[encoder encodeInt:identifier forKey:[NSString stringWithFormat:@"%@Die%i:identifier", prefix, count]];
	[encoder encodeBool:hasBeenPushed forKey:[NSString stringWithFormat:@"%@Die%i:hasBeenPushed", prefix, count]];
	[encoder encodeBool:markedToPush forKey:[NSString stringWithFormat:@"%@Die%i:markedToPush", prefix, count]];
}

- (id)init:(DiceGame*)game
{
    self = [super init];
    if (self) {
		[self roll:game];
        hasBeenPushed = NO;
        markedToPush = NO;
    }
    return self;
}

// Initialize ourself with a value
- (id)initWithNumber:(int)dieValueToSet withIdentifier:(int)i
{
        //Call our own initialization routine then set our dieValue
    self = [self init];
    if (self)
    {
        dieValue = dieValueToSet;
        hasBeenPushed = NO;
        markedToPush = NO;
		self->identifier = i;
    }

    return self;
}

- (void)roll:(DiceGame*)game
{
	dieValue = [game.randomGenerator randomNumber] % NUMBER_OF_SIDES + 1;
	identifier = [game.randomGenerator randomNumber];
}

- (void)push
{
    hasBeenPushed = YES;
}

- (NSString*)description
{
	return [self asString];
}

- (NSString *)debugDescription
{
	return [self asString];
}

- (NSString *)asString
{
    return [[NSString stringWithFormat:@"%i", dieValue] stringByAppendingString:(hasBeenPushed ? @"*" : @"")];
}

+ (int)getNumberOfDiceSides
{
    return NUMBER_OF_SIDES;
}

- (BOOL)isEqual:(Die *)die
{
    if (dieValue == [die dieValue] && hasBeenPushed == [die hasBeenPushed])
        return YES;
    return NO;
}

- (NSDictionary*)dictionaryValue
{
//	@property (readonly) int dieValue;
//	@property (readonly) BOOL hasBeenPushed;
//	@property (readwrite, assign) BOOL markedToPush;
	
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	
	[dictionary setValue:[NSNumber numberWithInt:dieValue] forKey:@"dieValue"];
	[dictionary setValue:[NSNumber numberWithBool:hasBeenPushed] forKey:@"hasBeenPushed"];
	[dictionary setValue:[NSNumber numberWithBool:markedToPush] forKey:@"markedToPush"];
	
	return dictionary;
}

- (id)initWithDictionary:(NSDictionary*)dictionary
{
	self = [super init];
	
	if (self)
	{
		dieValue = [[dictionary objectForKey:@"dieValue"] intValue];
		hasBeenPushed = [[dictionary objectForKey:@"hasBeenPushed"] boolValue];
		markedToPush = [[dictionary objectForKey:@"markedToPush"] boolValue];
	}
	
	return self;
}

@end
