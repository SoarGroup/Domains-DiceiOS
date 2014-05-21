//
//  MultiplayerMatchData.h
//  UM Liars Dice
//
//  Created by Alex Turner on 5/7/14.
//
//

#import <Foundation/Foundation.h>
#import "DiceGame.h"

@interface MultiplayerMatchData : NSObject

@property (strong, nonatomic) DiceGame* theGame;
@property (strong, nonatomic) NSData* theData;

-(id)initWithGame:(DiceGame*)theGame;
-(id)initWithData:(NSData*)theData withRequest:(GKMatchRequest*)matchRequest withMatch:(GKTurnBasedMatch*)match withHandler:(GameKitGameHandler*)handler;

@end
