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
{
	BOOL loadedNamed;
}

@property (nonatomic, strong) GKTurnBasedParticipant* participant;
@property (atomic, weak) GameKitGameHandler* handler;
@property (readwrite, assign) int playerID;
@property (atomic, strong) NSString* displayName;

- (id) initWithGameKitParticipant:(GKTurnBasedParticipant*)participant withGameKitGameHandler:(GameKitGameHandler*)handler;

- (NSString*) getDisplayName;
- (NSString*) getGameCenterName;

- (void) updateState:(PlayerState*)state;
- (int) getID;
- (void) setID:(int)anID;

- (void) itsYourTurn;

- (void) end;
@end
