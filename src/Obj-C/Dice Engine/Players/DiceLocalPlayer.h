//
//  DiceLocalPlayer.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GameKit/GameKit.h>

#import "Player.h"
#import "PlayGame.h"

@class GameKitGameHandler;
@class PlayerState;
@class PlayGameView;

@interface DiceLocalPlayer : NSObject <Player> {
    int playerID;
}

@property (atomic, strong) GKTurnBasedParticipant* participant;
@property (atomic, weak) GameKitGameHandler* handler;
@property (atomic, strong) NSString *name;
@property (atomic, weak) PlayerState *playerState;
@property (atomic, weak) PlayGameView *gameView;

- (id)initWithName:(NSString*)aName withHandler:(GameKitGameHandler*)handler withParticipant:(GKTurnBasedParticipant*)participant;

- (NSString*) getDisplayName;
- (NSString*) getGameCenterName;

@end
