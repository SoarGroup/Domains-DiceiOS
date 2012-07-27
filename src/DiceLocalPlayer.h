//
//  DiceLocalPlayer.h
//  Lair's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Player.h"
#import "PlayGame.h"

@class PlayerState;
@class PlayGameView;

@interface DiceLocalPlayer : NSObject <Player> {
    NSString *name;
    PlayerState *playerState;
    int playerID;
    id <PlayGame> gameView;
}

@property (readwrite, retain) NSString *name;
@property (readwrite, retain) PlayerState *playerState;
@property (readwrite, retain) id <PlayGame> gameView;

- (id)initWithName:(NSString*)aName;


@end
