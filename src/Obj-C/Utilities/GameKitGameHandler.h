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
	GKTurnBasedMatch* match;
	DiceGame* localGame;

	BOOL matchHasEnded;
}

@property (nonatomic, retain) DiceLocalPlayer* localPlayer;
@property (nonatomic, retain) NSArray* remotePlayers;

- (id)initWithDiceGame:(DiceGame*)game withLocalPlayer:(DiceLocalPlayer*)localPlayer withRemotePlayers:(NSArray*)remotePlayers;

- (void) saveMatchData;
- (void) updateMatchData;
- (void) matchHasEnded;

- (void) getMultiplayerMatchData:(MultiplayerMatchData**)data;
- (void) advanceToRemotePlayer:(DiceRemotePlayer*)player;

- (void) playerQuitMatch:(id<Player>)player withRemoval:(BOOL)remove;
- (BOOL) endMatchForAllParticipants;

- (DiceGame*)getDiceGame;
- (GKTurnBasedMatch*)getMatch;

@end
