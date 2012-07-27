//
//  DiceGame.h
//  Lair's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DiceServer.h"
#import "DiceGameState.h"
#import "DiceLocalPlayer.h"
#import "DiceClient.h"
#import "DiceRemotePlayer.h"
#import "DiceLocalPlayer.h"
#import "DiceSoarPlayer.h"
#import "DiceAction.h"
#import "Player.h"
#import "PlayGame.h"
#import "GameRecord.h"

@class DiceApplicationDelegate;

typedef enum DiceGameType {
    SERVER_ONLY,
    LOCAL_PRIVATE,
    LOCAL_PUBLIC,
    CLIENT,
} DiceGameType;

@interface DiceGame : NSObject {
    
    // Properties
    DiceApplicationDelegate *appDelegate;
    id <PlayGame> gameView;
    DiceGameType type;
    
    DiceServer *server;
    DiceGameState *gameState;
    
    // Array of id <Player>
    NSArray *players;
    
    DiceClient *client;
    
    // End of properties
    
    BOOL started;
    BOOL deferNotification;
    
    GameTime time;
}

-(DiceGame*)initWithType:(DiceGameType)type appDelegate:(DiceApplicationDelegate*)appDelegate username:(NSString*)usernameOrNil;

// Adding and removing players.
-(void)addPlayer:(id <Player>)player;
-(int)getNextID;

// Starting the game
-(void)startGame;

// Running the game
-(void)publishState;
-(void)handleAction:(DiceAction*)action;

- (void) end;

// Getting information about the game
-(int)getNumberOfPlayers;

-(id <Player>)getPlayerAtIndex:(int)index;
-(void) notifyCurrentPlayer;

@property(readwrite, retain) DiceApplicationDelegate *appDelegate;
@property(readwrite, assign) DiceGameType type;
@property(readwrite, retain) DiceServer *server;
@property(readwrite, retain) DiceGameState *gameState;
@property(readwrite, retain) NSArray *players;
@property(readwrite, retain) DiceClient *client;
@property(readwrite, retain) id <PlayGame> gameView;
@property(readwrite, assign) BOOL started;
@property(readwrite, assign) BOOL deferNotification;

@end
