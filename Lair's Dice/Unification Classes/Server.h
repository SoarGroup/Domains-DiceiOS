//
//  Server.h
//  Lair's Dice
//
//  Created by Alex Turner on 8/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#ifndef SERVER_H
#define SERVER_H

#import <Foundation/Foundation.h>

#import "DiceEngine.h"

#import "NetworkPlayer.h"

#import "Peer.h"

@interface Arguments : NSObject {
@private
    int dieNumber;
    int playerNumber;
    int die;
    
    BOOL wasChallenge;
    
    BOOL shouldLoseDiceExact;
    BOOL wasExact;
}

- (int)dieNumber;
- (int)playerNumber;
- (int)die;

- (void)setDieNumber:(int)number;
- (void)setPlayerNumber:(int)number;
- (void)setDie:(int)number;

- (BOOL)wasChallenge;
- (void)setWasChallenge:(BOOL)won1;

- (BOOL)wasExact;
- (void)setWasExact:(BOOL)won1;

- (BOOL)shouldLoseDiceExact;
- (void)setShouldLoseDiceExact:(BOOL)shouldLose;

@end

@interface UIButton (ButtonTitleUtils)

- (void)setTitle:(NSString *)title;

@end

@implementation UIButton (ButtonTitleUtils)

- (void)setTitle:(NSString *)title
{
    [self setTitle:title forState:UIControlStateNormal];
    [self setTitle:title forState:UIControlStateHighlighted];
    [self setTitle:title forState:UIControlStateSelected];
    [self setTitle:title forState:UIControlStateDisabled];
}

@end

@interface NSArray (Reverse)

- (NSArray *)reversedArray;

@end

@interface NSMutableArray (Reverse)

- (void)reverse;

@end

@implementation NSArray (Reverse)

- (NSArray *)reversedArray {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
    NSEnumerator *enumerator = [self reverseObjectEnumerator];
    for (id element in enumerator) {
        [array addObject:element];
    }
    return array;
}

@end

@implementation NSMutableArray (Reverse)

- (void)reverse {
    NSUInteger i = 0;
    NSUInteger j = [self count] - 1;
    while (i < j) {
        [self exchangeObjectAtIndex:i
                  withObjectAtIndex:j];
        
        i++;
        j--;
    }
}

@end

@class iPadServerViewController;
@class MainMenu;
@class iPadHelp;

@protocol ServerObjectProtocol <NSObject>

- (iPadServerViewController *)goToMainServerGameWithPlayers:(int)players;
- (MainMenu *)goToMainMenu;
- (iPadHelp *)goToHelp;

- (void)serverIsUp;

@end

@interface Server : NSObject <ServerProtocol> {
    DiceEngine *diceEngine;
    NSMutableArray *players;
    NSThread *mainLoop;
    
    Peer *peer;
    
    BOOL wasChallenge;
    BOOL wasExact;
    BOOL shouldLoseDieExact;
    int playerID;
	
	BOOL wifi;
	BOOL bluetooth;
	
	id <ServerObjectProtocol, NSObject> handler;
	
	id mainViewController;
}

@property (nonatomic, assign) id mainViewController;

- (id)initWithDelegate:(id)handler;

- (void)logToConsole:(NSString *)stringToOutputToConsole;

- (void)updateActionWithPush:(NSArray *)diceNumbersPushed withPlayer:(id <Player>)player withPlayerID:(int)playerID;
- (void)updateActionWithBid:(Bid *) bid withPlayer:(id <Player>)player;
- (void)updateActionWithExact:(id <Player>)player andWasTheExactRight:(BOOL *)wasTheExactRight withPlayerID:(int)playerID;
- (void)updateActionWithPass:(id <Player>)player;
- (void)updateActionWithChallenge:(id <Player>)firstPlayer against:(id <Player>)secondPlayer ofType:(Type)type withDidTheChallengerWin:(BOOL *)didTheChallengerWin withPlayerID:(int)playerID;

- (void)someoneWonTheGame:(NSString *)playerName;

- (void)startTheGameWithNumberOfAgents:(int)agents players:(int)players;

- (void)sendData:(NSString *)data toPlayer:(User)player;

- (void)setPlayerNames;

- (void)showAll:(DiceGameState *)gameState;

- (void)tappedArea:(int)area;

- (void)newTurn:(int)player;

- (void)synchronize;

//Sets the wifi logo & bluetooth logo to the enabled and disabled versions based on the BOOL
- (void)showWifi:(BOOL)enabled;
- (void)showBluetooth:(BOOL)enabled;

- (void)goToMainMenu;
- (void)startTheGameWithNumberOfAgents:(int)agents players:(int)networkPlayers;
- (void)goToHelp;

- (void)handleNewConnection:(id)connection;

@end

#endif
