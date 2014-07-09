//
//  Bid.h
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Bid : NSObject <EngineClass>

@property (nonatomic, strong) NSArray *diceToPush;
@property (nonatomic, readonly) NSInteger playerID;
@property (nonatomic, readonly) int numberOfDice;
@property (nonatomic, readonly) int rankOfDie;
@property (readwrite, strong) NSString *playerName;

- (id)initWithPlayerID:(NSInteger)playerIDToSet name:(NSString *)playerName dice:(int)dice rank:(int)rank;
- (id)initWithPlayerID:(NSInteger)playerIDToSet name:(NSString *)playerName dice:(int)dice rank:(int)rank push:(NSArray *)dicePushing;

-(id)initWithCoder:(NSCoder*)decoder;
-(void)encodeWithCoder:(NSCoder*)encoder;

- (BOOL)isLegalRaise:(Bid *)previousBid specialRules:(BOOL)specialRules playerSpecialRules:(BOOL)playerSpecialRules;

- (NSString *)asString;
- (NSString *)asStringOldStyle;

- (NSString *)description;
- (NSString *)debugDescription;

@end
