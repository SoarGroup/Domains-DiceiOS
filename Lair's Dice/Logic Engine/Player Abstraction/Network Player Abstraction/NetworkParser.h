//
//  NetworkParser.h
//  Lair's Dice
//
//  Created by Alex on 7/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Bid.h"
#import "DiceEngine.h"

typedef struct {
    ActionsAbleToSend action;
    
    Bid *bidOfThePlayer;
    NSArray *diceToPush;
    
    NSString *targetOfChallenge;
} inputFromClient;

typedef struct {
    NSArray *actions;
    NSArray *playersDice;
    
    Bid *previousBid;
    
    NSArray *validChallengeTargets;
    NSArray *corespondingChallengTypes;
    
    BOOL specialRules;
} outputToSendToClient;

@interface NetworkParser : NSObject {
    
}

+ (inputFromClient)parseInput:(NSString *)data withPlayerID:(int)playerID;
+ (NSString *)parseOutput:(outputToSendToClient)output;

+ (outputToSendToClient)parseInputFromServer:(NSString *)input;
+ (NSString *)parseInputFromClient:(inputFromClient)input;

+ (NSArray *)parseNewRound:(NSString *)input;

@end
