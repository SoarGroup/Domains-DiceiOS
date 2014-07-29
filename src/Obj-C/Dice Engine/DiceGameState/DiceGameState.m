//
//  DiceGameState.m
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceGameState.h"

#import "PlayerState.h"
#import "HistoryItem.h"
#import "Die.h"
#import "Player.h"
#import "DiceTypes.h"
#import "DiceGame.h"
#import "SoarPlayer.h"

#import "ApplicationDelegate.h"
#import "GameKitListener.h"

#import "PlayGameView.h"

@implementation DiceGameState

@synthesize playerStates;
@synthesize players, currentTurn, previousBid;
@synthesize playersLeft, theNewRoundListeners, game, losers, canContinueGame;

-(id)initWithCoder:(NSCoder*)decoder
{
	self = [super init];

	if (self)
	{
		int historyCount = [decoder decodeIntForKey:@"DiceGameState:history"];

		history = [[NSMutableArray alloc] init];
		for (int i = 0;i < historyCount;i++)
			[history addObject:[[HistoryItem alloc] initWithCoder:decoder withCount:i withGameState:self]];

		int roundCount = [decoder decodeIntForKey:@"DiceGameState:rounds"];

		rounds = [[NSMutableArray alloc] init];

		for (int i = 0;i < roundCount;i++)
		{
			int historyRoundCount = [decoder decodeIntForKey:[NSString stringWithFormat:@"DiceGameState:history%i", i]];

			NSMutableArray* historyFromRounds = [[NSMutableArray alloc] init];

			for (int j = 0;j < historyRoundCount;j++)
				[historyFromRounds addObject:[[HistoryItem alloc] initWithCoder:decoder withCount:j withGameState:self withPrefix:[NSString stringWithFormat:@"DiceGameState:history%i", i]]];

			[rounds addObject:historyFromRounds];
		}

		rounds = [decoder decodeObjectForKey:@"DiceGameState:rounds"];
		inSpecialRules = [decoder decodeBoolForKey:@"DiceGameState:inSpecialRules"];
		currentTurn = [decoder decodeIntForKey:@"DiceGameState:currentTurn"];
		playersLeft = [decoder decodeIntegerForKey:@"DiceGameState:playersLeft"];
		previousBid = [decoder decodeObjectForKey:@"DiceGameState:previousBid"];

		int playerStatesCount = [decoder decodeIntForKey:@"DiceGameState:playerStates"];

		NSMutableArray* playerStatesMutable = [[NSMutableArray alloc] init];
		for (int i = 0;i < playerStatesCount;i++)
			[playerStatesMutable addObject:[[PlayerState alloc] initWithCoder:decoder withCount:i withGameState:self] ];

		self.playerStates = playerStatesMutable;

		playersArrayToDecode = [decoder decodeObjectForKey:@"DiceGameState:players"];
		self.canContinueGame = [decoder decodeBoolForKey:@"DiceGameState:CanContinueGame"];

		int losersCount = [decoder decodeIntForKey:@"DiceGameState:losers"];

		for (int i = 0;i < losersCount;i++)
			[losers addObject:[NSNumber numberWithInt:[decoder decodeIntForKey:[NSString stringWithFormat:@"DiceGameState:losers%i", i]]]];

		theNewRoundListeners = [[NSMutableArray alloc] init];

		didLeave = NO;
		leavingPlayerID = 0;

		if ([decoder containsValueForKey:@"DiceGameState:GameWinner"])
			gameWinner = (id<Player>)[decoder decodeObjectForKey:@"DiceGameState:GameWinner"];
	}

	return self;
}

- (void) decodePlayers:(GKTurnBasedMatch*)match withHandler:(GameKitGameHandler*)handler
{
	NSMutableArray* finalPlayersArray = [[NSMutableArray alloc] init];
	NSMutableArray* participants = [[NSMutableArray alloc] initWithArray:match.participants];

	NSLock* lock = [[NSLock alloc] init];

	BOOL foundLocalPlayer = NO;
	for (NSString* player in playersArrayToDecode)
	{
		DDLogVerbose(@"Recieved player: %@", player);

		if (![[player substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"Soar"] &&
			![player isEqualToString:@"Human"]) // Complete Player
		{
			GKTurnBasedParticipant* participant;

			for (GKTurnBasedParticipant* p in participants)
			{
				if (p.playerID != nil &&
					[p.playerID isEqualToString:player])
				{
					// Found the player
					participant = p;
					break;
				}
			}

			[participants removeObject:participant];

			if ([[[GKLocalPlayer localPlayer] playerID] isEqualToString:participant.playerID])
			{
				assert(!foundLocalPlayer);

				// Local Player
				[finalPlayersArray addObject:[[DiceLocalPlayer alloc] initWithName:[GKLocalPlayer localPlayer].alias withHandler:handler withParticipant:nil]];
				foundLocalPlayer = YES;
			}
			else
			{
				// Remote Player
				[finalPlayersArray addObject:[[DiceRemotePlayer alloc] initWithGameKitParticipant:participant withGameKitGameHandler:handler]];
			}
		}
		else if ([player isEqualToString:@"Human"])
		{
			[finalPlayersArray addObject:@"Human"];
			continue;
			// Handle this case once all the others are done
		}
		else
		{
			DDLogVerbose(@"Got AI: %@", player);

			int difficulty = [player characterAtIndex:[player length]-1] - '0';

			NSString* soarName = [player substringWithRange:NSMakeRange(5, [player length]-2-5)];

			[finalPlayersArray addObject:[[SoarPlayer alloc] initWithGame:self.game connentToRemoteDebugger:NO lock:lock withGameKitGameHandler:handler difficulty:difficulty name:soarName] ];
		}
		[[finalPlayersArray lastObject] setID:(int)[finalPlayersArray count]-1];
	}

	if (!foundLocalPlayer)
	{
		// We just joined the match.  Find the first open slot
		for (int i = 0;i < [finalPlayersArray count];++i)
		{
			id obj = [finalPlayersArray objectAtIndex:i];

			if ([obj isKindOfClass:[NSString class]] &&
				[(NSString*)obj isEqualToString:@"Human"])
			{
				// Found the open slot
				DiceLocalPlayer* localPlayer = [[DiceLocalPlayer alloc] initWithName:[GKLocalPlayer localPlayer].alias withHandler:handler withParticipant:nil];
				foundLocalPlayer = YES;

				[localPlayer setID:i];

				[finalPlayersArray replaceObjectAtIndex:i withObject:localPlayer];

				GKTurnBasedParticipant* localParticipant = nil;

				for (GKTurnBasedParticipant* p in participants)
					if ([p.playerID isEqualToString:[[GKLocalPlayer localPlayer] playerID]])
					{
						localParticipant = p;
						break;
					}

				assert(localParticipant);

				[participants removeObject:localParticipant];
				break;
			}
		}
	}

	while ([participants count] > 0)
	{
		// Remote Player

		NSUInteger replacementIndex = 0;
		for (;replacementIndex < [finalPlayersArray count];replacementIndex++)
		{
			id object = [finalPlayersArray objectAtIndex:replacementIndex];

			if ([object isKindOfClass:[NSString class]] &&
				[(NSString*)object isEqualToString:@"Human"])
				break;
		}

		assert(replacementIndex != [finalPlayersArray count]);

		[finalPlayersArray replaceObjectAtIndex:replacementIndex withObject:[[DiceRemotePlayer alloc] initWithGameKitParticipant:[participants objectAtIndex:0] withGameKitGameHandler:handler]];
		[[finalPlayersArray objectAtIndex:replacementIndex] setID:(int)replacementIndex];

		[participants removeObjectAtIndex:0];
	}

	assert([participants count] == 0);
	assert(foundLocalPlayer);

	self.players = finalPlayersArray;

	if ([gameWinner isKindOfClass:NSString.class])
	{
		NSString* gameWinnerString = (NSString*)gameWinner;
		for (id<Player> player in self.players)
		{
			if ((![player isKindOfClass:SoarPlayer.class] &&
				[[player getGameCenterName] isEqualToString:gameWinnerString]) ||
				([player isKindOfClass:SoarPlayer.class] &&
				 [[player getGameCenterName] isEqualToString:[gameWinnerString substringToIndex:[gameWinnerString length] - 3]]))
			{
				gameWinner = player;
				break;
			}
		}
	}

	for (HistoryItem* item in history)
		[item canDecodePlayer];

	for (NSArray* array in rounds)
		for (HistoryItem* item in array)
			[item canDecodePlayer];

	didLeave = NO;
	leavingPlayerID = 0;

	for (GKTurnBasedParticipant* participant in match.participants)
	{
		if (participant.matchOutcome == GKTurnBasedMatchOutcomeLost ||
			participant.matchOutcome == GKTurnBasedMatchOutcomeQuit ||
			participant.matchOutcome == GKTurnBasedMatchOutcomeTimeExpired)
		{
			for (id<Player> player in players)
			{
				if ([player isKindOfClass:DiceRemotePlayer.class] &&
					[[(DiceRemotePlayer*)player participant].playerID isEqualToString:participant.playerID])
				{
					// Found the player who has lost, check to make sure they have
					PlayerState* state = [self playerStateForPlayerID:[player getID]];

					if (![state hasLost])
					{
						state.numberOfDice = 0;
						[state.arrayOfDice removeAllObjects];

						[self playerLosesGame:state.playerID];

						[self goToNextPlayerWhoHasntLost];

						leavingPlayerID = [player getID];
						didLeave = YES;
					}
				}
			}
		}
	}
}

-(void)encodeWithCoder:(NSCoder*)encoder
{
	[encoder encodeInt:(int)[history count] forKey:@"DiceGameState:history"];

	for (int i = 0;i < [history count];i++)
		[((HistoryItem*)[history objectAtIndex:i]) encodeWithCoder:encoder withCount:i];

	[encoder encodeInt:(int)[rounds count] forKey:@"DiceGameState:rounds"];

	for (int i = 0;i < [rounds count];i++)
	{
		NSArray* historyFromRounds = [rounds objectAtIndex:i];

		[encoder encodeInt:(int)[historyFromRounds count] forKey:[NSString stringWithFormat:@"DiceGameState:history%i", i]];

		for (int j = 0;j < [historyFromRounds count];j++)
			[((HistoryItem*)[historyFromRounds objectAtIndex:j]) encodeWithCoder:encoder withCount:j withPrefix:[NSString stringWithFormat:@"DiceGameState:history%i", i]];
	}

	[encoder encodeBool:inSpecialRules forKey:@"DiceGameState:inSpecialRules"];
	[encoder encodeInt:currentTurn forKey:@"DiceGameState:currentTurn"];
	[encoder encodeInteger:playersLeft forKey:@"DiceGameState:playersLeft"];
	[encoder encodeObject:previousBid forKey:@"DiceGameState:previousBid"];

	[encoder encodeInt:(int)[playerStates count] forKey:@"DiceGameState:playerStates"];

	for (int i = 0;i < [playerStates count];i++)
		[((PlayerState*)[playerStates objectAtIndex:i]) encodeWithCoder:encoder withCount:i];

	NSMutableArray* playersArray = [[NSMutableArray alloc] init];

	for (id<Player> player in players)
	{
		if ([player isKindOfClass:DiceLocalPlayer.class] || [player isKindOfClass:DiceRemotePlayer.class])
		{
			NSString* name = @"Human";

			if ([player getGameCenterName] != nil)
				name = [player getGameCenterName];

			[playersArray addObject:name];
		}
		else if ([player isKindOfClass:SoarPlayer.class])
			[playersArray addObject:[NSString stringWithFormat:@"%@-%d", [player getGameCenterName],((SoarPlayer*)player).difficulty]];
	}

	[encoder encodeObject:playersArray forKey:@"DiceGameState:players"];
	[encoder encodeBool:canContinueGame forKey:@"DiceGameState:CanContinueGame"];

	[encoder encodeInt:(int)[losers count] forKey:@"DiceGameState:losers"];

	for (int i = 0;i < [losers count];i++)
		[encoder encodeInt:[(NSNumber*)[losers objectAtIndex:i] intValue] forKey:[NSString stringWithFormat:@"DiceGameState:losers%i", i]];

	if (gameWinner)
		[encoder encodeObject:[gameWinner getGameCenterName] forKey:@"DiceGameState:GameWinner"];
}

/*** DiceGameState
 Takes a NSArray of player names and the maximum number of dice.
 ***/
- (id)initWithPlayers:(NSArray *)thePlayers numberOfDice:(int)numberOfDice game:(DiceGame *)aGame;
{
    self = [super init];
    if (self) {
		didLeave = NO;
		leavingPlayerID = 0;
        self.game = aGame;
        self.players = thePlayers;
        self.losers = [[NSMutableArray alloc] init];
        NSMutableArray *mutPlayerStates = [[NSMutableArray alloc] init];
        
        // Fill the player array with player states for each player in the game
        NSInteger numPlayers = [thePlayers count];
        for (int i = 0; i < numPlayers; ++i)
        {
            id <Player> player = [self.players objectAtIndex:i];
            // Create the new player state

            PlayerState *newPlayerState = [[PlayerState alloc] initWithName:[player getGameCenterName]
                                                                      withID:[player getID]
                                                            withNumberOfDice:numberOfDice 
                                                           withDiceGameState:self];
			
            [mutPlayerStates addObject:newPlayerState];
        }
        
        self.playerStates = [NSArray arrayWithArray:mutPlayerStates];
        self.theNewRoundListeners = [NSMutableArray array];
        rounds = [[NSMutableArray alloc] init];        
        playersLeft = [self.players count];
        gameWinner = nil;
        self.currentTurn = 0;
        inSpecialRules = NO;
        //[self goToNextPlayerWhoHasntLost];
		self.currentTurn = 0;
		self.canContinueGame = YES;
		[self createNewRound:NO];
    }
    return self;
}

- (void)addNewRoundListener:(id <NewRoundListener>)listener {
    [theNewRoundListeners addObject:listener];
}

// Handle bids
- (BOOL)handleBid:(NSInteger)playerID withBid:(Bid *)bid
{
    // Make sure it is the player's turn and the bid is correct
    if ([self checkPlayer:playerID] && [self checkBid:bid playerSpecialRules:(inSpecialRules && [[self getPlayerState:playerID] numberOfDice] > 1)]) {
        //Set the previous bid to this one
        self.previousBid = bid;
        // Add this bid to our history
        HistoryItem *newHistoryItem = [[HistoryItem alloc] initWithState:self 
                                                           andWithPlayer:[self getPlayerState:playerID] 
                                                                 withBid:bid];
        [history addObject:newHistoryItem];
        // Go to the next turn
        [self moveToNextTurn];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)handlePush:(NSInteger)playerID withPush:(NSArray *)push
{
    if (push == nil || [push count] == 0)
    {
        return NO;
    }
    // Get the last history item to make sure they can push.
    HistoryItem *item = [self lastHistoryItem];
	PlayerState* playerLocal = item.player;

    if (!item || playerLocal.playerID != playerID || (item.actionType != ACTION_BID && item.actionType != ACTION_PASS))
        return NO;
    
    // Get the player state of the player pushing.
    PlayerState *player = [self getPlayerState:playerID];
    //Make sure they haven't pushed already
    if ([push count] == 0)
        return NO;
    
    // Set the item to nil so we can reuse it for creating a new history item,
    // the original variable will be autoreleased.
    item = nil;
    item = [[HistoryItem alloc] initWithState:self 
                                andWithPlayer:[self getPlayerState:playerID] 
                                  whereTypeIs:ACTION_PUSH];
    [history addObject:item];
    
    // Tell the player to push the dice.
    [player pushDice:push];
    
    return YES;
}

- (BOOL)handlePass:(NSInteger)playerID andPushingDice:(BOOL)pushingDice
{
    // Make sure its a valid pass.
    if ([self checkPlayer:playerID]) {
        
        // Get the player state.
        PlayerState *player = [self getPlayerState:playerID];
        if ([player playerHasPassed] && !pushingDice)
            return NO;
        
        player.playerHasPassed = YES;
        HistoryItem *item = [[HistoryItem alloc] initWithState:self 
                                                 andWithPlayer:player 
                                                   whereTypeIs:ACTION_PASS 
                                                     withValue:([player playerHasAllSameDice] ? 1 : 0)];
        [history addObject:item];
        // Go to the next turn.
        [self moveToNextTurn];
        return YES;
    } else
        return NO;
}

// Handles a challenge, whether it is a challenge of a bid or a pass
- (BOOL)handleChallenge:(NSInteger)playerID againstTarget:(NSInteger)targetID withFirstPlayerWonOrNot:(BOOL *)didTheChallengerWin
{
    if (![self checkPlayer:playerID]) {
        return NO;
    }
    PlayerState *player = [self getPlayerState:playerID];
    HistoryItem *item = [self lastHistoryItem];
    HistoryItem *secondLast = nil;
    
    if ([[self history] count] >= 2)
        secondLast = [[self history] objectAtIndex:[[self history] count] - 2];

	PlayerState* playerLocal = item.player;
	PlayerState* secondPlayerLocal = secondLast.player;
    
    //Make sure its a valid challenge
    if (self.previousBid && [self.previousBid playerID] == targetID) {
        if ([self isBidCorrect:self.previousBid]) {
            [self playerLosesRound:playerID];
            HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                        andWithPlayer:player 
                                                          whereTypeIs:ACTION_CHALLENGE_BID
                                                            withValue:(int)targetID
                                                            andResult:0];
            [newItem setBid:self.previousBid];
            [newItem setLosingPlayer:playerID];
            [history addObject:newItem];
            *didTheChallengerWin = NO;
        } else {
            [self playerLosesRound:targetID];
            HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                        andWithPlayer:player 
                                                          whereTypeIs:ACTION_CHALLENGE_BID
                                                            withValue:(int)targetID
                                                            andResult:1];
            [newItem setBid:self.previousBid];
            [newItem setLosingPlayer:targetID];
            [history addObject:newItem];
            *didTheChallengerWin = YES;
        }
    } else if (((item && (item.actionType == ACTION_PASS && playerLocal.playerID == targetID)) ||
               (secondLast && secondLast.actionType == ACTION_PASS && secondPlayerLocal.playerID == targetID)))
	{
        if (playerLocal.playerID == targetID)
        {
            if (item.result == 1) // Pass was legal
            {
                [self playerLosesRound:playerID];
                HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                            andWithPlayer:player
                                                              whereTypeIs:ACTION_CHALLENGE_PASS
                                                                withValue:(int)targetID
                                                                andResult:0];
                [newItem setLosingPlayer:playerID];
                [history addObject:newItem];
                *didTheChallengerWin = NO;
            } else {
                [self playerLosesRound:targetID];
                HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                            andWithPlayer:player
                                                              whereTypeIs:ACTION_CHALLENGE_PASS
                                                                withValue:(int)targetID
                                                                andResult:1];
                [newItem setLosingPlayer:targetID];
                [history addObject:newItem];
                *didTheChallengerWin = YES;
            }
        }
        else
        {
            if (secondLast && secondLast.result == 1) // Pass was legal
            {
                [self playerLosesRound:playerID];
                HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                            andWithPlayer:player
                                                              whereTypeIs:ACTION_CHALLENGE_PASS
                                                                withValue:(int)targetID
                                                                andResult:0];
                [newItem setLosingPlayer:playerID];
                [history addObject:newItem];
                *didTheChallengerWin = NO;
            } else {
                [self playerLosesRound:targetID];
                HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                            andWithPlayer:player
                                                              whereTypeIs:ACTION_CHALLENGE_PASS
                                                                withValue:(int)targetID
                                                                andResult:1];
                [newItem setLosingPlayer:targetID];
                [history addObject:newItem];
                *didTheChallengerWin = YES;
            } 
        }
    } else {
        return NO;
    }
    
    if (*didTheChallengerWin)
    {
        int targetIndex = [self getIndexOfPlayerWithId:targetID];
        self.currentTurn = targetIndex % [self.playerStates count];
    }
    else
        self.currentTurn = (self.currentTurn) % [self.playerStates count];

	[self goToNextPlayerWhoHasntLost];
	[self createNewRound];

	if (gameWinner)
	{
		[gameWinner notifyHasWon];
		return YES;
	}

    return YES;
}

//Handle exacts
- (BOOL)handleExact:(NSInteger)playerID andWasTheExactRight:(BOOL *)wasTheExactRight
{
    //Make sure its the player's turn
    if (![self checkPlayer:playerID]) {
        return NO;
    }
    PlayerState *player = [self getPlayerState:playerID];
    Bid *bid = self.previousBid;
    if (!bid || [player playerHasExacted])
        return NO;
    [player setPlayerHasExacted:YES];
    
    //Make sure the exact is correct otherwise say it wasn't
    if ([self countDice:[bid rankOfDie]] == [bid numberOfDice]) {
        DDLogVerbose(@"%i: exact was correct", [player playerID]);
        HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                    andWithPlayer:player
                                                      whereTypeIs:ACTION_EXACT
                                                        withValue:1];
        [newItem setBid:bid];
        if ([player numberOfDice] < [player maxNumberOfDice])
            player.numberOfDice++;
		
		[newItem setWinningPlayer:playerID];
        [history addObject:newItem];
        
        *wasTheExactRight = YES;
    } else {
        DDLogVerbose(@"%i: exact was wrong", [player playerID]);
        [self playerLosesRound:playerID];
        HistoryItem *newItem = [[HistoryItem alloc] initWithState:self
                                                    andWithPlayer:player
                                                      whereTypeIs:ACTION_EXACT
                                                        withValue:0];
        [newItem setBid:bid];
        [newItem setLosingPlayer:playerID];
        [history addObject:newItem];
        
        *wasTheExactRight = NO;
    }

	[self createNewRound];

	if (gameWinner)
		[gameWinner notifyHasWon];

	return YES;
}

- (BOOL)handleAccept:(NSInteger)playerID
{
    if ([self checkPlayer:playerID]) {
        [self moveToNextTurn];
        return YES;
    }
    else
        return NO;
}

- (id <Player>)getPlayerWithID:(NSInteger)playerID {
    for (id <Player> player in self.players)
    {
        if ([player getID] == playerID)
        {
            return player;
        }
    }
    return nil;
}

- (id <Player>) getCurrentPlayer {
    return [self.players objectAtIndex:self.currentTurn];
}

// Return the current player's PlayerState*
- (PlayerState *)getCurrentPlayerState
{
    return [self.playerStates objectAtIndex:self.currentTurn];
}

// Returns true ifa player has won the game yet.
- (BOOL)hasAPlayerWonTheGame
{
    return (gameWinner != nil);
}

// Returns the state of the player that has won the game,
// or nil if no-one has won yet.
- (BOOL)usingSpecialRules
{
    return inSpecialRules;
}

- (BOOL)isGameInProgress
{
    return ![self hasAPlayerWonTheGame];
}

// Return the history array which contains the history items for the *current* round
- (NSArray *)history
{
    return history;
}

// Return an array of the history of *all* the rounds
- (NSArray *)roundHistory
{
    return rounds;
}

// Returns an array of the history objects relating to the
// last move made by the player with the playerID, or a
// empty array if that player hasn't played this turn.
- (NSArray *) lastMoveForPlayer:(NSInteger)playerID {
    NSMutableArray *mut = [NSMutableArray array];
    bool inPlayer = NO;
    for (NSInteger i = [history count] - 1; i >= 0; --i) {
        HistoryItem *item = [history objectAtIndex:i];
		PlayerState* playerLocal = item.player;
        int itemPlayerID = playerLocal.playerID;
        if (itemPlayerID == playerID) {
            inPlayer = YES;
            if (item.historyType != metaHistoryItem) {
                [mut addObject:item];
            }
        } else if (inPlayer) {
            break;
        }
    }
    return [NSArray arrayWithArray:mut];
}

// Return an array of the history of *all* of the rounds
// but in flat (instead of having to navigate till you get
// the right round then the history item its just bunch of
// history items in the order of 0 being the most recent and
// the last one the oldest
- (NSArray *)flatHistory
{
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (NSMutableArray *array in rounds) {
        if ([array isKindOfClass:[NSMutableArray class]]) {
            for (HistoryItem *item in array) {
                if ([item isKindOfClass:[HistoryItem class]]) {
                    [ret addObject:item];
                }
            }
        }
    }
    if (history)
    {
        for (HistoryItem *item in history) {
            if ([item isKindOfClass:[HistoryItem class]]) {
                [ret addObject:item];
            }
        }
    }
    NSRange range;
    range.location = 0;
    range.length = [ret count];
    return [ret subarrayWithRange:range];
}

// Last history item (useful shortcut function)
- (HistoryItem *)lastHistoryItem
{
    if (!history || [history count] == 0) {
        return nil;
    }
    if ([[history objectAtIndex:([history count] - 1)] isKindOfClass:[HistoryItem class]]) {
        return (HistoryItem *)[history objectAtIndex:([history count] - 1)];
    }
    return nil;
}

// PlayerStatus (Lost, Won, Playing) of a player via their playerID
- (PlayerStatus)playerStatus:(int)playerID
{
    PlayerState *player = [self getPlayerState:playerID];
    if ([player hasLost])
        return Lost;
    if ([self hasAPlayerWonTheGame])
        return Won;
    return Playing;
}

// Number of history items in the current round (number of turns taken this round)
- (NSInteger)historySize
{
    if (!history)
        return 0;
    return [history count];
}

- (NSInteger) getNumberOfPlayers:(BOOL)includeLostPlayers
{
    if (includeLostPlayers)
    {
        return [self.playerStates count];
    }
    int ret = 0;
    for (PlayerState *playerState in self.playerStates)
    {
        if (!playerState.hasLost)
        {
            ++ret;
        }
    }
    return ret;
}

// The current state in a readable text format
- (NSString *)stateString:(int)playerID
{
    NSMutableString *string = [NSMutableString string];
    [string appendString:[NSString stringWithFormat:@"%@'s turn\n", [[self getCurrentPlayer] getDisplayName]]];
    [string appendString:self.previousBid == nil ? @"No previous bid\n" : [NSString stringWithFormat:@"%@\n", [self.previousBid asString]]];
    int i = 0;
    for (PlayerState *player in self.playerStates) {
        if ([player isKindOfClass:[PlayerState class]]) {
            [string appendString:[player stateString:([player playerID] == playerID || playerID == -1)]];
            if ((i + 1) < [self.playerStates count])
            {
                [string appendString:@"\n"];
            }
            ++i;
        }
    }
    return string;
}

- (NSString *) historyText:(NSInteger)playerID
{
	return [[self historyText:playerID colorName:NO] string];
}

- (PlayerState*) playerStateForPlayerID:(NSInteger)playerID
{
	for (PlayerState* state in playerStates)
	{
		if ([state playerID] == playerID)
			return state;
	}

	return nil;
}

- (NSMutableAttributedString *) historyText:(NSInteger)playerID colorName:(BOOL)colorThePlayer {
    NSMutableAttributedString *labelText;
    // What playerID goes in this slot
    id <Player> player = [self getPlayerWithID:playerID];
    NSString *playerName = [player getDisplayName];
    NSArray *lastMove = [self lastMoveForPlayer:playerID];
    if ([lastMove count] == 0) {
        // This player hasn't bid yet.
        // Figure out what playerID goes in this slot.
		NSDictionary * attributes;

		if (colorThePlayer)
			attributes = [NSDictionary dictionaryWithObject:[UIColor redColor] forKey:NSForegroundColorAttributeName];
		else
			attributes = [NSDictionary dictionary];

		labelText = [[NSMutableAttributedString alloc] initWithString:playerName attributes:attributes];
    } else {
		labelText = [[NSMutableAttributedString alloc] init];

        for (NSInteger i = [lastMove count] - 1; i >= 0; --i) {
            HistoryItem *item = [lastMove objectAtIndex:i];

			NSDictionary * attributes;
			NSMutableAttributedString* move = [[NSMutableAttributedString alloc] init];

			NSArray *array = [[item asString] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];

			for (int j = 0;j < [array count];j++)
			{
				if (colorThePlayer && j == 0)
				{
					attributes = [NSDictionary dictionaryWithObject:[UIColor redColor] forKey:NSForegroundColorAttributeName];
				}
				else
					attributes = [NSDictionary dictionary];

				[move appendAttributedString:[[NSAttributedString alloc] initWithString:[array objectAtIndex:j] attributes:attributes] ];
				[move appendAttributedString:[[NSAttributedString alloc] initWithString:@" "] ];
			}

            [labelText appendAttributedString:move];
        }
    }

    return labelText;
}

- (NSString *)headerString:(int)playerIDorMinusOne singleLine:(BOOL)singleLine displayDiceCount:(BOOL)diceCount {
    int totalDice = [self countAllDice];
    int unknownDice = [self countUnknownDice:playerIDorMinusOne];
    NSString *conj = singleLine ? @".\nThere were " : @".\n";

    if (self.previousBid == nil)
        return [NSString stringWithFormat:@"No current bid%@%d dice, %d unknown.", conj, totalDice, unknownDice];

	DiceGame* localGame = self.game;
    NSString *previousBidPlayerName = [((id<Player>)[localGame.players objectAtIndex:self.previousBid.playerID]) getDisplayName];
    int bidDice = [self countSeenDice:playerIDorMinusOne rank:previousBid.rankOfDie];

	NSString* diceString = [NSString stringWithFormat:@"%d dice, ", totalDice];

	if (!diceCount)
		diceString = @"";

	if (didLeave)
		return [NSString stringWithFormat:@"Seed: %lu\n%@ quit", (unsigned long)localGame.randomGenerator->integerSeed, [[self getPlayerWithID:leavingPlayerID] getDisplayName]];

    if (playerIDorMinusOne < 0)
        return [NSString stringWithFormat:@"Seed: %lu, %@ bid %d %ds%@%@%d %ds.", (unsigned long)localGame.randomGenerator->integerSeed, previousBidPlayerName, previousBid.numberOfDice, previousBid.rankOfDie, conj, diceString, bidDice, previousBid.rankOfDie];

	return [NSString stringWithFormat:@"Seed: %lu, %@ bid %d %ds%@%@%d %ds, %d unknown.", (unsigned long)localGame.randomGenerator->integerSeed, previousBidPlayerName, previousBid.numberOfDice, previousBid.rankOfDie, conj, diceString, bidDice, previousBid.rankOfDie, unknownDice];
}

//Private Methods
- (void)createNewRound
{
	[self createNewRound:YES];
}

//Create a new round
- (void)createNewRound:(BOOL)newRound
{
	if ([NSThread isMainThread] && !canContinueGame)
	{
		[self performSelectorInBackground:@selector(createNewRound) withObject:nil];
		return;
	}

	DDLogVerbose(@"Created New Round");

    for (id <NewRoundListener> listener in theNewRoundListeners)
		[listener roundEnding];

	DiceGame* localGame = self.game;
	ApplicationDelegate* appDelegate = localGame.appDelegate;
	GameKitGameHandler* handler = [appDelegate.listener handlerForGame:localGame];
	if (newRound)
		localGame.newRound = YES;

	DiceRemotePlayer* next = nil;

	if (handler && ![[self playerStateForPlayerID:[[localGame localPlayer] getID]] hasLost])
		[handler saveMatchData];
	else if (handler && [[self playerStateForPlayerID:[[localGame localPlayer] getID]] hasLost] &&
			 [handler.match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID])
	{
		for (id<Player> player in localGame.players)
			if ([player isKindOfClass:DiceRemotePlayer.class] && ![[self playerStateForPlayerID:[player getID]] hasLost])
				next = player;

		if (next)
			[handler advanceToRemotePlayer:next];
	}

	while (!canContinueGame)
		sleep(1); //[[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];

	localGame.newRound = NO;
	inSpecialRules = NO;
	didLeave = NO;
	leavingPlayerID = 0;

	NSMutableArray* winners = [NSMutableArray array];
	NSMutableArray* loserAIs = [NSMutableArray array];

    for (PlayerState *player in self.playerStates) {
        [player isNewRound];

        if ([player isInSpecialRules] && playersLeft > 2)
            inSpecialRules = YES;

		if (![player hasLost] && handler && [[self playerStateForPlayerID:[[localGame localPlayer] getID]] hasLost] &&
			[handler.match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID] && !next)
		{
			NSNumber* stateID = [winners firstObject];

			if ([[self playerStateForPlayerID:[stateID intValue]] numberOfDice] < player.numberOfDice)
			{
				[loserAIs addObjectsFromArray:winners];
				[winners removeAllObjects];
				[winners addObject:[NSNumber numberWithInt:player.playerID]];
			}
			else if ([[self playerStateForPlayerID:[stateID intValue]] numberOfDice] == player.numberOfDice)
				[winners addObject:[NSNumber numberWithInt:player.playerID]];
			else
				[loserAIs addObject:[NSNumber numberWithInt:player.playerID]];
		}
    }

	if (winners.count > 1)
	{
		int winnerIndex = [localGame.randomGenerator randomNumber] % winners.count;

		for (int i = 0;i < winners.count;++i)
		{
			if (i == winnerIndex)
				continue;

			[loserAIs addObject:[winners objectAtIndex:i]];
			[winners removeObjectAtIndex:i];
			i--;
			winnerIndex--;
		}
	}

	for (NSNumber* loser in loserAIs)
	{
		PlayerState* state = [self playerStateForPlayerID:[loser intValue]];
		state.numberOfDice = 0;
		[self playerLosesGame:state.playerID];
	}

	self.previousBid = nil;
    if (history)
    {
        [rounds addObject:history];
        history = [[NSMutableArray alloc] init];
    }
    else
        history = [[NSMutableArray alloc] init];

    [history addObject:[[HistoryItem alloc] initWithMetaInformation:[NSString stringWithFormat:@"New Round"]] ];

	for (id <NewRoundListener> listener in theNewRoundListeners)
		[listener roundBeginning];

    [localGame notifyCurrentPlayer];
}

//Make a player lose the round (set the flags that they've lost)
- (void)playerLosesRound:(NSInteger)playerID
{
    [history addObject:[[HistoryItem alloc]
                         initWithMetaInformation:[self stateString:-1]]
                        ];
    DDLogVerbose(@"%@ lost the round.", [[self getPlayerState:playerID] asString]);
    DDLogVerbose(@"%@", [self stateString:-1]);
    PlayerState *player = [self getPlayerState:playerID];
    player.numberOfDice = player.numberOfDice - 1;
    DDLogVerbose(@"%@ has %i dice", [player playerName], [player numberOfDice]);

	if (player.numberOfDice == 0)
        [self playerLosesGame:playerID];
}

//Make a player lose the game (set the flags that they've lost the game)
- (void)playerLosesGame:(NSInteger)playerID
{
    [self.losers addObject:[NSNumber numberWithInt:[self getIndexOfPlayerWithId:playerID]]];
    DDLogVerbose(@"%@ lost the game.", [[self getPlayerState:playerID] asString]);
    PlayerState *player = [self getPlayerState:playerID];
    player.hasLost = YES;
	DiceGame* localGame = self.game;

	int causeID = -1;

	HistoryItem* lastItem = [self lastHistoryItem];

	switch ([lastItem actionType]) {
		case ACTION_CHALLENGE_BID:
		case ACTION_CHALLENGE_PASS:
			if ([lastItem value] == playerID)
			{
				PlayerState* lastItemState = [lastItem player];
				causeID = [lastItemState playerID];
				break;
			}
		case ACTION_EXACT:
		default:
			causeID = (int)playerID;
			break;
	}

	[history addObject:[[HistoryItem alloc] initWithState:self andWithPlayer:player whereTypeIs:ACTION_LOST withValue:causeID]];

	[[localGame getPlayerAtIndex:(int)playerID] notifyHasLost];
    --playersLeft;

    if (playersLeft <= 1)
    {
		[self goToNextPlayerWhoHasntLost];

		gameWinner = [self getCurrentPlayer];
        DDLogVerbose(@"%@ won!", [gameWinner getGameCenterName]);
    }
}

// Check a bid to make sure it is valid
- (BOOL)checkBid:(Bid *)bid playerSpecialRules:(BOOL)playerSpecialRules
{
    // Sanity Check
    if (bid.playerID != [self getCurrentPlayerState].playerID ||
        bid.rankOfDie < 1 ||
        bid.rankOfDie > 6 ||
        bid.numberOfDice < 1) {
        return NO;
    }
	
	if ([[bid diceToPush] count] >= [[self getCurrentPlayerState] numberOfDice])
		return NO;
    
    //Check if there is a previous bid, otherwise the bid is automatically valid
    if (!self.previousBid)
		return YES;
    
    //Make sure the bid is a legal raise over the previous bid
    if (![bid isLegalRaise:self.previousBid specialRules:[self usingSpecialRules] playerSpecialRules:playerSpecialRules])
        return NO;
	
    return YES;
}

// Return true if playerID is the current player id.
- (BOOL)checkPlayer:(NSInteger)playerID
{
    return [[self.players objectAtIndex:self.currentTurn] getID] == playerID;
}

// Advance until the current turn is of a player who hasn't lost
- (void)goToNextPlayerWhoHasntLost
{
	while ([[self.playerStates objectAtIndex:self.currentTurn] hasLost])
	{
		self.currentTurn = (self.currentTurn + 1) % [self.playerStates count];
	}
}

// Get a player's PlayerState by their playerID
- (PlayerState *) getPlayerState:(NSInteger)playerID
{
    for (PlayerState *state in self.playerStates)
    {
        if (state.playerID == playerID) return state;
    }
    return nil;
}

// Goto the next turn
- (void)moveToNextTurn
{
    //Set the currentTurn to the next player to make sure the next turn isn't same player
    self.currentTurn = (self.currentTurn + 1) % [self.playerStates count];
    //Goto the next player Who hasn't lost
    [self goToNextPlayerWhoHasntLost];
}

- (int)countKnownDice:(int)rankOfDice inArray:(NSArray *)arrayToCountIn
{
	int totalCount = 0;
	for (Die *die in arrayToCountIn)
	{
		if ([die isKindOfClass:[Die class]])
		{
			if ([die dieValue] == rankOfDice || (!inSpecialRules && [die dieValue] == 1))
				++totalCount;
		}
	}
	return totalCount;
}

// Get the total number of dice with a given face value (used for exacts)
- (int)countDice:(int)rankOfDice
{
    int totalCount = 0;
    for (PlayerState *player in self.playerStates)
    {
        if ([player isKindOfClass:[PlayerState class]])
        {
            for (Die *die in [player arrayOfDice])
            {
                if ([die isKindOfClass:[Die class]])
                {
                    if ([die dieValue] == rankOfDice || (!inSpecialRules && [die dieValue] == 1))
                        ++totalCount;
                }
            }
        }
    }
    return totalCount;
}

// Gets the total number of dice of the given face, as seen by the given player.
- (int)countSeenDice:(NSInteger)playerIDorMinusOne rank:(int)rank {
    int ret = 0;
    for (PlayerState *playerState in playerStates) {
        for (Die *die in playerState.arrayOfDice) {
            if (playerState.playerID == playerIDorMinusOne || die.hasBeenPushed || playerIDorMinusOne < 0) {
                if (die.dieValue == rank) {
                    ++ret;
                } else if (!inSpecialRules && die.dieValue == 1) {
                    ++ret;
                }
            }
        }
    }
    return ret;
}

// Gets the number of dice that are invisible to the given player
- (int)countUnknownDice:(NSInteger)playerIDorMinusOne {
    int ret = 0;
    for (PlayerState *playerState in playerStates) {
        for (Die *die in playerState.arrayOfDice) {
            if (!(playerState.playerID == playerIDorMinusOne || die.hasBeenPushed)) {
                ++ret;
            }
        }
    }
    return ret;
}

// Gets the total number of dice in the game
- (int)countAllDice {
    int ret = 0;
    DDLogVerbose(@"Count all dice");
    for (PlayerState *playerState in playerStates) {
        ret += [playerState.arrayOfDice count];
    }
    return ret;
}

// Is the input'd bid valid?
- (BOOL)isBidCorrect:(Bid *)bid
{
    if (([self countDice:[bid rankOfDie]]) >= [bid numberOfDice])
        return YES;
    return NO;
}

// Get the playerID of the person who last passed however if they didn't pass last turn it will return -1.  Basically a check to see whether the last player passed and if so what was their playerID
- (NSInteger)lastPassPlayerID
{
	HistoryItem* item = [self lastHistoryItem];

	if (item.actionType != ACTION_PASS)
		item = nil;

    if (item == nil && [history count] >= 2)
	{
		if (((HistoryItem*)[history objectAtIndex:[history count] - 1]).actionType == ACTION_PUSH &&
			((HistoryItem*)[history objectAtIndex:[history count] - 2]).actionType == ACTION_PASS)
		{
			item = [history objectAtIndex:[history count] - 2];
		}
	}

	if (item != nil)
	{
		PlayerState* localPlayer = item.player;
		return [localPlayer playerID];
	}
	else
		return -1;
}

// Get the playerID of the player who passed two turns ago.
- (NSInteger)secondLastPassPlayerID
{
    if ([self lastPassPlayerID] == -1)
        return -1;
	
    if (history == nil || [history count] < 2)
        return -1;
    
    HistoryItem* item = nil;

    if (item == nil && [history count] >= 2)
	{
		if (((HistoryItem*)[history objectAtIndex:[history count] - 1]).actionType == ACTION_PASS &&
			((HistoryItem*)[history objectAtIndex:[history count] - 2]).actionType == ACTION_PASS)
		{
			item = [history objectAtIndex:[history count] - 2];
		}
	}

	if (item == nil && [history count] >= 3)
	{
		if ((((HistoryItem*)[history objectAtIndex:[history count] - 1]).actionType == ACTION_PUSH &&
			 ((HistoryItem*)[history objectAtIndex:[history count] - 2]).actionType == ACTION_PASS &&
			 ((HistoryItem*)[history objectAtIndex:[history count] - 3]).actionType == ACTION_PASS) ||

			(((HistoryItem*)[history objectAtIndex:[history count] - 1]).actionType == ACTION_PASS &&
			 ((HistoryItem*)[history objectAtIndex:[history count] - 2]).actionType == ACTION_PUSH &&
			 ((HistoryItem*)[history objectAtIndex:[history count] - 3]).actionType == ACTION_PASS))
		{
			item = [history objectAtIndex:[history count] - 3];
		}
	}

	if (item == nil && [history count] >= 4)
	{
		if (((HistoryItem*)[history objectAtIndex:[history count] - 1]).actionType == ACTION_PUSH &&
			((HistoryItem*)[history objectAtIndex:[history count] - 2]).actionType == ACTION_PASS &&
			((HistoryItem*)[history objectAtIndex:[history count] - 3]).actionType == ACTION_PUSH &&
			((HistoryItem*)[history objectAtIndex:[history count] - 4]).actionType == ACTION_PASS)
		{
			item = [history objectAtIndex:[history count] - 4];
		}
	}

	if (item != nil)
	{
		PlayerState* localPlayer = item.player;

		return [localPlayer playerID];
	}
	else
		return -1;
}

- (NSArray *)playersWhoHaveLost
{
    NSMutableArray *playersWhoHaveLost = [[NSMutableArray alloc] init];
    
    for (PlayerState *player in self.playerStates)
    {
        if ([player isKindOfClass:[PlayerState class]])
        {
            if ([player hasLost])
            {
                NSNumber *number = [NSNumber numberWithInt:[player playerID]];
                [playersWhoHaveLost addObject:number];
            }
        }
    }
    
    NSArray *array = [[NSArray alloc] initWithArray:playersWhoHaveLost];
    return array;
}

- (int) getIndexOfPlayerWithId:(NSInteger)playerID
{
    for (int i = 0; i < [playerStates count]; ++i)
    {
        if (((PlayerState *)[self.playerStates objectAtIndex:i]).playerID == playerID)
        {
            return i;
        }
    }
    return -1;
}

- (id<Player>) gameWinner
{
	if ([self->gameWinner isKindOfClass:NSString.class])
	{
		for (id<Player> player in self.players)
			if ([[player getGameCenterName] isEqualToString:(NSString*)self->gameWinner])
			{
				self->gameWinner = player;
				break;
			}
	}

	return self->gameWinner;
}

@end
