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

#pragma mark Protocol

#ifndef Protocol
#define Protocol 1

#define Proto_ClientCommand		@"CLIENT:"

#define Proto_LastAction		@"LASTACTION"
#define Proto_ReRollDice		@"REROLL"
#define Proto_PreviousBid		@"PREVIOUSBID"

#define Proto_NewDice			@"NEWDICE"
#define Proto_Dice				@"DICE"

#define Proto_Seperator			@" "

#define Proto_CommandDelimiter	@"\n"

#define Proto_SpecialRules		@"SPECIALRULES"

#define Proto_ShowAll			@"SHOWALL"
#define Proto_DoneShowAll		@"DONESHOWALL"

#endif

#pragma mark End of Protocol
