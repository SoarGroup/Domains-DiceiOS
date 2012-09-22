//
//  DiceEngine.m
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DiceEngine.h"
#import "HistoryItem.h"
#import "Die.h"

#import "NetworkPlayer.h"

@interface DiceEngine()

//Private methods

- (BOOL)checkPlayerName:(NSString *)playerName againstListOfPlayerIDs:(NSArray *)playerIDs;
- (id <Player>)playerByPlayerName:(NSString *)playerName;

- (void)roundEnded:(id <AppDelegateProtocol>)caller;

@end

@implementation DiceEngine

//synthesize our variable
@synthesize playersInTheGame;

@synthesize diceGameState;

//Initialize ourself
- (id)initWithPlayers:(NSArray *)playersWhichImplementPlayerProtocol
{
    //Make sure our super class initialized properly
    self = [super init];
    if (self) {
        //Initialize our local variables setting them to the defaults
        playersInTheGame = playersWhichImplementPlayerProtocol;
        [playersInTheGame retain];
        NSMutableArray *playerNames = [[NSMutableArray alloc] init];
        for (id <Player> player in playersInTheGame) {
            [playerNames addObject:[player getName]];
        }
        NSRange range;
        range.location = 0;
        range.length = [playerNames count];
        NSArray *playerNamesArray = [playerNames subarrayWithRange:range];
        [playerNames release];
        diceGameState = [[DiceGameState alloc] initWithPlayerNames:playerNamesArray 
                                                   andNumberOfDice:NUMBER_OF_DICE_PER_PLAYER];
        
        droppedPlayerIDs = [[NSMutableArray alloc] init];
    }
    return self;
}

//Dealloc method
- (void)dealloc
{
    //Release all variables that have been alloc'd (but not autoreleased)
    [diceGameState release];
    [playersInTheGame release];
    [super dealloc]; //call our super's dealloc
}

- (void)dropPlayer:(NSString *)name
{
    
}

- (void)doneShowAll
{
    doneShowAll = YES;
}

- (void)roundEnded:(id <AppDelegateProtocol>)caller
{
    doneShowAll = NO;
    
    BOOL gameOver = NO;
    
    for (int i = 0; i < [[diceGameState players] count];i++)
    {
        PlayerState *player = [[diceGameState players] objectAtIndex:i];
        if ([player hasLost])
            gameOver = YES;
        else
            gameOver = NO;
    }
    
    [caller showAll:diceGameState];
    
    if (!gameOver)
    {
        while (!doneShowAll) {}
    }
    
    [diceGameState createNewRound];
    
    roundEnded = YES;
    
    int i = 0;
    for (id <Player> player in playersInTheGame)
    {
        [player newRound:[[diceGameState player:i] arrayOfDice]];
        i++;
    }
}

//Push dice (can be called via a player or via our "hacked" bid & push method
- (BOOL)pushAfterBid:(NSArray *)arrayOfDiceToPush withCallerBeing:(id<Player>)caller
{
    int callerID = [diceGameState playerIDByPlayerName:[caller name]];
    if (callerID != -1)
    {
        if ([diceGameState currentPlayerID] == callerID || 
            [[diceGameState previousBid] playerID] == callerID)
        {
            NSMutableArray *muteArrayOfActualDice = [[NSMutableArray alloc] initWithArray:[[diceGameState player:[diceGameState playerIDByPlayerName:[caller name]]] arrayOfDice]];
            
            BOOL correct = YES;
            for (Die *die in arrayOfDiceToPush) {
                if (![die isKindOfClass:[Die class]])
                    correct = NO;
                
                BOOL hasDie = NO;
                for (int i = 0;i < [muteArrayOfActualDice count];i++)
                {
                    Die *dieTwo = [muteArrayOfActualDice objectAtIndex:i];
                    if ([dieTwo isKindOfClass:[Die class]]) {
                        if ([die isEqual:dieTwo] && ![dieTwo hasBeenPushed]) {
                            hasDie = YES;
                            [muteArrayOfActualDice removeObjectAtIndex:i];
                            break;
                        }
                    }
                }
                
                if (!hasDie)
                    correct = NO;
            }
            
            [muteArrayOfActualDice release];
            
            if (correct) {
                BOOL twasCorrect = [diceGameState handlePush:callerID withPush:arrayOfDiceToPush];
                if (twasCorrect)
                    return YES;
                else
                    NSLog(@"twasCorrect failed!");
            }
            else
                NSLog(@"Correct was wrong!");
        }
        else
        {
            if ([diceGameState currentPlayerID] != callerID && !([diceGameState currentPlayerID] == ((callerID + 1) % [playersInTheGame count]) && [[diceGameState previousBid] playerID] == callerID))
                NSLog(@"System totally screwed up :P CallerID was not the current player nor the next player or the previous player");
            
            if ([diceGameState currentPlayerID] != ((callerID + 1) % [playersInTheGame count]) && [[diceGameState previousBid] playerID] != callerID)
            {
                if ([diceGameState currentPlayerID] == callerID)
                    NSLog(@"Should not of failed? Something really weird occured!");
                else
                {
                    NSLog(@"Current player was not the next player nor the previous player!");
                }
            }
            
            if ([diceGameState currentPlayerID] == ((callerID + 1) % [playersInTheGame count]) && [[diceGameState previousBid] playerID] != callerID)
            {
                if ([diceGameState currentPlayerID] == callerID)
                    NSLog(@"Should not of failed? Something really weird occured!");
                else
                {
                    NSLog(@"The previous bid's player was not the caller ID but the current player is the next player");
                }
            }
            
            if ([diceGameState currentPlayerID] != ((callerID + 1) % [playersInTheGame count]) && [[diceGameState previousBid] playerID] == callerID)
            {
                if ([diceGameState currentPlayerID] == callerID)
                    NSLog(@"Should not of failed? Something really weird occured!");
                else
                {
                    NSLog(@"Current player is not the next player but the previous bid's player is the caller!");
                }
            }
        }
    }
    else
        NSLog(@"Caller ID was -1!");
    return NO;
}

//The real "int main" of our logic engine
- (void)mainLoop:(Lair_s_DiceAppDelegate <AppDelegateProtocol> *)caller
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL isGameOver = NO;
    
    droppedPlayerIDs = [[NSMutableArray alloc] init];
    
    int playerToStartAt = 0;
    BOOL lost = NO;
    
    int i = 0;
    for (id <Player> player in playersInTheGame)
    {
        [player newRound:[[diceGameState player:i] arrayOfDice]];
        i++;
    }
    
    BOOL announcedSpecialRules = NO;
    BOOL announcedNewTurn = NO;
        
    //The main loop
    while (!isGameOver)
    {
        if([[NSThread currentThread] isCancelled])
            break;
        
        if (![diceGameState isGameInProgress] && [diceGameState gameWinner])
        {
            isGameOver = YES;
            break;
        }
        
        int i;
        
        if (lost)
        {
            i = playerToStartAt;
            lost = NO;
        }
        else
            i = 0;
        
        int errors = 0;
        
        int pass = 0;
        
        //For each player give them a turn and then parse the results
        while(i < [playersInTheGame count])
        {
            if([[NSThread currentThread] isCancelled])
            {
                break;
                break;
                break;
            }
            
            if ([[playersInTheGame objectAtIndex:i] conformsToProtocol:@protocol(Player)])
            {
                if ([diceGameState usingSpecialRules] && !announcedSpecialRules)
                {
                    [caller specialRulesAreInEffect];
                    announcedSpecialRules = YES;
                }
                else if (![diceGameState usingSpecialRules])
                {
                    announcedSpecialRules = NO;
                }
                
                if (![self checkPlayerName:[[playersInTheGame objectAtIndex:i] name] againstListOfPlayerIDs:droppedPlayerIDs])
                {
                    
                    {
                        BOOL didAdd = NO;
                        
                        NSArray *playerIDsOfPlayersWhoHaveLost = [diceGameState playersWhoHaveLost];
                        for (NSNumber *playerID in playerIDsOfPlayersWhoHaveLost)
                        {
                            if ([playerID isKindOfClass:[NSNumber class]])
                            {
                                BOOL found = NO;
                                for (NSNumber *alreadyLost in droppedPlayerIDs)
                                {
                                    if ([alreadyLost isKindOfClass:[NSNumber class]])
                                    {
                                        if (playerID == alreadyLost)
                                            found = YES;
                                    }
                                }
                                
                                if (!found)
                                {
                                    [droppedPlayerIDs addObject:playerID];
                                    [caller hideAllDice:[playerID intValue]];
                                    didAdd = YES;
                                }
                            }
                        }
                        
                        if (didAdd)
                        {
                            i = [diceGameState currentPlayerID];
                            
                            if (![diceGameState isGameInProgress] && [diceGameState gameWinner])
                                break;
                            
                            continue;
                        }
                    }
                    
                    NSLog(@"Turn: %d", i);
                    
                    id <Player, NSObject> playerInTheGame = (id <Player, NSObject>)[playersInTheGame objectAtIndex:i];
                    
                    if (!announcedNewTurn)
                    {
                        [caller newTurn:i];
                        announcedNewTurn = YES;
                    }
                        
                    turnInformationToSendToClient info;
                    info.roundHistory = [diceGameState history];
                    
                    NSNumber *bidNumber = [NSNumber numberWithInt:A_BID];
                    NSNumber *passNumber = [NSNumber numberWithInt:A_PASS];
                    NSNumber *exactNumber = [NSNumber numberWithInt:A_EXACT];
                    NSNumber *challengePassNumber = [NSNumber numberWithInt:A_CHALLENGE_PASS];
                    NSNumber *challengeBidNumber = [NSNumber numberWithInt:A_CHALLENGE_BID];
                    
                    NSMutableArray *actionsCanDo = [[NSMutableArray alloc] init];
                    
                    if (![[diceGameState player:[diceGameState playerIDByPlayerName:[playerInTheGame name]]] playerHasPassed])
                    {
                        [actionsCanDo addObject:passNumber];
                    }
                    
                    if ([diceGameState lastHistoryItem].actionType == A_PASS)
                    {
                        [actionsCanDo addObject:challengePassNumber];
                    }
                    
                    
                    if ([diceGameState lastHistoryItem].actionType == A_BID)
                    {
                        [actionsCanDo addObject:challengeBidNumber];
                        [actionsCanDo addObject:exactNumber];
                    }
                    
                    if ([[diceGameState history] count] >= 2)
                    {
                        HistoryItem *secondToLastHistoryItem = [[diceGameState history] objectAtIndex:[[diceGameState history] count] - 2];
                        
                        if (secondToLastHistoryItem.actionType == A_BID && [diceGameState lastHistoryItem].actionType == A_PUSH)
                        {
                            [actionsCanDo addObject:exactNumber];
                            [actionsCanDo addObject:challengeBidNumber];
                        }
                    }
                    
                    [actionsCanDo addObject:bidNumber];
                    
                    info.actionsAbleToSend = [[NSArray alloc] initWithArray:actionsCanDo];
                    [actionsCanDo release];
                    
                    info.playerID = [diceGameState playerIDByPlayerName:[playerInTheGame name]];
                    
                    info.dice = [[diceGameState player:info.playerID] arrayOfDice];
                    
                    info.players = [diceGameState players];
                    
                    info.errors = errors;
                    
                    info.gameState = diceGameState;
                    
                    info.pass = pass;
                    
                    if([[NSThread currentThread] isCancelled])
                    {
                        break;
                        break;
                        break;
                    }
                    
                    for (int i = 0;i < [playersInTheGame count];i++)
                    {
                        id player = [playersInTheGame objectAtIndex:i];
                        if ([player conformsToProtocol:@protocol(Player)])
                        {
                            id <Player, NSObject> protoPlayer = player;
                            
                            if ([playerInTheGame isKindOfClass:[NetworkPlayer class]])
                                [protoPlayer showPublicInformation:diceGameState];
                        }
                    }
                    
                    turnInformationSentFromTheClient clientReturnInfo ; // = [playerInTheGame isMyTurn:info];
                    
                    if([[NSThread currentThread] isCancelled])
                    {
                        break;
                        break;
                        break;
                    }
                    
                    if (clientReturnInfo.action == A_PUSH) //Parse their push
                    {
                        BOOL correct = YES;
                        for (Die *die in clientReturnInfo.diceToPush) {
                            if (![die isKindOfClass:[Die class]])
                                correct = NO;
                            
                            BOOL hasDie = NO;
                            for (Die *dieTwo in [[diceGameState player:[diceGameState playerIDByPlayerName:[playerInTheGame name]]] arrayOfDice])
                            {
                                if ([die isEqual:dieTwo]) {
                                    hasDie = YES;
                                    break;
                                }
                            }
                            
                            if (!hasDie)
                                correct = NO;
                        }
                        
                        if (correct && [self pushAfterBid:clientReturnInfo.diceToPush withCallerBeing:playerInTheGame])
                        {
                            errors = 0;
                            
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            
                            for (Die *die in clientReturnInfo.diceToPush) {
                                if ([die isKindOfClass:[Die class]])
                                {
                                    NSNumber *dieValue = [[NSNumber alloc] initWithInt:[die dieValue]];
                                    [dieValue autorelease];
                                    [array addObject:dieValue];
                                }
                            }
                            
                            NSArray *arrayOfDiceValues = [[NSArray alloc] initWithArray:array];
                            [arrayOfDiceValues autorelease];
                            [array release];
                            
                            [caller updateActionWithPush:arrayOfDiceValues withPlayer:playerInTheGame withPlayerID:info.playerID];
                            
                            [playerInTheGame reroll:[(PlayerState *)[diceGameState player:i] arrayOfDice]];
                        }
                        else
                        {
                            if (true)
                            {
                                
                                errors++;
                                
                                if (!correct)
                                    [caller performSelectorOnMainThread:@selector(logToConsole:) withObject:@"Invalid dice in push!" waitUntilDone:NO];
                                
                                if (![self pushAfterBid:clientReturnInfo.diceToPush withCallerBeing:playerInTheGame])
                                {
                                    NSLog(@"Current player ID:%i\ni:%i", [diceGameState currentPlayerID], i);
                                    
                                    [caller performSelectorOnMainThread:@selector(logToConsole:) withObject:@"Push after bid failed!" waitUntilDone:NO];
                                }
                                continue;
                            }
                        }
                    } else if (clientReturnInfo.action == A_BID) { // Parse their bid
                        if ([diceGameState handleBid:[diceGameState playerIDByPlayerName:[playerInTheGame name]] withBid:clientReturnInfo.bid]) {
                            errors = 0;
                            
                            [caller updateActionWithBid:clientReturnInfo.bid withPlayer:playerInTheGame];
                        }
                        else
                        {
                            if (true) {
                                
                                errors++;
                                
                                [caller performSelectorOnMainThread:@selector(logToConsole:) withObject:@"Invalid bid!" waitUntilDone:NO];
                                continue;
                            }
                        }
                    } else if (clientReturnInfo.action == A_PASS) { //Parse their pass
                        if ([diceGameState handlePass:[diceGameState playerIDByPlayerName:[playerInTheGame name]]]) {
                            errors = 0;
                            
                            [caller updateActionWithPass:playerInTheGame];
                        } else {
                            if (true) {
                                
                                errors++;
                                
                                [caller performSelectorOnMainThread:@selector(logToConsole:) withObject:@"Invalid pass!" waitUntilDone:NO];
                                continue;
                            }
                        }
                    } else if (clientReturnInfo.action == A_CHALLENGE_PASS) { //Parse their challenne
                        BOOL *didTheChallengerWin = calloc(1, sizeof(BOOL));
                        *didTheChallengerWin = NO;
                        if ([diceGameState handleChallenge:[diceGameState playerIDByPlayerName:[playerInTheGame name]]
                                             againstTarget:[diceGameState playerIDByPlayerName:clientReturnInfo.targetOfChallenge]
                                   withFirstPlayerWonOrNot:didTheChallengerWin])
                        {
                            errors = 0;
                            
                            if (*didTheChallengerWin)
                            {
                                [caller updateActionWithChallenge:playerInTheGame against:[self playerByPlayerName:clientReturnInfo.targetOfChallenge] ofType:A_CHALLENGE_PASS withDidTheChallengerWin:didTheChallengerWin withPlayerID:[diceGameState playerIDByPlayerName:clientReturnInfo.targetOfChallenge]];
                                
                                playerToStartAt = [diceGameState playerIDByPlayerName:clientReturnInfo.targetOfChallenge];
                                
                                lost = YES;
                            }
                            else
                            {
                                [caller updateActionWithChallenge:playerInTheGame against:[self playerByPlayerName:clientReturnInfo.targetOfChallenge] ofType:A_CHALLENGE_PASS withDidTheChallengerWin:didTheChallengerWin withPlayerID:info.playerID];
                                
                                playerToStartAt = info.playerID;
                                lost = YES;
                            }
                            
                            [self roundEnded:caller];
                            
                            announcedNewTurn = NO;
                            
                            break;
                        } else {
                            if (true) {
                                
                                errors++;
                                
                                [caller performSelectorOnMainThread:@selector(logToConsole:) withObject:@"Challenging a pass failed! Was it really a pass last time?" waitUntilDone:NO];
                                continue;
                            }
                        }
                    } else if (clientReturnInfo.action == A_CHALLENGE_BID) { //parse their challenge
                        BOOL *didTheChallengerWin = calloc(1, sizeof(BOOL));
                        *didTheChallengerWin = NO;
                        if ([diceGameState handleChallenge:[diceGameState playerIDByPlayerName:[playerInTheGame name]]
                                             againstTarget:[diceGameState playerIDByPlayerName:clientReturnInfo.targetOfChallenge]
                                   withFirstPlayerWonOrNot:didTheChallengerWin])
                        {
                            errors = 0;
                            
                            if (*didTheChallengerWin)
                            {
                                [caller updateActionWithChallenge:playerInTheGame against:[self playerByPlayerName:clientReturnInfo.targetOfChallenge] ofType:A_CHALLENGE_BID withDidTheChallengerWin:didTheChallengerWin withPlayerID:[diceGameState playerIDByPlayerName:clientReturnInfo.targetOfChallenge]];
                                
                                playerToStartAt = [diceGameState playerIDByPlayerName:clientReturnInfo.targetOfChallenge];
                                lost = YES;
                            }
                            else
                            {
                                [caller updateActionWithChallenge:playerInTheGame against:[self playerByPlayerName:clientReturnInfo.targetOfChallenge] ofType:A_CHALLENGE_BID withDidTheChallengerWin:didTheChallengerWin withPlayerID:info.playerID];
                                
                                playerToStartAt = info.playerID;
                                lost = YES;
                            }
                            
                            [self roundEnded:caller];
                            
                            announcedNewTurn = NO;
                            
                            break;
                        } else {
                            if (true) {
                                
                                errors++;
                                
                                [caller performSelectorOnMainThread:@selector(logToConsole:) withObject:@"Challenging a bid failed! Was it really a bid last time?" waitUntilDone:NO];
                                continue;
                            }
                        }
                    } else if (clientReturnInfo.action == A_EXACT) { //parse their exact
                        BOOL *wasExactRight = calloc(1, sizeof(BOOL));
                        *wasExactRight = NO;
                        if ([diceGameState handleExact:[diceGameState playerIDByPlayerName:[playerInTheGame name]] andWasTheExactRight:wasExactRight])
                        {
                            errors = 0;
                                                        
                            if (*wasExactRight)
                            {
                                [caller updateActionWithExact:playerInTheGame andWasTheExactRight:wasExactRight withPlayerID:info.playerID];
                                
                                playerToStartAt = info.playerID;
                                lost = YES;
                            }
                            else
                            {
                                [caller updateActionWithExact:playerInTheGame andWasTheExactRight:wasExactRight withPlayerID:info.playerID];
                                
                                playerToStartAt = info.playerID;
                                lost = YES;
                            }
                            
                            [self roundEnded:caller];
                            
                            announcedNewTurn = NO;
                            
                            break;
                        } else {
                            if (true) {
                                errors++;
                                
                                [caller performSelectorOnMainThread:@selector(logToConsole:) withObject:@"Exact failed!" waitUntilDone:NO];
                                continue;
                            }
                        }
                    } else if (clientReturnInfo.action == A_SLEEP || roundEnded) {
                        
                        i++;
                        pass = 0;
                        errors = 0;
                        
                        roundEnded = NO;
                        
                        announcedNewTurn = NO;
                        continue;
                    } else { //unknown action, say so
                        errors++;
                        NSString *error;
                        
                        if (clientReturnInfo.errorString)
                            error = [NSString stringWithFormat:@"%@ - Unknown command!", clientReturnInfo.errorString];
                        else
                            error = @"Unknown command!";
                        
                        [caller performSelectorOnMainThread:@selector(logToConsole:) withObject:error waitUntilDone:NO];
                        continue;
                    }
                    
                    pass++;
                }
                else
                {
                    i++;
                }
            }
        }
    }
    
    for (int i = 0;i < [playersInTheGame count];i++)
    {
        id <Player, NSObject> player = [playersInTheGame objectAtIndex:i];
        
        if ([self checkPlayerName:[player name] againstListOfPlayerIDs:droppedPlayerIDs])
            [caller hideAllDice:[diceGameState playerIDByPlayerName:[player name]]];
    }
    
    [droppedPlayerIDs release];
    
    if (![[NSThread currentThread] isCancelled])
        [caller someoneWonTheGame:[[diceGameState gameWinner] playerName]]; //Someone won the game, lets update the diplay with this
    [pool release];
}

//Check a player name to make see if it exists and is valid
- (BOOL)checkPlayerName:(NSString *)playerName againstListOfPlayerIDs:(NSArray *)playerIDs
{
    BOOL found = NO;
    
    for (NSNumber *number in playerIDs) {
        if ([[[diceGameState player:[number integerValue]] playerName] hasPrefix:playerName])
            found = YES;
    }
    return found;
}

//Get a player by their name
- (id <Player>)playerByPlayerName:(NSString *)playerName
{
    for (id <Player> player in playersInTheGame)
    {
        NSString *playerSName = [player name];
        if ([playerName hasPrefix:playerSName])
        {
            return player;
        }
    }
    
    return nil;
}

@end
