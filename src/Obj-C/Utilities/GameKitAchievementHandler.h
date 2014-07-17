//
//  GameKitAchievementHandler.h
//  UM Liars Dice
//
//  Created by Alex Turner on 7/17/14.
//
//

#import <Foundation/Foundation.h>

@class GKAchievement;
@class DiceGame;

@interface GameKitAchievementHandler : NSObject

@property (nonatomic, strong) NSArray* achievements;

-(id)init;

+(NSArray*)addMissingAchievements:(NSArray*)achievements;
+(BOOL)containsAchievement:(NSString*)identifier achievementList:(NSArray*)achievements;

-(void)resetAchievements;
-(void)updateAchievements:(DiceGame*)game;

+(BOOL)handleBasicAchievement:(GKAchievement*)basicAchievement game:(DiceGame*)game;
+(BOOL)handleStriveAchievement:(GKAchievement*)striveAchievement game:(DiceGame*)game;
+(BOOL)handleHardAchievement:(GKAchievement*)hardAchievement game:(DiceGame*)game;
+(BOOL)handleHiddenAchievement:(GKAchievement*)hiddenAchievement game:(DiceGame*)game;

@end
