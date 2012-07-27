//
//  DiceGameState.h
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Bid.h"
#import "Player.h"
#import "DiceTypes.h"

@class HistoryItem;
@class PlayerState;
@class DiceGame;

@protocol NewRoundListener <NSObject> 
- (BOOL) roundEnding;
- (BOOL) roundBeginning;
@end

@interface DiceGameState : NSObject {
@private
    NSArray *players; // of type Player
    NSArray *playerStates; // of type PlayerState
    DiceGame *game;
    int currentTurn;
    int playersLeft;
    Bid *previousBid;
    id <Player> gameWinner;
    
    NSMutableArray *history;
    NSMutableArray *rounds;
    NSMutableArray *newRoundListeners;
    NSMutableArray *losers;
    
    BOOL inSpecialRules;
}

- (id)initWithPlayers:(NSArray *)players numberOfDice:(int)numberOfDice game:(DiceGame*)game;
- (void)dealloc;

- (BOOL)handleBid:(int)playerID withBid:(Bid *)bid;
- (BOOL)handlePush:(int)playerID withPush:(NSArray *)push;
- (BOOL)handlePass:(int)playerID;
- (BOOL)handleChallenge:(int)playerID againstTarget:(int)targetID withFirstPlayerWonOrNot:(BOOL *)didTheChallengerWin;
- (BOOL)handleExact:(int)playerID andWasTheExactRight:(BOOL *)wasTheExactRight;
- (BOOL)handleAccept:(int)playerID;
- (void)addNewRoundListener:(id <NewRoundListener>)listener;

@property (readwrite, retain) NSArray *players;
@property (readwrite, retain) NSArray *playerStates;
@property (readwrite, retain) NSMutableArray *losers;
@property (readwrite, assign) int currentTurn;
@property (readwrite, assign) int playersLeft;
@property (readwrite, retain) Bid *previousBid;
@property (readwrite, retain) NSMutableArray *newRoundListeners;
@property (readwrite, retain) DiceGame *game;

- (id <Player>)getCurrentPlayer;
- (id <Player>)getPlayerWithID:(int)playerID;
- (PlayerState *)getCurrentPlayerState;
- (BOOL)hasAPlayerWonTheGame;
- (id <Player>)gameWinner;
- (BOOL)usingSpecialRules;
- (BOOL)isGameInProgress;
- (NSArray *)history;
- (NSArray *)roundHistory;
- (NSArray *)flatHistory;
- (HistoryItem *)lastHistoryItem;
- (PlayerStatus)playerStatus:(int)playerID;
- (int)historySize;
- (int) getNumberOfPlayers:(BOOL)includeLostPlayers;
- (NSString *)stateString:(int)playerID;
- (NSString *)headerString:(int)playerIDorMinusOne singleLine:(BOOL)singleLine;
- (NSArray *) lastMoveForPlayer:(int)playerID;
- (BOOL)checkBid:(Bid *)bid playerSpecialRules:(BOOL)playerSpecialRules;
- (BOOL)checkPlayer:(int)playerID;

- (int)lastPassPlayerID;
- (int)secondLastPassPlayerID;

- (NSArray *)playersWhoHaveLost;

- (int)countKnownDice:(int)rankOfDice inArray:(NSArray *)arrayToCountIn;

- (NSString *) historyText:(int)playerID;

@end

@interface DiceGameState()
- (void)createNewRound;
- (void)playerLosesRound:(int)playerID;
- (void)playerLosesGame:(int)playerID;
- (void)goToNextPlayerWhoHasntLost;

- (PlayerState *) getPlayerState:(int)playerID;
- (void)moveToNextTurn;

- (int)countDice:(int)rankOfDice;
- (int)countSeenDice:(int)playerIDorMinusOne rank:(int)rank;
- (int)countUnknownDice:(int)playerIDorMinusOne;
- (int)countAllDice;
- (BOOL)isBidCorrect:(Bid *)bid;

- (int) getIndexOfPlayerWithId:(int)playerID;

@end
