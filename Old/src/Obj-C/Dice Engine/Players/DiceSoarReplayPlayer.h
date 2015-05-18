//
//  DiceReplayPlayer.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Player.h"
#import "PlayGame.h"
#import "SoarPlayer.h"

@class PlayerState;

@interface DiceSoarReplayPlayer : SoarPlayer

@property (atomic, strong) NSMutableArray *gameViews;

@end
