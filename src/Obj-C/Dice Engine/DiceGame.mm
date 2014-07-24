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
#import "PlayGameView.h"
#import "SoarPlayer.h"

#include "NSMutableArrayShuffle.h"

extern std::map<void*, sml::Agent*> agents;

@implementation DiceGame

@synthesize gameState, players, appDelegate, gameView, started, deferNotification, newRound, gameLock;

- (id)initWithAppDelegate:(ApplicationDelegate*)anAppDelegate
{
    self = [super init];

	if (self)
	{
		self.appDelegate = anAppDelegate;
		self.gameState = nil;
		started = NO;

		time = [DiceDatabase getCurrentGameTime];
		nextID = 0;

		self.players = [[NSArray alloc] init];

		shouldNotifyOfNewRound = NO;
		newRound = NO;
	}

    return self;
}

- (void) dealloc
{
	if (self.gameLock)
	{
		auto it = agents.find((__bridge void*)self.gameLock);
		if (it != agents.end())
		{
			NSLock* lock = (__bridge_transfer NSLock*)it->first;

			agents.erase(it);
			NSLog(@"Releasing Lock: %p", lock);
		}
	}

	NSLog(@"%@ deallocated", self.class);
}

-(DiceGame*)init
{
	return [self initWithAppDelegate:nil];
}

-(NSString*)gameNameString
{
	NSString* name = @"";

	for (id<Player> player in players)
	{
		if (![player isKindOfClass:SoarPlayer.class])
			name = [name stringByAppendingFormat:@"%@ vs ", [player getDisplayName]];
	}

	if ([name length] > 4)
		name = [name substringToIndex:[name length] - 4];

	return name;
}

-(NSString*)AINameString
{
	int AICount = 0;

	for (id<Player> player in players)
	{
		if ([player isKindOfClass:SoarPlayer.class])
			AICount++;
	}

	if (AICount > 0)
		return [NSString stringWithFormat:@"%i AIs", AICount];

	return [NSString string];
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
		self.started = [decoder decodeBoolForKey:@"DiceGame:started"];
		self.deferNotification = [decoder decodeBoolForKey:@"DiceGame:deferNotification"];

		time.day = [decoder decodeIntForKey:@"DiceGame:time:day"];
		time.hour = [decoder decodeIntForKey:@"DiceGame:time:hour"];
		time.minute = [decoder decodeIntForKey:@"DiceGame:time:minute"];
		time.month = [decoder decodeIntForKey:@"DiceGame:time:month"];
		time.second = [decoder decodeIntForKey:@"DiceGame:time:second"];
		time.year = [decoder decodeIntForKey:@"DiceGame:time:year"];

		nextID = [decoder decodeIntForKey:@"DiceGame:nextID"];

		self.gameState = [decoder decodeObjectForKey:@"DiceGame:gameState"];
		self.gameState.game = self;

		if ([decoder containsValueForKey:@"NewRound"])
			newRound = YES;
	}

	return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder
{
	[encoder encodeBool:started forKey:@"DiceGame:started"];
	[encoder encodeBool:deferNotification forKey:@"DiceGame:deferNotification"];
	[encoder encodeInt:time.day forKey:@"DiceGame:time:day"];
	[encoder encodeInt:time.hour forKey:@"DiceGame:time:hour"];
	[encoder encodeInt:time.minute forKey:@"DiceGame:time:minute"];
	[encoder encodeInt:time.month forKey:@"DiceGame:time:month"];
	[encoder encodeInt:time.second forKey:@"DiceGame:time:second"];
	[encoder encodeInt:time.year forKey:@"DiceGame:time:year"];

	[encoder encodeInt:nextID forKey:@"DiceGame:nextID"];

	[encoder encodeObject:gameState forKey:@"DiceGame:gameState"];

	if (newRound)
		[encoder encodeBool:YES forKey:@"NewRound"];
}

- (void)updateGame:(DiceGame *)remote
{
	if (!remote)
		return;

	shouldNotifyOfNewRound = remote->shouldNotifyOfNewRound;

	id remoteGameView = remote.gameView;
	if (remoteGameView)
		gameView = remoteGameView;

	if (remote.players)
	{
		self.players = [NSArray arrayWithArray:remote.players];

		for (id<Player> p in self.players)
		{
			if ([p isKindOfClass:DiceLocalPlayer.class])
			{
				DiceLocalPlayer* player = p;
				PlayGameView* localView = gameView;
				if (localView)
					[((DiceLocalPlayer*)player).gameViews addObject:localView];

				player.playerState = [self.gameState playerStateForPlayerID:player.getID];
			}
			else if ([p isKindOfClass:SoarPlayer.class])
				((SoarPlayer*)p).game = self;
		}
	}

	id remoteAppDelegate = remote.appDelegate;
	if (remoteAppDelegate)
		appDelegate = remoteAppDelegate;

	started = remote.started;
	deferNotification = remote.deferNotification;
	time = remote->time;
	nextID = remote->nextID;

	BOOL didAdvanceTurns = NO;

	if (remote->newRound != newRound)
	{
		if (remote->newRound)
			for (id <NewRoundListener> listener in self.gameState.theNewRoundListeners)
				[listener roundBeginning];
	}

	if (remote.gameState)
	{
		NSArray* myHistory = self.gameState.flatHistory;
		NSArray* newHistory = remote.gameState.flatHistory;

		if ([myHistory count] < [newHistory count])
			NSLog(@"WARNING: History is less! This should not happen!");

		if ([myHistory count] != [newHistory count])
		{
			int index = (int)[myHistory count];

			if (![[[newHistory objectAtIndex:([myHistory count]-1)] description] isEqualToString:[[myHistory lastObject] description]])
			{
				NSLog(@"WARNING: History objects are not equivalent! This will go horribly wrong!  Replaying entire history!");

				index = 0;
			}

			for (;index < [newHistory count];++index)
				NSLog(@"REPLAY HISTORY: %@", [[newHistory objectAtIndex:index] debugDescription]);
		}

		if (remote.gameState.currentTurn != self.gameState.currentTurn)
			didAdvanceTurns = YES;

		if (remote.newRound)
		{
			// Round over
			for (id <NewRoundListener> listener in self.gameState.theNewRoundListeners)
				[listener roundEnding];
		}

		self.gameState = remote.gameState;

		if (players)
			self.gameState.players = players;
	}

	[self publishState];

	if (self.gameState.hasAPlayerWonTheGame)
	{
		for (id<Player> player in players)
		{
			[player end];

			if ([player isKindOfClass:DiceLocalPlayer.class])
				[(DiceLocalPlayer*)player end:YES];
		}

		return;
	}
	
	newRound = remote->newRound;

	int currentTurnGK = self.gameState.currentTurn;
	if ([GKLocalPlayer localPlayer].isAuthenticated)
	{
		ApplicationDelegate* delegate = self.appDelegate;
		GKTurnBasedParticipant* currentParticipant = [[delegate.listener handlerForGame:self].match currentParticipant];

		for (int i = 0;i < [self.players count];++i)
		{
			id<Player> p = [self.players objectAtIndex:i];

			if ([[currentParticipant playerID] isEqualToString:[p getGameCenterName]])
			{
				currentTurnGK = i;
				break;
			}
		}
	}

	if (didAdvanceTurns && ![[self.players objectAtIndex:currentTurnGK] isKindOfClass:DiceRemotePlayer.class])
		[self notifyCurrentPlayer];

	PlayerState* playerState = [[self.gameState lastHistoryItem] player];

	if (newRound && [[players objectAtIndex:[playerState playerID]] isKindOfClass:DiceLocalPlayer.class])
		[self.gameState createNewRound];
}

- (void) setGameView:(PlayGameView*)aGameView
{
    gameView = aGameView;
    for (id <Player> player in self.players)
    {
        if ([player isKindOfClass:[DiceLocalPlayer class]])
			[((DiceLocalPlayer*)player).gameViews addObject:self.gameView];
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
	PlayGameView* localView = self.gameView;
    if ([player isKindOfClass:[DiceLocalPlayer class]] && localView)
		[((DiceLocalPlayer*)player).gameViews addObject:localView];
    
    NSMutableArray *mut = [[NSMutableArray alloc] initWithArray:self.players];
    [mut addObject:player];
    self.players = [[NSArray alloc] initWithArray:mut];
    [player setID:[self getNextID]];
}

- (void)shufflePlayers
{
	NSMutableArray* playerArray = [NSMutableArray arrayWithArray:self.players];

	[playerArray shuffle];

	for (int i = 0;i < [playerArray count];++i)
	{
		id<Player> p = [playerArray objectAtIndex:i];
		[p setID:i];
	}

	self.players = playerArray;
}

-(int)getNextID {
    return nextID++;
}

-(void)startGame
{
	if (self.gameState.gameWinner)
		return;
	
    if (self.started)
	{
		[self publishState];
		return;
	}

    self.started = YES;
    self.gameState = [[DiceGameState alloc] initWithPlayers:self.players numberOfDice:5 game:self];
		
    [self publishState];
    [self notifyCurrentPlayer];
}

-(void)publishState
{
    for (id <Player> player in players)
    {
		PlayerState* state = [gameState getPlayerState:[player getID]];
		state.gameState = self.gameState;

        [player updateState:state];
    }

	self.gameState.game = self;
	PlayGameView* localGameView = self.gameView;
	PlayerState* localState = [localGameView state];

	if (![localState hasLost] && (newRound || shouldNotifyOfNewRound) && localGameView)
	{
		for (id <NewRoundListener> listener in self.gameState.theNewRoundListeners)
			[listener roundEnding];
		
		shouldNotifyOfNewRound = NO;
	}
}

-(void) notifyCurrentPlayer
{
    if ([self.gameState hasAPlayerWonTheGame]) {
            NSLog(@"Game over, no need to notify player");
        return;
    }
    NSLog(@"Notifying current player %@", [[gameState getCurrentPlayer] getGameCenterName]);

	PlayGameView* view = self.gameView;
	PlayerState* currentState = view.state;
	DiceLocalPlayer* player = currentState.playerPtr;
	ApplicationDelegate* delegate = self.appDelegate;
	GameKitGameHandler* handler = [delegate.listener handlerForGame:self];
	GKTurnBasedMatch* match = handler.match;

	if (!handler || [match.currentParticipant.playerID isEqualToString:player.participant.playerID])
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
	[self handleAction:action notify:YES];

	ApplicationDelegate* delegate = self.appDelegate;
	[delegate.achievements updateAchievements:self];
}

-(void)handleAction:(DiceAction*)action notify:(BOOL)notify;
{
    NSLog(@"Handling action: %@", action);
    self.deferNotification = NO;

	self.gameState.game = self;

    switch (action.actionType)
    {
        case ACTION_BID:
        {
            NSString *playerName = [self.gameState getPlayerState:action.playerID].playerName;
            Bid *bid = [[Bid alloc] initWithPlayerID:action.playerID name:playerName dice:action.count rank:action.face];
            [gameState handleBid:action.playerID withBid:bid];
            [gameState handlePush:action.playerID withPush:action.push];
            break;
        }
        case ACTION_PASS:
        {
            [gameState handlePass:action.playerID andPushingDice:([action.push count] > 0)];
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
		case ACTION_LOST:
			break;
        default:
        {
            return;
        }
    }

	[self publishState];

	PlayGameView* localGameView = self.gameView;
	PlayerState* localState = localGameView.state;
	ApplicationDelegate* delegate = self.appDelegate;

	if (gameState.gameWinner || ([localState hasLost] && [delegate.listener handlerForGame:self] != nil))
		return;

	if (notify)
		[self notifyCurrentPlayer];
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
	
    GameRecord *record = [[GameRecord alloc]
                          initWithGameTime:time
                          NumPlayers:numPlayers
                          firstPlace:places[0]
                          secondPlace:places[1]
                          thirdPlace:places[2]
                          fourthPlace:places[3]];
    
    DiceDatabase *database = [[DiceDatabase alloc] init];
    [database addGameRecord:record];
    
    for (id <Player> player in self.players) {
        [player end];
    }

	ApplicationDelegate* delegate = self.appDelegate;
	[delegate.achievements updateAchievements:self];
	[delegate.leaderboards updateGame:self];
}

- (BOOL)isMultiplayer
{
	for (id<Player> player in players)
		if ([player isKindOfClass:DiceRemotePlayer.class])
			return YES;

	return NO;
}

- (BOOL)hasHardestAI
{
	for (id<Player> player in players)
		if ([player isKindOfClass:SoarPlayer.class] &&
			[(SoarPlayer*)player difficulty] == 4)
			return YES;

	return NO;
}

@end
