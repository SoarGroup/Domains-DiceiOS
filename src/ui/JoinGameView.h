//
//  JoinGameView.h
//  Lair's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DiceGame;

@interface JoinGameView : UIViewController {
    DiceGame *game;
}

- (id)initWithGame:(DiceGame*)aGame;

@property (readwrite, retain) DiceGame *game;
- (IBAction)backPressed:(id)sender;

@end
