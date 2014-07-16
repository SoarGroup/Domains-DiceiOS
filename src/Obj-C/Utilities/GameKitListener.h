//
//  GameKitListener.h
//  UM Liars Dice
//
//  Created by Alex Turner on 5/8/14.
//
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

#import "GameKitGameHandler.h"

@interface GameKitListener : NSObject <GKLocalPlayerListener, EngineClass>
{

}

@property (nonatomic, strong) NSMutableArray* handlers;

- (void) addGameKitGameHandler:(GameKitGameHandler*)handler;
- (void) removeGameKitGameHandler:(GameKitGameHandler*)handler;

- (GameKitGameHandler*)handlerForMatch:(GKTurnBasedMatch*)match;
- (GameKitGameHandler*)handlerForGame:(DiceGame*)game;

- (void) player:(GKPlayer *)player didAcceptInvite:(GKInvite *)invite;

- (void) player:(GKPlayer *)player matchEnded:(GKTurnBasedMatch *)match;

- (void) player:(GKPlayer *)player receivedTurnEventForMatch:(GKTurnBasedMatch *)match didBecomeActive:(BOOL)didBecomeActive;

@end
