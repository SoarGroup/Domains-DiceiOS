//
//  Player.m
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlayerState.h"
#import <stdlib.h>

#import "Die.h"
#import "HistoryItem.h"
#import "DiceGameState.h"

@implementation PlayerState

@synthesize playerID, playerHasPassed, playerHasExacted, playerHasPushedAllDice, gameState, numberOfDice, maxNumberOfDice, hasLost, playerName, arrayOfDice, lock;

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

- (BOOL) hasWon {
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
        {
            Die *die1 = [[Die alloc] init];
            [die1 autorelease];
            
            [arrayOfDice addObject:die1];
        }
        
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
    if (numberOfDice == 1 && !hasDoneSpecialRules && [self getNumberOfPlayers] > 1)
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
    [self.lock unlock];
}

// Method for pushing our dice
- (void)pushDice:(NSArray *)diceToPush
{
    [self.lock lock];
    playerHasPassed = NO;
    NSMutableArray *arrayOfDiceActual = [[NSMutableArray alloc] initWithArray:arrayOfDice];
    for (Die *dieToPush in diceToPush) {        
        for (int i = 0;i < [arrayOfDiceActual count];i++)
        {
            Die *actualDie = [arrayOfDiceActual objectAtIndex:i];
            if ([actualDie isKindOfClass:[Die class]]) // Make sure the actualDie is a Die
            {
                // Make sure the die is *exactly* equal
                if ([dieToPush isEqual:actualDie]) 
                {
                    // Push it if not already pushed, makes no sense to do
                    // another check since it will just be pushed again and
                    // the check should have been done earlier in our program
                    // execution.
                    [actualDie push];
                    
                    // Make sure we do not push unlimited dice of real dice
                    // (ie. we have a die with a face value of 5.  Make sure
                    // we do not allow pushing of more than the number of die
                    // with that face value (5 in this case) )
                    [arrayOfDiceActual removeObjectAtIndex:i];
                    
                    break;
                }
            }
        }
    }
    
        //release our temporary array
    [arrayOfDiceActual release];
    
    BOOL isThereDiceLeft = NO;
    
        //Roll all non-pushed dice
    for (Die *die in arrayOfDice) {
        if ([die isKindOfClass:[Die class]]) { // make sure it really is a die probably is but best to check to make sure otherwise we would crash which would be bad
            if (!die.hasBeenPushed) { // make sure it wasn't pushed
                isThereDiceLeft = YES;
                [die roll]; //roll the die since it wasn't pushed
            }
        }
    }
    
        //Set whether the player has pushed all their dice to the opposite of isThereDiceLeft
    playerHasPushedAllDice = !isThereDiceLeft;
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
    NSMutableArray *pushedDice = [[NSMutableArray alloc] init];
    for (Die *die in arrayOfDice) {
        if ([die isKindOfClass:[Die class]]) {
            if ([die hasBeenPushed]) {
                [pushedDice addObject:die];
            }
        }
    }
    
    NSArray *array = [[NSArray alloc] initWithArray:pushedDice];
    [pushedDice release];
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
    if (hasLost) return -1;
    if (![self canChallengeLastPass]) return -1;
    
    NSArray *history = [self.gameState history];
    if (!history || [history count] < 2) return -1;
    
    HistoryItem *item;
    if ([[history objectAtIndex:[history count] - 2] isKindOfClass:[HistoryItem class]])
    {
        item = [history objectAtIndex:[history count] - 2];
    }
    if (item != nil && [self.gameState getCurrentPlayerState] == self && item.actionType == ACTION_PASS)
    {
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

- (int) getNumberOfPlayers {
    return [self.gameState getNumberOfPlayers:NO];
}

- (Die *) getDie:(int)index {
    return [arrayOfDice objectAtIndex:index];
}

@end
