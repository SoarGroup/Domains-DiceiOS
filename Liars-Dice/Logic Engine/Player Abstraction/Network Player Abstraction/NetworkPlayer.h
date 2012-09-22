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

@class Server;

#ifndef USER_STRUCT
#define USER_STRUCT 1
//User struct containing their name and unique id
typedef struct {
	NSString *name;
	int uniqueID;
} User;
#endif

@interface NetworkPlayer : NSObject <Player, NSStreamDelegate> {
    NSString *name;
    
    BOOL push;
    
    NSString *command;
    
    inputFromClient temporaryInput;
    
    int playerID;
    
    NSArray *dicePushing;
    
    Server *delegate;
    
    BOOL hasInput;
    
    BOOL doneShowAll;
	
	int uniqueID;
}

@property (nonatomic, assign) Server *delegate;

@property (nonatomic, assign) BOOL doneShowAll;

@property (nonatomic, readonly) int uniqueID;

- (id)initWithUser:(User)user playerID:(int)playerID;

- (void)clientData:(NSString *)data;

- (void)dealloc;

- (NSString*)name;

- (turnInformationSentFromTheClient)isMyTurn:(turnInformationToSendToClient)turnInfo;

- (void)drop;

- (void)cleanup;

- (void)newRound:(NSArray *)arrayOfDice;

- (void)showPublicInformation:(DiceGameState *)gameState;

@end
