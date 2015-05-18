//
//  Player.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/5/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@class PlayerState;
@class GameKitGameHandler;

@protocol Player <NSObject>
- (NSString*) getDisplayName;
- (NSString*) getGameCenterName;

- (void) updateState:(PlayerState*)state;
- (int) getID;
- (void) setID:(int)anID;

- (void) itsYourTurn;

- (void) end;

- (void)notifyHasLost;
- (void)notifyHasWon;

- (void)setHandler:(GameKitGameHandler*)handler;
- (void)removeHandler;
- (void)setParticipant:(GKTurnBasedParticipant*)participant;

- (NSDictionary*)dictionaryValue;

@end
