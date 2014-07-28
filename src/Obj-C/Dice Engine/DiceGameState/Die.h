//
//  Die.h
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NUMBER_OF_SIDES 6

@class DiceGame;

@interface Die : NSObject

-(id)initWithCoder:(NSCoder*)decoder withCount:(int)count withPrefix:(NSString*)prefix;
-(void)encodeWithCoder:(NSCoder*)encoder withCount:(int)count withPrefix:(NSString*)prefix;

@property (readonly) int dieValue;
@property (readonly) BOOL hasBeenPushed;
@property (readwrite, assign) BOOL markedToPush;

- (id)init:(DiceGame*)game;
- (id)initWithNumber:(int)dieValue;
- (void)roll:(DiceGame*)game;
- (void)push;

- (NSString *)asString;

+ (int)getNumberOfDiceSides;

- (BOOL) isEqual:(Die *)die;

@end
