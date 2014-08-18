//
//  Agent.h
//  Liar's Dice
//
//  Created by Alex on 6/21/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus

#import "portability.h"
#import "sml_Connection.h"
#import "sml_Client.h"
#import "sml_Events.h"
#import "sml_ClientAgent.h"
#import "sml_ClientIdentifier.h"
#import "ElementXML.h"
#import "DiceAction.h"
#import <unordered_map>

#import "Player.h"
#import "GameKitGameHandler.h"

#import <vector>

@class DiceGameState;
@class DiceGame;

#endif

@interface SoarPlayer : NSObject <Player> {
    BOOL cleanup;

	int outputCallBackID;

	BOOL didNotify;
	BOOL exitThread;
}

+ (void)initialize;
#ifdef __cplusplus
+ (std::unordered_map<unsigned long, sml::Agent*>&) agents;
+ (sml::Kernel*) kernel;
#endif

- (void) cancelThread;

- (id)initWithGame:(DiceGame*)game connentToRemoteDebugger:(BOOL)connect lock:(NSLock *)lock withGameKitGameHandler:(GameKitGameHandler*)gkgHandler difficulty:(int)diff;

- (id)initWithGame:(DiceGame*)game connentToRemoteDebugger:(BOOL)connect lock:(NSLock *)lock withGameKitGameHandler:(GameKitGameHandler*)gkgHandler difficulty:(int)diff name:(NSString*)name;

- (NSString*) getDisplayName;
- (NSString*) getGameCenterName;

- (void)drop;
- (void)newRound:(NSArray *)arrayOfDice;
- (void)showPublicInformation:(DiceGameState *)gameState;
- (void) handleAgentCommandsWithRefresh:(BOOL *)needsRefresh sleep:(BOOL *)sleep;

+ (NSString*) makePlayerName;

@property (nonatomic, strong) GKTurnBasedParticipant* participant;
@property (atomic, weak) GameKitGameHandler* handler;
@property (readwrite, strong) NSString* name;
@property (readwrite, atomic, weak) PlayerState *playerState;
@property (readwrite, assign) int playerID;
@property (readwrite, atomic, weak) DiceGame *game;
@property (readwrite, strong) NSLock *turnLock;

@property (readonly, assign) int difficulty;


@end
