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

@property (nonatomic, weak) DiceLocalPlayer* localPlayer;
@property (nonatomic, strong) NSArray* remotePlayers;
@property (nonatomic, readonly, strong) GKTurnBasedMatch* match;
@property (nonatomic, strong) DiceGame* localGame;
@property (nonatomic, readonly, strong) NSArray* participants;

- (id)initWithDiceGame:(DiceGame*)game withLocalPlayer:(DiceLocalPlayer*)localPlayer withRemotePlayers:(NSArray*)remotePlayers withMatch:(GKTurnBasedMatch*)match;

- (void) saveMatchData;
- (void) updateMatchData;
- (void) matchHasEnded;

- (void) advanceToRemotePlayer:(DiceRemotePlayer*)player;

- (void) playerQuitMatch:(id<Player>)player withRemoval:(BOOL)remove;
- (BOOL) endMatchForAllParticipants;

- (GKTurnBasedMatch*)getMatch;

+ (NSData*)archiveAndCompressObject:(NSObject*)object;
+ (NSObject*)uncompressAndUnarchiveObject:(NSData*)data;

+ (NSData *)bzip2:(NSData*)data;

@end
