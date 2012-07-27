//
//  DiceSoarPlayer.h
//  Lair's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Player.h"

@interface DiceSoarPlayer : NSObject <Player> {
    int playerID;
    NSString *name;
}

@property (readwrite, retain) NSString *name;

-(id)initWithName:(NSString*)name;

@end
