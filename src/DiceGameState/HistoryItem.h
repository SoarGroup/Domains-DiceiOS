//
//  HistoryItem.h
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
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
    
    int playerLosingADie;
    int playerWinningADie;
    
    Bid *bid;
}

@property (readwrite, retain) PlayerState *player;
@property (readwrite, assign) ActionType actionType;
@property (readwrite, assign) HistoryItemType historyType;
@property (readwrite, assign) int value;
@property (readwrite, assign) int result;
@property (readwrite, retain) DiceGameState *diceGameState;
@property (readwrite, retain) Bid *bid;
@property (readwrite, retain) NSString *state;

- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer whereTypeIs:(ActionType)newType withValue:(int)value andResult:(int)result;
- (id) initWithMetaInformation:(NSString *)meta;
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer whereTypeIs:(ActionType)newType withValue:(int)newValue;
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer whereTypeIs:(ActionType)newType;
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer withBid:(Bid *)newBid;
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer withBid:(Bid *)newBid andWithResult:(int)newResult;

- (void)dealloc;

- (void)setLosingPlayer:(int)playerID;
- (void)setWinningPlayer:(int)playerID;

- (NSString *)asString;
- (NSString *)asDetailedString;

@end
