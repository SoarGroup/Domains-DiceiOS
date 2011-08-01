//
//  Lair_s_DiceAppDelegate_iPhone.h
//  Lair's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Lair_s_DiceAppDelegate.h"

#import "Peer.h"

#import "NetworkParser.h"

@class iPhoneViewController;
@class iPhoneMainMenu;

@interface Lair_s_DiceAppDelegate_iPhone : Lair_s_DiceAppDelegate <ClientProtocol> {    
    iPhoneViewController *viewController;
    iPhoneMainMenu *mainMenuViewController;
    
    BOOL isMyTurn;
    
    outputToSendToClient temporaryInput;
        
    Peer *peer;
    
    NSString *serverID;
    
    BOOL hasData;
    
    BOOL connectedToServer;
}

- (void)endTurn;

- (void)goToMainGame:(NSString *)name;
- (void)goToMainMenu;
- (void)goToHelp;

@end
