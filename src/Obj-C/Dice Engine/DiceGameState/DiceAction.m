//
//  DiceAction.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
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

@end
