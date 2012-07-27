//
//  GameRecord.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/3/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "GameRecord.h"

@implementation GameRecord

@synthesize gameTime, numPlayers, firstPlace, secondPlace, thirdPlace, fourthPlace;

- (id)initWithGameTime:(GameTime)aGameTime
NumPlayers:(int)aNumPlayers
firstPlace:(int)aFirstPlace
secondPlace:(int)aSecondPlace
thirdPlace:(int)aThirdPlace
fourthPlace:(int)aFourthPlace
{
self = [super init];
if (self) {
    self.gameTime = aGameTime;
    self.numPlayers = aNumPlayers;
    self.firstPlace = aFirstPlace;
    self.secondPlace = aSecondPlace;
    self.thirdPlace = aThirdPlace;
    self.fourthPlace = aFourthPlace;
}
return self;
}

@end
