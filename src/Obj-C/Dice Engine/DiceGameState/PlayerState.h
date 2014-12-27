//
//  PlayerState.h
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Player.h"

@class DiceGameState;
@class Bid;
@class Die;

@interface PlayerState : NSObject {
@private
    BOOL specialRules;
}

@property (readwrite, assign) BOOL hasDoneSpecialRules;

@property (readwrite, assign) int playerID;
@property (readwrite, strong) NSString *playerName;
@property (readwrite, strong) NSLock *lock;

@property (nonatomic, assign) BOOL playerHasPassed;
@property (nonatomic, assign) BOOL playerHasExacted;
@property (nonatomic, assign) int numberOfDice;

@property (nonatomic, assign) BOOL hasLost;
@property (nonatomic, readonly) BOOL playerHasPushedAllDice;

@property (nonatomic, readwrite) int maxNumberOfDice;
@property (readwrite, atomic, weak) DiceGameState *gameState;
@property (readwrite, strong) NSMutableArray *arrayOfDice;

- (id)initWithName:(NSString*)playerName withID:(int)playerID withNumberOfDice:(int)dice withDiceGameState:(DiceGameState *)gameState;

-(id)initWithCoder:(NSCoder*)decoder withCount:(int)count withGameState:(DiceGameState*)state;
-(void)encodeWithCoder:(NSCoder*)encoder withCount:(int)count;

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

- (id<Player>)playerPtr;

- (NSDictionary*)dictionaryValue;

@end
