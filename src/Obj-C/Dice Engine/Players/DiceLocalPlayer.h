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

@property (nonatomic, retain) GKTurnBasedParticipant* participant;
@property (nonatomic, retain) GameKitGameHandler* handler;
@property (readwrite, retain) NSString *name;
@property (readwrite, retain) PlayerState *playerState;
@property (readwrite, retain) PlayGameView *gameView;

- (id)initWithName:(NSString*)aName withHandler:(GameKitGameHandler*)handler withParticipant:(GKTurnBasedParticipant*)participant;


@end
