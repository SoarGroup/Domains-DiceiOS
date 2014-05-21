//
//  GameKitGameHandler.h
//  UM Liars Dice
//
//  Created by Alex Turner on 5/8/14.
//
//

#import <Foundation/Foundation.h>

#import "DiceLocalPlayer.h"
#import "DiceRemotePlayer.h"
#import "DiceGame.h"

@class MultiplayerMatchData;

@interface GameKitGameHandler : NSObject
{
	BOOL matchHasEnded;
}

@property (nonatomic, assign) DiceLocalPlayer* localPlayer;
@property (nonatomic, retain) NSArray* remotePlayers;
@property (nonatomic, readonly, retain) GKTurnBasedMatch* match;
@property (nonatomic, retain) DiceGame* localGame;
@property (nonatomic, readonly, retain) NSArray* participants;

- (id)initWithDiceGame:(DiceGame*)game withLocalPlayer:(DiceLocalPlayer*)localPlayer withRemotePlayers:(NSArray*)remotePlayers withMatch:(GKTurnBasedMatch*)match;

- (void) saveMatchData;
- (void) updateMatchData;
- (void) matchHasEnded;

- (void) advanceToRemotePlayer:(DiceRemotePlayer*)player;

- (void) playerQuitMatch:(id<Player>)player withRemoval:(BOOL)remove;
- (BOOL) endMatchForAllParticipants;

- (GKTurnBasedMatch*)getMatch;

@end
