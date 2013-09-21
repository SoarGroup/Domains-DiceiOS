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
        self.state = [diceGameState stateString:-1];
        playerLosingADie = -1;
        playerWinningADie = -1;
    }
    return self;
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

- (void)dealloc
{
    [super dealloc];
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
    [self initWithState:gameState andWithPlayer:newPlayer whereTypeIs:ACTION_BID];
    if (self)
        self.bid = newBid;
    return self;
}

//Initialize ourself with specialized information
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer withBid:(Bid *)newBid andWithResult:(int)newResult
{
    [self initWithState:gameState andWithPlayer:newPlayer whereTypeIs:ACTION_EXACT withValue:-1 andResult:result];
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
    NSString *first = nil;
    NSString *playerName = self.player.playerName;
    NSString *second = nil;
    if (self.historyType == actionHistoryItem)
    {
        switch (self.actionType) {
            case ACTION_ACCEPT:
                first = [NSString stringWithFormat:@"%@ accepted.", playerName];
                break;
            case ACTION_BID:
                first = [self.bid asString];
                break;
            case ACTION_PUSH:
                first = [NSString stringWithFormat:@", pushed."];
                break;
            case ACTION_CHALLENGE_BID:
			{
				NSString *valueName = [self.diceGameState getPlayerState:value].playerName;
                first = [NSString stringWithFormat:@"%@ challenged %@'s bid.", playerName, valueName];
                break;
			}
            case ACTION_CHALLENGE_PASS:
            {
				NSString *valueName = [self.diceGameState getPlayerState:value].playerName;
                first = [NSString stringWithFormat:@"%@ challenged %@'s pass.", playerName, valueName];
                break;
            }
            case ACTION_EXACT:
                first = [NSString stringWithFormat:@"%@ exacted.", playerName];
                break;
            case ACTION_PASS:
                first = [NSString stringWithFormat:@"%@ passed.", playerName];
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
            NSString *valueName = [self.diceGameState getPlayerState:playerLosingADie].playerName;
            second = [NSString stringWithFormat:@"%@ lost a die.", valueName];
        } else if (playerWinningADie != -1) {
            NSString *valueName = [self.diceGameState getPlayerState:playerWinningADie].playerName;
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
    NSString *first = nil;
    NSString *playerName = self.player.playerName;
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
                NSString *valueName = [self.diceGameState getPlayerState:value].playerName;
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
            NSString *valueName = [self.diceGameState getPlayerState:playerLosingADie].playerName;
            second = [NSString stringWithFormat:@"%@ lost a die.", valueName];
        } else if (playerWinningADie != -1) {
            NSString *valueName = [self.diceGameState getPlayerState:playerWinningADie].playerName;
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
