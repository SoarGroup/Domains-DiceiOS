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

#import "Random.h"

#define COMPATIBILITY_BUILD 209

@class ApplicationDelegate;

@interface DiceGame : NSObject <NSCoding>
{
    GameTime time;
	int nextID;
	
	BOOL transfered;
@public
	BOOL shouldNotifyOfNewRound;

	int compatibility_build;
}

- (id)initWithAppDelegate:(ApplicationDelegate*)anAppDelegate withSeed:(int)setSeed;
- (id)initWithAppDelegate:(ApplicationDelegate*)anAppDelegate;

// Encoding
-(id)initWithCoder:(NSCoder*)decoder;
-(void)encodeWithCoder:(NSCoder*)encoder;

// Adding and removing players.
-(void)addPlayer:(id <Player>)player;
-(void)shufflePlayers;

-(int)getNextID;

// Starting the game
-(void)startGame;

// Running the game
-(void)publishState;
-(void)handleAction:(DiceAction*)action;
-(void)handleAction:(DiceAction*)action notify:(BOOL)notify;
-(void)updateGame:(DiceGame*)remote;

- (void)end;

- (BOOL)isMultiplayer;
- (BOOL)hasHardestAI;

// Getting information about the game
-(NSInteger)getNumberOfPlayers;

-(id <Player>)getPlayerAtIndex:(int)index;
-(DiceLocalPlayer*)localPlayer;

-(void) notifyCurrentPlayer;

-(NSString*)gameNameString;
-(NSString*)AINameString;

-(NSString*)lastTurnInfo;

-(void)logGameToFile;

@property(readwrite, weak) ApplicationDelegate *appDelegate;
@property(readwrite, strong) DiceGameState *gameState;
@property(readwrite, strong) NSArray *players;
@property(readwrite, weak) PlayGameView* gameView;
@property(readwrite, assign) BOOL started;
@property(readwrite, assign) BOOL deferNotification;
@property(readwrite, assign) BOOL newRound;

@property(readwrite, strong) NSLock* gameLock;

@property(readwrite, strong) Random* randomGenerator;

@property(readwrite, strong) NSMutableArray* all_actions;

@end
