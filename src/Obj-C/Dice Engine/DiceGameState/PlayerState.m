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
	DiceGameState* gameStateLocal = self.gameState;
    return gameStateLocal.gameWinner == [gameStateLocal.players objectAtIndex:self.playerID];
}

    //Initilization method
- (id)initWithName:(NSString*)name withID:(int)ID withNumberOfDice:(int)dice withDiceGameState:(DiceGameState *)aGameState
{
        //Same deal as the DiceGameState initialization, make sure our super class initializes properly, otherwise return ourself which will be nil (it will be the correct address if it initilized properly
    self = [super init];

    if (self) {
            //Set our local variables
        self.lock = [[NSLock alloc] init];
        [self.lock lock];
        self.playerName = name;
        playerID = ID;
        numberOfDice = dice;
        maxNumberOfDice = dice;
        hasLost = NO;
        playerHasPassed = NO;
        playerHasExacted = NO;
        
        self.gameState = aGameState;
		DiceGame* localGame = aGameState.game;
        
        self.arrayOfDice = [[NSMutableArray alloc] init];
        
            //Set our dice
        for (int i = 0;i < dice;i++)
			[arrayOfDice addObject:[[Die alloc] init:localGame]];

        specialRules = NO;
        hasDoneSpecialRules = NO;
        [self.lock unlock];
    }

    return self;
}

-(id)initWithCoder:(NSCoder*)decoder withCount:(int)count withGameState:(DiceGameState*)state
{
	self = [super init];

	if (self)
	{
		self.gameState = state;
		
		specialRules = [decoder decodeBoolForKey:[NSString stringWithFormat:@"PlayerState%i:specialRules", count]];
		self.hasDoneSpecialRules = [decoder decodeBoolForKey:[NSString stringWithFormat:@"PlayerState%i:hasDoneSpecialRules", count]];

		self.playerID = [decoder decodeIntForKey:[NSString stringWithFormat:@"PlayerState%i:playerID", count]];
		self.playerName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"PlayerState%i:playerName", count]];

		self.playerHasPassed = [decoder decodeBoolForKey:[NSString stringWithFormat:@"PlayerState%i:playerHasPassed", count]];
		self.playerHasExacted = [decoder decodeBoolForKey:[NSString stringWithFormat:@"PlayerState%i:playerHasExacted", count]];
		self.numberOfDice = [decoder decodeIntForKey:[NSString stringWithFormat:@"PlayerState%i:numberOfDice", count]];

		self.hasLost = [decoder decodeBoolForKey:[NSString stringWithFormat:@"PlayerState%i:hasLost", count]];
		playerHasPushedAllDice = [decoder decodeBoolForKey:[NSString stringWithFormat:@"PlayerState%i:playerHasPushedAllDice", count]];

		self.maxNumberOfDice = [decoder decodeIntForKey:[NSString stringWithFormat:@"PlayerState%i:maxNumberOfDice", count]];

		int arrayOfDiceCount = [decoder decodeIntForKey:[NSString stringWithFormat:@"PlayerState%i:arrayOfDice", count]];

		self.numberOfDice = arrayOfDiceCount;

		self.arrayOfDice = [[NSMutableArray alloc] init];

		for (int i = 0;i < arrayOfDiceCount;i++)
			[self.arrayOfDice addObject:[[Die alloc] initWithCoder:decoder withCount:i withPrefix:[NSString stringWithFormat:@"PlayerState%i:", count]]];
	}

	return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder withCount:(int)count
{
	[encoder encodeBool:specialRules forKey:[NSString stringWithFormat:@"PlayerState%i:specialRules", count]];
	[encoder encodeBool:hasDoneSpecialRules forKey:[NSString stringWithFormat:@"PlayerState%i:hasDoneSpecialRules", count]];

	[encoder encodeInt:playerID forKey:[NSString stringWithFormat:@"PlayerState%i:playerID", count]];
	[encoder encodeObject:playerName forKey:[NSString stringWithFormat:@"PlayerState%i:playerName", count]];

	[encoder encodeBool:playerHasPassed forKey:[NSString stringWithFormat:@"PlayerState%i:playerHasPassed", count]];
	[encoder encodeBool:playerHasExacted forKey:[NSString stringWithFormat:@"PlayerState%i:playerHasExacted", count]];
	[encoder encodeInt:numberOfDice forKey:[NSString stringWithFormat:@"PlayerState%i:numberOfDice", count]];

	[encoder encodeBool:hasLost forKey:[NSString stringWithFormat:@"PlayerState%i:hasLost", count]];
	[encoder encodeBool:playerHasPushedAllDice forKey:[NSString stringWithFormat:@"PlayerState%i:playerHasPushedAllDice", count]];

	[encoder encodeInt:maxNumberOfDice forKey:[NSString stringWithFormat:@"PlayerState%i:maxNumberOfDice", count]];

	[encoder encodeInt:(int)[arrayOfDice count] forKey:[NSString stringWithFormat:@"PlayerState%i:arrayOfDice", count]];

	for (int i = 0;i < [arrayOfDice count];i++)
		[((Die*)[arrayOfDice objectAtIndex:i]) encodeWithCoder:encoder withCount:i withPrefix:[NSString stringWithFormat:@"PlayerState%i:", count]];
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
	DiceGameState* gameStateLocal = self.gameState;
	DiceGame* localGame = gameStateLocal.game;

    for (int i = 0;i < numberOfDice;i++) {
		Die *newDie = [[Die alloc] init:localGame];

        [arrayOfDice addObject:newDie];
    }

	if ([[gameStateLocal getPlayerWithID:self.playerID] isKindOfClass:[DiceLocalPlayer class]])
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

	DiceGameState* localState = gameState;
	DiceGame* localGame = localState.game;

	for (Die* arrayDie in arrayOfDice)
	{
		if (!arrayDie.hasBeenPushed)
			[arrayDie roll:localGame];
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
    [self.lock unlock];
    return array;
}

    //Can we bid?
- (BOOL)canBid
{
        //If we have lost, we can't
	DiceGameState* gameStateLocal = self.gameState;

	if (hasLost || gameStateLocal.gameWinner) return NO;

    PlayerState *currentState = [gameStateLocal getCurrentPlayerState];
    bool ret = currentState == self;

	Bid* previousBid = gameStateLocal.previousBid;
	if (previousBid.rankOfDie == 1 && previousBid.numberOfDice == 25)
		return false;

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
        // Get the previous bid for the next check
	DiceGameState* gameStateLocal = self.gameState;

	if (hasLost || gameStateLocal.gameWinner) return NO;

    Bid *previousBid = gameStateLocal.previousBid;
        // Make sure the current player is us, the previous bid exists, and the previous bid's playerID is not us
    
    HistoryItem *item = [gameStateLocal lastHistoryItem];
    if (item != nil)
    {   
        if (item.actionType == ACTION_BID)
        {
            if ([gameStateLocal getCurrentPlayerState] == self)
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
    
    if ([[gameStateLocal history] count] >= 2)
    {
        HistoryItem *secondToLastHistoryItem = [[gameStateLocal history] objectAtIndex:[[gameStateLocal history] count] - 2];
        
        if (secondToLastHistoryItem.actionType == ACTION_BID && 
            [gameStateLocal lastHistoryItem].actionType == ACTION_PUSH &&
            [gameStateLocal getCurrentPlayerState] == self &&
            previousBid != nil &&
            [previousBid playerID] != playerID)
        {
            return previousBid;
        }
        else if (secondToLastHistoryItem.actionType == ACTION_BID && 
                 [gameStateLocal lastHistoryItem].actionType == ACTION_PASS &&
                 [gameStateLocal getCurrentPlayerState] == self &&
                 previousBid != nil &&
                 [previousBid playerID] != playerID) {
            return previousBid;
        }
        else if ([[gameStateLocal history] count] >= 3) {
            HistoryItem *thirdToLastHistoryItem = [[gameStateLocal history] objectAtIndex:[[gameStateLocal history] count] - 3];
                if (thirdToLastHistoryItem.actionType == ACTION_BID && 
                    secondToLastHistoryItem.actionType == ACTION_PUSH && 
                    [gameStateLocal lastHistoryItem].actionType == ACTION_PASS &&
                    [gameStateLocal getCurrentPlayerState] == self &&
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
	DiceGameState* gameStateLocal = self.gameState;

	if (hasLost || gameStateLocal.gameWinner) return -1;

    HistoryItem *historyItem = [gameStateLocal lastHistoryItem];
    if (historyItem != nil && [gameStateLocal getCurrentPlayerState] == self)
    {
		PlayerState* playerLocal = historyItem.player;

		if (historyItem.actionType == ACTION_PASS && playerLocal.playerID != self.playerID)
			return playerLocal.playerID;
		else if (historyItem.actionType == ACTION_PUSH)
		{
			HistoryItem *secondToLastHistoryItem = [[gameStateLocal history] objectAtIndex:[[gameStateLocal history] count] - 2];
			PlayerState* secondPlayerLocal = secondToLastHistoryItem.player;

			if (secondToLastHistoryItem.actionType == ACTION_PASS && secondPlayerLocal.playerID != self.playerID && secondPlayerLocal.playerID == playerLocal.playerID)
				return playerLocal.playerID;
		}
    }
	
    return -1;
}


    //Can we challenge the second to last pass?
- (BOOL)canChallengeSecondLastPass
{
    return [self getChallengeableSecondLastPass] != -1;
}

- (int) getChallengeableSecondLastPass {
    if (![self canChallengeLastPass])
		return -1;

	DiceGameState* gameStateLocal = self.gameState;

	if (hasLost || gameStateLocal.gameWinner) return -1;

    NSArray *history = [gameStateLocal history];
	
    if (!history || [history count] < 2)
		return -1;
    
    HistoryItem *item = nil;

	if ([history count] >= 2)
	{
		if (((HistoryItem*)[history objectAtIndex:[history count] - 1]).actionType == ACTION_PASS &&
			((HistoryItem*)[history objectAtIndex:[history count] - 2]).actionType == ACTION_PASS)
		{
			item = [history objectAtIndex:[history count] - 2];
			PlayerState* playerLocal = item.player;

			if (playerLocal.playerID == self.playerID)
				item = nil;
		}
	}

	if (item == nil && [history count] >= 3)
	{
		if ((((HistoryItem*)[history objectAtIndex:[history count] - 1]).actionType == ACTION_PUSH &&
			((HistoryItem*)[history objectAtIndex:[history count] - 2]).actionType == ACTION_PASS &&
			((HistoryItem*)[history objectAtIndex:[history count] - 3]).actionType == ACTION_PASS) ||

			(((HistoryItem*)[history objectAtIndex:[history count] - 1]).actionType == ACTION_PASS &&
			 ((HistoryItem*)[history objectAtIndex:[history count] - 2]).actionType == ACTION_PUSH &&
			 ((HistoryItem*)[history objectAtIndex:[history count] - 3]).actionType == ACTION_PASS))
		{
			item = [history objectAtIndex:[history count] - 3];
			PlayerState* playerLocal = item.player;

			if (playerLocal.playerID == self.playerID)
				item = nil;
		}
	}

	if (item == nil && [history count] >= 4)
	{
		if (((HistoryItem*)[history objectAtIndex:[history count] - 1]).actionType == ACTION_PUSH &&
			((HistoryItem*)[history objectAtIndex:[history count] - 2]).actionType == ACTION_PASS &&
			((HistoryItem*)[history objectAtIndex:[history count] - 3]).actionType == ACTION_PUSH &&
			((HistoryItem*)[history objectAtIndex:[history count] - 4]).actionType == ACTION_PASS)
		{
			item = [history objectAtIndex:[history count] - 4];
			PlayerState* playerLocal = item.player;

			if (playerLocal.playerID == self.playerID)
				item = nil;
		}
	}

	PlayerState* playerLocal = item.player;

    if (item != nil)
		return playerLocal.playerID;

    return -1;
}

- (BOOL) isMyTurn
{
	DiceGameState* gameStateLocal = self.gameState;

    return (![gameStateLocal hasAPlayerWonTheGame]) && [[gameStateLocal getCurrentPlayer] getID] == self.playerID;
}

    //Can we exact?
- (BOOL)canExact
{
	DiceGameState* gameStateLocal = self.gameState;

	if (hasLost || gameStateLocal.gameWinner) return NO;

    Bid *previousBid = [gameStateLocal previousBid];
    return ([self isMyTurn] && !playerHasExacted && previousBid && [previousBid playerID] != playerID);
}

    //Can we pass?
- (BOOL)canPass
{
	DiceGameState* gameStateLocal = self.gameState;

	if (hasLost || gameStateLocal.gameWinner) return NO;

	return ([self isMyTurn] && !playerHasPassed && [arrayOfDice count] > 1);
}

    //Can we push?
- (BOOL)canPush
{
	DiceGameState* gameStateLocal = self.gameState;

	if (hasLost || gameStateLocal.gameWinner) return NO;

    HistoryItem *item = [gameStateLocal lastHistoryItem];
    return (item && item.player == self && item.actionType == ACTION_BID && [[self unPushedDice] count] > 1);
}

    //Can we accept?
- (BOOL)canAccept
{
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
	DiceGameState* gameStateLocal = self.gameState;

    if (showPrivate)
    {
        return [gameStateLocal stateString:self.playerID];
    }
    return [gameStateLocal stateString:-2]; // -2 for no private information
}

- (NSString *)headerString:(BOOL)singleLine {
	DiceGameState* gameStateLocal = self.gameState;

    return [gameStateLocal headerString:self.playerID singleLine:singleLine displayDiceCount:YES];
}

- (NSInteger) getNumberOfPlayers {
	DiceGameState* gameStateLocal = self.gameState;

    return [gameStateLocal getNumberOfPlayers:NO];
}

- (Die *) getDie:(int)index {
    return [arrayOfDice objectAtIndex:index];
}

- (id<Player>)playerPtr
{
	DiceGameState* localState = self.gameState;
	return [localState.players objectAtIndex:playerID];
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"PlayerState: (hasDoneSpecialRules: %@) (PlayerID: %i) (PlayerName: %@) (Lock: %@) (PlayerHasPassed: %@) (PlayerHasExacted: %@) (NumberOfDice: %i) (HasLost: %@) (PlayerHasPushedAllDice: %@) (MaxNumberOfDice: %i) (GameState: %@) (ArrayOfDice: %@)", hasDoneSpecialRules ? @"YES" : @"NO", playerID, playerName, lock, playerHasPassed ? @"YES" : @"NO", playerHasExacted ? @"YES" : @"NO", numberOfDice, hasLost ? @"YES" : @"NO", playerHasPushedAllDice ? @"YES" : @"NO", maxNumberOfDice, gameState, arrayOfDice];
}

@end
