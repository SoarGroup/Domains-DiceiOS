//
//  PlayerState.h
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DiceGameState;
@class Bid;
@class Die;

@interface PlayerState : NSObject {
@private
    int playerID;
    int numberOfDice;
    BOOL hasLost;
    NSMutableArray *arrayOfDice;
    
    NSString *playerName;
    DiceGameState *gameState;
    int maxNumberOfDice;

    BOOL playerHasPassed;
    BOOL playerHasExacted;
    BOOL playerHasPushedAllDice;
    
    BOOL specialRules;
    
    NSLock *lock;
}

@property (readwrite, assign) BOOL hasDoneSpecialRules;

@property (readwrite, assign) int playerID;
@property (readwrite, retain) NSString *playerName;
@property (readwrite, retain) NSLock *lock;

@property (nonatomic) BOOL playerHasPassed;
@property (nonatomic) BOOL playerHasExacted;
@property (nonatomic) int numberOfDice;

@property (nonatomic) BOOL hasLost;
@property (nonatomic, readonly) BOOL playerHasPushedAllDice;

@property (nonatomic, readwrite) int maxNumberOfDice;
@property (readwrite, retain) DiceGameState *gameState;
@property (readwrite, retain) NSArray *arrayOfDice;

- (id)initWithName:(NSString*)playerName withID:(int)playerID withNumberOfDice:(int)dice withDiceGameState:(DiceGameState *)gameState;
- (void)dealloc;

- (void)isNewRound;
- (void)pushDice:(NSArray *)diceToPush;

- (NSArray *)unPushedDice;
- (NSArray *)pushedDice;
- (NSArray *)markedToPushDice;

- (BOOL)canBid;
- (BOOL)hasWon;

- (BOOL)canChallengeBid;
- (Bid *)getChallengeableBid;

- (BOOL)canChallengeLastPass;
// Returns the playerID of the player who passed, or -1 if no such player exists.
- (int)getChallengeableLastPass;

- (BOOL)canChallengeSecondLastPass;
// Returns the playerID of the player who passed, or -1 if no such player exists.
- (int) getChallengeableSecondLastPass;

- (BOOL)canChallengeAnything;

- (BOOL) isMyTurn;
- (BOOL)canExact;
- (BOOL)canPass;
- (BOOL)canPush;
- (BOOL)canAccept;

- (BOOL)playerHasAllSameDice;

- (BOOL)isInSpecialRules;

- (NSString *)asString;
- (NSString *)stateString:(BOOL)showHidden;
- (NSString *)headerString:(BOOL)singleLine;
- (NSString *)perceptionString:(BOOL)showPrivate;
- (Die *) getDie:(int)index;

- (NSInteger) getNumberOfPlayers;

@end
