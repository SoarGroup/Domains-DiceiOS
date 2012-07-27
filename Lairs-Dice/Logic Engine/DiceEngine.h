//
//  DiceEngine.h
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DiceGameState.h"
#import "Lair_s_DiceAppDelegate.h"
#import "Player.h"

@class Bid;

#define NUMBER_OF_DICE_PER_PLAYER 5

typedef enum ActionsAbleToSend_ {
    A_BID = 1,
    A_CHALLENGE_BID = 3,
    A_CHALLENGE_PASS = 4,
    A_EXACT = 5,
    A_PASS = 6,
    A_PUSH = 2,
    A_SLEEP = 10
} ActionsAbleToSend;

// Parallel array to ActionsAbleToSend_ enum values.
static NSString *ActionsAbleToSend_names[] = {
    @"Bid",
    @"Challenge bid",
    @"Challenge pass",
    @"Exact",
    @"Pass",
    @"Push",
    @"Sleep",
};

typedef struct turnInformationSentFromTheClient_ {
    ActionsAbleToSend action;
    Bid *bid;
    NSArray *diceToPush;
    NSString *targetOfChallenge;
    NSString *errorString;
} turnInformationSentFromTheClient;

typedef struct turnInformationToSendToClient_ {
    NSArray *roundHistory;
    NSArray *actionsAbleToSend;
    NSArray *dice;
    NSArray *players;
    int playerID;
    int errors;
    int pass;
    DiceGameState *gameState; //For Soar agent Only!
} turnInformationToSendToClient;

@protocol AppDelegateProtocol

- (void)updateActionWithPush:(NSArray *)diceNumbersPushed withPlayer:(id <Player>)player withPlayerID:(int)playerID;
- (void)updateActionWithBid:(Bid *) bid withPlayer:(id <Player>)player;
- (void)updateActionWithExact:(id <Player>)player andWasTheExactRight:(BOOL *)wasTheExactRight withPlayerID:(int)playerID;
- (void)updateActionWithPass:(id <Player>)player;
- (void)updateActionWithChallenge:(id <Player>)firstPlayer against:(id <Player>)secondPlayer ofType:(ActionType)type withDidTheChallengerWin:(BOOL *)didTheChallengerWin withPlayerID:(int)playerID;

- (void)someoneWonTheGame:(NSString *)playerName;

- (void)specialRulesAreInEffect;

- (void)showAll:(DiceGameState *)gameState;

- (void)newTurn:(int)player;

- (void)hideAllDice:(int)playerID;

@end

@interface DiceEngine : NSObject {
    DiceGameState *diceGameState;
    NSArray *playersInTheGame;
    NSMutableArray *droppedPlayerIDs;
    
    BOOL roundEnded;
    
    BOOL doneShowAll;
}

@property (nonatomic, readonly) NSArray *playersInTheGame;
@property (nonatomic, retain) DiceGameState *diceGameState;

- (id)initWithPlayers:(NSArray *)playersWhichImplementPlayerProtocol;
- (void)dealloc;

- (BOOL)pushAfterBid:(NSArray *)arrayOfDiceToPush withCallerBeing:(id <Player>)caller;

- (void)mainLoop:(Lair_s_DiceAppDelegate <AppDelegateProtocol> *)caller;

- (void)doneShowAll;

@end
