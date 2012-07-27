//
//  Lair_s_DiceAppDelegate_iPhone.h
//  Lair's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Lair_s_DiceAppDelegate.h"
#import "MainMenu.h"

@class iPadServerViewController;
@class iPadHelp;

#import "Peer.h"

#import "NetworkParser.h"

@class iPhoneViewController;
@class iPhoneMainMenu;

#import "Server.h"

@interface Lair_s_DiceAppDelegate_iPhone : Lair_s_DiceAppDelegate <ClientProtocol, ServerObjectProtocol> {    
    UIViewController *viewController;
    
    BOOL isMyTurn;
    
    outputToSendToClient temporaryInput;
        
    Peer *peer;
	
    NSString *serverID;
    
    BOOL hasData;
    
    BOOL connectedToServer;
	
	BOOL hasSentName;
	
	int uniqueID;
	
	Server *server;
}

@property (nonatomic, assign) int uniqueID;

- (void)endTurn;

- (void)goToMainGame:(NSString *)name;
- (void)goToiPhoneMainMenu;
- (void)goToiPhoneHelp;

- (void)goToServer;

- (iPadServerViewController *)goToMainServerGameWithPlayers:(int)players;

- (MainMenu *)goToMainMenu;
- (iPadHelp *)goToHelp;

@end
