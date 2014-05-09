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
    id ret = [self init];
    if (ret) {
        dieValue = dieValueToSet;
    }
    return ret;
}

- (void)roll
{
    dieValue = (arc4random() % ((unsigned)NUMBER_OF_SIDES) + 1);
}

- (void)push
{
    hasBeenPushed = YES;
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
