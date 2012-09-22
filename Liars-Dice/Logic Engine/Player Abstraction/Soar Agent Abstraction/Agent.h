//
//  Agent.h
//  iSoar
//
//  Created by Alex on 6/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus

#include "portability.h"
#include "sml_Connection.h"
#include "sml_Client.h"
#include "sml_Events.h"
#include "sml_ClientAgent.h"
#include "sml_ClientIdentifier.h"
#include "ElementXML.h"

//#import "Player.h"

@class DiceGameState;

#endif

@interface Agent : NSObject {
#ifdef __cplusplus
    sml::Kernel *kernel;
    sml::Agent *agent;
#endif
    
    BOOL remoteConnected;
    
    BOOL cleanup;
    
    NSString *name;
}

- (id)init:(BOOL)connect;

- (void)dealloc;

- (NSString*)name;

// - (turnInformationSentFromTheClient)isMyTurn:(turnInformationToSendToClient)turnInfo;

- (void)drop;

- (void)cleanup;

- (void)newRound:(NSArray *)arrayOfDice;

- (void)showPublicInformation:(DiceGameState *)gameState;

@end
