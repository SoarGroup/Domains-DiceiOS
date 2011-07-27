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

//#import "Server.h"
#import "NetworkPlayer.h"

#import "Peer.h"

#import "iPadHelp.h"

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

@interface Lair_s_DiceAppDelegate_iPad : Lair_s_DiceAppDelegate <AppDelegateProtocol, ServerProtocol> {
    DiceEngine *diceEngine;
    NSMutableArray *players;
    NSThread *mainLoop;
    
    Peer *peer;
}

- (id)init;

- (void)logToConsole:(NSString *)stringToOutputToConsole;

- (void)updateActionWithPush:(NSArray *)diceNumbersPushed withPlayer:(id <Player>)player withPlayerID:(int)playerID;
- (void)updateActionWithBid:(Bid *) bid withPlayer:(id <Player>)player;
- (void)updateActionWithExact:(id <Player>)player andWasTheExactRight:(BOOL *)wasTheExactRight withPlayerID:(int)playerID;
- (void)updateActionWithPass:(id <Player>)player;
- (void)updateActionWithChallenge:(id <Player>)firstPlayer against:(id <Player>)secondPlayer ofType:(Type)type withDidTheChallengerWin:(BOOL *)didTheChallengerWin withPlayerID:(int)playerID;

- (void)someoneWonTheGame:(NSString *)playerName;

- (void)startTheGameWithNumberOfAgents:(int)agents players:(int)players;

- (void)goToMainMenu;

- (void)goToHelp;

- (void)sendData:(NSString *)data toPlayer:(NSString *)player;

- (void)setPlayerNames;

- (void)showAll:(DiceGameState *)gameState;

@end
