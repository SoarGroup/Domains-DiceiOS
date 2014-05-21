//
//  HistoryItem.h
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DiceGameState.h"
#import "PlayerState.h"

typedef enum HistoryItemType {
    actionHistoryItem,
    metaHistoryItem
} HistoryItemType;

@interface HistoryItem : NSObject {
@private
    DiceGameState *diceGameState;
    PlayerState *player;
    ActionType actionType;
    HistoryItemType historyType;
    int value;
    int result;
    NSString *state;
    
    NSInteger playerLosingADie;
    NSInteger playerWinningADie;
    
    Bid *bid;
}

@property (readwrite, assign) PlayerState *player;
@property (readwrite, assign) ActionType actionType;
@property (readwrite, assign) HistoryItemType historyType;
@property (readwrite, assign) int value;
@property (readwrite, assign) int result;
@property (readwrite, assign) DiceGameState *diceGameState;
@property (readwrite, retain) Bid *bid;
@property (readwrite, retain) NSString *state;

- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer whereTypeIs:(ActionType)newType withValue:(int)value andResult:(int)result;
- (id) initWithMetaInformation:(NSString *)meta;
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer whereTypeIs:(ActionType)newType withValue:(int)newValue;
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer whereTypeIs:(ActionType)newType;
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer withBid:(Bid *)newBid;
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer withBid:(Bid *)newBid andWithResult:(int)newResult;

-(id)initWithCoder:(NSCoder*)decoder withCount:(int)count withGameState:(DiceGameState*)state;
-(void)encodeWithCoder:(NSCoder*)encoder withCount:(int)count;

- (void)dealloc;

- (void)setLosingPlayer:(NSInteger)playerID;
- (void)setWinningPlayer:(NSInteger)playerID;

- (NSString *)asString;
- (NSString *)asDetailedString;

@end
