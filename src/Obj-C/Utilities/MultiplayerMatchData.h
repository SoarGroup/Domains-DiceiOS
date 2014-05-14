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

@property (readonly, nonatomic) DiceGame* theGame;
@property (readonly, nonatomic) NSData* theData;

-(id)initWithGame:(DiceGame*)theGame;
-(id)initWithData:(NSData*)theData;

@end
