//
//  NetworkParser.m
//  Lair's Dice
//
//  Created by Alex on 7/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NetworkParser.h"


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
    NSArray *array = [inputString componentsSeparatedByString:@"_"];
    
    
    inputFromClient input;
    input.action = 0;
    
    for (NSString *string in array)
    {
        if ([string hasPrefix:@"C:BID"])
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
        else if ([string hasPrefix:@"C:CHALLENGE"])
        {
            //Handles the challenges
            input.action = A_CHALLENGE_BID;
            input.targetOfChallenge = [[string componentsSeparatedByString:@","] objectAtIndex:1];
            [input.targetOfChallenge retain];
            break;
        }
        else if ([string hasPrefix:@"C:EXACT"])
        {
            //Handles the exact
            input.action = A_EXACT;
            break;
        }
        else if ([string hasPrefix:@"C:PASS"])
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
    NSString *finalOutput = @"SDICE";
    
    for (NSNumber *die in output.playersDice)
        finalOutput = [NSString stringWithFormat:@"%@_%i", finalOutput, [die intValue]];
    
    finalOutput = [NSString stringWithFormat:@"%@\n", finalOutput];
    
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
            finalOutput = [NSString stringWithFormat:@"%@,", finalOutput];
        
        i++;
    }
    
    finalOutput = [finalOutput stringByAppendingFormat:@"\nPBID_%i_%i", output.previousBid.numberOfDice, output.previousBid.rankOfDie];
    
    if (challenge)
    {
        finalOutput = [NSString stringWithFormat:@"%@\n", finalOutput];
        
        int i = 0;
        for (NSString *target in output.validChallengeTargets)
        {
            finalOutput = [finalOutput stringByAppendingString:target];
            
            finalOutput = [finalOutput stringByAppendingFormat:@":%i", [(NSNumber *)[output.corespondingChallengTypes objectAtIndex:i] intValue]];
            
            if ((i + 1) < [output.validChallengeTargets count])
                finalOutput = [finalOutput stringByAppendingString:@","];
            
            i++;
        }
        
        NSLog(@"Was challenge:%@", finalOutput);
    }
    
    if (output.specialRules)
    {
        finalOutput = [NSString stringWithFormat:@"%@\nSRULES", finalOutput];
    }
    
    return finalOutput;
}

+ (outputToSendToClient)parseInputFromServer:(NSString *)input
{
    NSString *serverInput = input;
    
    NSArray *serverSplit = [serverInput componentsSeparatedByString:@"\n"];
    
    if ([serverSplit count] >= 2)
    {
        outputToSendToClient output;
        output.previousBid = nil;
        
        output.specialRules = NO;
        
        BOOL challenge = NO;
        
        int i = 0;
        for (NSString *string in serverSplit)
        {
            if ([string hasPrefix:@"SDICE_"])
            {
                NSArray *numbers = [string componentsSeparatedByString:@"_"];
                NSMutableArray *numbersAsNSNumbers = [NSMutableArray array];
                
                for (NSString *string in numbers)
                {
                    if ([string intValue] > 0)
                        [numbersAsNSNumbers addObject:[NSNumber numberWithInt:[string intValue]]];
                }
                
                NSArray *numbersAsUseable = [NSArray arrayWithArray:numbersAsNSNumbers];
                
                output.playersDice = numbersAsUseable;
            }
            else if (i == 1)
            {
                NSArray *availibleActions = [string componentsSeparatedByString:@","];
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
            else if (i == 2)
            {
                NSArray *previousBidAsStrings = [string componentsSeparatedByString:@"_"];
                NSNumber *rankOfDie = nil;
                NSNumber *numberOfDice = nil;
                
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
            
            if (challenge && i == 3)
            {
                NSArray *targets = [string componentsSeparatedByString:@","];
                NSMutableArray *finalTargets = [[NSMutableArray alloc] init];
                NSMutableArray *finalTypes = [[NSMutableArray alloc] init];
                
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
            
            if (i == 4)
            {
                if ([string hasPrefix:@"SRULES"])
                {
                    output.specialRules = YES;
                }
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
        return output;
    }
}

+ (NSString *)parseInputFromClient:(inputFromClient)input
{
    NSString *finalOutput = @"";
    
    switch (input.action) {
        case A_PUSH:
        case A_BID:
            finalOutput = [NSString stringWithFormat:@"C:BID_%i_%i", input.bidOfThePlayer.numberOfDice, input.bidOfThePlayer.rankOfDie];
            
            if ([input.diceToPush count])
            {
                finalOutput = [finalOutput stringByAppendingString:@"_PUSH"];
                
                for (NSNumber *number in input.diceToPush)
                {
                    if ([number isKindOfClass:[NSNumber class]])
                        finalOutput = [finalOutput stringByAppendingFormat:@"_%i", [number intValue]];
                }
            }
            break;
        case A_CHALLENGE_BID:
        case A_CHALLENGE_PASS:
            finalOutput = [@"C:CHALLENGE" stringByAppendingFormat:@",%@", input.targetOfChallenge];
            break;
        case A_EXACT:
            finalOutput = @"C:EXACT";
            break;
        case A_PASS:
            finalOutput = @"C:PASS";
            break;
        default:
            break;
    }
    
    return finalOutput;
}

+ (NSArray *)parseNewRound:(NSString *)input
{
    if ([input hasPrefix:@"NDICE_"])
    {
        NSArray *numbers = [input componentsSeparatedByString:@"_"];
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
