    //
    //  Bid.m
    //  iSoar
    //
    //  Created by Alex on 6/20/11.
    //  Copyright (c) 2012 University of Michigan. All rights reserved.
    //

#import "Bid.h"

@implementation Bid

    //Synthesize our properties
@synthesize diceToPush;

@synthesize playerID, rankOfDie, numberOfDice, playerName;

    //Initialize ourself
- (id)initWithPlayerID:(NSInteger)playerIDToSet name:(NSString *)aPlayerName dice:(int)dice rank:(int)rank
{
    self = [super init]; //check to makesure our super class initialized properly
    if (self) {
        // set our local variables
        if (dice <= 0) {
            NSLog(@"Creating bid with zero dice!");
            // HACK
            dice = 1;
        }
        playerID = playerIDToSet;
        numberOfDice = dice;
        rankOfDie = rank;
        self.playerName = aPlayerName;
    }
    return self;
}

    //Initialize ourself by calling our default method but also set some other properties
- (id)initWithPlayerID:(NSInteger)playerIDToSet name:(NSString *)aPlayerName dice:(int)dice rank:(int)rank push:(NSArray *)dicePushing
{
    id ret = [self initWithPlayerID:playerID name:aPlayerName dice:dice rank:rank];
    if (ret) {
        diceToPush = dicePushing;
        [diceToPush retain];
    }
    return ret;
}

    //Is this bid legal?
- (BOOL)isLegalRaise:(Bid *)previousBid specialRules:(BOOL)specialRules playerSpecialRules:(BOOL)playerSpecialRules
{
    if (playerSpecialRules && [previousBid rankOfDie] != [self rankOfDie])
    {
        return NO;
    }
    if (self.rankOfDie == 1 && previousBid.rankOfDie != 1 && !specialRules)
    {
        int requiredNumberOfDice = (int) ceil(previousBid.numberOfDice / 2.0); //Whats the minimum number of ones we have to bid
        
        if (self.numberOfDice >= requiredNumberOfDice) //Is our bet correct?
        {
            return YES;
        }
    }
    else if (previousBid.rankOfDie == 1 && self.rankOfDie != 1 && !specialRules)
    { //If the last bid was a one...
        int requiredNumberOfDice = previousBid.numberOfDice * 2 + 1; // Whats the minimum number of dice we have to bid?
        if (self.numberOfDice >= requiredNumberOfDice)
        {
            return YES;
        }
    }
    else
    { // Otherwise...
        if (self.rankOfDie > previousBid.rankOfDie &&
            self.numberOfDice == previousBid.numberOfDice) //Is our rank bigger than the previous rank?
        {
            return YES;
        }
        
        if (self.numberOfDice > previousBid.numberOfDice) //Is the number of dice more than the previous rank?
        {
            return YES;
        }
    }
    return NO;
}

    //Dealloc method
- (void)dealloc
{
        //Release our array of dice we are pushing, only alloc'd variable that is never autoreleased
    [super dealloc];
}

-(NSString *)stringForDieFace:(NSInteger)die andIsPlural:(BOOL)plural {
	switch (die)
	{
		case 1:
			return [@"one" stringByAppendingString:(plural ? @"s" : @"")];
		case 2:
			return [@"two" stringByAppendingString:(plural ? @"s" : @"")];
		case 3:
			return [@"three" stringByAppendingString:(plural ? @"s" : @"")];
		case 4:
			return [@"four" stringByAppendingString:(plural ? @"s" : @"")];
		case 5:
			return [@"five" stringByAppendingString:(plural ? @"s" : @"")];
		case 6:
			return [@"six" stringByAppendingString:(plural ? @"es" : @"")];
		default:
			return [@"unknown" stringByAppendingString:(plural ? @"s" : @"")];
	}
}

    //Ourself as a human readable string
- (NSString *)asString
{
    return [NSString stringWithFormat:@"%@ bid %d %@", self.playerName, self.numberOfDice, [self stringForDieFace:self.rankOfDie andIsPlural:(self.numberOfDice > 1)]];
}

- (NSString *)asStringOldStyle
{
    return [NSString stringWithFormat:@"%@ bid %d %ds", self.playerName, self.numberOfDice, self.rankOfDie];
}

@end
