//
//  DiceAction.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceAction.h"
#import "Die.h"

@implementation DiceAction

@synthesize actionType, playerID, count, face, push, targetID;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (DiceAction *) bidAction:(NSInteger)playerID count:(int)count face:(int)face push:(NSArray *)push {
    DiceAction *ret = [[DiceAction alloc] init];
    ret.actionType = ACTION_BID;
    ret.playerID = playerID;
    ret.count = count;
    ret.face = face;
    ret.push = push;
    return ret;
}

+ (DiceAction *) challengeAction:(NSInteger)playerID target:(NSInteger)targetId {
    DiceAction *ret = [[DiceAction alloc] init];
    ret.actionType = ACTION_CHALLENGE_BID; // TODO test for bid / pass challenge?
    ret.playerID = playerID;
    ret.targetID = targetId;
    return ret;
}

+ (DiceAction *) exactAction:(NSInteger)playerID {
    DiceAction *ret = [[DiceAction alloc] init];
    ret.actionType = ACTION_EXACT;
    ret.playerID = playerID;
    return ret;
}

+ (DiceAction *) passAction:(NSInteger)playerID push:(NSArray*)push {
    DiceAction *ret = [[DiceAction alloc] init];
    ret.actionType = ACTION_PASS;
    ret.playerID = playerID;
    ret.push = push;
    return ret;
}

+ (DiceAction *) acceptAction:(NSInteger)playerID {
    DiceAction *ret = [[DiceAction alloc] init];
    ret.actionType = ACTION_ACCEPT;
    ret.playerID = playerID;
    return ret;
}

+ (DiceAction *) pushAction:(NSInteger)playerID push:(NSArray *)push {
    DiceAction *ret = [[DiceAction alloc] init];
    ret.actionType = ACTION_PUSH;
    ret.playerID = playerID;
    ret.push = push;
    return ret;
}

+ (DiceAction *) lost:(NSInteger)playerID
{
	DiceAction *ret = [[DiceAction alloc] init];
	ret.actionType = ACTION_LOST;
	ret.playerID = playerID;
	return ret;
}

+ (NSString*) actionTypeToString:(ActionType)formatType
{
	NSString *result = nil;

	switch(formatType) {
		case ACTION_ACCEPT:
			result = @"ACTION_ACCEPT";
			break;
		case ACTION_BID:
			result = @"ACTION_BID";
			break;
		case ACTION_PUSH:
			result = @"ACTION_PUSH";
			break;
		case ACTION_CHALLENGE_BID:
			result = @"ACTION_CHALLENGE_BID";
			break;
		case ACTION_CHALLENGE_PASS:
			result = @"ACTION_CHALLENGE_PASS";
			break;
		case ACTION_EXACT:
			result = @"ACTION_EXACT";
			break;
		case ACTION_PASS:
			result = @"ACTION_PASS";
			break;
		case ACTION_QUIT:
			result = @"ACTION_QUIT";
			break;
		case ACTION_LOST:
			result = @"ACTION_LOST";
			break;
		case TUTORIAL:
			result = @"TUTORIAL";
			break;
		default:
			[NSException raise:NSGenericException format:@"Unexpected FormatType."];
	}

	return result;
}

- (NSString*)description
{
    NSMutableString* pushString = [[NSMutableString alloc] init];
    
    for (Die* die in push)
        [pushString appendFormat:@" %i", die.dieValue];
    
	return [NSString stringWithFormat:@"(ActionType: %u) (PlayerID: %li) (Count: %i) (Face: %i) (Push:%@) (TargetID: %li)", actionType, (long)playerID, count, face, pushString, (long)targetID];
}

@end
