//
//  DiceGame.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceGame.h"

#import "ApplicationDelegate.h"
#import "DiceAction.h"
#import "PlayerState.h"
#import "PlayGame.h"
#import "DiceDatabase.h"
#import "GameRecord.h"
#import "HistoryItem.h"

@implementation DiceGame

@synthesize gameState, players, appDelegate, gameView, started, deferNotification;

- (id)initWithAppDelegate:(ApplicationDelegate*)anAppDelegate
{
    if (!(self = [super init])) return self;
    
    self.appDelegate = anAppDelegate;
    self.gameState = nil;
    started = NO;

    time = [DiceDatabase getCurrentGameTime];
	nextID = 0;
    
    self.players = [[[NSArray alloc] init] autorelease];

    return self;
}

-(NSString*)gameNameString
{
	NSString* name = @"";

	for (int i = 0;i < [players count];++i)
	{
		name = [name stringByAppendingString:[[players objectAtIndex:i] name]];

		if (i != ([players count] - 1))
			name = [name stringByAppendingString:@" vs "];
	}

	return name;
}

-(NSString*)lastTurnInfo
{
	return [[gameState lastHistoryItem] state];
}

// Encoding
-(id)initWithCoder:(NSCoder*)decoder
{
	self = [super init];

	if (self)
	{
		started = [decoder decodeBoolForKey:@"DiceGame:started"];
		deferNotification = [decoder decodeBoolForKey:@"DiceGame:deferNotification"];
		[[decoder decodeObjectForKey:@"DiceGame:time"] getValue:&time];
		nextID = [decoder decodeIntForKey:@"DiceGame:nextID"];

		gameState = [decoder decodeObjectForKey:@"DiceGame:gameState"];
		gameState.game = self;

		[gameState decodePlayers];
	}

	return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder
{
	[encoder encodeBool:started forKey:@"DiceGame:started"];
	[encoder encodeBool:deferNotification forKey:@"DiceGame:deferNotification"];
	[encoder encodeObject:[NSValue valueWithBytes:&time objCType:@encode(struct GameTime)] forKey:@"DiceGame:time"];
	[encoder encodeInt:nextID forKey:@"DiceGame:nextID"];

	[encoder encodeObject:gameState forKey:@"DiceGame:gameState"];
}

- (void)updateGame:(DiceGame *)remote
{
	started = remote.started;
	deferNotification = remote.deferNotification;
	time = remote->time;
	nextID = remote->nextID;

	gameState = remote.gameState;
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
    if (self.started)
		return;

    self.started = YES;
    self.gameState = [[[DiceGameState alloc] initWithPlayers:self.players numberOfDice:5 game:self] autorelease];
		
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

-(NSInteger)getNumberOfPlayers
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
    int numPlayers = (int)self.players.count; // Safe conversion due to player count being non-zero and never greater than 2 million something
    NSMutableArray *losers = self.gameState.losers;

    int places[] = {-1, -1, -1, -1, -1, -1, -1, -1};
	
	for (NSInteger i = [losers count];i > 0;i--)
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
