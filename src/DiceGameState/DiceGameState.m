//
//  DiceGameState.m
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DiceGameState.h"

#import "PlayerState.h"
#import "HistoryItem.h"
#import "Die.h"
#import "Player.h"
#import "DiceTypes.h"
#import "DiceGame.h"

@implementation DiceGameState

@synthesize playerStates;
@synthesize players, currentTurn, previousBid;
@synthesize playersLeft, newRoundListeners, game, losers;

/*** DiceGameState
 Takes a NSArray of player names and the maximum number of dice.
 ***/
- (id)initWithPlayers:(NSArray *)thePlayers numberOfDice:(int)numberOfDice game:(DiceGame *)aGame;
{
    self = [super init];
    if (self) {
        self.game = aGame;
        self.players = thePlayers;
        self.losers = [[[NSMutableArray alloc] init] autorelease];
        NSMutableArray *mutPlayerStates = [[[NSMutableArray alloc] init] autorelease];
        
        // Fill the player array with player states for each player in the game
        int numPlayers = [thePlayers count];
        NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
        for (int i = 0; i < numPlayers; ++i)
        {
            id <Player> player = [self.players objectAtIndex:i];
            NSString *playerName = [player getName];
            // Create the new player state
            NSNumber *value = [dict objectForKey:playerName];
            NSString *suffix = @"";
            if (value == nil)
            {
                [dict setValue:[NSNumber numberWithInt:2] forKey:playerName];
            }
            else
            {
                [dict setValue:[NSNumber numberWithInt:[value intValue] + 1] forKey:playerName];
                suffix = [NSString stringWithFormat:@"-%d", [value intValue]];
            }
            PlayerState *newPlayerState = [[[PlayerState alloc] initWithName:[playerName stringByAppendingString:suffix] 
                                                                      withID:[player getID]
                                                            withNumberOfDice:numberOfDice 
                                                           withDiceGameState:self]
                                           autorelease];
            [mutPlayerStates addObject:newPlayerState];
        }
        
        self.playerStates = [NSArray arrayWithArray:mutPlayerStates];
        self.newRoundListeners = [NSMutableArray array];
        rounds = [[NSMutableArray alloc] init];        
        playersLeft = [self.players count];
        gameWinner = nil;
        self.currentTurn = 0;
        inSpecialRules = NO;
        [self goToNextPlayerWhoHasntLost];
        [self createNewRound];
    }
    return self;
}

// Dealloc method, release all of our variables
- (void)dealloc
{
    [rounds release];
    [history release];
    // Make sure our super class deallocs too
    [super dealloc];
}

- (void)addNewRoundListener:(id <NewRoundListener>)listener {
    [newRoundListeners addObject:listener];
}

// Handle bids
- (BOOL)handleBid:(int)playerID withBid:(Bid *)bid
{
    // Make sure it is the player's turn and the bid is correct
    if ([self checkPlayer:playerID] && [self checkBid:bid playerSpecialRules:(inSpecialRules && [[self getPlayerState:playerID] numberOfDice] > 1)]) {
        //Set the previous bid to this one
        self.previousBid = bid;
        // Add this bid to our history
        HistoryItem *newHistoryItem = [[HistoryItem alloc] initWithState:self 
                                                           andWithPlayer:[self getPlayerState:playerID] 
                                                                 withBid:bid];
        [newHistoryItem autorelease]; //autorelease it when history is dealloc'd
        [history addObject:newHistoryItem];
        // Go to the next turn
        [self moveToNextTurn];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)handlePush:(int)playerID withPush:(NSArray *)push
{
    if (push == nil || [push count] == 0)
    {
        return NO;
    }
    // Get the last history item to make sure they can push.
    HistoryItem *item = [self lastHistoryItem];
    if (!item || item.player.playerID != playerID || item.actionType != ACTION_BID)
        return NO;
    
    // Get the player state of the player pushing.
    PlayerState *player = [self getPlayerState:playerID];
    //Make sure they haven't pushed already
    if ([push count] == 0)
        return NO;
    
    // Set the item to nil so we can reuse it for creating a new history item,
    // the original variable will be autoreleased.
    item = nil;
    item = [[HistoryItem alloc] initWithState:self 
                                andWithPlayer:[self getPlayerState:playerID] 
                                  whereTypeIs:ACTION_PUSH];
    [item autorelease];
    [history addObject:item];
    
    // Tell the player to push the dice.
    [player pushDice:push];
    
    return YES;
}

- (BOOL)handlePass:(int)playerID
{
    // Make sure its a valid pass.
    if ([self checkPlayer:playerID]) {
        
        // Get the player state.
        PlayerState *player = [self getPlayerState:playerID];
        if ([player playerHasPassed])
            return NO;
        
        player.playerHasPassed = YES;
        HistoryItem *item = [[HistoryItem alloc] initWithState:self 
                                                 andWithPlayer:player 
                                                   whereTypeIs:ACTION_PASS 
                                                     withValue:([player playerHasAllSameDice] ? 1 : 0)];
        [item autorelease];
        [history addObject:item];
        // Go to the next turn.
        [self moveToNextTurn];
        return YES;
    } else
        return NO;
}

// Handles a challenge, whether it is a challenge of a bid or a pass
- (BOOL)handleChallenge:(int)playerID againstTarget:(int)targetID withFirstPlayerWonOrNot:(BOOL *)didTheChallengerWin
{
    if (![self checkPlayer:playerID]) {
        return NO;
    }
    PlayerState *player = [self getPlayerState:playerID];
    HistoryItem *item = [self lastHistoryItem];
    HistoryItem *secondLast;
    
    if ([[self history] count] >= 2)
    {
        secondLast = [[self history] objectAtIndex:[[self history] count] - 2];
    }
    
    //Make sure its a valid challenge
    if (self.previousBid && [self.previousBid playerID] == targetID) {
        if ([self isBidCorrect:self.previousBid]) {
            [self playerLosesRound:playerID];
            HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                        andWithPlayer:player 
                                                          whereTypeIs:ACTION_CHALLENGE_BID
                                                            withValue:[self.previousBid playerID]
                                                            andResult:0];
            [newItem setBid:self.previousBid];
            [newItem setLosingPlayer:playerID];
            [newItem autorelease];
            [history addObject:newItem];
            *didTheChallengerWin = NO;
        } else {
            int loserID = [self.previousBid playerID];
            [self playerLosesRound:loserID];
            HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                        andWithPlayer:player 
                                                          whereTypeIs:ACTION_CHALLENGE_BID
                                                            withValue:[self.previousBid playerID]
                                                            andResult:1];
            [newItem setBid:self.previousBid];
            [newItem setLosingPlayer:loserID];
            [newItem autorelease];
            [history addObject:newItem];
            *didTheChallengerWin = YES;
        }
    } else if ((item.actionType == ACTION_PASS && item.player.playerID == targetID) || 
               (secondLast.actionType == ACTION_PASS && secondLast.player.playerID == targetID)) {
        if (item.player.playerID == targetID)
        {
            if (item.result == 1) // Pass was legal
            {
                [self playerLosesRound:playerID];
                HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                            andWithPlayer:player
                                                              whereTypeIs:ACTION_CHALLENGE_PASS
                                                                withValue:targetID
                                                                andResult:0];
                [newItem setLosingPlayer:playerID];
                [newItem autorelease];
                [history addObject:newItem];
                *didTheChallengerWin = NO;
            } else {
                [self playerLosesRound:targetID];
                HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                            andWithPlayer:player
                                                              whereTypeIs:ACTION_CHALLENGE_PASS
                                                                withValue:targetID
                                                                andResult:1];
                [newItem setLosingPlayer:targetID];
                [newItem autorelease];
                [history addObject:newItem];
                *didTheChallengerWin = YES;
            }
        }
        else
        {
            if (secondLast.result == 1) // Pass was legal
            {
                [self playerLosesRound:playerID];
                HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                            andWithPlayer:player
                                                              whereTypeIs:ACTION_CHALLENGE_PASS
                                                                withValue:targetID
                                                                andResult:0];
                [newItem setLosingPlayer:playerID];
                [newItem autorelease];
                [history addObject:newItem];
                *didTheChallengerWin = NO;
            } else {
                [self playerLosesRound:targetID];
                HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                            andWithPlayer:player
                                                              whereTypeIs:ACTION_CHALLENGE_PASS
                                                                withValue:targetID
                                                                andResult:1];
                [newItem setLosingPlayer:targetID];
                [newItem autorelease];
                [history addObject:newItem];
                *didTheChallengerWin = YES;
            } 
        }
    } else {
        return NO;
    }
    
    if (*didTheChallengerWin)
    {
        int targetIndex = [self getIndexOfPlayerWithId:targetID];
        self.currentTurn = targetIndex % [self.playerStates count];
        [self goToNextPlayerWhoHasntLost];
    }
    else
    {
        self.currentTurn = (self.currentTurn) % [self.playerStates count];
    }
    
    // This is handled in "playerLosesRound" above
    // [self goToNextPlayerWhoHasntLost];
    
    [self createNewRound];
    
    return YES;
}

//Handle exacts
- (BOOL)handleExact:(int)playerID andWasTheExactRight:(BOOL *)wasTheExactRight
{
    //Make sure its the player's turn
    if (![self checkPlayer:playerID]) {
        return NO;
    }
    PlayerState *player = [self getPlayerState:playerID];
    Bid *bid = self.previousBid;
    if (!bid || [player playerHasExacted])
        return NO;
    [player setPlayerHasExacted:YES];
    
    //Make sure the exact is corret otherwise say it wasn't
    if ([self countDice:[bid rankOfDie]] == [bid numberOfDice]) {
        NSLog(@"%i: exact was correct", [player playerID]);
        HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                    andWithPlayer:player
                                                      whereTypeIs:ACTION_EXACT
                                                        withValue:1];
        [newItem setBid:bid];
        if ([player numberOfDice] < [player maxNumberOfDice])
        {
            player.numberOfDice++;
            [newItem setWinningPlayer:playerID];
        }
        [newItem autorelease];
        [history addObject:newItem];
        
        *wasTheExactRight = YES;
    } else {
        NSLog(@"%i: exact was wrong", [player playerID]);
        [self playerLosesRound:playerID];
        HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                    andWithPlayer:player
                                                      whereTypeIs:ACTION_EXACT
                                                        withValue:0];
        [newItem setBid:bid];
        [newItem setLosingPlayer:playerID];
        [newItem autorelease];
        [history addObject:newItem];
        
        *wasTheExactRight = NO;
    }
    // self.currentTurn = playerID;
    // Pointless because we'll just create a new round anyways but left there because the java engine does this
    [self goToNextPlayerWhoHasntLost];
    [self createNewRound];
    return YES;
}

- (BOOL)handleAccept:(int)playerID
{
    if ([self checkPlayer:playerID]) {
        [self moveToNextTurn];
        return YES;
    }
    else
        return NO;
}

- (id <Player>)getPlayerWithID:(int)playerID {
    for (id <Player> player in self.players)
    {
        if ([player getID] == playerID)
        {
            return player;
        }
    }
    return nil;
}

- (id <Player>) getCurrentPlayer {
    return [self.players objectAtIndex:self.currentTurn];
}

// Return the current player's PlayerState*
- (PlayerState *)getCurrentPlayerState
{
    return [self.playerStates objectAtIndex:self.currentTurn];
}

// Returns true ifa player has won the game yet.
- (BOOL)hasAPlayerWonTheGame
{
    return (gameWinner != nil);
}

// Returns the state of the player that has won the game,
// or nil if no-one has won yet.
- (id <Player>)gameWinner
{
    return gameWinner;
}

- (BOOL)usingSpecialRules
{
    return inSpecialRules;
}

- (BOOL)isGameInProgress
{
    return ![self hasAPlayerWonTheGame];
}

// Return the history array which contains the history items for the *current* round
- (NSArray *)history
{
    return history;
}

// Return an array of the history of *all* the rounds
- (NSArray *)roundHistory
{
    return rounds;
}

// Returns an array of the history objects relating to the
// last move made by the player with the playerID, or a
// empty array if that player hasn't played this turn.
- (NSArray *) lastMoveForPlayer:(int)playerID {
    NSMutableArray *mut = [NSMutableArray array];
    bool inPlayer = NO;
    for (int i = [history count] - 1; i >= 0; --i) {
        HistoryItem *item = [history objectAtIndex:i];
        int itemPlayerID = item.player.playerID;
        if (itemPlayerID == playerID) {
            inPlayer = YES;
            if (item.historyType != metaHistoryItem) {
                [mut addObject:item];
            }
        } else if (inPlayer) {
            break;
        }
    }
    return [NSArray arrayWithArray:mut];
}

// Return an array of the history of *all* of the rounds
// but in flat (instead of having to navigate till you get
// the right round then the history item its just bunch of
// history items in the order of 0 being the most recent and
// the last one the oldest
- (NSArray *)flatHistory
{
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (NSMutableArray *array in rounds) {
        if ([array isKindOfClass:[NSMutableArray class]]) {
            for (HistoryItem *item in array) {
                if ([item isKindOfClass:[HistoryItem class]]) {
                    [ret addObject:item];
                }
            }
        }
    }
    if (history)
    {
        for (HistoryItem *item in history) {
            if ([item isKindOfClass:[HistoryItem class]]) {
                [ret addObject:item];
            }
        }
    }
    NSRange range;
    range.location = 0;
    range.length = [ret count];
    NSArray *array = [ret subarrayWithRange:range];
    [ret release];
    [array autorelease];
    return array;
}

// Last history item (useful shortcut function)
- (HistoryItem *)lastHistoryItem
{
    if (!history || [history count] == 0) {
        return nil;
    }
    if ([[history objectAtIndex:([history count] - 1)] isKindOfClass:[HistoryItem class]]) {
        return (HistoryItem *)[history objectAtIndex:([history count] - 1)];
    }
    return nil;
}

// PlayerStatus (Lost, Won, Playing) of a player via their playerID
- (PlayerStatus)playerStatus:(int)playerID
{
    PlayerState *player = [self getPlayerState:playerID];
    if ([player hasLost])
        return Lost;
    if ([self hasAPlayerWonTheGame])
        return Won;
    return Playing;
}

// Number of history items in the current round (number of turns taken this round)
- (int)historySize
{
    if (!history)
        return 0;
    return [history count];
}

- (int) getNumberOfPlayers:(BOOL)includeLostPlayers
{
    if (includeLostPlayers)
    {
        return [self.playerStates count];
    }
    int ret = 0;
    for (PlayerState *playerState in self.playerStates)
    {
        if (!playerState.hasLost)
        {
            ++ret;
        }
    }
    return ret;
}

// The current state in a readable text format
- (NSString *)stateString:(int)playerID
{
    NSMutableString *string = [NSMutableString string];
    [string appendString:[NSString stringWithFormat:@"%@'s turn\n", [[self getCurrentPlayer] getName]]];
    [string appendString:self.previousBid == nil ? @"No previous bid\n" : [NSString stringWithFormat:@"%@\n", [self.previousBid asString]]];
    int i = 0;
    for (PlayerState *player in self.playerStates) {
        if ([player isKindOfClass:[PlayerState class]]) {
            [string appendString:[player stateString:([player playerID] == playerID || playerID == -1)]];
            if ((i + 1) < [self.playerStates count])
            {
                [string appendString:@"\n"];
            }
            ++i;
        }
    }
    return string;
}


- (NSString *) historyText:(int)playerID {
    NSString *labelText;
    // What playerID goes in this slot
    id <Player> player = [self getPlayerWithID:playerID];
    NSString *playerName = [player getName];
    NSArray *lastMove = [self lastMoveForPlayer:playerID];
    if ([lastMove count] == 0) {
        // This player hasn't bid yet.
        // Figure out what playerID goes in this slot.
        labelText = playerName;
    } else {
        NSMutableString *moveString = [NSMutableString string];
        for (int i = [lastMove count] - 1; i >= 0; --i) {
            HistoryItem *item = [lastMove objectAtIndex:i];
            [moveString appendFormat:@"%@", [item asString]];
            //if (i > 0) {
            //    [moveString appendFormat:@" "];
            //}
        }
        labelText = moveString;
    }
    return labelText;
}

- (NSString *)headerString:(int)playerIDorMinusOne singleLine:(BOOL)singleLine {
    int totalDice = [self countAllDice];
    int unknownDice = [self countUnknownDice:playerIDorMinusOne];
    NSString *conj = singleLine ? @". There were " : @".\n";
    if (self.previousBid == nil) {
        return [NSString stringWithFormat:@"No current bid%@%d dice, %d unknown.", conj, totalDice, unknownDice];
    }
    NSString *previousBidPlayerName = self.previousBid.playerName;
    int bidDice = [self countSeenDice:playerIDorMinusOne rank:previousBid.rankOfDie];
    if (playerIDorMinusOne < 0) {
        return [NSString stringWithFormat:@"%@ bid %d %ds%@%d dice, %d %ds.", previousBidPlayerName, previousBid.numberOfDice, previousBid.rankOfDie, conj, totalDice, bidDice, previousBid.rankOfDie];
    }
    return [NSString stringWithFormat:@"%@ bid %d %ds%@%d dice, %d %ds, %d unknown.", previousBidPlayerName, previousBid.numberOfDice, previousBid.rankOfDie, conj, totalDice, bidDice, previousBid.rankOfDie, unknownDice];
}

//Private Methods

//Create a new round
- (void)createNewRound
{
    BOOL deferNotification = NO;
    for (id <NewRoundListener> listener in newRoundListeners) {
        if ([listener roundEnding]) {
            deferNotification = YES;
        }
    }
    inSpecialRules = NO;
    
    for (PlayerState *player in self.playerStates) {
        [player isNewRound];
        if ([player isInSpecialRules] && playersLeft > 2)
        {
            inSpecialRules = YES;
        }
    }
    self.previousBid = nil;
    if (history)
    {
        [rounds addObject:history];
        [history release];
        history = nil;
        history = [[NSMutableArray alloc] init];
    }
    else
    {
        history = [[NSMutableArray alloc] init];
    }
    [history addObject:[[[HistoryItem alloc] initWithMetaInformation:[NSString stringWithFormat:@"New Round"]] autorelease]];
    for (id <NewRoundListener> listener in newRoundListeners) {
        if ([listener roundBeginning]) {
            deferNotification = YES;
        }
    }
    if (deferNotification) {
        game.deferNotification = YES;
    }
}

//Make a player lose the round (set the flags that they've lost)
- (void)playerLosesRound:(int)playerID
{
    [history addObject:[[[HistoryItem alloc]
                         initWithMetaInformation:[self stateString:-1]]
                        autorelease]];
    NSLog(@"%@ lost the round.", [[self getPlayerState:playerID] asString]);
    NSLog(@"%@", [self stateString:-1]);
    PlayerState *player = [self getPlayerState:playerID];
    player.numberOfDice = player.numberOfDice - 1;
    NSLog(@"%@ has %i dice", [player playerName], [player numberOfDice]);
    if (player.numberOfDice == 0) {
        [self playerLosesGame:playerID];
    }
    [self goToNextPlayerWhoHasntLost];
}

//Make a player lose the game (set the flags that they've lost the game)
- (void)playerLosesGame:(int)playerID
{
    [self.losers addObject:[NSNumber numberWithInt:[self getIndexOfPlayerWithId:playerID]]];
    NSLog(@"%@ lost the game.", [[self getPlayerState:playerID] asString]);
    PlayerState *player = [self getPlayerState:playerID];
    player.hasLost = YES;
    --playersLeft;
    // [player setNumberOfDice:0];
    if (playersLeft <= 1)
    {
        [self goToNextPlayerWhoHasntLost];
        
        NSLog(@"%@ won!", [[self getCurrentPlayer] getName]);
        gameWinner = [self getCurrentPlayer];
    }
}

// Check a bid to make sure it is valid
- (BOOL)checkBid:(Bid *)bid playerSpecialRules:(BOOL)playerSpecialRules
{
    // Sanity Check
    if (bid.playerID != [self getCurrentPlayerState].playerID ||
        bid.rankOfDie < 1 ||
        bid.rankOfDie > 6 ||
        bid.numberOfDice < 1) {
        return NO;
    }
    
    //Check if there is a previous bid, otherwise the bid is automatically valid
    if (!self.previousBid) return YES;
    
    //Make sure the bid is a legal raise over the previous bid
    if (![bid isLegalRaise:self.previousBid specialRules:[self usingSpecialRules] playerSpecialRules:playerSpecialRules])
        return NO;
    return YES;
}

// Return true if playerID is the current player id.
- (BOOL)checkPlayer:(int)playerID
{
    return [[self.players objectAtIndex:self.currentTurn] getID] == playerID;
}

// Advance until the current turn is of a player who hasn't lost
- (void)goToNextPlayerWhoHasntLost
{
    while ([[self.playerStates objectAtIndex:self.currentTurn] hasLost])
    {
        self.currentTurn = (self.currentTurn + 1) % [self.playerStates count];
    }
}

// Get a player's PlayerState by their playerID
- (PlayerState *) getPlayerState:(int)playerID
{
    for (PlayerState *state in self.playerStates)
    {
        if (state.playerID == playerID) return state;
    }
    return nil;
}

// Goto the next turn
- (void)moveToNextTurn
{
    //Set the currentTurn to the next player to make sure the next turn isn't same player
    self.currentTurn = (self.currentTurn + 1) % [self.playerStates count];
    //Goto the next player Who hasn't lost
    [self goToNextPlayerWhoHasntLost];
}

- (int)countKnownDice:(int)rankOfDice inArray:(NSArray *)arrayToCountIn
{
	int totalCount = 0;
	for (Die *die in arrayToCountIn)
	{
		if ([die isKindOfClass:[Die class]])
		{
			if ([die dieValue] == rankOfDice || (!inSpecialRules && [die dieValue] == 1))
				++totalCount;
		}
	}
	return totalCount;
}

// Get the total number of dice with a given face value (used for exacts)
- (int)countDice:(int)rankOfDice
{
    int totalCount = 0;
    for (PlayerState *player in self.playerStates)
    {
        if ([player isKindOfClass:[PlayerState class]])
        {
            for (Die *die in [player arrayOfDice])
            {
                if ([die isKindOfClass:[Die class]])
                {
                    if ([die dieValue] == rankOfDice || (!inSpecialRules && [die dieValue] == 1))
                        ++totalCount;
                }
            }
        }
    }
    return totalCount;
}

// Gets the total number of dice of the given face, as seen by the given player.
- (int)countSeenDice:(int)playerIDorMinusOne rank:(int)rank {
    int ret = 0;
    for (PlayerState *playerState in playerStates) {
        for (Die *die in playerState.arrayOfDice) {
            if (playerState.playerID == playerIDorMinusOne || die.hasBeenPushed || playerIDorMinusOne < 0) {
                if (die.dieValue == rank) {
                    ++ret;
                } else if (!inSpecialRules && die.dieValue == 1) {
                    ++ret;
                }
            }
        }
    }
    return ret;
}

// Gets the number of dice that are invisible to the given player
- (int)countUnknownDice:(int)playerIDorMinusOne {
    int ret = 0;
    for (PlayerState *playerState in playerStates) {
        for (Die *die in playerState.arrayOfDice) {
            if (!(playerState.playerID == playerIDorMinusOne || die.hasBeenPushed)) {
                ++ret;
            }
        }
    }
    return ret;
}

// Gets the total number of dice in the game
- (int)countAllDice {
    int ret = 0;
    NSLog(@"Count all dice");
    for (PlayerState *playerState in playerStates) {
        ret += [playerState.arrayOfDice count];
    }
    return ret;
}

// Is the input'd bid valid?
- (BOOL)isBidCorrect:(Bid *)bid
{
    if (([self countDice:[bid rankOfDie]]) >= [bid numberOfDice])
        return YES;
    return NO;
}

// Get the playerID of the person who last passed however if they didn't pass last turn it will return -1.  Basically a check to see whether the last player passed and if so what was their playerID
- (int)lastPassPlayerID
{
    HistoryItem *item = [self lastHistoryItem];
    if (item == nil || [item actionType] != ACTION_PASS)
        return -1;
    return [[item player] playerID];
}

// Get the playerID of the player who passed two turns ago.
- (int)secondLastPassPlayerID
{
    if ([self lastPassPlayerID] == -1)
        return -1;
	
    if (history == nil || [history count] < 2)
        return -1;
    
    HistoryItem *item = [history objectAtIndex:[history count] - 2];
    if (item == nil || [item actionType] != ACTION_PASS)
        return -1;
    
    return [[item player] playerID];
}

- (NSArray *)playersWhoHaveLost
{
    NSMutableArray *playersWhoHaveLost = [[[NSMutableArray alloc] init] autorelease];
    
    for (PlayerState *player in self.playerStates)
    {
        if ([player isKindOfClass:[PlayerState class]])
        {
            if ([player hasLost])
            {
                NSNumber *number = [NSNumber numberWithInt:[player playerID]];
                [playersWhoHaveLost addObject:number];
            }
        }
    }
    
    NSArray *array = [[[NSArray alloc] initWithArray:playersWhoHaveLost] autorelease];
    return array;
}

- (int) getIndexOfPlayerWithId:(int)playerID
{
    for (int i = 0; i < [playerStates count]; ++i)
    {
        if (((PlayerState *)[self.playerStates objectAtIndex:i]).playerID == playerID)
        {
            return i;
        }
    }
    return -1;
}

@end
