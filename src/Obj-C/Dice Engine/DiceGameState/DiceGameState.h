//
//  DiceGameState.h
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Bid.h"
#import "Player.h"
#import "DiceTypes.h"

@class HistoryItem;
@class PlayerState;
@class DiceGame;

@protocol NewRoundListener <NSObject, NSCoding>
- (BOOL) roundEnding;
- (BOOL) roundBeginning;
@end

@interface DiceGameState : NSObject {
@private
    id <Player> gameWinner;
    
    NSMutableArray *history;
    NSMutableArray *rounds;
	NSArray* playersArrayToDecode;

    BOOL inSpecialRules;
}

// Encoding
-(id)initWithCoder:(NSCoder*)decoder;
-(void)encodeWithCoder:(NSCoder*)encoder;
-(void)decodePlayers;

- (id)initWithPlayers:(NSArray *)players numberOfDice:(int)numberOfDice game:(DiceGame*)game;
- (void)dealloc;

- (BOOL)handleBid:(NSInteger)playerID withBid:(Bid *)bid;
- (BOOL)handlePush:(NSInteger)playerID withPush:(NSArray *)push;
- (BOOL)handlePass:(NSInteger)playerID andPushingDice:(BOOL)pushingDice;
- (BOOL)handleChallenge:(NSInteger)playerID againstTarget:(NSInteger)targetID withFirstPlayerWonOrNot:(BOOL *)didTheChallengerWin;
- (BOOL)handleExact:(NSInteger)playerID andWasTheExactRight:(BOOL *)wasTheExactRight;
- (BOOL)handleAccept:(NSInteger)playerID;
- (void)addNewRoundListener:(id <NewRoundListener>)listener;

@property (readwrite, retain) NSArray *players;
@property (readwrite, retain) NSArray *playerStates;
@property (readwrite, retain) NSMutableArray *losers;
@property (readwrite, assign) int currentTurn;
@property (readwrite, assign) NSInteger playersLeft;
@property (readwrite, retain) Bid *previousBid;
@property (readwrite, retain) NSMutableArray *theNewRoundListeners;
@property (readwrite, retain) DiceGame *game;
@property (readwrite, atomic, assign) BOOL canContinueGame;

- (id <Player>)getCurrentPlayer;
- (id <Player>)getPlayerWithID:(NSInteger)playerID;
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
- (NSInteger)historySize;
- (NSInteger) getNumberOfPlayers:(BOOL)includeLostPlayers;
- (NSString *)stateString:(int)playerID;
- (NSString *)headerString:(int)playerIDorMinusOne singleLine:(BOOL)singleLine;
- (NSArray *) lastMoveForPlayer:(NSInteger)playerID;
- (BOOL)checkBid:(Bid *)bid playerSpecialRules:(BOOL)playerSpecialRules;
- (BOOL)checkPlayer:(NSInteger)playerID;

- (NSInteger)lastPassPlayerID;
- (NSInteger)secondLastPassPlayerID;

- (NSArray *)playersWhoHaveLost;

- (int)countKnownDice:(int)rankOfDice inArray:(NSArray *)arrayToCountIn;

- (NSString *) historyText:(NSInteger)playerID;
- (PlayerState*) playerStateForPlayerID:(NSInteger)playerID;
- (NSMutableAttributedString *) historyText:(NSInteger)playerID colorName:(BOOL)colorThePlayer;

@end

@interface DiceGameState()
- (void)createNewRound;
- (void)playerLosesRound:(NSInteger)playerID;
- (void)playerLosesGame:(NSInteger)playerID;
- (void)goToNextPlayerWhoHasntLost;

- (PlayerState *) getPlayerState:(NSInteger)playerID;
- (void)moveToNextTurn;

- (int)countDice:(int)rankOfDice;
- (int)countSeenDice:(NSInteger)playerIDorMinusOne rank:(int)rank;
- (int)countUnknownDice:(NSInteger)playerIDorMinusOne;
- (int)countAllDice;
- (BOOL)isBidCorrect:(Bid *)bid;

- (int) getIndexOfPlayerWithId:(NSInteger)playerID;

@end
