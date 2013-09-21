//
//  Bid.h
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Bid : NSObject {
@private
    NSInteger playerID;
    int numberOfDice;
    int rankOfDie;
    NSArray *diceToPush;
    NSString *playerName;
}

@property (nonatomic, retain) NSArray *diceToPush;
@property (nonatomic, readonly) NSInteger playerID;
@property (nonatomic, readonly) int numberOfDice;
@property (nonatomic, readonly) int rankOfDie;
@property (readwrite, retain) NSString *playerName;

- (id)initWithPlayerID:(NSInteger)playerIDToSet name:(NSString *)playerName dice:(int)dice rank:(int)rank;
- (id)initWithPlayerID:(NSInteger)playerIDToSet name:(NSString *)playerName dice:(int)dice rank:(int)rank push:(NSArray *)dicePushing;

- (void)dealloc;

- (BOOL)isLegalRaise:(Bid *)previousBid specialRules:(BOOL)specialRules playerSpecialRules:(BOOL)playerSpecialRules;

- (NSString *)asString;

@end
