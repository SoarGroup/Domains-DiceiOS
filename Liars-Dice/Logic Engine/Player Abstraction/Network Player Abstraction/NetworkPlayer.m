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

#import "Server.h"

@interface NetworkPlayer()

- (void)send:(NSString *)message;

@end

@implementation NetworkPlayer

@synthesize delegate, doneShowAll, uniqueID;

- (id)initWithUser:(User)user playerID:(int)ID;
{
    self = [super init];
    if (self)
    {
        playerID = ID;
        name = user.name;
		uniqueID = user.uniqueID;
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
        previousAction = [[gameState lastHistoryItem] actionType];
    
    if (previousAction == A_PUSH)
        previousAction = A_BID;
    
    if ([[gameState history] count] >= 2)
    {
        HistoryItem *item = [[gameState history] objectAtIndex:[[gameState history] count] - 2];
        secondToLastAction = [item type];
    }
    
    
    NSString *info;
    
    if (previousAction == A_BID || secondToLastAction == A_BID)
        info = [NSString stringWithFormat:@"%@%@%i%@%i%@%@%@%i%@%i", Proto_LastAction, Proto_Seperator, previousAction, Proto_Seperator, secondToLastAction, Proto_CommandDelimiter, Proto_PreviousBid, Proto_Seperator, [[gameState previousBid] numberOfDice], Proto_Seperator, [[gameState previousBid] rankOfDie]];
    else
        info = [NSString stringWithFormat:@"%@%@%i%@%i", Proto_LastAction, Proto_Seperator, previousAction, Proto_Seperator, secondToLastAction];
    
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
	output.actions = nil;
	output.playersDice = nil;
	output.previousBid = nil;
	output.nameOfPreviousBidPlayer = nil;
	output.validChallengeTargets = nil;
	output.corespondingChallengTypes = nil;
	output.specialRules = (BOOL)nil;
	output.allDicePushed = nil;
	output.diceUnderCups = (int)nil;
	output.arrayOfNumbers = nil;
	output.players = nil;
	output.previousPass.playerID = -1;
	output.previousPass.nameOfThePlayer = nil;
	output.secondToLastPass.playerID = -1;
	output.secondToLastPass.nameOfThePlayer = nil;
	
    output.actions = turnInfo.actionsAbleToSend;
    
    NSMutableArray *arrayOfDice = [NSMutableArray array];
    for (Die *die in turnInfo.dice)
    {
        if ([die isKindOfClass:[Die class]])
            [arrayOfDice addObject:[NSNumber numberWithInt:[die dieValue]]];
    }
    
    output.playersDice = [NSArray arrayWithArray:arrayOfDice];
    
	if ([[turnInfo.gameState history] count] > 0)
	{
		HistoryItem *previousItem = [[turnInfo.gameState history] objectAtIndex:0];
		HistoryItem *secondToLastItem = ([[turnInfo.gameState history] count] > 1 ? [[turnInfo.gameState history] objectAtIndex:1] : nil);
		
		if ((previousItem != nil && [previousItem type] == ACTION_BID)
            || (secondToLastItem != nil && previousItem != nil && [secondToLastItem type] == ACTION_BID && [previousItem type] == ACTION_PASS))
		{
			output.previousBid = [turnInfo.gameState previousBid];
			output.nameOfPreviousBidPlayer = (output.previousBid != nil ? [[[[turnInfo.gameState getPlayerState:[[turnInfo.gameState previousBid] playerID]] playerName] componentsSeparatedByString:@"-"] objectAtIndex:0] : @"");
		}
	}
    
    NSMutableArray *targets = [[[NSMutableArray alloc] init] autorelease];
    NSMutableArray *challengeTypes = [[[NSMutableArray alloc] init] autorelease];
    
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
	
	NSMutableArray *allPushedDice = [[[NSMutableArray alloc] init] autorelease];
    
	for (PlayerState *player in [turnInfo.gameState players])
		[allPushedDice addObjectsFromArray:[player pushedDice]];
	
	output.allDicePushed = allPushedDice;
	
	int diceUnderCups = 0;
	
	for (PlayerState *player in [turnInfo.gameState players])
		diceUnderCups += [[player unPushedDice] count];
	
	output.diceUnderCups = diceUnderCups;
	
	NSMutableArray *arrayOfNumbers = [[[NSMutableArray alloc] init] autorelease];
	
	for (Die *die in [[turnInfo.gameState player:turnInfo.playerID] arrayOfDice])
	{
		if ([die isKindOfClass:[Die class]])
		{
			int dieFace = [die dieValue];
			
			numberOfDiceStruct dieStruct;
			
			dieStruct.dieFace = dieFace;
			
			NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
			[array addObjectsFromArray:allPushedDice];
			[array addObjectsFromArray:[[turnInfo.gameState player:turnInfo.playerID] arrayOfDice]];
			dieStruct.numberOfKnownDice = [turnInfo.gameState countKnownDice:dieFace inArray:array];
			
			NSValue *value = [[[NSValue alloc] initWithBytes:&dieStruct objCType:@encode(numberOfDiceStruct)] autorelease];
			[arrayOfNumbers addObject:value];
		}
	}
	
	output.arrayOfNumbers = arrayOfNumbers;
	
	NSMutableArray *playerStructs = [[[NSMutableArray alloc] init] autorelease];
	
	for (PlayerState *player in [turnInfo.gameState players])
	{
		if ([player isKindOfClass:[PlayerState class]])
		{
			playerStruct playerStructObject;
			
			playerStructObject.playerID = [player playerID];
			playerStructObject.numberOfDice = [player numberOfDice];
			playerStructObject.pushedDice = [player pushedDice];
			
			playerStructObject.nameOfThePlayer = [[[player playerName] componentsSeparatedByString:@"-"] objectAtIndex:0];
			
			NSValue *valueOfPlayerStructObject = [[[NSValue alloc] initWithBytes:&playerStructObject objCType:@encode(playerStruct)] autorelease];
			[playerStructs addObject:valueOfPlayerStructObject];
		}
	}
	
	output.players = playerStructs;
	
	Pass previousPass;
	previousPass.playerID = (int)nil;
	previousPass.nameOfThePlayer = nil;
	
	previousPass.playerID = [turnInfo.gameState lastPassPlayerID];
	previousPass.nameOfThePlayer = (previousPass.playerID != -1 ? [[turnInfo.gameState player:previousPass.playerID] playerName] : nil);
	
	output.previousPass = previousPass;
	
	Pass secondToLastPass;
	secondToLastPass.playerID = (int)nil;
	secondToLastPass.nameOfThePlayer = nil;
	
	secondToLastPass.playerID = [turnInfo.gameState secondLastPassPlayerID];
	secondToLastPass.nameOfThePlayer = (secondToLastPass.playerID != -1 ? [[turnInfo.gameState player:secondToLastPass.playerID] playerName] : nil);
	
	output.secondToLastPass = secondToLastPass;
	
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
	User userStruct;
	userStruct.name = name;
	userStruct.uniqueID = uniqueID;
    [delegate sendData:message toPlayer:userStruct];
}

- (void)newRound:(NSArray *)arrayOfDice
{
    NSString *output = Proto_NewDice;
    
    for (Die *die in arrayOfDice)
    {
        if ([die isKindOfClass:[Die class]])
            output = [output stringByAppendingFormat:@"%@%i", Proto_Seperator, [die dieValue]];
    }
    
    [self send:output];
}

- (void)reroll:(NSArray *)arrayOfDice
{
    NSString *output = Proto_ReRollDice;
    
    for (Die *die in arrayOfDice)
    {
        if ([die isKindOfClass:[Die class]])
            output = [output stringByAppendingFormat:@"%@%i", Proto_Seperator, [die dieValue]];
    }
    
    [self send:output];
}

- (void)clientData:(NSString *)data
{
    temporaryInput = [NetworkParser parseInput:data withPlayerID:playerID];
    hasInput = YES;
}

@end
