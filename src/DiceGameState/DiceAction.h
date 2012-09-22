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

@interface DiceAction : NSObject {
    ActionType actionType;
    int playerID;
    int count;
    int face;
    NSArray *push;
    int targetID;
}

@property (readwrite, assign) ActionType actionType;
@property (readwrite, assign) int playerID;
@property (readwrite, assign) int count;
@property (readwrite, assign) int face;
@property (readwrite, retain) NSArray *push;
@property (readwrite, assign) int targetID;

+ (DiceAction *) bidAction:(int)playerID count:(int)count face:(int)face push:(NSArray *)push;
+ (DiceAction *) challengeAction:(int)playerID target:(int)targetId;
+ (DiceAction *) exactAction:(int)playerID;
+ (DiceAction *) passAction:(int)playerID push:(NSArray*)push;
+ (DiceAction *) acceptAction:(int)playerID;
+ (DiceAction *) pushAction:(int)playerID push:(NSArray *)push;

@end
