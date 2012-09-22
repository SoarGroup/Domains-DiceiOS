//
//  Lair_s_DiceAppDelegate_iPad.h
//  Lair's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/NSPort.h>

#import "Lair_s_DiceAppDelegate.h"
#import "DiceEngine.h"

#import "Server.h"
#import "NetworkPlayer.h"

#import "Peer.h"

#import "iPadHelp.h"

typedef struct {
    int integer;
    int secondInteger;
} intStruct;

@interface Lair_s_DiceAppDelegate_iPad : Lair_s_DiceAppDelegate <ServerObjectProtocol> {
	
    Server *server;
}

- (id)init;

- (iPadServerViewController *)goToMainServerGameWithPlayers:(int)players;
- (MainMenu *)goToMainMenu;
- (iPadHelp *)goToHelp;

@end
