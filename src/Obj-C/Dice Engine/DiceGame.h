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

@public
	BOOL shouldNotifyOfNewRound;
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
-(NSString*)AINameString;

-(NSString*)lastTurnInfo;

@property(readwrite, weak) ApplicationDelegate *appDelegate;
@property(readwrite, strong) DiceGameState *gameState;
@property(readwrite, strong) NSArray *players;
@property(readwrite, weak) PlayGameView* gameView;
@property(readwrite, assign) BOOL started;
@property(readwrite, assign) BOOL deferNotification;

@end
