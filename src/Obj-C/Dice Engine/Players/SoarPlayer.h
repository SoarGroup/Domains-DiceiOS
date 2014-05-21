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

#import "Player.h"
#import "GameKitGameHandler.h"

@class DiceGameState;
@class DiceGame;

#endif

@interface SoarPlayer : NSObject <Player> {
#ifdef __cplusplus
	sml::Agent *agent;
	sml::Kernel *kernel;
#endif
    
    BOOL remoteConnected;
    BOOL cleanup;

	int outputCallBackID;
}

- (id)initWithGame:(DiceGame*)game connentToRemoteDebugger:(BOOL)connect lock:(NSLock *)lock withGameKitGameHandler:(GameKitGameHandler*)gkgHandler;
- (void)dealloc;
- (NSString*)name;
- (void)drop;
- (void)newRound:(NSArray *)arrayOfDice;
- (void)showPublicInformation:(DiceGameState *)gameState;
- (void) handleAgentCommandsWithRefresh:(BOOL *)needsRefresh sleep:(BOOL *)sleep;

+ (NSString*) makePlayerName;

@property (nonatomic, retain) GKTurnBasedParticipant* participant;
@property (nonatomic, assign) GameKitGameHandler* handler;
@property (readwrite, retain) NSString* name;
@property (readwrite, retain) PlayerState *playerState;
@property (readwrite, assign) int playerID;
@property (readwrite, assign) DiceGame *game;
@property (readwrite, retain) NSLock *turnLock;

@end
