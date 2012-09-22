//
//  NetworkParser.m
//  Lair's Dice
//
//  Created by Alex on 7/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NetworkParser.h"

#import "Die.h"

@implementation NetworkParser

+ (inputFromClient)parseInput:(NSString *)data withPlayerID:(int)playerID
{
    NSString *inputString = data;
    
    /* 
     N = Number
     D = Die Value (ie. A Two or A Three etc. 'cept in number form, 2, 3)
     Possible commands:
     BID N D
     BID N D PUSH D D D D
     CHALLENGE
     EXACT
     PASS
     */
    NSArray *array = [inputString componentsSeparatedByString:Proto_Seperator];
    
    
    inputFromClient input;
    input.action = 0;
    
    for (NSString *string in array)
    {
        if ([string hasPrefix:[NSString stringWithFormat:@"%@%@", Proto_ClientCommand, @"BID"]])
        {
            if ([array count] < 3)
                break;
            
            //Handles the bids
            NSArray *bidArray = [array subarrayWithRange:NSMakeRange(0, 3)];
            
            if ([[bidArray objectAtIndex:1] intValue] > 0 && [[bidArray objectAtIndex:2] intValue] > 0)
            {
                Bid *bid = [[Bid alloc] initWithPlayerID:playerID andThereBeing:[[bidArray objectAtIndex:1] intValue] eachBeing:[[bidArray objectAtIndex:2] intValue]];
                
                input.action = A_BID;
                input.bidOfThePlayer = bid;
                
                if ([array count] > 3)
                {
                    NSArray *pushArray = [array subarrayWithRange:NSMakeRange(3, [array count] - 3)];
                    
                    if ([pushArray count] >= 2)
                    {
                        input.action = A_PUSH;
                        
                        NSMutableArray *arrayOfDice = [[NSMutableArray alloc] init];
                        
                        for (NSString *string in pushArray)
                        {
                            if ([string intValue] > 0)
                                [arrayOfDice addObject:[NSNumber numberWithInt:[string intValue]]];
                        }
                        
                        NSArray *diceToPush = [NSArray arrayWithArray:arrayOfDice];
                        [arrayOfDice release];
                        input.diceToPush = diceToPush;
                        [input.diceToPush retain];
                    }
                }
            }
            
            break;
        }
        else if ([string hasPrefix:[NSString stringWithFormat:@"%@%@", Proto_ClientCommand, @"CHALLENGE"]])
        {
            //Handles the challenges
            input.action = A_CHALLENGE_BID;
            input.targetOfChallenge = [[string componentsSeparatedByString:@","] objectAtIndex:1];
            [input.targetOfChallenge retain];
            break;
        }
        else if ([string hasPrefix:[NSString stringWithFormat:@"%@%@", Proto_ClientCommand, @"EXACT"]])
        {
            //Handles the exact
            input.action = A_EXACT;
            break;
        }
        else if ([string hasPrefix:[NSString stringWithFormat:@"%@%@", Proto_ClientCommand, @"PASS"]])
        {
            //Handles the passes
            input.action = A_PASS;
            break;
        }
    }
    
    return input;
}

+ (NSString *)parseOutput:(outputToSendToClient)output
{
#pragma mark - Client Dice Output
	
	NSString *finalOutput = [NSString stringWithFormat:@"%i%@%@", Proto_Enum_ClientDice, Proto_ProtocolTypesEnd, Proto_Dice];
    
    for (NSNumber *die in output.playersDice)
        finalOutput = [NSString stringWithFormat:@"%@%@%i", finalOutput, Proto_Seperator, [die intValue]];
    
#pragma mark - Actions able to do
	
    finalOutput = [NSString stringWithFormat:@"%@%@", finalOutput, Proto_CommandDelimiter];
	
	finalOutput = [finalOutput stringByAppendingFormat:@"%i%@", Proto_Enum_Actions, Proto_ProtocolTypesEnd];
	
    BOOL challenge = NO;
    
    int i = 0;
    for (NSNumber *actionAsInt in output.actions)
    {
        switch ([actionAsInt intValue]) {
            case A_BID:
                finalOutput = [finalOutput stringByAppendingString:@"BID"];
                break;
            case A_PUSH:
                finalOutput = [finalOutput stringByAppendingString:@"PUSH"];
                break;
            case A_CHALLENGE_BID:
            case A_CHALLENGE_PASS:
            {
                finalOutput = [finalOutput stringByAppendingString:@"CHALLENGE"];
                challenge = YES;
            }
                break;
            case A_PASS:
                finalOutput = [finalOutput stringByAppendingString:@"PASS"];
                break;
            case A_EXACT:
                finalOutput = [finalOutput stringByAppendingString:@"EXACT"];
                break;
            default:
                break;
        }
        
        if ((i + 1) < [output.actions count])
            finalOutput = [finalOutput stringByAppendingString:Proto_ArraySeperator];
        
        i++;
    }
	
#pragma mark - Previous Bid
	
	if (output.previousBid != nil)
	{
		finalOutput = [finalOutput stringByAppendingFormat:@"%@%i%@", Proto_CommandDelimiter, Proto_Enum_PreviousBid, Proto_ProtocolTypesEnd];
		
		finalOutput = [finalOutput stringByAppendingFormat:@"%@%@%i%@%i:%@", Proto_PreviousBid, Proto_Seperator, output.previousBid.numberOfDice, Proto_Seperator, output.previousBid.rankOfDie, output.nameOfPreviousBidPlayer];
	}
    
#pragma mark - Challenges
	
    if (challenge)
    {
        finalOutput = [NSString stringWithFormat:@"%@%@", finalOutput, Proto_CommandDelimiter];
		
		finalOutput = [NSString stringWithFormat:@"%@%i%@", finalOutput, Proto_Enum_ChallengeTargets_Types, Proto_ProtocolTypesEnd];
        
        int i = 0;
        for (NSString *target in output.validChallengeTargets)
        {
            finalOutput = [finalOutput stringByAppendingString:target];
            
            finalOutput = [finalOutput stringByAppendingFormat:@":%i", [(NSNumber *)[output.corespondingChallengTypes objectAtIndex:i] intValue]];
            
            if ((i + 1) < [output.validChallengeTargets count])
                finalOutput = [finalOutput stringByAppendingString:Proto_ArraySeperator];
            
            i++;
        }
	}
    
#pragma mark - Special Rules
	
    if (output.specialRules)
    {
		finalOutput = [finalOutput stringByAppendingFormat:@"%@%i%@", Proto_CommandDelimiter, Proto_Enum_SpecialRules, Proto_ProtocolTypesEnd];
		
        finalOutput = [NSString stringWithFormat:@"%@", Proto_SpecialRules];
    }
	
#pragma mark - All Dice Pushed
	
	if (output.allDicePushed && [output.allDicePushed count] > 0)
	{
		finalOutput = [finalOutput stringByAppendingFormat:@"%@%i%@", Proto_CommandDelimiter, Proto_Enum_AllDice, Proto_ProtocolTypesEnd];
		
		i = 0;
		for (Die* die in output.allDicePushed)
		{
			if ([die isKindOfClass:[Die class]])
			{
				finalOutput = [NSString stringWithFormat:@"%@%i", finalOutput, [die dieValue]];
				
				if ((i + 1) < [output.allDicePushed count])
					finalOutput = [finalOutput stringByAppendingString:Proto_ArraySeperator];
			}
			
			i++;
		}
		
	}
	
#pragma mark - Dice Under Cups
	
	finalOutput = [finalOutput stringByAppendingFormat:@"%@%i%@", Proto_CommandDelimiter, Proto_Enum_DiceUnderCups, Proto_ProtocolTypesEnd];
	
	finalOutput = [finalOutput stringByAppendingFormat:@"%i", output.diceUnderCups];
	
#pragma mark - Array Of Numbers
	
	finalOutput = [finalOutput stringByAppendingFormat:@"%@%i%@", Proto_CommandDelimiter, Proto_Enum_ArrayOfNumbers, Proto_ProtocolTypesEnd];
	
	i = 0;
	for (NSValue *numberOfDiceNSValue in output.arrayOfNumbers)
	{
		if ([numberOfDiceNSValue isKindOfClass:[NSValue class]])
		{
			numberOfDiceStruct dieNumber;
			[numberOfDiceNSValue getValue:&dieNumber];
			
			finalOutput = [finalOutput stringByAppendingFormat:@"%i:%i", dieNumber.dieFace, dieNumber.numberOfKnownDice];
			
			if ((i + 1) < [output.arrayOfNumbers count])
				finalOutput = [finalOutput stringByAppendingString:Proto_ArraySeperator];
		}
		
		i++;
	}
	
#pragma mark - Player Structs
	
	finalOutput = [finalOutput stringByAppendingFormat:@"%@%i%@", Proto_CommandDelimiter, Proto_Enum_PlayerStructs, Proto_ProtocolTypesEnd];
	
	i = 0;
	for (NSValue *playerStructNSValueEncoded in output.players)
	{
		if ([playerStructNSValueEncoded isKindOfClass:[NSValue class]])
		{
			playerStruct playerStructFromNSValue;
			[playerStructNSValueEncoded getValue:&playerStructFromNSValue];
			
			finalOutput = [finalOutput stringByAppendingFormat:@"%i:%i:%@", playerStructFromNSValue.playerID, playerStructFromNSValue.numberOfDice, playerStructFromNSValue.nameOfThePlayer];
			
			if (playerStructFromNSValue.pushedDice && [playerStructFromNSValue.pushedDice count] > 0)
			{
				finalOutput = [finalOutput stringByAppendingFormat:@":"];
				
				int i = 0;
				for (Die *die in playerStructFromNSValue.pushedDice)
				{
					if ([die isKindOfClass:[Die class]])
					{
						finalOutput = [finalOutput stringByAppendingFormat:@"%i", [die dieValue]];
						
						if ((i + 1) < [playerStructFromNSValue.pushedDice count])
							finalOutput = [finalOutput stringByAppendingString:Proto_ArraySeperator];
					}
					i++;
				}
			}
			
			if ((i + 1) < [output.players count])
				finalOutput = [finalOutput stringByAppendingString:@"|"];
		}
		
		i++;
	}
	
#pragma mark - Previous Pass
	
	if (output.previousPass.playerID != -1 && output.previousPass.nameOfThePlayer != nil)
	{
		finalOutput = [finalOutput stringByAppendingFormat:@"%@%i%@", Proto_CommandDelimiter, Proto_Enum_PreviousPass, Proto_ProtocolTypesEnd];
		
		finalOutput = [finalOutput stringByAppendingFormat:@"%i:%@", output.previousPass.playerID, output.previousPass.nameOfThePlayer];
	}
	
#pragma mark - Second To Last Pass
	
	if (output.secondToLastPass.playerID != -1 && output.secondToLastPass.nameOfThePlayer != nil)
	{
		finalOutput = [finalOutput stringByAppendingFormat:@"%@%i%@", Proto_CommandDelimiter, Proto_Enum_SecondToLastPass, Proto_ProtocolTypesEnd];
		
		finalOutput = [finalOutput stringByAppendingFormat:@"%i:%@", output.secondToLastPass.playerID, output.secondToLastPass.nameOfThePlayer];
	}
	
    return finalOutput;
}

+ (outputToSendToClient)parseInputFromServer:(NSString *)input
{
    NSString *serverInput = input;
    
    NSArray *serverSplit = [serverInput componentsSeparatedByString:Proto_CommandDelimiter];
    
    if ([serverSplit count])
    {
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
        
        BOOL challenge = NO;
        
        int i = 0;
        for (NSString *string in serverSplit)
        {
			ProtocolTypes protocolType = [[[string componentsSeparatedByString:Proto_ProtocolTypesEnd] objectAtIndex:0] intValue];
			NSString *networkCommand = [[string componentsSeparatedByString:Proto_ProtocolTypesEnd] objectAtIndex:1];
			
            if (protocolType == Proto_Enum_ClientDice)
            {
                NSArray *numbers = [networkCommand componentsSeparatedByString:Proto_Seperator];
                NSMutableArray *numbersAsNSNumbers = [NSMutableArray array];
                
                for (NSString *string in numbers)
                {
                    if ([string intValue] > 0)
                        [numbersAsNSNumbers addObject:[NSNumber numberWithInt:[string intValue]]];
                }
                                
                output.playersDice = [NSArray arrayWithArray:numbersAsNSNumbers];
            }
            else if (protocolType == Proto_Enum_Actions)
            {
                NSArray *availibleActions = [networkCommand componentsSeparatedByString:Proto_ArraySeperator];
                NSMutableArray *arrayOfNumbers = [NSMutableArray array];
                
                for (NSString *action in availibleActions)
                {
                    if ([action isEqualToString:@"BID"])
                        [arrayOfNumbers addObject:[[NSNumber numberWithInt:A_BID] retain]];
                    else if ([action isEqualToString:@"CHALLENGE"])
                    {
                        [arrayOfNumbers addObject:[[NSNumber numberWithInt:A_CHALLENGE_BID] retain]];
                        challenge = YES;
                    }
                    else if ([action isEqualToString:@"PASS"])
                        [arrayOfNumbers addObject:[[NSNumber numberWithInt:A_PASS] retain]];
                    else if ([action isEqualToString:@"EXACT"])
                        [arrayOfNumbers addObject:[[NSNumber numberWithInt:A_EXACT] retain]];
                }
                
                NSArray *numbersAsUsable = [NSArray arrayWithArray:arrayOfNumbers];
                output.actions = numbersAsUsable;
            }
            else if (protocolType == Proto_Enum_PreviousBid)
            {
				NSArray *previousBidVSName = [networkCommand componentsSeparatedByString:@":"];
                NSArray *previousBidAsStrings = [[previousBidVSName objectAtIndex:0] componentsSeparatedByString:Proto_Seperator];
                NSNumber *rankOfDie = nil;
                NSNumber *numberOfDice = nil;
				
				output.nameOfPreviousBidPlayer = [previousBidVSName objectAtIndex:1];
                
                int i = 0;
                for (NSString *number in previousBidAsStrings)
                {
                    if (i != 0)
                    {
                        if (i == 1)
                            numberOfDice = [NSNumber numberWithInt:[number intValue]];
                        else if (i == 2)
                            rankOfDie = [NSNumber numberWithInt:[number intValue]];
                    }
                    i++;
                }
                
                if (rankOfDie && numberOfDice)
                {
                    Bid *bid = [[Bid alloc] initWithPlayerID:-1 andThereBeing:[numberOfDice intValue] eachBeing:[rankOfDie intValue]];
                    output.previousBid = bid;
                }
            }
            else if (challenge && protocolType == Proto_Enum_ChallengeTargets_Types)
            {
                NSArray *targets = [networkCommand componentsSeparatedByString:@","];
                NSMutableArray *finalTargets = [[[NSMutableArray alloc] init] autorelease];
                NSMutableArray *finalTypes = [[[NSMutableArray alloc] init] autorelease];
                
                for (NSString *target in targets)
                {
                    NSArray *partsOfTheTarget = [target componentsSeparatedByString:@":"];
                    
                    [finalTargets addObject:[partsOfTheTarget objectAtIndex:0]];
                    
                    if ([(NSString *)[partsOfTheTarget objectAtIndex:1] isEqualToString:[NSString stringWithFormat:@"%i", A_BID]])
                        [finalTypes addObject:[NSNumber numberWithInt:A_BID]];
                    else
                        [finalTypes addObject:[NSNumber numberWithInt:A_PASS]];
                }
				
                output.validChallengeTargets = [[NSArray alloc] initWithArray:finalTargets];
                output.corespondingChallengTypes = [[NSArray alloc] initWithArray:finalTypes];
            }
            else if (protocolType == Proto_Enum_SpecialRules)
            {
                if ([string hasPrefix:Proto_SpecialRules])
                {
                    output.specialRules = YES;
                }
            }
            else if (protocolType == Proto_Enum_AllDice)
			{
				NSMutableArray *arrayOfPushedDice = [[[NSMutableArray alloc] init] autorelease];
				NSArray *splitArray = [networkCommand componentsSeparatedByString:Proto_ArraySeperator];
				
				for (NSString *dieAsString in splitArray)
					[arrayOfPushedDice addObject:[[[Die alloc] initWithNumber:[dieAsString intValue]] autorelease]];
				
				output.allDicePushed = [[NSArray alloc] initWithArray:arrayOfPushedDice];
			}
			else if (protocolType == Proto_Enum_DiceUnderCups)
			{
				output.diceUnderCups = [networkCommand intValue];
			}
			else if (protocolType == Proto_Enum_ArrayOfNumbers)
			{
				NSMutableArray *numberOfDiceStructsEncodedInNSValues = [[[NSMutableArray alloc] init] autorelease];
				NSArray *splitArray = [networkCommand componentsSeparatedByString:Proto_ArraySeperator];
				
				for (NSString *string in splitArray)
				{
					NSArray *partsOfStruct = [string componentsSeparatedByString:@":"];
					
					numberOfDiceStruct numberOfDice;
					numberOfDice.dieFace = [[partsOfStruct objectAtIndex:0] intValue];
					numberOfDice.numberOfKnownDice = [[partsOfStruct objectAtIndex:1] intValue];
					
					NSValue *valueToAddToArray = [[[NSValue alloc] initWithBytes:&numberOfDice objCType:@encode(numberOfDiceStruct)] autorelease];
					
					[numberOfDiceStructsEncodedInNSValues addObject:valueToAddToArray];
				}
				
				output.arrayOfNumbers = [[NSArray alloc] initWithArray:numberOfDiceStructsEncodedInNSValues];
			}
			else if (protocolType == Proto_Enum_PlayerStructs)
			{
				NSMutableArray *playerStructsEncodedInNSValues = [[[NSMutableArray alloc] init] autorelease];
				NSArray *playerSplits = [networkCommand componentsSeparatedByString:@"|"];
				
				for (NSString *playerAsString in playerSplits)
				{
					NSArray *partsOfThePlayer = [playerAsString componentsSeparatedByString:@":"];
					
					playerStruct structOfThePlayer;
					structOfThePlayer.playerID = [[partsOfThePlayer objectAtIndex:0] intValue];
					structOfThePlayer.numberOfDice = [[partsOfThePlayer objectAtIndex:1] intValue];
					structOfThePlayer.nameOfThePlayer = [partsOfThePlayer objectAtIndex:2];
					
					NSMutableArray *arrayOfPushedDice = [[[NSMutableArray alloc] init] autorelease];
					if ([partsOfThePlayer count] == 4)
					{
						NSArray *pushedDice = [[partsOfThePlayer objectAtIndex:3] componentsSeparatedByString:Proto_ArraySeperator];
						
						for (NSString *dieAsString in pushedDice)
							[arrayOfPushedDice addObject:[[[Die alloc] initWithNumber:[dieAsString intValue]] autorelease]];
					}
					structOfThePlayer.pushedDice = [[NSArray alloc] initWithArray:arrayOfPushedDice];
					
					NSValue *valueToInsertIntoPlayerStructsArray = [[[NSValue alloc] initWithBytes:&structOfThePlayer objCType:@encode(playerStruct)] autorelease];
					[playerStructsEncodedInNSValues addObject:valueToInsertIntoPlayerStructsArray];
				}
				
				output.players = [[NSArray alloc] initWithArray:playerStructsEncodedInNSValues];
			}
			else if (protocolType == Proto_Enum_PreviousPass)
			{
				NSArray *previousPassSplit = [networkCommand componentsSeparatedByString:@":"];
				
				output.previousPass.playerID = [[previousPassSplit objectAtIndex:0] intValue];
				output.previousPass.nameOfThePlayer = [previousPassSplit objectAtIndex:1];
			}
			else if (protocolType == Proto_Enum_SecondToLastPass)
			{
				NSArray *secondToLastPassSplit = [networkCommand componentsSeparatedByString:@":"];
				
				output.secondToLastPass.playerID = [[secondToLastPassSplit objectAtIndex:0] intValue];
				output.secondToLastPass.nameOfThePlayer = [secondToLastPassSplit objectAtIndex:1];
			}
			
            i++;
        }
        
        return output;
    }
    else
    {
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
        return output;
    }
}

+ (NSString *)parseInputFromClient:(inputFromClient)input
{
    NSString *finalOutput = @"";
    
    switch (input.action) {
        case A_PUSH:
        case A_BID:
            finalOutput = [NSString stringWithFormat:@"%@BID%@%i%@%i", Proto_ClientCommand, Proto_Seperator, input.bidOfThePlayer.numberOfDice, Proto_Seperator, input.bidOfThePlayer.rankOfDie];
            
            if ([input.diceToPush count])
            {
                finalOutput = [finalOutput stringByAppendingString:[NSString stringWithFormat:@"%@PUSH", Proto_Seperator]];
                
                for (NSNumber *number in input.diceToPush)
                {
                    if ([number isKindOfClass:[NSNumber class]])
                        finalOutput = [finalOutput stringByAppendingFormat:@"%@%i", Proto_Seperator, [number intValue]];
                }
            }
            break;
        case A_CHALLENGE_BID:
        case A_CHALLENGE_PASS:
            finalOutput = [[NSString stringWithFormat:@"%@CHALLENGE", Proto_Seperator] stringByAppendingFormat:@",%@", input.targetOfChallenge];
            break;
        case A_EXACT:
            finalOutput = [NSString stringWithFormat:@"%@EXACT", Proto_Seperator];
            break;
        case A_PASS:
            finalOutput = [NSString stringWithFormat:@"%@PASS", Proto_Seperator];
            break;
        default:
            break;
    }
    
    return finalOutput;
}

+ (NSArray *)parseNewRound:(NSString *)input
{
    if ([input hasPrefix:[NSString stringWithFormat:@"%@%@", Proto_NewDice, Proto_Seperator]] || [input hasPrefix:[NSString stringWithFormat:@"%@%@", Proto_ReRollDice, Proto_Seperator]])
    {
        NSArray *numbers = [input componentsSeparatedByString:Proto_Seperator];
        NSMutableArray *numbersAsNSNumbers = [NSMutableArray array];
        
        for (NSString *string in numbers)
        {
            if ([string intValue] > 0)
                [numbersAsNSNumbers addObject:[NSNumber numberWithInt:[string intValue]]];
        }
        
        NSArray *numbersAsUseable = [NSArray arrayWithArray:numbersAsNSNumbers];
        return numbersAsUseable;
    }
    return nil;
}

@end
