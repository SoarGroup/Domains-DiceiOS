//
//  DiceGame.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DiceGameState.h"
#import "DiceLocalPlayer.h"
#import "DiceRemotePlayer.h"
#import "DiceLocalPlayer.h"
#import "DiceAction.h"
#import "Player.h"
#import "PlayGame.h"
#import "GameRecord.h"
#import "GameKitListener.h"

@class ApplicationDelegate;

@interface DiceGame : NSObject <NSCoding>
{
    GameTime time;
	int nextID;
}

-(DiceGame*)initWithAppDelegate:(ApplicationDelegate*)appDelegate;

// Encoding
-(id)initWithCoder:(NSCoder*)decoder;
-(void)encodeWithCoder:(NSCoder*)encoder;

// Adding and removing players.
-(void)addPlayer:(id <Player>)player;
-(int)getNextID;

// Starting the game
-(void)startGame;

// Running the game
-(void)publishState;
-(void)handleAction:(DiceAction*)action;
-(void)updateGame:(DiceGame*)remote;

- (void)end;

// Getting information about the game
-(NSInteger)getNumberOfPlayers;

-(id <Player>)getPlayerAtIndex:(int)index;
-(void) notifyCurrentPlayer;

-(NSString*)gameNameString;
-(NSString*)lastTurnInfo;

@property(readwrite, retain) ApplicationDelegate *appDelegate;
@property(readwrite, retain) DiceGameState *gameState;
@property(readwrite, retain) NSArray *players;
@property(readwrite, retain) id <PlayGame> gameView;
@property(readwrite, assign) BOOL started;
@property(readwrite, assign) BOOL deferNotification;

@end
