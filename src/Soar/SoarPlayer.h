//
//  Agent.h
//  iSoar
//
//  Created by Alex on 6/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
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

@class DiceGameState;
@class DiceGame;

#endif

@interface SoarPlayer : NSObject <Player> {
#ifdef __cplusplus
    sml::Kernel *kernel;
    sml::Agent *agent;
#endif
    
    BOOL remoteConnected;
    BOOL cleanup;
    NSString *name;
    DiceGame *game;
    
    // stuff for interface Player
    PlayerState *playerState;
    int playerID;
    NSLock *turnLock;
}

- (id)initWithName:(NSString *)name game:(DiceGame*)game connentToRemoteDebugger:(BOOL)connect lock:(NSLock *)lock;
- (void)dealloc;
- (NSString*)name;
- (void)drop;
- (void)newRound:(NSArray *)arrayOfDice;
- (void)showPublicInformation:(DiceGameState *)gameState;
- (void) handleAgentCommandsWithRefresh:(BOOL *)needsRefresh sleep:(BOOL *)sleep;

@property (readwrite, retain) NSString* name;
@property (readwrite, retain) PlayerState *playerState;
@property (readwrite, assign) int playerID;
@property (readwrite, retain) DiceGame *game;
@property (readwrite, retain) NSLock *turnLock;

@end
