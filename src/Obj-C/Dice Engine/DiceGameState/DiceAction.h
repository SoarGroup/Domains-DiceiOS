//
//  DiceAction.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DiceGameState.h"
#import "DiceTypes.h"

@interface DiceAction : NSObject

@property (readwrite, assign) ActionType actionType;
@property (readwrite, assign) NSInteger playerID;
@property (readwrite, assign) int count;
@property (readwrite, assign) int face;
@property (readwrite, strong) NSArray *push;
@property (readwrite, assign) NSInteger targetID;

+ (DiceAction *) bidAction:(NSInteger)playerID count:(int)count face:(int)face push:(NSArray *)push;
+ (DiceAction *) challengeAction:(NSInteger)playerID target:(NSInteger)targetId;
+ (DiceAction *) exactAction:(NSInteger)playerID;
+ (DiceAction *) passAction:(NSInteger)playerID push:(NSArray*)push;
+ (DiceAction *) acceptAction:(NSInteger)playerID;
+ (DiceAction *) pushAction:(NSInteger)playerID push:(NSArray *)push;
+ (DiceAction *) lost:(NSInteger)playerID;

@end
