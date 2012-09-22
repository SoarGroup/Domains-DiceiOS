//
//  DiceGame.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceGame.h"

#import "DiceApplicationDelegate.h"
#import "DiceAction.h"
#import "PlayerState.h"
#import "PlayGame.h"
#import "DiceDatabase.h"
#import "GameRecord.h"

@implementation DiceGame

@synthesize type, server, gameState, players, client, appDelegate, gameView, started, deferNotification;

- (id)initWithType:(DiceGameType)aType appDelegate:(DiceApplicationDelegate*)anAppDelegate username:(NSString*)usernameOrNil
{
    if (!(self = [super init])) return self;
    
    self.appDelegate = anAppDelegate;
    self.type = aType;
    self.gameState = nil;
    started = NO;
    time = [DiceDatabase getCurrentGameTime];
	nextID = 0;
    
    switch (aType) {
        case SERVER_ONLY:
            self.server = [[[DiceServer alloc] init] autorelease];
            //self.gameState = [[[DiceGameState alloc] init] autorelease];
            self.players = [[[NSArray alloc] init] autorelease];
            self.client = nil;
            break;
        case LOCAL_PRIVATE:
            self.server = nil;
            //self.gameState = [[[DiceGameState alloc] init] autorelease];
            self.players = [[[NSArray alloc] init] autorelease];
            [self addPlayer:[[[DiceLocalPlayer alloc] initWithName:usernameOrNil] autorelease]];
            self.client = nil;
            break;
        case LOCAL_PUBLIC:
            self.server = [[[DiceServer alloc] init] autorelease];
            //self.gameState = [[[DiceGameState alloc] init] autorelease];
            self.players = [[[NSArray alloc] init] autorelease];
            [self addPlayer:[[[DiceLocalPlayer alloc] initWithName:usernameOrNil] autorelease]];
            self.client = nil;   
            break;
        case CLIENT:
            self.server = nil;
            //self.gameState = nil;
            self.players = nil;
            self.client = [[[DiceClient alloc] init] autorelease];   
            break;
    }
    
    return self;
}

- (void) setGameView:(id <PlayGame>)aGameView
{
    gameView = aGameView;
    for (id <Player> player in self.players)
    {
        if ([player isKindOfClass:[DiceLocalPlayer class]])
        {
            ((DiceLocalPlayer*)player).gameView = self.gameView;
        }
    }
}

- (id <PlayGame>) gameView
{
    return gameView;
}

-(void)addPlayer:(id <Player>)player
{
    assert(!started);
    assert(players != nil);
    if ([player isKindOfClass:[DiceLocalPlayer class]])
    {
        ((DiceLocalPlayer*)player).gameView = self.gameView;
    }
    
    NSMutableArray *mut = [[[NSMutableArray alloc] initWithArray:self.players] autorelease];
    [mut addObject:player];
    self.players = [[[NSArray alloc] initWithArray:mut] autorelease];
    [player setID:[self getNextID]];
}

-(int)getNextID {
    return nextID++;
}

-(void)startGame
{
    assert(!self.started);
	
	NSMutableArray *mut = [[[NSMutableArray alloc] initWithArray:self.players] autorelease];
	
	//Shuffle the array
	for (int i = 0;i < 16;i++)
		[mut exchangeObjectAtIndex:(rand()%([mut count]-1)+1) withObjectAtIndex:(rand()%([mut count]-1)+1)];
	
	int shouldMovePlayer = rand()%100;
	
	if (shouldMovePlayer >= 49)
		[mut exchangeObjectAtIndex:0 withObjectAtIndex:([mut count]-1)];
	
	self.players = [[[NSArray alloc] initWithArray:mut] autorelease];
	
    self.started = YES;
    self.gameState = [[[DiceGameState alloc] initWithPlayers:self.players
                                                numberOfDice:5 game:self]
                      autorelease];
		
    [self publishState];
    [self notifyCurrentPlayer];
}

-(void)publishState
{
    for (id <Player> player in players)
    {
        [player updateState:[gameState getPlayerState:[player getID]]];
    }
}

-(void) notifyCurrentPlayer
{
    if ([self.gameState hasAPlayerWonTheGame]) {
            NSLog(@"Game over, no need to notify player");
        return;
    }
    NSLog(@"Notifying current player %@", [[gameState getCurrentPlayer] getName]);
    [[gameState getCurrentPlayer] itsYourTurn];
}

-(int)getNumberOfPlayers
{
    return [self.players count];
}

-(id <Player>)getPlayerAtIndex:(int)index
{
    return [self.players objectAtIndex:index];
}

-(void)handleAction:(DiceAction*)action
{
    NSLog(@"Handling action: %i", action.actionType);
    self.deferNotification = NO;
    switch (action.actionType)
    {
        case ACTION_BID:
        {
            NSString *playerName = [self.gameState getPlayerState:action.playerID].playerName;
            Bid *bid = [[[Bid alloc] initWithPlayerID:action.playerID name:playerName dice:action.count rank:action.face] autorelease];
            [gameState handleBid:action.playerID withBid:bid];
            [gameState handlePush:action.playerID withPush:action.push];
            break;
        }
        case ACTION_PASS:
        {
            [gameState handlePass:action.playerID];
            [gameState handlePush:action.playerID withPush:action.push];
            break;
        }
        case ACTION_EXACT:
        {
            BOOL wasRight;
            [gameState handleExact:action.playerID andWasTheExactRight:&wasRight];
            break;
        }
        case ACTION_CHALLENGE_BID:
        case ACTION_CHALLENGE_PASS:
        {
            BOOL wonChallenge;
            [gameState handleChallenge:action.playerID againstTarget:action.targetID withFirstPlayerWonOrNot:&wonChallenge];
            break;
        }   
        case ACTION_PUSH:
        {
            [gameState handlePush:action.playerID withPush:action.push];
            break;
        }
        default:
        {
            return;
        }
    }
    [self publishState];
    if (!deferNotification) {
        [self notifyCurrentPlayer];
    }
}

- (void) end
{
    int numPlayers = self.players.count;
    NSMutableArray *losers = self.gameState.losers;
    int places[] = {-1, -1, -1, -1};
	for (int i = [losers count];i > 0;i--)
	{
		NSNumber *loser = [losers objectAtIndex:i-1];
		places[i] = [loser intValue];
	}
	
    id <Player> winner = [gameState gameWinner];
    if (winner != nil) {
        places[0] = [winner getID];
    }
    GameRecord *record = [[[GameRecord alloc]
                          initWithGameTime:time
                          NumPlayers:numPlayers
                          firstPlace:places[0]
                          secondPlace:places[1]
                          thirdPlace:places[2]
                          fourthPlace:places[3]] autorelease];
    
    DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];
    [database addGameRecord:record];
    
    for (id <Player> player in self.players) {
        [player end];
    }
}

@end
