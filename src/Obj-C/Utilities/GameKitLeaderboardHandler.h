//
//  GameKitLeaderboardHandler.h
//  UM Liars Dice
//
//  Created by Alex Turner on 7/18/14.
//
//

#import <Foundation/Foundation.h>

@class DiceGame;

@interface GameKitLeaderboardHandler : NSObject

@property (nonatomic, strong) NSArray* leaderboards;

- (id)init;

- (void)updateGame:(DiceGame*)game;

@end
