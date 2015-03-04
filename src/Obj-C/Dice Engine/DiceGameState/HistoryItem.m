//
//  HistoryItem.m
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "HistoryItem.h"
#import "Die.h"
#import "PlayGameView.h"

@implementation HistoryItem

@synthesize player, actionType, historyType, value, result, diceGameState;
@synthesize bid, state, dice;
@synthesize timestamp;

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
		
		self.timestamp = [NSDate date];
    }
    return self;
}

-(id)initWithCoder:(NSCoder*)decoder withCount:(int)count withGameState:(DiceGameState*)gameState
{
	return [self initWithCoder:decoder withCount:count withGameState:gameState withPrefix:@"HistoryItem"];
}

-(id)initWithCoder:(NSCoder*)decoder withCount:(int)count withGameState:(DiceGameState*)gameState withPrefix:(NSString*)prefix
{
	self = [super init];

    if (self)
	{
        self.diceGameState = gameState;

		playerIDDecode = [decoder decodeIntForKey:[NSString stringWithFormat:@"%@%i:player", prefix, count]];

		self.actionType = (ActionType)[decoder decodeIntForKey:[NSString stringWithFormat:@"%@%i:actionType", prefix, count]];
		self.value = [decoder decodeIntForKey:[NSString stringWithFormat:@"%@%i:value", prefix, count]];
		self.result = [decoder decodeIntForKey:[NSString stringWithFormat:@"%@%i:result", prefix, count]];
		self.state = [decoder decodeObjectForKey:[NSString stringWithFormat:@"%@%i:state", prefix, count]];
		playerLosingADie = [decoder decodeInt64ForKey:[NSString stringWithFormat:@"%@%i:playerLosingADie", prefix, count]];
		playerWinningADie = [decoder decodeInt64ForKey:[NSString stringWithFormat:@"%@%i:playerWinningADie", prefix, count]];
		
		self.historyType = (HistoryItemType)[decoder decodeIntForKey:[NSString stringWithFormat:@"%@%i:historyType", prefix, count]];

		self.diceGameState = gameState;
		self.bid = [decoder decodeObjectForKey:[NSString stringWithFormat:@"%@%i:bid", prefix, count]];
		self.dice = [decoder decodeObjectForKey:[NSString stringWithFormat:@"%@%i:dice", prefix, count]];
		
		NSMutableArray* diceMutable = [[NSMutableArray alloc] init];
		int countOfDice = [decoder decodeIntForKey:[NSString stringWithFormat:@"%@%i:dice", prefix, count]];
		
		for (int i = 0;i < countOfDice;++i)
			[diceMutable addObject:[[Die alloc] initWithCoder:decoder withCount:i withPrefix:[NSString stringWithFormat:@"HistoryItem%@%i:", prefix, count]]];
		self.dice = diceMutable;
		
		self.timestamp = [decoder decodeObjectForKey:[NSString stringWithFormat:@"%@%i:timestamp", prefix, count]];
    }

    return self;
}

- (void)canDecodePlayer
{
	DiceGameState* gameState = self.diceGameState;
	self.player = [gameState playerStateForPlayerID:playerIDDecode];
}

-(void)encodeWithCoder:(NSCoder*)encoder withCount:(int)count
{
	[self encodeWithCoder:encoder withCount:count withPrefix:@"HistoryItem"];
}

-(void)encodeWithCoder:(NSCoder*)encoder withCount:(int)count withPrefix:(NSString*)prefix
{
	PlayerState* playerLocal = self.player;
	[encoder encodeInt:(playerLocal ? playerLocal.playerID : -1) forKey:[NSString stringWithFormat:@"%@%i:player", prefix, count]];
	[encoder encodeInt:self.actionType forKey:[NSString stringWithFormat:@"%@%i:actionType", prefix, count]];
	[encoder encodeInt:self.value forKey:[NSString stringWithFormat:@"%@%i:value", prefix, count]];
	[encoder encodeInt:self.result forKey:[NSString stringWithFormat:@"%@%i:result", prefix, count]];
	[encoder encodeObject:self.state forKey:[NSString stringWithFormat:@"%@%i:state", prefix, count]];
	[encoder encodeInt64:playerLosingADie forKey:[NSString stringWithFormat:@"%@%i:playerLosingADie", prefix, count]];
	[encoder encodeInt64:playerWinningADie forKey:[NSString stringWithFormat:@"%@%i:playerWinningADie", prefix, count]];

	[encoder encodeInt:historyType forKey:[NSString stringWithFormat:@"%@%i:historyType", prefix, count]];
	[encoder encodeObject:bid forKey:[NSString stringWithFormat:@"%@%i:bid", prefix, count]];
	
	[encoder encodeInt:(int)[dice count] forKey:[NSString stringWithFormat:@"%@%i:dice", prefix, count]];
	
	for (int i = 0;i < [dice count];i++)
		[((Die*)[dice objectAtIndex:i]) encodeWithCoder:encoder withCount:i withPrefix:[NSString stringWithFormat:@"HistoryItem%@%i:", prefix, count]];
	
	[encoder encodeObject:self.timestamp forKey:[NSString stringWithFormat:@"%@%i:timestamp", prefix, count]];
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

- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer whereTypeIs:(ActionType)newType withDice:(NSArray*)dicePushed;
{
	self.dice = dicePushed;
	
    return [self initWithState:gameState andWithPlayer:newPlayer whereTypeIs:newType withValue:-1 andResult:-1];
}

//Initialize ourself with specialized information
- (id)initWithState:(DiceGameState *)gameState andWithPlayer:(PlayerState *)newPlayer withBid:(Bid *)newBid
{
    self = [self initWithState:gameState andWithPlayer:newPlayer whereTypeIs:ACTION_BID withDice:nil];

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

    NSString *first = @"";
    NSString *playerName = [((id<Player>)[gameStateLocal.players objectAtIndex:playerLocal.playerID]) getDisplayName];
    NSString *second = nil;
    if (self.historyType == actionHistoryItem)
    {
        switch (self.actionType) {
            case ACTION_ACCEPT:
                first = [NSString stringWithFormat:@"%@ accepted", playerName];
                break;
            case ACTION_BID:
				[self.bid setPlayerName:playerName];
                first = [self.bid asStringOldStyle];
				[self.bid setPlayerName:playerLocal.playerName];
                break;
            case ACTION_PUSH:
                first = [NSString stringWithFormat:@", pushed"];
                break;
            case ACTION_CHALLENGE_BID:
			{
				NSString *valueName = [((id<Player>)[gameStateLocal.players objectAtIndex:value]) getDisplayName];

				if ([valueName isEqualToString:@"You"])
					valueName = @"your";
				else
					valueName = [valueName stringByAppendingString:@"'s"];

                first = [NSString stringWithFormat:@"%@ challenged %@ bid", playerName, valueName];
                break;
			}
            case ACTION_CHALLENGE_PASS:
            {
				NSString *valueName = [((id<Player>)[gameStateLocal.players objectAtIndex:value]) getDisplayName];

				if ([valueName isEqualToString:@"You"])
					valueName = @"your";
				else
					valueName = [valueName stringByAppendingString:@"'s"];

                first = [NSString stringWithFormat:@"%@ challenged %@ pass", playerName, valueName];
                break;
            }
            case ACTION_EXACT:
                first = [NSString stringWithFormat:@"%@ exacted", playerName];
                break;
            case ACTION_PASS:
                first = [NSString stringWithFormat:@"%@ passed", playerName];
                break;
            case ACTION_ILLEGAL:
                first = [NSString stringWithFormat:@"%@ made illegal move", playerName];
                break;
			case ACTION_QUIT:
				first = [NSString stringWithFormat:@"%@ quit", playerName];
				break;
			case ACTION_LOST:
				break;
			default:
			{
				DDLogError(@"Impossible Situation? HistoryItem.m:207");
				break;
			}
        }

        if (playerLosingADie != -1) {
            NSString *valueName = [((id<Player>)[gameStateLocal.players objectAtIndex:playerLosingADie]) getDisplayName];
            second = [NSString stringWithFormat:@"%@ lost a die", valueName];
        } else if (playerWinningADie != -1) {
            NSString *valueName = [((id<Player>)[gameStateLocal.players objectAtIndex:playerWinningADie]) getDisplayName];
            second = [NSString stringWithFormat:@"%@ won a die", valueName];
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

    NSString *first = @"";
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
				first = [NSString stringWithFormat:@"%@ quit", playerName];
				break;
			case ACTION_LOST:
				break;
			default:
			{
				DDLogError(@"Impossible Situation? HistoryItem.m:274");
				break;
			}
        }
        if (playerLosingADie != -1) {
            NSString *valueName = [gameStateLocal getPlayerState:playerLosingADie].playerName;
            second = [NSString stringWithFormat:@"%@ lost a die", valueName];
        } else if (playerWinningADie != -1) {
            NSString *valueName = [gameStateLocal getPlayerState:playerWinningADie].playerName;
            second = [NSString stringWithFormat:@"%@ won a die", valueName];
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

- (NSString*)description
{
	return [self asString];
}

- (NSString*)debugDescription
{
	return [self asDetailedString];
}

- (PlayerState*)player
{
	DiceGameState* gameState = self.diceGameState;
	PlayerState* playerState = player;
	if (!playerState && gameState.players)
		[self canDecodePlayer];

	playerState = player;
	return playerState;
}

- (NSString*)accessibleText
{
	PlayerState* playerLocal = self.player;
	DiceGameState* gameStateLocal = self.diceGameState;
	
	NSString* historyString = nil;
	NSString *playerName = [((id<Player>)[gameStateLocal.players objectAtIndex:playerLocal.playerID]) getDisplayName];
	
	if (self.historyType == actionHistoryItem)
	{
		switch (self.actionType) {
			case ACTION_BID:
				[self.bid setPlayerName:playerName];
				historyString = [self.bid asString];
				[self.bid setPlayerName:playerLocal.playerName];
				break;
			case ACTION_PUSH:
				historyString = [NSString stringWithFormat:@"%@ pushed dice: ", playerName];
				
				for (Die* die in dice)
					historyString = [historyString stringByAppendingFormat:@" %i", die.dieValue];
				
				break;
			case ACTION_CHALLENGE_BID:
			{
				NSString *valueName = [((id<Player>)[gameStateLocal.players objectAtIndex:value]) getDisplayName];
				
				if ([valueName isEqualToString:@"You"])
					valueName = @"your";
				else
					valueName = [valueName stringByAppendingString:@"'s"];
				
				historyString = [NSString stringWithFormat:@"%@ challenged %@ bid; %@ %@", playerName, valueName, playerName, result == 1 ? @"won" : @"lost"];
				break;
			}
			case ACTION_CHALLENGE_PASS:
			{
				NSString *valueName = [((id<Player>)[gameStateLocal.players objectAtIndex:value]) getDisplayName];
				
				if ([valueName isEqualToString:@"You"])
					valueName = @"your";
				else
					valueName = [valueName stringByAppendingString:@"'s"];
				
				historyString = [NSString stringWithFormat:@"%@ challenged %@ pass; %@ %@", playerName, valueName, playerName, result == 1 ? @"won" : @"lost"];
				break;
			}
			case ACTION_EXACT:
				historyString = [NSString stringWithFormat:@"%@ exacted; they were %@", playerName, result == 1 ? @"correct" : @"incorrect"];
				break;
			case ACTION_PASS:
				historyString = [NSString stringWithFormat:@"%@ passed", playerName];
				break;
			case ACTION_ILLEGAL:
				break;
			case ACTION_QUIT:
				historyString = [NSString stringWithFormat:@"%@ quit", playerName];
				break;
			case ACTION_LOST:
				historyString = [NSString stringWithFormat:@"%@ lost", playerName];
				break;
			case ACTION_ACCEPT:
			default:
				break;
		}
	}
	
	return historyString;
}

- (NSAttributedString *)asHistoryString
{
	PlayerState* playerLocal = self.player;
	DiceGameState* gameStateLocal = self.diceGameState;
	
	NSAttributedString* historyString = nil;
	NSString *playerName = [((id<Player>)[gameStateLocal.players objectAtIndex:playerLocal.playerID]) getDisplayName];
	
	if (self.historyType == actionHistoryItem)
	{
		switch (self.actionType) {
			case ACTION_BID:
				[self.bid setPlayerName:playerName];
				historyString = [[NSAttributedString alloc] initWithString:[self.bid asStringOldStyle] attributes:nil];
				historyString = [PlayGameView formatTextAttributedString:historyString];
				[self.bid setPlayerName:playerLocal.playerName];
				break;
			case ACTION_PUSH:
				historyString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ pushed dice ", playerName]];
				
				for (Die* die in dice)
				{
					NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
					attachment.image = [PlayGameView imageForDie:die.dieValue];
					[attachment setBounds:CGRectMake(0, -5, 21, 21)];
					
					NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
					
					[(NSMutableAttributedString*)historyString appendAttributedString:attachmentString];
					[(NSMutableAttributedString*)historyString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
				}
				
				break;
			case ACTION_CHALLENGE_BID:
			{
				NSString *valueName = [((id<Player>)[gameStateLocal.players objectAtIndex:value]) getDisplayName];
				
				if ([valueName isEqualToString:@"You"])
					valueName = @"your";
				else
					valueName = [valueName stringByAppendingString:@"'s"];
				
				historyString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ challenged %@ bid; %@ %@", playerName, valueName, playerName, result == 1 ? @"won" : @"lost"]];
				break;
			}
			case ACTION_CHALLENGE_PASS:
			{
				NSString *valueName = [((id<Player>)[gameStateLocal.players objectAtIndex:value]) getDisplayName];
				
				if ([valueName isEqualToString:@"You"])
					valueName = @"your";
				else
					valueName = [valueName stringByAppendingString:@"'s"];
				
				historyString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ challenged %@ pass; %@ %@", playerName, valueName, playerName, result == 1 ? @"won" : @"lost"]];
				break;
			}
			case ACTION_EXACT:
				historyString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ exacted; they were %@", playerName, result == 1 ? @"correct" : @"incorrect"]];
				break;
			case ACTION_PASS:
				historyString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ passed", playerName]];
				break;
			case ACTION_ILLEGAL:
				break;
			case ACTION_QUIT:
				historyString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ quit", playerName]];
				break;
			case ACTION_LOST:
				historyString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ lost", playerName]];
				break;
			case ACTION_ACCEPT:
			default:
				break;
		}
	}
	
	NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:historyString];
	[attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, historyString.length)];
	
	return attributedString;
}

@end
