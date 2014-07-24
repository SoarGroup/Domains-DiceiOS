//
//  Die.m
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "Die.h"
#import <stdlib.h>

@implementation Die

@synthesize dieValue, hasBeenPushed, markedToPush;

-(id)initWithCoder:(NSCoder*)decoder withCount:(int)count withPrefix:(NSString *)prefix
{
	self = [super init];

	if (self)
	{
		dieValue = [decoder decodeIntForKey:[NSString stringWithFormat:@"%@Die%i:dieValue", prefix, count]];
		hasBeenPushed = [decoder decodeBoolForKey:[NSString stringWithFormat:@"%@Die%i:hasBeenPushed", prefix, count]];
		markedToPush = [decoder decodeBoolForKey:[NSString stringWithFormat:@"%@Die%i:markedToPush", prefix, count]];
	}

	return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder withCount:(int)count withPrefix:(NSString *)prefix
{
	[encoder encodeInt:dieValue forKey:[NSString stringWithFormat:@"%@Die%i:dieValue", prefix, count]];
	[encoder encodeBool:hasBeenPushed forKey:[NSString stringWithFormat:@"%@Die%i:hasBeenPushed", prefix, count]];
	[encoder encodeBool:markedToPush forKey:[NSString stringWithFormat:@"%@Die%i:markedToPush", prefix, count]];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self roll];
        hasBeenPushed = NO;
        markedToPush = NO;
    }
    return self;
}

// Initialize ourself with a value
- (id)initWithNumber:(int)dieValueToSet
{
        //Call our own initialization routine then set our dieValue
    self = [self init];
    if (self)
        dieValue = dieValueToSet;

    return self;
}

- (void)roll
{
#ifdef DEBUG
	dieValue = (rand() % NUMBER_OF_SIDES + 1);
#else
    dieValue = (arc4random_uniform((unsigned)NUMBER_OF_SIDES) + 1);
#endif
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

@end
