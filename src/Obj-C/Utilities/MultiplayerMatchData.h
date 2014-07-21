//
//  MultiplayerMatchData.h
//  UM Liars Dice
//
//  Created by Alex Turner on 5/7/14.
//
//

#import <Foundation/Foundation.h>
#import "DiceGame.h"

extern const int kNo_AIs;
extern const int kAI_Only;
extern const int kAI_Human;
extern const int kAI_1;
extern const int kAI_2;
extern const int kAI_3;
extern const int kAI_4;
extern const int kAI_5;
extern const int kAI_6;
extern const int kAI_7;
extern const int kAI_8;

@interface MultiplayerMatchData : NSObject

@property (strong, nonatomic) DiceGame* theGame;
@property (strong, nonatomic) NSData* theData;

-(id)initWithGame:(DiceGame*)theGame;
-(id)initWithData:(NSData*)theData withRequest:(GKMatchRequest*)matchRequest withMatch:(GKTurnBasedMatch*)match withHandler:(GameKitGameHandler*)handler;

@end
