//
//  NetworkPlayer.m
//  iSoar
//
//  Created by Alex on 6/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NetworkPlayer.h"
#import "Die.h"
#import "HistoryItem.h"

#import "Lair_s_DiceAppDelegate_iPad.h"

@interface NetworkPlayer()

- (void)send:(NSString *)message;

@end

@implementation NetworkPlayer

@synthesize delegate, doneShowAll;

- (id)initWithName:(NSString *)clientName playerID:(int)ID
{
    self = [super init];
    if (self)
    {
        playerID = ID;
        name = clientName;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (NSString*)name
{
    return name;
}

- (void)showPublicInformation:(DiceGameState *)gameState
{    
    ActionsAbleToSend previousAction = 0;
    ActionsAbleToSend secondToLastAction = 0;
    
    if ([[gameState history] count] >= 1)
        previousAction = [[gameState lastHistoryItem] type];
    
    if (previousAction == A_PUSH)
        previousAction = A_BID;
    
    if ([[gameState history] count] >= 2)
    {
        HistoryItem *item = [[gameState history] objectAtIndex:[[gameState history] count] - 2];
        secondToLastAction = [item type];
    }
    
    
    NSString *info;
    
    if (previousAction == A_BID || secondToLastAction == A_BID)
        info = [NSString stringWithFormat:@"LACTION_%i_%i\nPBID_%i_%i", previousAction, secondToLastAction, [[gameState previousBid] numberOfDice], [[gameState previousBid] rankOfDie]];
    else
        info = [NSString stringWithFormat:@"LACTION_%i_%i", previousAction, secondToLastAction];
    
    if (previousAction != 0)
        [self send:info];
}

- (turnInformationSentFromTheClient)isMyTurn:(turnInformationToSendToClient)turnInfo
{
    if (turnInfo.pass >= 1 && push == NO)
    {
        turnInformationSentFromTheClient info;
        hasInput = NO;
        info.action = A_SLEEP;
        hasInput = NO;
        return info;
    }
    else if (turnInfo.pass >= 1 && push == YES)
    {
        turnInformationSentFromTheClient info;
        info.action = A_PUSH;
        info.diceToPush = dicePushing;
        push = NO;
        hasInput = NO;
        return info;
    }
    else if (turnInfo.pass >= 2)
    {
        turnInformationSentFromTheClient info;
        info.action = A_SLEEP;
        hasInput = NO;
        return info;
    }
    
    if (temporaryInput.action == A_SLEEP)
    {
        hasInput = NO;
    }
    
    outputToSendToClient output;
    output.actions = turnInfo.actionsAbleToSend;
    
    NSMutableArray *arrayOfDice = [NSMutableArray array];
    for (Die *die in turnInfo.dice)
    {
        if ([die isKindOfClass:[Die class]])
            [arrayOfDice addObject:[NSNumber numberWithInt:[die dieValue]]];
    }
    
    output.playersDice = [NSArray arrayWithArray:arrayOfDice];
    
    output.previousBid = [turnInfo.gameState previousBid];
    
    NSMutableArray *targets = [[NSMutableArray alloc] init];
    NSMutableArray *challengeTypes = [[NSMutableArray alloc] init];
    
    if ([[turnInfo.gameState history] count] > 1)
    {
        if ([[turnInfo.gameState lastHistoryItem] type] == A_PASS)
        {
            {
                NSString *targetName = [[[turnInfo.gameState lastHistoryItem] player] playerName];
                NSArray *parts = [targetName componentsSeparatedByString:@"-"];
                targetName = @"";
                int i = 0;
                for (NSString *string in parts)
                {
                    if (i < ([parts count] - 1))
                        targetName = [targetName stringByAppendingString:string];
                    
                    i++;
                }
                
                [targets addObject:targetName];
            }
            [challengeTypes addObject:[NSNumber numberWithInt:A_PASS]];
            
            HistoryItem *secondToLastItem = [[turnInfo.gameState history] objectAtIndex:[[turnInfo.gameState history] count] - 2];
            
            if (([secondToLastItem type] == A_PUSH || [secondToLastItem type] == A_BID) && [[secondToLastItem player] playerID] != playerID)
            {
                {
                    NSString *targetName = [[secondToLastItem player] playerName];
                    NSArray *parts = [targetName componentsSeparatedByString:@"-"];
                    targetName = @"";
                    int i = 0;
                    for (NSString *string in parts)
                    {
                        if (i < ([parts count] - 1))
                            targetName = [targetName stringByAppendingString:string];
                        
                        i++;
                    }
                    
                    [targets addObject:targetName];
                }
                [challengeTypes addObject:[NSNumber numberWithInt:A_BID]];
            }
        }
        else if ([[turnInfo.gameState lastHistoryItem] type] == A_PUSH || [[turnInfo.gameState lastHistoryItem] type] == A_BID)
        {
            {
                NSString *targetName = [[[turnInfo.gameState lastHistoryItem] player] playerName];
                NSArray *parts = [targetName componentsSeparatedByString:@"-"];
                targetName = @"";
                int i = 0;
                for (NSString *string in parts)
                {
                    if (i < ([parts count] - 1))
                        targetName = [targetName stringByAppendingString:string];
                    
                    i++;
                }
                
                [targets addObject:targetName];
            }
            [challengeTypes addObject:[NSNumber numberWithInt:A_BID]];
        }
    }
    else
    {
        if ([[turnInfo.gameState lastHistoryItem] type] == A_BID)
        {
            {
                NSString *targetName = [[[turnInfo.gameState lastHistoryItem] player] playerName];
                NSArray *parts = [targetName componentsSeparatedByString:@"-"];
                targetName = @"";
                int i = 0;
                for (NSString *string in parts)
                {
                    if (i < ([parts count] - 1))
                        targetName = [targetName stringByAppendingString:string];
                    
                    i++;
                }
                
                [targets addObject:targetName];
            }
            [challengeTypes addObject:[NSNumber numberWithInt:A_BID]];
        }
        else if ([[turnInfo.gameState lastHistoryItem] type] == A_PASS)
        {
            {
                NSString *targetName = [[[turnInfo.gameState lastHistoryItem] player] playerName];
                NSArray *parts = [targetName componentsSeparatedByString:@"-"];
                targetName = @"";
                int i = 0;
                for (NSString *string in parts)
                {
                    if (i < ([parts count] - 1))
                        targetName = [targetName stringByAppendingString:string];
                    
                    i++;
                }
                
                [targets addObject:targetName];
            }
            [challengeTypes addObject:[NSNumber numberWithInt:A_PASS]];
        }
    }
        
    output.validChallengeTargets = targets;
    output.corespondingChallengTypes = challengeTypes;
    output.specialRules = [turnInfo.gameState usingSpecialRules];
    
    [self send:[NetworkParser parseOutput:output]];
    
    while (!hasInput);
    
    inputFromClient input = temporaryInput;
    
    turnInformationSentFromTheClient informationToSend;
    informationToSend.action = 0;
    informationToSend.bid = nil;
    informationToSend.diceToPush = nil;
    informationToSend.errorString = nil;
    informationToSend.targetOfChallenge = nil;
    
    if (input.action == A_PUSH)
        informationToSend.action = A_BID;
    else
        informationToSend.action = input.action;
    
    if (input.action == A_CHALLENGE_BID || input.action == A_CHALLENGE_PASS)
    {
        if ([[[[turnInfo.gameState lastHistoryItem] player] playerName] hasPrefix:input.targetOfChallenge])
        {
            if ([[turnInfo.gameState lastHistoryItem] type] == A_BID)
                informationToSend.action = A_CHALLENGE_BID;
            else
                informationToSend.action = A_CHALLENGE_PASS;
        }
        else if ([[turnInfo.gameState history] count] > 1)
        {
            if ([[[[[turnInfo.gameState history] objectAtIndex:[[turnInfo.gameState history] count] - 2] player] playerName] hasPrefix:input.targetOfChallenge])
            {
                HistoryItem *secondToLastItem = [[turnInfo.gameState history] objectAtIndex:[[turnInfo.gameState history] count] - 2];
                
                if ([secondToLastItem type] == A_BID)
                    informationToSend.action = A_CHALLENGE_BID;
                else
                    informationToSend.action = A_CHALLENGE_PASS;
            }
        }
    }
    
    if (informationToSend.action == A_BID)
        informationToSend.bid = [[Bid alloc] initWithPlayerID:turnInfo.playerID andThereBeing:input.bidOfThePlayer.numberOfDice eachBeing:input.bidOfThePlayer.rankOfDie];
    else
        informationToSend.bid = nil;
    
    NSMutableArray *muteArray = [[NSMutableArray alloc] init];
    
    if (input.action == A_PUSH)
    {
        if ([input.diceToPush isKindOfClass:[NSArray class]])
        {
            for (int i = 0;i < [input.diceToPush count];i++) {
                NSNumber *number = [input.diceToPush objectAtIndex:i];
                if ([number isKindOfClass:[NSNumber class]]) {
                    Die *newDie = [[Die alloc] initWithNumber:[number intValue]];
                    [newDie autorelease];
                    [muteArray addObject:newDie];
                    [number release];
                }
            }
            
            [input.diceToPush release];
        }
    }
    
    NSArray *staticArray = [[NSArray alloc] initWithArray:muteArray];
    [staticArray autorelease];
    [muteArray release];
    
    dicePushing = staticArray;
    
    if (input.action == A_PUSH)
        push = YES;
    
    if ([turnInfo.roundHistory count] > 0)
    {
        HistoryItem *lastHistoryItem = [turnInfo.roundHistory objectAtIndex:([turnInfo.roundHistory count] - 1)];
        informationToSend.targetOfChallenge = [[lastHistoryItem player] playerName];
    }
    else
        informationToSend.targetOfChallenge = nil;
    
    return informationToSend;
}

- (void)drop
{
    
}

- (void)cleanup
{
    [self send:[NSString stringWithFormat:@"%@:CLEANUP", name]];
}

- (void)send:(NSString *)message
{
    hasInput = NO;
    [delegate sendData:message toPlayer:name];
}

- (void)newRound:(NSArray *)arrayOfDice
{
    NSString *output = @"NDICE";
    
    for (Die *die in arrayOfDice)
    {
        if ([die isKindOfClass:[Die class]])
            output = [output stringByAppendingFormat:@"_%i", [die dieValue]];
    }
    
    [self send:output];
}

- (void)reroll:(NSArray *)arrayOfDice
{
    NSString *output = @"RDICE";
    
    for (Die *die in arrayOfDice)
    {
        if ([die isKindOfClass:[Die class]])
            output = [output stringByAppendingFormat:@"_%i", [die dieValue]];
    }
    
    [self send:output];
}

- (void)clientData:(NSString *)data
{
    temporaryInput = [NetworkParser parseInput:data withPlayerID:playerID];
    hasInput = YES;
}

@end
