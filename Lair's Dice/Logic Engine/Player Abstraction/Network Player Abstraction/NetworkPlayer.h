//
//  NetworkPlayer.h
//  iSoar
//
//  Created by Alex on 6/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DiceEngine.h"
#import "NetworkParser.h"

@class Lair_s_DiceAppDelegate_iPad;

@interface NetworkPlayer : NSObject <Player, NSStreamDelegate> {
    NSString *name;
    
    BOOL push;
    
    NSString *command;
    
    inputFromClient temporaryInput;
    
    int playerID;
    
    NSArray *dicePushing;
    
    Lair_s_DiceAppDelegate_iPad *delegate;
    
    BOOL hasInput;
    
    BOOL doneShowAll;
}

@property (nonatomic, assign) Lair_s_DiceAppDelegate_iPad *delegate;

@property (nonatomic, assign) BOOL doneShowAll;

- (id)initWithName:(NSString *)name playerID:(int)playerID;

- (void)clientData:(NSString *)data;

- (void)dealloc;

- (NSString*)name;

- (turnInformationSentFromTheClient)isMyTurn:(turnInformationToSendToClient)turnInfo;

- (void)drop;

- (void)cleanup;

- (void)newRound:(NSArray *)arrayOfDice;

- (void)showPublicInformation:(DiceGameState *)gameState;

@end
