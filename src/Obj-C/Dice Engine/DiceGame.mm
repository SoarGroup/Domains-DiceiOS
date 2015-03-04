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

#import "DiceReplayPlayer.h"
#import "DiceSoarReplayPlayer.h"

#include "NSMutableArrayShuffle.h"

@implementation DiceGame

@synthesize gameState, players, appDelegate, gameView, started, deferNotification, newRound, gameLock, randomGenerator, all_actions;

- (id)initWithAppDelegate:(ApplicationDelegate*)anAppDelegate withSeed:(int)setSeed
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
		
		DDLogGameHistory(@"Start of Match");
		
		self.randomGenerator = [[Random alloc] init:setSeed];
		
		self.all_actions = [[NSMutableArray alloc] init];
		[all_actions addObject:[NSNumber numberWithInt:setSeed]];
		[all_actions addObject:[NSMutableArray array]];
		
		compatibility_build = COMPATIBILITY_BUILD;
		
		transfered = NO;
	}
	
	return self;
}

- (id)initWithAppDelegate:(ApplicationDelegate*)anAppDelegate
{
	return [self initWithAppDelegate:anAppDelegate withSeed:arc4random_uniform(RAND_MAX)];
}

-(DiceGame*)init
{
	return [self initWithAppDelegate:nil];
}

- (void)dealloc
{
	if (!transfered)
		[SoarPlayer destroyThread:gameLock];
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
		if ([decoder containsValueForKey:@"DiceGame:compatibility_build"])
			compatibility_build = [decoder decodeIntForKey:@"DiceGame:compatibility_build"];
		else
			compatibility_build = -1;
		
		if (compatibility_build != COMPATIBILITY_BUILD)
			return nil;
		
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
		
		if ([decoder containsValueForKey:@"DiceGame:all_actions"])
			self.all_actions = [decoder decodeObjectForKey:@"DiceGame:all_actions"];
		
		newRound = [decoder containsValueForKey:@"NewRound"];
		
		transfered = NO;
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
	[encoder encodeObject:all_actions forKey:@"DiceGame:all_actions"];
	
	[encoder encodeInt:compatibility_build forKey:@"DiceGame:compatibility_build"];
	
	transfered = NO;

	if (newRound)
		[encoder encodeBool:YES forKey:@"NewRound"];
}

- (void)updateGame:(DiceGame *)remote
{
	if (!remote)
		return;

	DDLogGameKit(@"Recieved update");
	
	self.all_actions = remote.all_actions;
	
	if (remote->gameLock)
	{
		gameLock = remote->gameLock;
		remote->transfered = YES;
	}

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
			if ([p isKindOfClass:DiceLocalPlayer.class] || [p isKindOfClass:DiceReplayPlayer.class] || [p isKindOfClass:DiceSoarReplayPlayer.class])
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

			if ([player isKindOfClass:DiceLocalPlayer.class] || [player isKindOfClass:DiceReplayPlayer.class] || [player isKindOfClass:DiceSoarReplayPlayer.class])
				[(DiceLocalPlayer*)player end:YES];
		}

		[self logGameToFile];
		return;
	}

	PlayGameView* localView = self.gameView;
	if ([self.gameState.theNewRoundListeners count] == 0 && localView)
		[self.gameState addNewRoundListener:localView];

	if (!remote->newRound && newRound)
	{
		[gameLock lock];
		
		for (id <NewRoundListener> listener in self.gameState.theNewRoundListeners)
			[listener roundBeginning];
		
		[gameLock unlock];
	}

	newRound = remote->newRound;

	[self publishState];

	ApplicationDelegate* delegate = self.appDelegate;
	GameKitGameHandler* handler = [delegate.listener handlerForGame:self];
	GKTurnBasedMatch* match = handler.match;
	NSString* currentPlayerID = match.currentParticipant.player.playerID;
	NSString* localPlayerID = [GKLocalPlayer localPlayer].playerID;

	if ([match.currentParticipant.player.playerID isEqualToString:localPlayerID] &&
		[[players objectAtIndex:gameState.currentTurn] isKindOfClass:DiceRemotePlayer.class])
	{
		DiceRemotePlayer* next = nil;

		for (id<Player> player in players)
			if ([player isKindOfClass:DiceRemotePlayer.class] && ![[self.gameState playerStateForPlayerID:[player getID]] hasLost])
				next = player;

		if (next)
			[handler advanceToRemotePlayer:next];
	}
	
	[self logGameToFile];

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
        if ([player isKindOfClass:[DiceLocalPlayer class]] || [player isKindOfClass:DiceReplayPlayer.class] || [player isKindOfClass:DiceSoarReplayPlayer.class])
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
    if (([player isKindOfClass:[DiceLocalPlayer class]] || [player isKindOfClass:DiceReplayPlayer.class] || [player isKindOfClass:DiceSoarReplayPlayer.class])
        && localView)
		[((DiceLocalPlayer*)player).gameViews addObject:localView];
    
    NSMutableArray *mut = [[NSMutableArray alloc] initWithArray:self.players];
    [mut addObject:player];
    self.players = [[NSArray alloc] initWithArray:mut];
    [player setID:[self getNextID]];
	
	[[all_actions objectAtIndex:1] addObject:[player dictionaryValue]];
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
    
//    DDLogInfo(@"Notifying current player %@", [[gameState getCurrentPlayer] getGameCenterName]);

	ApplicationDelegate* delegate = self.appDelegate;
	GameKitGameHandler* handler = [delegate.listener handlerForGame:self];
	GKTurnBasedMatch* match = handler.match;
	NSString* currentPlayerID = match.currentParticipant.player.playerID;
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

-(void)logGameToFile
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains
	(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	NSString *fileName = [NSString stringWithFormat:@"%@/%lu.log", documentsDirectory, (unsigned long)randomGenerator->integerSeed];
	
	[all_actions writeToFile:fileName atomically:YES];
}

-(void)handleAction:(DiceAction*)action
{
	[self handleAction:action notify:YES];
}

-(void)handleAction:(DiceAction*)action notify:(BOOL)notify;
{
	if (!action)
		return;
	
    if ([NSThread isMainThread])
    {
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            [self handleAction:action notify:notify];
        });
        return;
    }
	
#ifdef DEBUG
	NSMutableDictionary* replayState = [NSMutableDictionary dictionary];
	
	for (PlayerState* state in gameState.playerStates)
	{
		NSString* name = [NSString stringWithFormat:@"Player-%i", state.playerID];
		
		[replayState setValue:[state dictionaryValue] forKey:name];
	}
	
	if (action.replayState)
	{
		// Check the state
		assert([action.replayState isEqualToDictionary:replayState]);
	}
	action.replayState = replayState;
#endif

    DDLogGameHistory(@"%@", action);
	[all_actions addObject:[action dictionaryValue]];
	
	[self logGameToFile];
	
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
            notify = NO;
            break;
        }
        case ACTION_CHALLENGE_BID:
        case ACTION_CHALLENGE_PASS:
        {
            BOOL wonChallenge;
            [gameState handleChallenge:action.playerID againstTarget:action.targetID withFirstPlayerWonOrNot:&wonChallenge];
            notify = NO;
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
    NSUInteger numPlayers = self.players.count; // Safe conversion due to player count being non-zero and never greater than 2 million something
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
		if ([player isKindOfClass:DiceLocalPlayer.class] || [player isKindOfClass:DiceReplayPlayer.class] || [player isKindOfClass:DiceSoarReplayPlayer.class])
		{
			localPlayer = player;
			break;
		}

	return localPlayer;
}

@end
