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

@synthesize gameState, players, appDelegate, gameView, started, deferNotification, newRound, gameLock, randomGenerator;

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

#ifdef DEBUG
		self.randomGenerator = [[Random alloc] init:arc4random_uniform(RAND_MAX)];
#else
		self.randomGenerator = [[Random alloc] init:NO_SEED];
#endif
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
			DDLogDebug(@"Releasing Lock: %p", lock);
		}
	}
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

		self.randomGenerator = [decoder decodeObjectForKey:@"DiceGame:randomGenerator"];

		newRound = [decoder containsValueForKey:@"NewRound"];
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

	[encoder encodeObject:randomGenerator forKey:@"DiceGame:randomGenerator"];

	[encoder encodeInt:nextID forKey:@"DiceGame:nextID"];

	[encoder encodeObject:gameState forKey:@"DiceGame:gameState"];

	if (newRound)
		[encoder encodeBool:YES forKey:@"NewRound"];
}

- (void)updateGame:(DiceGame *)remote
{
	if (!remote)
		return;

	DDLogGameKit(@"Recieved update");

	shouldNotifyOfNewRound = remote->shouldNotifyOfNewRound;

	if (remote.randomGenerator)
		randomGenerator = remote.randomGenerator;

	id remoteGameView = remote.gameView;
	if (remoteGameView)
		gameView = remoteGameView;

	if (remote.players && (!self.players || self.players.count == 0))
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

	if (remote.gameState)
	{
		NSArray* myHistory = self.gameState.flatHistory;
		NSArray* newHistory = remote.gameState.flatHistory;

		if (myHistory && newHistory && [myHistory count] < [newHistory count])
			DDLogError(@"History is less! This should not happen!");

		if (myHistory && newHistory &&  [newHistory count] >= [myHistory count])
		{
			int index = (int)[myHistory count];

			if (![[[newHistory objectAtIndex:([myHistory count]-1)] description] isEqualToString:[[myHistory lastObject] description]])
			{
				DDLogError(@"History objects are not equivalent! This will go horribly wrong!  Replaying entire history!");
				index = 0;
			}

			for (;index < [newHistory count];++index)
            {
                HistoryItem* item = [newHistory objectAtIndex:index];
                DiceAction* action = [[DiceAction alloc] init];
                
                action.actionType = item.actionType;
                PlayerState* player = item.player;
                action.playerID = player.playerID;
                action.count = item.bid.numberOfDice;
                action.face = item.bid.rankOfDie;
                action.push = item.bid.diceToPush;
                action.targetID = item.value;
                
				DDLogGameHistory(@"%@", action);
            }
		}

		if (remote.gameState.currentTurn != self.gameState.currentTurn)
			didAdvanceTurns = YES;

		self.gameState = remote.gameState;

		if (players)
			self.gameState.players = players;
	}

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

	PlayGameView* localView = self.gameView;
	if ([self.gameState.theNewRoundListeners count] == 0 && localView)
		[self.gameState addNewRoundListener:localView];

	if (!remote->newRound && newRound)
		for (id <NewRoundListener> listener in self.gameState.theNewRoundListeners)
			[listener roundBeginning];

	newRound = remote->newRound;

	[self publishState];

	ApplicationDelegate* delegate = self.appDelegate;
	GameKitGameHandler* handler = [delegate.listener handlerForGame:self];
	GKTurnBasedMatch* match = handler.match;
	NSString* currentPlayerID = match.currentParticipant.playerID;
	NSString* localPlayerID = [GKLocalPlayer localPlayer].playerID;

	if ([match.currentParticipant.playerID isEqualToString:localPlayerID] &&
		[[players objectAtIndex:gameState.currentTurn] isKindOfClass:DiceRemotePlayer.class])
	{
		DiceRemotePlayer* next = nil;

		for (id<Player> player in players)
			if ([player isKindOfClass:DiceRemotePlayer.class] && ![[self.gameState playerStateForPlayerID:[player getID]] hasLost])
				next = player;

		if (next)
			[handler advanceToRemotePlayer:next];
	}

	if (newRound && ![currentPlayerID isEqualToString:localPlayerID])
		return;

	if (gameState && (newRound || (gameState->didLeave && [currentPlayerID isEqualToString:localPlayerID])))
	{
		gameState.canContinueGame = NO;
		[gameState createNewRound];
		return;
	}

	if (didAdvanceTurns)
		[self notifyCurrentPlayer];
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

	[playerArray shuffle:self];

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
    if ([self.gameState hasAPlayerWonTheGame])
    {
        DDLogInfo(@"Game over, no need to notify player");
        return;
    }
    
    DDLogInfo(@"Notifying current player %@", [[gameState getCurrentPlayer] getGameCenterName]);

	ApplicationDelegate* delegate = self.appDelegate;
	GameKitGameHandler* handler = [delegate.listener handlerForGame:self];
	GKTurnBasedMatch* match = handler.match;
	NSString* currentPlayerID = match.currentParticipant.playerID;
	NSString* localPlayerID = [GKLocalPlayer localPlayer].playerID;

	if (!handler || [currentPlayerID isEqualToString:localPlayerID])
	{
		// I am in control of the match
		[[gameState getCurrentPlayer] itsYourTurn];
	}
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
}

-(void)handleAction:(DiceAction*)action notify:(BOOL)notify;
{
    DDLogGameHistory(@"%@", action);
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
        default:
			break;
    }

	[self publishState];

	PlayGameView* localGameView = self.gameView;
	PlayerState* localState = localGameView.state;
	ApplicationDelegate* delegate = self.appDelegate;
    
    [delegate.achievements updateAchievements:self];

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

-(DiceLocalPlayer*)localPlayer
{
	DiceLocalPlayer* localPlayer = nil;

	for (id<Player> player in players)
		if ([player isKindOfClass:DiceLocalPlayer.class])
		{
			localPlayer = player;
			break;
		}

	return localPlayer;
}

@end
