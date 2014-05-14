//
//  Player.m
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "PlayerState.h"
#import <stdlib.h>

#import "Die.h"
#import "HistoryItem.h"
#import "DiceGameState.h"
#import "DiceLocalPlayer.h"

@implementation PlayerState

@synthesize playerID, playerHasPassed, playerHasExacted, playerHasPushedAllDice, gameState, numberOfDice, maxNumberOfDice, hasLost, playerName, arrayOfDice, lock, hasDoneSpecialRules;

// Set the number of dice that the player has while making sure its 1)
// not more than the max number of dice and 2) not less than 0.
- (void)setNumberOfDice:(int)newNumberOfDice
{
    if (newNumberOfDice > maxNumberOfDice)
    {
        numberOfDice = maxNumberOfDice;
        return;
    }
    else if (newNumberOfDice < 0)
    {
        numberOfDice = 0;
        return;
    }
    
    numberOfDice = newNumberOfDice;
    
    /*
    if (numberOfDice == 0)
        [arrayOfDice removeAllObjects];
     */
}

- (BOOL) hasWon
{
    return self.gameState.gameWinner == self;
}

    //Initilization method
- (id)initWithName:(NSString*)name withID:(int)ID withNumberOfDice:(int)dice withDiceGameState:(DiceGameState *)aGameState
{
        //Same deal as the DiceGameState initialization, make sure our super class initializes properly, otherwise return ourself which will be nil (it will be the correct address if it initilized properly
    self = [super init];

    if (self) {
            //Set our local variables
        self.lock = [[[NSLock alloc] init] autorelease];
        [self.lock lock];
        self.playerName = name;
        playerID = ID;
        numberOfDice = dice;
        maxNumberOfDice = dice;
        hasLost = NO;
        playerHasPassed = NO;
        playerHasExacted = NO;
        
        self.gameState = aGameState;
        
        self.arrayOfDice = [[[NSMutableArray alloc] init] autorelease];
        
            //Set our dice
        for (int i = 0;i < dice;i++)
            [arrayOfDice addObject:[[[Die alloc] init] autorelease]];
        
        specialRules = NO;
        hasDoneSpecialRules = NO;
        [self.lock unlock];
    }

    return self;
}

    //Dealloc our alloc'd variables that were never autoreleased
- (void)dealloc
{
    [arrayOfDice release];
    [super dealloc];
}

    //Its a new round, set everything up
- (void)isNewRound
{
    [self.lock lock];
    if (numberOfDice == 1 && !hasDoneSpecialRules && [self getNumberOfPlayers] > 2)
    {
        specialRules = YES;
        hasDoneSpecialRules = YES;
    }
    else if (specialRules)
    {
        specialRules = NO;
    }
        //Remove all the old dice
    [arrayOfDice removeAllObjects];
    playerHasPassed = NO;
    //Create our new dice
    for (int i = 0;i < numberOfDice;i++) {
        Die *newDie = [[Die alloc] init];
        [newDie autorelease];
        
        [arrayOfDice addObject:newDie];
    }
	
	if ([[gameState getPlayerWithID:self.playerID] isKindOfClass:[DiceLocalPlayer class]])
	{
		for (int i = 1;i < [arrayOfDice count];i++)
		{
			Die* die = [arrayOfDice objectAtIndex:i];
			int dieValue = [die dieValue];
			int hole = i;
			
			while (hole > 0 && [[arrayOfDice objectAtIndex:(hole - 1)] dieValue] > dieValue)
			{
				[arrayOfDice exchangeObjectAtIndex:hole withObjectAtIndex:(hole-1)];
				hole -= 1;
			}
		}
	}
	
    [self.lock unlock];
}

// Method for pushing our dice
- (void)pushDice:(NSArray *)diceToPush
{
    [self.lock lock];
    playerHasPassed = NO;
	for (Die* die in diceToPush)
	{
		for (Die* arrayDie in arrayOfDice)
		{
			if ([die isEqual:arrayDie] && !die.hasBeenPushed)
			{
				[arrayDie push];
				arrayDie.markedToPush = YES;
				break;
			}
		}
	}

	for (Die* arrayDie in arrayOfDice)
	{
		if (!arrayDie.hasBeenPushed)
			[arrayDie roll];
	}

	// Sort dice
	arrayOfDice = [NSMutableArray arrayWithArray:[arrayOfDice sortedArrayUsingComparator:^(Die* obj1, Die* obj2)
				   {
					   if (obj1.hasBeenPushed && !obj2.hasBeenPushed)
						   return (NSComparisonResult)NSOrderedAscending;
					   else if (obj2.hasBeenPushed && !obj1.hasBeenPushed)
						   return (NSComparisonResult)NSOrderedDescending;
					   else
					   {
						   if (obj1.dieValue > obj2.dieValue)
							   return (NSComparisonResult)NSOrderedDescending;
						   else if (obj1.dieValue < obj2.dieValue)
							   return (NSComparisonResult)NSOrderedAscending;

						   return (NSComparisonResult)NSOrderedSame;
					   }
				   }]];

	[arrayOfDice retain];
    
        //Set whether the player has pushed all their dice to the opposite of isThereDiceLeft
    playerHasPushedAllDice = NO;
    [self.lock unlock];
}

    //return a non-modifiable array of unpushed dice
- (NSArray *)unPushedDice
{
    [self.lock lock];
    NSMutableArray *unPushedDice = [[NSMutableArray alloc] init];
    for (Die *die in arrayOfDice) {
        if ([die isKindOfClass:[Die class]]) {
            if (![die hasBeenPushed]) {
                [unPushedDice addObject:die];
            }
        }
    }
    
    NSArray *array = [[NSArray alloc] initWithArray:unPushedDice];
    [unPushedDice release];
    [array autorelease];
    [self.lock unlock];
    return array;
}

    //return a non-modifiable array of pushed dice
- (NSArray *)pushedDice
{
    [self.lock lock];
    NSMutableArray *pushedDice = [[[NSMutableArray alloc] init] autorelease];
    for (Die *die in arrayOfDice) {
        if ([die isKindOfClass:[Die class]]) {
            if ([die hasBeenPushed]) {
                [pushedDice addObject:die];
            }
        }
    }
    
    NSArray *array = [NSArray arrayWithArray:pushedDice];
    [self.lock unlock];
    return array;
}

- (NSArray *)markedToPushDice
{
	[self.lock lock];
    NSMutableArray *markedDice = [[NSMutableArray alloc] init];
    for (Die *die in arrayOfDice) {
        if ([die isKindOfClass:[Die class]]) {
            if ([die markedToPush] && ![die hasBeenPushed]) {
                [markedDice addObject:die];
            }
        }
    }
    
    NSArray *array = [[NSArray alloc] initWithArray:markedDice];
    [markedDice release];
    [array autorelease];
    [self.lock unlock];
    return array;
}

    //Can we bid?
- (BOOL)canBid
{
        //If we have lost, we can't
    if (hasLost) return NO;
        //if the current player is us then yes we can otherwise return NO
    PlayerState *currentState = [self.gameState getCurrentPlayerState];
    bool ret = currentState == self;
    return ret;
}

- (BOOL) canChallengeAnything
{
    return [self canChallengeBid]
    || [self canChallengeLastPass]
    || [self canChallengeSecondLastPass];
}

// Can we challenge a bid?
- (BOOL)canChallengeBid {
    return [self getChallengeableBid] != nil;
}

- (Bid *) getChallengeableBid
{
        // Have we lost? If so of course we can't
    if (hasLost) return NO;
        // Get the previous bid for the next check
    Bid *previousBid = self.gameState.previousBid;
        // Make sure the current player is us, the previous bid exists, and the previous bid's playerID is not us
    
    HistoryItem *item = [self.gameState lastHistoryItem];
    if (item != nil)
    {   
        if (item.actionType == ACTION_BID)
        {
            if ([self.gameState getCurrentPlayerState] == self)
            {
                if (previousBid != nil)
                {
                    if (previousBid.playerID != playerID)
                    {
                        return previousBid;
                    }
                }
            }
        }
    }
    
    if ([[self.gameState history] count] >= 2)
    {
        HistoryItem *secondToLastHistoryItem = [[self.gameState history] objectAtIndex:[[self.gameState history] count] - 2];
        
        if (secondToLastHistoryItem.actionType == ACTION_BID && 
            [self.gameState lastHistoryItem].actionType == ACTION_PUSH &&
            [self.gameState getCurrentPlayerState] == self &&
            previousBid != nil &&
            [previousBid playerID] != playerID)
        {
            return previousBid;
        }
        else if (secondToLastHistoryItem.actionType == ACTION_BID && 
                 [self.gameState lastHistoryItem].actionType == ACTION_PASS &&
                 [self.gameState getCurrentPlayerState] == self &&
                 previousBid != nil &&
                 [previousBid playerID] != playerID) {
            return previousBid;
        }
        else if ([[self.gameState history] count] >= 3) {
            HistoryItem *thirdToLastHistoryItem = [[self.gameState history] objectAtIndex:[[self.gameState history] count] - 3];
                if (thirdToLastHistoryItem.actionType == ACTION_BID && 
                    secondToLastHistoryItem.actionType == ACTION_PUSH && 
                    [self.gameState lastHistoryItem].actionType == ACTION_PASS &&
                    [self.gameState getCurrentPlayerState] == self &&
                    previousBid != nil &&
                    [previousBid playerID] != playerID) {
                    return previousBid;
            }
        }
    }
    
    return nil;
}

    //Can we challenge the last pass?
- (BOOL)canChallengeLastPass
{
    return [self getChallengeableLastPass] != -1;
}

// Returns the playerID of the player who passed, or -1 if no such player exists.
- (int)getChallengeableLastPass {
    if (hasLost) return -1;
    HistoryItem *historyItem = [self.gameState lastHistoryItem];
    if (historyItem != nil && [self.gameState getCurrentPlayerState] == self && historyItem.actionType == ACTION_PASS)
    {
		if (historyItem.player.playerID != self.playerID)
			return historyItem.player.playerID;
    }
	
    return -1;
}


    //Can we challenge the second to last pass?
- (BOOL)canChallengeSecondLastPass
{
    return [self getChallengeableSecondLastPass] != -1;
}

- (int) getChallengeableSecondLastPass {
    if (hasLost)
		return -1;
	
    if (![self canChallengeLastPass])
		return -1;
    
    NSArray *history = [self.gameState history];
	
    if (!history || [history count] < 2)
		return -1;
    
    HistoryItem *item;
	
    if ([[history objectAtIndex:[history count] - 2] isKindOfClass:[HistoryItem class]])
        item = [history objectAtIndex:[history count] - 2];
	else
		item = nil;
	
    if (item != nil && [self.gameState getCurrentPlayerState] == self && item.actionType == ACTION_PASS)
    {
		if (item.player.playerID != self.playerID)
			return item.player.playerID;
    }
    return -1;
}

- (BOOL) isMyTurn
{
    return (![self.gameState hasAPlayerWonTheGame]) && [[self.gameState getCurrentPlayer] getID] == self.playerID;
}

    //Can we exact?
- (BOOL)canExact
{
    if (hasLost) return -1;
    Bid *previousBid = [self.gameState previousBid];
    return ([self isMyTurn] && !playerHasExacted && previousBid && [previousBid playerID] != playerID);
}

    //Can we pass?
- (BOOL)canPass
{
    if (hasLost) return NO;
    return ([self isMyTurn] && !playerHasPassed && [arrayOfDice count] > 1);
}

    //Can we push?
- (BOOL)canPush
{
    if (hasLost) return NO;
    HistoryItem *item = [self.gameState lastHistoryItem];
    return (item && item.player == self && item.actionType == ACTION_BID && [[self unPushedDice] count] > 1);
}

    //Can we accept?
- (BOOL)canAccept
{
    if (hasLost) return NO;
    return NO;
}

- (BOOL)playerHasAllSameDice
{
    int value = -1;
    [self.lock lock];
    for (Die *die in arrayOfDice) {
        if ([die isKindOfClass:[Die class]]) {
            if (value == -1)
            {
                value = [die dieValue];
            } else {
                if ([die dieValue] != value) {
                    [self.lock unlock];
                    return NO;
                }
            }
        }
    }
    [self.lock unlock];
    return YES;
}

- (BOOL)isInSpecialRules
{
    return specialRules;
}

    //Our name
- (NSString *)asString
{
    return playerName;
}

    //Our state as a human readable string
- (NSString *)stateString:(BOOL)showHidden
{
    [self.lock lock];
    NSString *string = [@"" stringByAppendingFormat:@"(%@): ", playerName];
    if (showHidden)
    {
        int i = 0;
        for (Die *die in arrayOfDice) {
            if ([die isKindOfClass:[Die class]]) {
                string = [string stringByAppendingString:[die asString]];
                if ((i + 1) < [arrayOfDice count])
                    string = [string stringByAppendingString:@" "];
                ++i;
            }
        }
    } else {
        int i = 0;
        for (Die *die in arrayOfDice) {
            if ([die isKindOfClass:[Die class]]) {
                string = [string stringByAppendingString:([die hasBeenPushed] ? [die asString] : @"?")];
                if ((i + 1) < [arrayOfDice count])
                    string = [string stringByAppendingString:@" "];
                ++i;
            }
        }
    }
    [self.lock unlock];
    return string;
}

- (NSString*) perceptionString:(BOOL)showPrivate
{
    if (showPrivate)
    {
        return [self.gameState stateString:self.playerID];
    }
    return [self.gameState stateString:-2]; // -2 for no private information
}

- (NSString *)headerString:(BOOL)singleLine {
    return [gameState headerString:self.playerID singleLine:singleLine];
}

- (NSInteger) getNumberOfPlayers {
    return [self.gameState getNumberOfPlayers:NO];
}

- (Die *) getDie:(int)index {
    return [arrayOfDice objectAtIndex:index];
}

@end
