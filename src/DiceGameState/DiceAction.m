//
//  DiceAction.m
//  Lair's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DiceAction.h"

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

+ (DiceAction *) bidAction:(int)playerID count:(int)count face:(int)face push:(NSArray *)push {
    DiceAction *ret = [[[DiceAction alloc] init] autorelease];
    ret.actionType = ACTION_BID;
    ret.playerID = playerID;
    ret.count = count;
    ret.face = face;
    ret.push = push;
    return ret;
}

+ (DiceAction *) challengeAction:(int)playerID target:(int)targetId {
    DiceAction *ret = [[[DiceAction alloc] init] autorelease];
    ret.actionType = ACTION_CHALLENGE_BID; // TODO test for bid / pass challenge?
    ret.playerID = playerID;
    ret.targetID = targetId;
    return ret;
}

+ (DiceAction *) exactAction:(int)playerID {
    DiceAction *ret = [[[DiceAction alloc] init] autorelease];
    ret.actionType = ACTION_EXACT;
    ret.playerID = playerID;
    return ret;
}

+ (DiceAction *) passAction:(int)playerID push:(NSArray*)push {
    DiceAction *ret = [[[DiceAction alloc] init] autorelease];
    ret.actionType = ACTION_PASS;
    ret.playerID = playerID;
    ret.push = push;
    return ret;
}

+ (DiceAction *) acceptAction:(int)playerID {
    DiceAction *ret = [[[DiceAction alloc] init] autorelease];
    ret.actionType = ACTION_ACCEPT;
    ret.playerID = playerID;
    return ret;
}

+ (DiceAction *) pushAction:(int)playerID push:(NSArray *)push {
    DiceAction *ret = [[[DiceAction alloc] init] autorelease];
    ret.actionType = ACTION_PUSH;
    ret.playerID = playerID;
    ret.push = push;
    return ret;
}

@end
