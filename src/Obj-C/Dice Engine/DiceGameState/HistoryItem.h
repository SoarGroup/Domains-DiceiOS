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
    NSInteger playerLosingADie;
    NSInteger playerWinningADie;

	int playerIDDecode;
}

@property (readwrite, nonatomic, weak) PlayerState *player;
@property (readwrite, assign) ActionType actionType;
@property (readwrite, assign) HistoryItemType historyType;
@property (readwrite, assign) int value;
@property (readwrite, assign) int result;
@property (readwrite, weak) DiceGameState *diceGameState;
@property (readwrite, strong) Bid *bid;
@property (readwrite, strong) NSString *state;

- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer whereTypeIs:(ActionType)newType withValue:(int)value andResult:(int)result;
- (id) initWithMetaInformation:(NSString *)meta;
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer whereTypeIs:(ActionType)newType withValue:(int)newValue;
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer whereTypeIs:(ActionType)newType;
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer withBid:(Bid *)newBid;
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer withBid:(Bid *)newBid andWithResult:(int)newResult;

-(id)initWithCoder:(NSCoder*)decoder withCount:(int)count withGameState:(DiceGameState*)state;
-(id)initWithCoder:(NSCoder*)decoder withCount:(int)count withGameState:(DiceGameState*)state withPrefix:(NSString*)prefix;
-(void)encodeWithCoder:(NSCoder*)encoder withCount:(int)count;
-(void)encodeWithCoder:(NSCoder*)encoder withCount:(int)count withPrefix:(NSString*)prefix;

- (void)setLosingPlayer:(NSInteger)playerID;
- (void)setWinningPlayer:(NSInteger)playerID;

- (void)canDecodePlayer;

- (NSString *)asString;
- (NSString *)asDetailedString;

@end
