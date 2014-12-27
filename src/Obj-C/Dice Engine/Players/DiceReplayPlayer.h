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

@class PlayerState;

@interface DiceReplayPlayer : NSObject <Player> {
    int playerID;
}

@property (atomic, strong) NSString *name;
@property (atomic, weak) PlayerState *playerState;
@property (atomic, strong) NSMutableArray *gameViews;
@property (atomic, strong) NSArray* actions;
@property (atomic, strong) NSMutableArray* myActions;

- (id)initWithName:(NSString *)name withPlayerID:(int)playerID withActions:(NSArray*)actions;

- (NSString*) getDisplayName;
- (NSString*) getGameCenterName;

- (void) end:(BOOL)showAlert;

@end
