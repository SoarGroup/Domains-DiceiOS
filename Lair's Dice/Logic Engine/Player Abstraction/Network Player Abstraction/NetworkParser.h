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
	//Actions able to do
    NSArray *actions;
	//The client's dice
    NSArray *playersDice;
    
	//The previous bid (may not be the last action, could be second to last)
    Bid *previousBid;
	//The name of the previous player who bid
	NSString *nameOfPreviousBidPlayer;
	
	//The previous pass (if it exists always the last action)
	Pass previousPass; //Check if nameOfThePlayer is nil to see if it was the last action
    //The second to last pass (if it exists it's the second to last action)
	Pass secondToLastPass;
	
	//Valid challenge targets
    NSArray *validChallengeTargets;
	//Each element in this array corresponds to the identical position in validChallengeTargets 'cept this is the last actions as nsnumbers
    NSArray *corespondingChallengTypes;
    
	//Are special rules enabled?
    BOOL specialRules;
	
	//An array containing all the Dice (class) that are pushed
	NSArray *allDicePushed;
	
	int diceUnderCups; //The number of dice that are under the cups

	NSArray *arrayOfNumbers; //This is an array which contains structa encoded in NSValue objects (the array contains NSValue*s).  The struct is numberOfDiceStruct which is the number of dice known for a specific die including under the client's cup.
	
	NSArray *players; //player structs encoded in an NSValue object.
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
