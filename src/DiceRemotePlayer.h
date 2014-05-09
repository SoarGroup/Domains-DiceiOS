//
//  DiceRemotePlayer.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

#import "Player.h"

@class GameKitGameHandler;

@interface DiceRemotePlayer : NSObject <Player>

@property (nonatomic, retain) GKTurnBasedParticipant* participant;
@property (nonatomic, retain) GameKitGameHandler* handler;
@property (readwrite, assign) int playerID;

- (id) initWithGameKitParticipant:(GKTurnBasedParticipant*)participant withGameKitGameHandler:(GameKitGameHandler*)handler;

- (NSString*) getName;
- (void) updateState:(PlayerState*)state;
- (int) getID;
- (void) setID:(int)anID;

- (void) itsYourTurn;

- (void) end;
@end
