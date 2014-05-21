//
//  HistoryItem.m
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "HistoryItem.h"


@implementation HistoryItem

@synthesize player, actionType, historyType, value, result, diceGameState;
@synthesize bid, state;

// Initialize ourself
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer whereTypeIs:(ActionType)newType withValue:(int)newValue andResult:(int)newResult
{
    self = [super init];
    if (self) {
        self.diceGameState = gameState;
        self.player = newPlayer;
        self.actionType = newType;
        self.value = newValue;
        self.result = newResult;
        self.state = [gameState stateString:-1];
        playerLosingADie = -1;
        playerWinningADie = -1;
    }
    return self;
}

-(id)initWithCoder:(NSCoder*)decoder withCount:(int)count withGameState:(DiceGameState*)gameState
{
	self = [super init];

    if (self)
	{
        self.diceGameState = gameState;

		int playerID = [decoder decodeIntForKey:[NSString stringWithFormat:@"HistoryItem%i:player", count]];
		self.player = [gameState playerStateForPlayerID:playerID];

		self.actionType = (ActionType)[decoder decodeIntForKey:[NSString stringWithFormat:@"HistoryItem%i:actionType", count]];
		self.value = [decoder decodeIntForKey:[NSString stringWithFormat:@"HistoryItem%i:value", count]];
		self.result = [decoder decodeIntForKey:[NSString stringWithFormat:@"HistoryItem%i:result", count]];
		self.state = [decoder decodeObjectForKey:[NSString stringWithFormat:@"HistoryItem%i:state", count]];
		playerLosingADie = [decoder decodeInt64ForKey:[NSString stringWithFormat:@"HistoryItem%i:playerLosingADie", count]];
		playerWinningADie = [decoder decodeInt64ForKey:[NSString stringWithFormat:@"HistoryItem%i:playerWinningADie", count]];
    }

    return self;

}

-(void)encodeWithCoder:(NSCoder*)encoder withCount:(int)count
{
	PlayerState* playerLocal = self.player;
	[encoder encodeInt:playerLocal.playerID forKey:[NSString stringWithFormat:@"HistoryItem%i:player", count]];
	[encoder encodeInt:self.actionType forKey:[NSString stringWithFormat:@"HistoryItem%i:actionType", count]];
	[encoder encodeInt:self.value forKey:[NSString stringWithFormat:@"HistoryItem%i:value", count]];
	[encoder encodeInt:self.result forKey:[NSString stringWithFormat:@"HistoryItem%i:result", count]];
	[encoder encodeObject:self.state forKey:[NSString stringWithFormat:@"HistoryItem%i:state", count]];
	[encoder encodeInt64:playerLosingADie forKey:[NSString stringWithFormat:@"HistoryItem%i:playerLosingADie", count]];
	[encoder encodeInt64:playerWinningADie forKey:[NSString stringWithFormat:@"HistoryItem%i:playerWinningADie", count]];
}

- (id) initWithMetaInformation:(NSString *)meta
{
    if (!((self = [super init])))
    {
        return nil;
    }
    self.state = meta;
    self.historyType = metaHistoryItem;
    return self;
}

- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer whereTypeIs:(ActionType)newType withValue:(int)newValue
{
    return [self initWithState:gameState andWithPlayer:newPlayer whereTypeIs:newType withValue:newValue andResult:newValue];
}

- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer whereTypeIs:(ActionType)newType
{
    return [self initWithState:gameState andWithPlayer:newPlayer whereTypeIs:newType withValue:-1 andResult:-1];
}

//Initialize ourself with specialized information
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer withBid:(Bid *)newBid
{
    self = [self initWithState:gameState andWithPlayer:newPlayer whereTypeIs:ACTION_BID];

	if (self)
        self.bid = newBid;

    return self;
}

//Initialize ourself with specialized information
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer withBid:(Bid *)newBid andWithResult:(int)newResult
{
    self = [self initWithState:gameState andWithPlayer:newPlayer whereTypeIs:ACTION_EXACT withValue:-1 andResult:result];

	if (self)
        self.bid = newBid;

	return self;
}

//Set the losing playerID if someone lost this turn
- (void)setLosingPlayer:(NSInteger)playerID
{
    playerLosingADie = playerID;
}

//Set the winnign playerID if someone lost this turn
- (void)setWinningPlayer:(NSInteger)playerID
{
    playerWinningADie = playerID;
}

//Ourself as a human readable string
- (NSString *)asString
{
	PlayerState* playerLocal = self.player;
	DiceGameState* gameStateLocal = self.diceGameState;

    NSString *first = nil;
    NSString *playerName = playerLocal.playerName;
    NSString *second = nil;
    if (self.historyType == actionHistoryItem)
    {
        switch (self.actionType) {
            case ACTION_ACCEPT:
                first = [NSString stringWithFormat:@"%@ accepted.", playerName];
                break;
            case ACTION_BID:
                first = [self.bid asStringOldStyle];
                break;
            case ACTION_PUSH:
                first = [NSString stringWithFormat:@", pushed."];
                break;
            case ACTION_CHALLENGE_BID:
			{
				NSString *valueName = [gameStateLocal getPlayerState:value].playerName;
                first = [NSString stringWithFormat:@"%@ challenged %@'s bid.", playerName, valueName];
                break;
			}
            case ACTION_CHALLENGE_PASS:
            {
				NSString *valueName = [gameStateLocal getPlayerState:value].playerName;
                first = [NSString stringWithFormat:@"%@ challenged %@'s pass.", playerName, valueName];
                break;
            }
            case ACTION_EXACT:
                first = [NSString stringWithFormat:@"%@ exacted.", playerName];
                break;
            case ACTION_PASS:
                first = [NSString stringWithFormat:@"%@ passed", playerName];
                break;
            case ACTION_ILLEGAL:
                first = [NSString stringWithFormat:@"%@ made illegal move.", playerName];
                break;
			case ACTION_QUIT:
			default:
			{
				NSLog(@"Impossible Situation? HistoryItem.m:128");
				break;
			}
        }

        if (playerLosingADie != -1) {
            NSString *valueName = [gameStateLocal getPlayerState:playerLosingADie].playerName;
            second = [NSString stringWithFormat:@"%@ lost a die.", valueName];
        } else if (playerWinningADie != -1) {
            NSString *valueName = [gameStateLocal getPlayerState:playerWinningADie].playerName;
            second = [NSString stringWithFormat:@"%@ won a die.", valueName];
        }
        
    }
    else
    {
        first = self.state;
    }
    if (second == nil)
    {
        return first;
    }
    return [first stringByAppendingString:[@"\n" stringByAppendingString:second]];
}

- (NSString *)asDetailedString
{
	PlayerState* playerLocal = self.player;
	DiceGameState* gameStateLocal = self.diceGameState;

    NSString *first = nil;
    NSString *playerName = playerLocal.playerName;
    NSString *second = nil;
    if (self.historyType == actionHistoryItem)
    {
        switch (self.actionType) {
            case ACTION_ACCEPT:
                first = [NSString stringWithFormat:@"%@ accepted", playerName];
                break;
            case ACTION_BID:
                first = [self.bid asString];
                break;
            case ACTION_PUSH:
                first = [NSString stringWithFormat:@"%@ pushed", playerName];
                break;
            case ACTION_CHALLENGE_BID:
                first = [NSString stringWithFormat:@"%@ challenged bid (%@), result %i", playerName, [self.bid asString], result];
                break;
            case ACTION_CHALLENGE_PASS:
            {
                NSString *valueName = [gameStateLocal getPlayerState:value].playerName;
                first = [NSString stringWithFormat:@"%@ challenged %@'s pass, result %i", playerName, valueName, result];
                break;
            }
            case ACTION_EXACT:
                first = [NSString stringWithFormat:@"%@ exacted (%@), result %i", playerName, [self.bid asString], result];
                break;
            case ACTION_PASS:
                first = [NSString stringWithFormat:@"%@ passed", playerName];
                break;
            case ACTION_ILLEGAL:
                first = [NSString stringWithFormat:@"%@ made an illegal move", playerName];
                break;
			case ACTION_QUIT:
			default:
			{
				NSLog(@"Impossible Situation? HistoryItem.m:128");
				break;
			}
        }
        if (playerLosingADie != -1) {
            NSString *valueName = [gameStateLocal getPlayerState:playerLosingADie].playerName;
            second = [NSString stringWithFormat:@"%@ lost a die.", valueName];
        } else if (playerWinningADie != -1) {
            NSString *valueName = [gameStateLocal getPlayerState:playerWinningADie].playerName;
            second = [NSString stringWithFormat:@"%@ won a die.", valueName];
        }
        
    }
    else
    {
        first = self.state;
    }
    if (second == nil)
    {
        return first;
    }
    return [first stringByAppendingString:[@"\n" stringByAppendingString:second]];
}

@end
