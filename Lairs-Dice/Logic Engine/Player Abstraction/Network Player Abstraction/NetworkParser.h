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
#import "Die.h"

typedef struct {
    ActionsAbleToSend action;
    
    Bid *bidOfThePlayer;
    NSArray *diceToPush;
    
    NSString *targetOfChallenge;
} inputFromClient;

typedef struct {
	int dieFace; //The face of the die as a number
	int numberOfKnownDice; //The number of dice known (pushed & non-pushed)
} numberOfDiceStruct; //Number of known dice for a peticular face including under the client's cup

typedef struct {
	int playerID; //The player's ID
	
	int numberOfDice; //The number of dice the player has
	NSArray *pushedDice; //The dice the player has pushed
	
	NSString *nameOfThePlayer;
} playerStruct;

typedef struct {
	int playerID; //The player ID (-1 if none)
	NSString *nameOfThePlayer; //The name of the player (nil if none)
} Pass; //Previous Pass Struct

typedef struct {
    
	// Available actions
    // Array of NSNumbers corresponding to values from the enum ActionsAbleToSend_
    NSArray *actions;
	
    // The client's dice
    // Array of NSNumbers representing the face values of each die.
    NSArray *playersDice;
    
	// The previous bid (may not be the last action, could be second to last)
    Bid *previousBid;
    
	//The name of the previous player who bid
	NSString *nameOfPreviousBidPlayer;
	
	// The previous pass (if it exists always the last action)
    // If this doesn't exist, previousPass.playerId == -1 and previousPass.nameOfThePlayer == nil
	Pass previousPass; // Check if nameOfThePlayer is nil to see if it was the last action
    
    //The second to last pass (if it exists it's the second to last action)
    // If this doesn't exist, secondToLastPass.playerId == -1 and secondToLastPass.nameOfThePlayer == nil
	Pass secondToLastPass;
	
	// Valid challenge targets
    // Array of NSStrings, maybe player names?
    NSArray *validChallengeTargets;
    
	// Each element in this array corresponds to the identical position in validChallengeTargets except this is the last actions as nsnumbers
    // Array of NSNumber* corresponding to either A_BID or A_PASS
    NSArray *corespondingChallengTypes;
    
	// Are special rules enabled?
    BOOL specialRules;
	
	// An array containing all the dice that are pushed
    // Array of Die*.
	NSArray *allDicePushed;
	
	int diceUnderCups; // The number of dice that are under the cups

    // This is an array which contains structs encoded in NSValue objects (the array contains NSValue*s).
    // The struct is numberOfDiceStruct which is the number of dice known 
    // for a specific die including under the client's cup.
    // Array of NSValue* each of which is an encoded numberOfDiceStruct.
	NSArray *arrayOfNumbers;
    
    // Player structs encoded in an NSValue object.
    // Array of NSValue* each of which is of type playerStruct.
	NSArray *players;
    
} outputToSendToClient;

static NSString* outputToSendToClient_string(outputToSendToClient* output, bool full)
{
    NSMutableString *mut = [[[NSMutableString alloc] init] autorelease];
    
    // Special rules
    if (output->specialRules)
    {
        [mut appendString:@"SPECIAL RULES\n"];
    }
    
    // Actions
    if (full)
    {
    [mut appendString:@"Available actions:\n"];
    for (NSNumber *number in output->actions)
    {
        [mut appendFormat:@"%@, ", ActionsAbleToSend_names[[number intValue]]];
    }
    [mut appendString:@"\n"];
    }
    
    // Dice
    if (full)
    {
    [mut appendString:@"Your dice:\n"];
    for (NSNumber *number in output->playersDice)
    {
        [mut appendFormat:@"%d, ", [number intValue]];
    }
    [mut appendString:@"\n"];
    }
    
    // Previous bid
    [mut appendFormat:@"Previous bid:\n%@\n", [output->previousBid asString]];

    // Previous pass
    if (output->previousPass.playerID != -1 && output->previousPass.nameOfThePlayer != nil)
    {
        [mut appendFormat:@"Previous pass:\n%@\n", output->previousPass.nameOfThePlayer];
    }
    
    // Second-to-last pass
    if (output->previousPass.playerID != -1 && output->secondToLastPass.nameOfThePlayer != nil)
    {
        [mut appendFormat:@"Second-to-last pass:\n%@\n", output->secondToLastPass.nameOfThePlayer];
    }
    
    // Challenge targets
    [mut appendString:@"Can challenge:"];
    for (int i = 0; i < [output->validChallengeTargets count]; ++i)
    {
        NSString *str = [output->validChallengeTargets objectAtIndex:i];
        NSNumber *number = [output->corespondingChallengTypes objectAtIndex:i];
        NSString *type = [number intValue] == A_BID ? @"bid" : @"pass";
        [mut appendFormat:@"%@'s %@\n", str, type];
    }
    [mut appendString:@"\n"];

    // Pushed dice
    [mut appendString:@"Pushed dice:\n"];
    for (Die * die in output->allDicePushed)
    {
        [mut appendFormat:@"%@, ", [die asString]];
    }
    [mut appendString:@"\n"];
    
    // Dice under cups
    [mut appendFormat:@"Dice under cups:\n%d\n", output->diceUnderCups];
    
    // Number of known dice
    [mut appendString:@"Number of known dice:\n"];
    for (NSValue *value in output->arrayOfNumbers) {
        numberOfDiceStruct numDiceStruct;
        [value getValue:&numDiceStruct];
        int numDice = numDiceStruct.numberOfKnownDice;
        int dieFace = numDiceStruct.dieFace;
        [mut appendFormat:@"%d %ds, ", numDice, dieFace];
    }
    [mut appendString:@"\n"];
    
    // Add players
    [mut appendString:@"Players:\n"];
    for (NSValue *value in output->players)
    {
        playerStruct player;
        [value getValue:&player];
        int playerId = player.playerID;
        int numberOfDice = player.numberOfDice; // The number of dice the player has
        NSArray *pushedDice = player.pushedDice; // The dice the player has pushed
        NSString *playerName = player.nameOfThePlayer;
        [mut appendFormat:@"%@, %d dice", playerName, numberOfDice];
        if ([pushedDice count] != 0)
        {
            [mut appendFormat:@"\nPushed: ", playerName, numberOfDice];
            
            for (Die * die in pushedDice)
            {
                [mut appendFormat:@"%@, ", [die asString]];
            }
        }
        [mut appendString:@"\n"];
    }

    return [NSString stringWithString:mut];
}

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

#define Proto_CommandDelimiter	@"\n" //Do not use in your commands

#define Proto_ArraySeperator	@","

#define Proto_SpecialRules		@"SPECIALRULES"

#define Proto_ShowAll			@"SHOWALL"
#define Proto_DoneShowAll		@"DONESHOWALL"

#define Proto_ProtocolTypesEnd	@"|EndOfProtocolType|" // Do not use in your commands

typedef enum {
	Proto_Enum_Actions = 0,
	Proto_Enum_ClientDice = 1,
	Proto_Enum_PreviousBid = 2,
	Proto_Enum_ChallengeTargets_Types = 3,
	Proto_Enum_SpecialRules = 4,
	Proto_Enum_AllDice = 5,
	Proto_Enum_DiceUnderCups = 6,
	Proto_Enum_ArrayOfNumbers = 7,
	Proto_Enum_PlayerStructs = 8,
	Proto_Enum_PreviousPass = 9,
	Proto_Enum_SecondToLastPass = 10
} ProtocolTypes;

#endif

#pragma mark End of Protocol
